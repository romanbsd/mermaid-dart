part of 'ast.dart';

/// Defines the supported git graph direction values.
enum GitGraphDirection {
  /// Selects the left to right variant.
  leftToRight,

  /// Selects the top to bottom variant.
  topToBottom,

  /// Selects the bottom to top variant.
  bottomToTop,
}

/// Defines the supported git graph commit type values.
enum GitGraphCommitType {
  /// Selects the normal variant.
  normal,

  /// Selects the reverse variant.
  reverse,

  /// Selects the highlight variant.
  highlight,
}

/// Typed abstract syntax tree node for git graph syntax.
final class GitGraphAst extends DiagramAst {
  /// Creates a typed [GitGraphAst].
  const GitGraphAst({
    this.direction,
    this.statements = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.gitGraph;

  /// The direction.
  final GitGraphDirection? direction;

  /// The statements.
  final List<GitGraphStatementAst> statements;

  @override
  List<Object?> get diagramFields => [direction, statements];
}

/// Typed abstract syntax tree node for git graph statement syntax.
sealed class GitGraphStatementAst with _AstValueEquality {
  const GitGraphStatementAst();
}

/// Typed abstract syntax tree node for git graph commit syntax.
final class GitGraphCommitAst extends GitGraphStatementAst {
  /// Creates a typed [GitGraphCommitAst].
  const GitGraphCommitAst({this.id, this.message, this.tags = const [], this.type});

  /// The id.
  final String? id;

  /// The message.
  final String? message;

  /// The tags.
  final List<String> tags;

  /// The type.
  final GitGraphCommitType? type;

  @override
  List<Object?> get equalityFields => [id, message, tags, type];
}

/// Typed abstract syntax tree node for git graph branch syntax.
final class GitGraphBranchAst extends GitGraphStatementAst {
  /// Creates a typed [GitGraphBranchAst].
  const GitGraphBranchAst({required this.name, this.order});

  /// The name.
  final String name;

  /// The order.
  final int? order;

  @override
  List<Object?> get equalityFields => [name, order];
}

/// Typed abstract syntax tree node for git graph merge syntax.
final class GitGraphMergeAst extends GitGraphStatementAst {
  /// Creates a typed [GitGraphMergeAst].
  const GitGraphMergeAst({required this.branch, this.id, this.tags = const [], this.type});

  /// The branch.
  final String branch;

  /// The id.
  final String? id;

  /// The tags.
  final List<String> tags;

  /// The type.
  final GitGraphCommitType? type;

  @override
  List<Object?> get equalityFields => [branch, id, tags, type];
}

/// Typed abstract syntax tree node for git graph checkout syntax.
final class GitGraphCheckoutAst extends GitGraphStatementAst {
  /// Creates a typed [GitGraphCheckoutAst].
  const GitGraphCheckoutAst({required this.branch});

  /// The branch.
  final String branch;

  @override
  List<Object?> get equalityFields => [branch];
}

/// Typed abstract syntax tree node for git graph cherry pick syntax.
final class GitGraphCherryPickAst extends GitGraphStatementAst {
  /// Creates a typed [GitGraphCherryPickAst].
  const GitGraphCherryPickAst({this.id, this.parent, this.tags = const []});

  /// The id.
  final String? id;

  /// The parent.
  final String? parent;

  /// The tags.
  final List<String> tags;

  @override
  List<Object?> get equalityFields => [id, parent, tags];
}
