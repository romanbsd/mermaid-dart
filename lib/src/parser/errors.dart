/// A Mermaid source location, using one-based line and column numbers.
final class SourceLocation {
  const SourceLocation({required this.line, required this.column});

  final int line;
  final int column;
}

/// Thrown when Mermaid input does not conform to the selected grammar.
final class MermaidParseException implements FormatException {
  const MermaidParseException({
    required this.message,
    required this.source,
    required this.offset,
    required this.line,
    required this.column,
  });

  @override
  final String message;

  @override
  final String source;

  @override
  final int offset;

  final int line;
  final int column;

  @override
  String toString() =>
      'MermaidParseException: Parse error on line $line, column $column: '
      '$message';
}

/// Thrown when no parser has been implemented for a diagram type.
final class UnsupportedDiagramTypeException implements Exception {
  const UnsupportedDiagramTypeException(this.diagramType);

  final String diagramType;

  @override
  String toString() => 'Unsupported diagram type: $diagramType';
}
