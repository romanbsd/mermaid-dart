/// A Mermaid source location, using one-based line and column numbers.
final class SourceLocation {
  /// Creates a location at the one-based [line] and [column].
  const SourceLocation({required this.line, required this.column});

  /// The one-based source line.
  final int line;

  /// The one-based source column.
  final int column;
}

/// Thrown when Mermaid input does not conform to the selected grammar.
final class MermaidParseException implements FormatException {
  /// Creates a parse failure for [source] at [offset], [line], and [column].
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

  /// The one-based line containing the parse failure.
  final int line;

  /// The one-based column containing the parse failure.
  final int column;

  @override
  String toString() =>
      'MermaidParseException: Parse error on line $line, column $column: '
      '$message';
}

/// Thrown when no parser has been implemented for a diagram type.
final class UnsupportedDiagramTypeException implements Exception {
  /// Creates an exception for the unsupported [diagramType] wire name.
  const UnsupportedDiagramTypeException(this.diagramType);

  /// The unrecognized diagram type supplied by the caller.
  final String diagramType;

  @override
  String toString() => 'Unsupported diagram type: $diagramType';
}
