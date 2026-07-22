import 'package:collection/collection.dart';

import '../../parser/ast.dart';
import '../options.dart';

enum GitCommitKind { commit, merge, cherryPick }

final class GitGraphModel {
  const GitGraphModel({required this.branches, required this.commits});

  final List<GitBranchModel> branches;
  final List<GitCommitModel> commits;
}

final class GitBranchModel {
  const GitBranchModel({required this.name, required this.order, required this.creationIndex});

  final String name;
  final double order;
  final int creationIndex;
}

final class GitCommitModel {
  const GitCommitModel({
    required this.id,
    required this.message,
    required this.sequence,
    required this.branch,
    required this.parents,
    required this.tags,
    required this.kind,
    required this.type,
    this.customType,
    this.customId = false,
  });

  final String id;
  final String message;
  final int sequence;
  final String branch;
  final List<String> parents;
  final List<String> tags;
  final GitCommitKind kind;
  final GitGraphCommitType type;
  final GitGraphCommitType? customType;
  final bool customId;

  GitGraphCommitType? get decoratedType => customType ?? (kind == GitCommitKind.commit ? type : null);
}

GitGraphModel buildGitGraphModel(GitGraphAst ast, GitGraphRenderOptions options) {
  final branches = <GitBranchModel>[
    GitBranchModel(name: options.mainBranchName, order: options.mainBranchOrder, creationIndex: 0),
  ];
  final heads = <String, String?>{options.mainBranchName: null};
  final commits = <GitCommitModel>[];
  var currentBranch = options.mainBranchName;

  GitCommitModel? commitById(String? id) => id == null ? null : commits.where((commit) => commit.id == id).lastOrNull;
  void addCommit(GitCommitModel commit) {
    commits.add(commit);
    heads[currentBranch] = commit.id;
  }

  for (final statement in ast.statements) {
    switch (statement) {
      case GitGraphBranchAst(:final name, :final order):
        if (heads.containsKey(name)) continue;
        final creationIndex = branches.length;
        branches.add(
          GitBranchModel(
            name: name,
            order: order?.toDouble() ?? double.parse('0.$creationIndex'),
            creationIndex: creationIndex,
          ),
        );
        heads[name] = heads[currentBranch];
        currentBranch = name;
      case GitGraphCheckoutAst(:final branch):
        if (!heads.containsKey(branch)) {
          throw ArgumentError.value(branch, 'branch', 'Cannot checkout an unknown branch');
        }
        currentBranch = branch;
      case GitGraphCommitAst(:final id, :final message, :final tags, :final type):
        final sequence = commits.length;
        final parent = heads[currentBranch];
        addCommit(
          GitCommitModel(
            id: id ?? 'commit-$sequence',
            message: message ?? '',
            sequence: sequence,
            branch: currentBranch,
            parents: [?parent],
            tags: tags,
            kind: GitCommitKind.commit,
            type: type ?? GitGraphCommitType.normal,
            customId: id != null,
          ),
        );
      case GitGraphMergeAst(:final branch, :final id, :final tags, :final type):
        final currentHead = heads[currentBranch];
        final otherHead = heads[branch];
        if (currentHead == null || otherHead == null || branch == currentBranch) continue;
        final sequence = commits.length;
        addCommit(
          GitCommitModel(
            id: id ?? 'merge-$sequence',
            message: 'merged branch $branch into $currentBranch',
            sequence: sequence,
            branch: currentBranch,
            parents: [currentHead, otherHead],
            tags: tags,
            kind: GitCommitKind.merge,
            type: GitGraphCommitType.normal,
            customType: type,
            customId: id != null,
          ),
        );
      case GitGraphCherryPickAst(:final id, :final parent, :final tags):
        final source = commitById(id);
        final currentHead = heads[currentBranch];
        if (source == null || currentHead == null || source.branch == currentBranch) continue;
        if (source.kind == GitCommitKind.merge && (parent == null || !source.parents.contains(parent))) continue;
        final sequence = commits.length;
        addCommit(
          GitCommitModel(
            id: 'cherry-pick-$sequence',
            message: 'cherry-picked ${source.message} into $currentBranch',
            sequence: sequence,
            branch: currentBranch,
            parents: [currentHead, source.id],
            tags: tags.isEmpty
                ? ['cherry-pick:${source.id}${source.kind == GitCommitKind.merge ? '|parent:$parent' : ''}']
                : tags,
            kind: GitCommitKind.cherryPick,
            type: GitGraphCommitType.normal,
          ),
        );
    }
  }

  final sortedBranches = [...branches]
    ..sort((left, right) {
      final byOrder = left.order.compareTo(right.order);
      return byOrder != 0 ? byOrder : left.creationIndex.compareTo(right.creationIndex);
    });
  return GitGraphModel(branches: sortedBranches, commits: commits);
}
