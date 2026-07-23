part of 'ast.dart';

/// Syntax tree for a `treemap` diagram.
final class TreemapAst extends DiagramAst {
  const TreemapAst({this.rows = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  @override
  DiagramType get type => DiagramType.treemap;

  final List<TreemapRowAst> rows;

  @override
  List<Object?> get diagramFields => [rows];
}

sealed class TreemapRowAst with _AstValueEquality {
  const TreemapRowAst();
}

final class TreemapNodeRowAst extends TreemapRowAst {
  const TreemapNodeRowAst({required this.indent, required this.item});

  final int indent;
  final TreemapItemAst item;

  @override
  List<Object?> get equalityFields => [indent, item];
}

final class TreemapClassDefAst extends TreemapRowAst {
  const TreemapClassDefAst({required this.name, this.style});

  final String name;
  final String? style;

  @override
  List<Object?> get equalityFields => [name, style];
}

sealed class TreemapItemAst with _AstValueEquality {
  const TreemapItemAst({required this.name, this.classSelector});

  final String name;
  final String? classSelector;
}

final class TreemapSectionAst extends TreemapItemAst {
  const TreemapSectionAst({required super.name, super.classSelector});

  @override
  List<Object?> get equalityFields => [name, classSelector];
}

final class TreemapLeafAst extends TreemapItemAst {
  const TreemapLeafAst({required super.name, required this.value, super.classSelector});

  final num value;

  @override
  List<Object?> get equalityFields => [name, value, classSelector];
}
