import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart/src/rendering/geometry/git_graph.dart';
import 'package:test/test.dart';

void main() {
  group('buildGitGraphModel', () {
    test('builds deterministic branch heads, merges, and cherry-picks', () {
      final model = buildGitGraphModel(
        const GitGraphAst(
          statements: [
            GitGraphCommitAst(id: 'ZERO'),
            GitGraphBranchAst(name: 'feature'),
            GitGraphCommitAst(id: 'A'),
            GitGraphCheckoutAst(branch: 'main'),
            GitGraphCommitAst(id: 'MAIN'),
            GitGraphMergeAst(branch: 'feature', id: 'M'),
            GitGraphCherryPickAst(id: 'A'),
          ],
        ),
        const GitGraphRenderOptions(),
      );

      expect(model.commits.map((commit) => commit.id), ['ZERO', 'A', 'MAIN', 'M', 'cherry-pick-4']);
      expect(model.commits[1].parents, ['ZERO']);
      expect(model.commits[2].parents, ['ZERO']);
      expect(model.commits[3].parents, ['MAIN', 'A']);
      expect(model.commits[3].kind, GitCommitKind.merge);
      expect(model.commits[4].parents, ['M', 'A']);
      expect(model.commits[4].kind, GitCommitKind.cherryPick);
      expect(model.commits[4].tags, ['cherry-pick:A']);
    });

    test('sorts explicit branch orders before stable implicit orders', () {
      final model = buildGitGraphModel(
        const GitGraphAst(
          statements: [
            GitGraphBranchAst(name: 'implicit'),
            GitGraphCheckoutAst(branch: 'main'),
            GitGraphBranchAst(name: 'first', order: -1),
          ],
        ),
        const GitGraphRenderOptions(),
      );

      expect(model.branches.map((branch) => branch.name), ['first', 'main', 'implicit']);
    });

    test('uses stable IDs for commits without explicit identifiers', () {
      final model = buildGitGraphModel(
        const GitGraphAst(statements: [GitGraphCommitAst(), GitGraphCommitAst()]),
        const GitGraphRenderOptions(),
      );

      expect(model.commits.map((commit) => commit.id), ['commit-0', 'commit-1']);
    });

    test('keeps the latest commit when an explicit ID is reused', () {
      final model = buildGitGraphModel(
        const GitGraphAst(
          statements: [
            GitGraphCommitAst(id: 'A', message: 'first'),
            GitGraphCommitAst(id: 'A', message: 'replacement'),
            GitGraphCommitAst(id: 'B'),
          ],
        ),
        const GitGraphRenderOptions(),
      );

      expect(model.commits.map((commit) => commit.id), ['A', 'B']);
      expect(model.commits.first.message, 'replacement');
      expect(model.commits.last.parents, ['A']);
    });

    test('keeps implicit branch order stable past nine branches', () {
      final model = buildGitGraphModel(
        GitGraphAst(statements: [for (var i = 1; i <= 12; i++) GitGraphBranchAst(name: 'b$i')]),
        const GitGraphRenderOptions(),
      );

      // Implicit orders must preserve creation order; the previous
      // `double.parse('0.$creationIndex')` made b10 (0.1) collide with b1 and
      // sort ahead of b2..b9.
      expect(model.branches.map((branch) => branch.name), [
        'main',
        'b1',
        'b2',
        'b3',
        'b4',
        'b5',
        'b6',
        'b7',
        'b8',
        'b9',
        'b10',
        'b11',
        'b12',
      ]);
    });
  });
}
