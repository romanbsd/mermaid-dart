part of 'ast.dart';

/// Syntax tree for a `pie` diagram.
final class PieAst extends DiagramAst {
  /// Creates a typed [PieAst].
  const PieAst({
    this.showData = false,
    this.sections = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.pie;

  /// The show data.
  final bool showData;

  /// The sections.
  final List<PieSectionAst> sections;

  @override
  List<Object?> get diagramFields => [showData, sections];
}

/// A labeled numeric section in a [PieAst].
final class PieSectionAst with _AstValueEquality {
  /// Creates a typed [PieSectionAst].
  const PieSectionAst({required this.label, required this.value});

  /// The label.
  final String label;

  /// The value.
  final num value;

  @override
  List<Object?> get equalityFields => [label, value];

  @override
  String toString() => 'PieSectionAst(label: $label, value: $value)';
}
