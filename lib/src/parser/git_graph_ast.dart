part of 'ast.dart';

enum GitGraphDirection { leftToRight, topToBottom, bottomToTop }

enum GitGraphCommitType { normal, reverse, highlight }

final class GitGraphAst extends DiagramAst {
  const GitGraphAst({
    this.direction,
    this.statements = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.gitGraph;

  final GitGraphDirection? direction;
  final List<GitGraphStatementAst> statements;

  @override
  List<Object?> get diagramFields => [direction, statements];
}

sealed class GitGraphStatementAst with _AstValueEquality {
  const GitGraphStatementAst();
}

final class GitGraphCommitAst extends GitGraphStatementAst {
  const GitGraphCommitAst({this.id, this.message, this.tags = const [], this.type});

  final String? id;
  final String? message;
  final List<String> tags;
  final GitGraphCommitType? type;

  @override
  List<Object?> get equalityFields => [id, message, tags, type];
}

final class GitGraphBranchAst extends GitGraphStatementAst {
  const GitGraphBranchAst({required this.name, this.order});

  final String name;
  final int? order;

  @override
  List<Object?> get equalityFields => [name, order];
}

final class GitGraphMergeAst extends GitGraphStatementAst {
  const GitGraphMergeAst({required this.branch, this.id, this.tags = const [], this.type});

  final String branch;
  final String? id;
  final List<String> tags;
  final GitGraphCommitType? type;

  @override
  List<Object?> get equalityFields => [branch, id, tags, type];
}

final class GitGraphCheckoutAst extends GitGraphStatementAst {
  const GitGraphCheckoutAst({required this.branch});

  final String branch;

  @override
  List<Object?> get equalityFields => [branch];
}

final class GitGraphCherryPickAst extends GitGraphStatementAst {
  const GitGraphCherryPickAst({this.id, this.parent, this.tags = const []});

  final String? id;
  final String? parent;
  final List<String> tags;

  @override
  List<Object?> get equalityFields => [id, parent, tags];
}
