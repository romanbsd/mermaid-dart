part of 'ast.dart';

/// Syntax tree for a `treemap` diagram.
final class TreemapAst extends DiagramAst {
  /// Creates a typed [TreemapAst].
  const TreemapAst({this.rows = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  @override
  DiagramType get type => DiagramType.treemap;

  /// The rows.
  final List<TreemapRowAst> rows;

  @override
  List<Object?> get diagramFields => [rows];
}

/// Typed abstract syntax tree node for treemap row syntax.
sealed class TreemapRowAst with _AstValueEquality {
  const TreemapRowAst();
}

/// Typed abstract syntax tree node for treemap node row syntax.
final class TreemapNodeRowAst extends TreemapRowAst {
  /// Creates a typed [TreemapNodeRowAst].
  const TreemapNodeRowAst({required this.indent, required this.item});

  /// The indent.
  final int indent;

  /// The item.
  final TreemapItemAst item;

  @override
  List<Object?> get equalityFields => [indent, item];
}

/// Typed abstract syntax tree node for treemap class def syntax.
final class TreemapClassDefAst extends TreemapRowAst {
  /// Creates a typed [TreemapClassDefAst].
  const TreemapClassDefAst({required this.name, this.style});

  /// The name.
  final String name;

  /// The style.
  final String? style;

  @override
  List<Object?> get equalityFields => [name, style];
}

/// Typed abstract syntax tree node for treemap item syntax.
sealed class TreemapItemAst with _AstValueEquality {
  const TreemapItemAst({required this.name, this.classSelector});

  /// The name.
  final String name;

  /// The class selector.
  final String? classSelector;
}

/// Typed abstract syntax tree node for treemap section syntax.
final class TreemapSectionAst extends TreemapItemAst {
  /// Creates a typed [TreemapSectionAst].
  const TreemapSectionAst({required super.name, super.classSelector});

  @override
  List<Object?> get equalityFields => [name, classSelector];
}

/// Typed abstract syntax tree node for treemap leaf syntax.
final class TreemapLeafAst extends TreemapItemAst {
  /// Creates a typed [TreemapLeafAst].
  const TreemapLeafAst({required super.name, required this.value, super.classSelector});

  /// The value.
  final num value;

  @override
  List<Object?> get equalityFields => [name, value, classSelector];
}
