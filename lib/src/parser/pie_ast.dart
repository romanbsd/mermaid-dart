part of 'ast.dart';

/// Syntax tree for a `pie` diagram.
final class PieAst extends DiagramAst {
  const PieAst({
    this.showData = false,
    this.sections = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  final bool showData;
  final List<PieSectionAst> sections;

  @override
  List<Object?> get diagramFields => [showData, sections];
}

/// A labeled numeric section in a [PieAst].
final class PieSectionAst with _AstValueEquality {
  const PieSectionAst({required this.label, required this.value});

  final String label;
  final num value;

  @override
  List<Object?> get equalityFields => [label, value];

  @override
  String toString() => 'PieSectionAst(label: $label, value: $value)';
}
