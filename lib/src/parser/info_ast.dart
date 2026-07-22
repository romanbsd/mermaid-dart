part of 'ast.dart';

/// Syntax tree for an `info` diagram.
final class InfoAst extends DiagramAst {
  const InfoAst({super.title, super.accessibilityTitle, super.accessibilityDescription});

  @override
  List<Object?> get diagramFields => const [];

  @override
  String toString() =>
      'InfoAst(title: $title, accessibilityTitle: $accessibilityTitle, '
      'accessibilityDescription: $accessibilityDescription)';
}
