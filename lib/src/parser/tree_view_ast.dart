part of 'ast.dart';

/// Typed abstract syntax tree node for tree view syntax.
final class TreeViewAst extends DiagramAst {
  /// Creates a typed [TreeViewAst].
  const TreeViewAst({this.nodes = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  @override
  DiagramType get type => DiagramType.treeView;

  /// The nodes.
  final List<TreeViewNodeAst> nodes;

  @override
  List<Object?> get diagramFields => [nodes];
}

/// Typed abstract syntax tree node for tree view node syntax.
final class TreeViewNodeAst with _AstValueEquality {
  /// Creates a typed [TreeViewNodeAst].
  const TreeViewNodeAst({required this.name, this.indent, this.cssClass, this.icon, this.description});

  /// The name.
  final String name;

  /// The indent.
  final int? indent;

  /// The css class.
  final String? cssClass;

  /// The icon.
  final String? icon;

  /// The description.
  final String? description;

  @override
  List<Object?> get equalityFields => [name, indent, cssClass, icon, description];
}
