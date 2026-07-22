part of 'ast.dart';

final class TreeViewAst extends DiagramAst {
  const TreeViewAst({this.nodes = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  final List<TreeViewNodeAst> nodes;

  @override
  List<Object?> get diagramFields => [nodes];
}

final class TreeViewNodeAst with _AstValueEquality {
  const TreeViewNodeAst({required this.name, this.indent, this.cssClass, this.icon, this.description});

  final String name;
  final int? indent;
  final String? cssClass;
  final String? icon;
  final String? description;

  @override
  List<Object?> get equalityFields => [name, indent, cssClass, icon, description];
}
