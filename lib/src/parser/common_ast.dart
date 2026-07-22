part of 'ast.dart';

/// Base type for syntax trees produced by Mermaid parsers.
sealed class DiagramAst with _AstValueEquality {
  const DiagramAst({this.title, this.accessibilityTitle, this.accessibilityDescription});

  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;

  List<Object?> get diagramFields;

  @override
  List<Object?> get equalityFields => [...diagramFields, title, accessibilityTitle, accessibilityDescription];
}
