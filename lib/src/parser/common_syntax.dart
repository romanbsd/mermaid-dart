import 'package:collection/collection.dart';
import 'package:petitparser/petitparser.dart';
import 'package:yaml/yaml.dart';

import 'errors.dart';

final Parser<Object?> horizontalSpaceParser = pattern(' \t').star();
final Parser<Object?> whitespaceParser = pattern(' \t\r\n').star();
final Parser<Object?> lineEndParser = char('\n') | endOfInput();
final Parser<Object?> lineTextParser = pattern('^\n\r').star();
final Parser<Object?> quotedStringParser =
    (char('"') & (char('\\') & any() | pattern('^"\\\\')).star() & char('"')) |
    (char("'") & (char('\\') & any() | pattern("^'\\\\")).star() & char("'"));

final Parser<CommonMetadataEntry> _titleParser =
    (string('title') & ((pattern(' \t').plus() & lineTextParser & lineEndParser) | lineEndParser)).flatten().map(
      (lexeme) => DiagramTitleEntry(normalizeSingleLine(lexeme.substring('title'.length))),
    );
final Parser<CommonMetadataEntry> _accessibilityTitleParser =
    (string('accTitle') & horizontalSpaceParser & char(':') & lineTextParser & lineEndParser).flatten().map(
      (lexeme) => AccessibilityTitleEntry(normalizeSingleLine(lexeme.substring(lexeme.indexOf(':') + 1))),
    );
final Parser<Object?> _singleLineAccessibilityDescriptionParser = char(':') & lineTextParser & lineEndParser;
final Parser<Object?> _multiLineAccessibilityDescriptionParser =
    char('{') & any().starLazy(char('}')) & char('}') & horizontalSpaceParser & lineEndParser;
final Parser<CommonMetadataEntry> _accessibilityDescriptionParser =
    (string('accDescr') &
            horizontalSpaceParser &
            (_singleLineAccessibilityDescriptionParser | _multiLineAccessibilityDescriptionParser))
        .flatten()
        .map((lexeme) => AccessibilityDescriptionEntry(_metadataDescriptionValue(lexeme)));

final Parser<Object?> commonMetadataParser = _titleParser | _accessibilityTitleParser | _accessibilityDescriptionParser;

sealed class CommonMetadataEntry {
  const CommonMetadataEntry(this.value);

  final String value;
}

final class DiagramTitleEntry extends CommonMetadataEntry {
  const DiagramTitleEntry(super.value);
}

final class AccessibilityTitleEntry extends CommonMetadataEntry {
  const AccessibilityTitleEntry(super.value);
}

final class AccessibilityDescriptionEntry extends CommonMetadataEntry {
  const AccessibilityDescriptionEntry(super.value);
}

final class CommonMetadata {
  const CommonMetadata({this.title, this.accessibilityTitle, this.accessibilityDescription});

  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;

  /// Keeps explicitly parsed metadata and fills absent values from [fallback].
  CommonMetadata withFallback(CommonMetadata fallback) => CommonMetadata(
    title: title ?? fallback.title,
    accessibilityTitle: accessibilityTitle ?? fallback.accessibilityTitle,
    accessibilityDescription: accessibilityDescription ?? fallback.accessibilityDescription,
  );
}

Object? parseGrammar(
  Parser<Object?> grammar,
  String source, {
  void Function(String syntax, Failure failure)? onFailure,
}) {
  final syntax = hideIgnoredSyntax(source);
  final result = grammar.parse(syntax);
  if (result is Failure) {
    onFailure?.call(syntax, result);
    throwParseFailure(source, result);
  }
  return result.value;
}

List<T> flattenParserValues<T>(Object? value) {
  final values = <T>[];
  void collect(Object? part) {
    switch (part) {
      case T():
        values.add(part);
      case Iterable<Object?>():
        part.forEach(collect);
    }
  }

  collect(value);
  return values;
}

CommonMetadata commonMetadataFromParserValues(Object? value) {
  String? title;
  String? accessibilityTitle;
  String? accessibilityDescription;
  for (final entry in flattenParserValues<CommonMetadataEntry>(value)) {
    switch (entry) {
      case DiagramTitleEntry():
        title = entry.value;
      case AccessibilityTitleEntry():
        accessibilityTitle = entry.value;
      case AccessibilityDescriptionEntry():
        accessibilityDescription = entry.value;
    }
  }
  return CommonMetadata(
    title: title,
    accessibilityTitle: accessibilityTitle,
    accessibilityDescription: accessibilityDescription,
  );
}

final class PreparedDiagramSource {
  const PreparedDiagramSource({required this.syntax, required this.metadata});

  /// Source with ignored syntax, the diagram header, and metadata masked.
  /// Newlines and offsets are preserved for diagnostics.
  final String syntax;
  final CommonMetadata metadata;
}

final class SourceLine {
  const SourceLine({required this.text, required this.offset});

  final String text;
  final int offset;
}

PreparedDiagramSource prepareDiagramSource(String source, {required List<String> headers}) {
  assert(headers.isNotEmpty);
  final metadata = readCommonMetadata(source);
  var syntax = hideIgnoredSyntax(source);
  final alternatives = [...headers]..sort((left, right) => right.length.compareTo(left.length));
  final header = RegExp(
    '^([\\t \\r\\n]*)(?:${alternatives.map(RegExp.escape).join('|')})(?=\\s|\$)',
  ).firstMatch(syntax);
  if (header == null) {
    throwParseError(source, 'Expected ${headers.join(' or ')}', firstNonWhitespaceOffset(syntax));
  }
  syntax = syntax.replaceRange(header.start, header.end, _hideNonNewlines(header.group(0)!));
  return PreparedDiagramSource(syntax: hideCommonMetadata(syntax), metadata: metadata);
}

List<SourceLine> sourceLines(String source) => [
  for (final match in RegExp(r'.*(?:\r\n|\n|\r|$)').allMatches(source))
    if (match.start != match.end)
      SourceLine(text: match.group(0)!.replaceFirst(RegExp(r'[\r\n]+$'), ''), offset: match.start),
];

int firstNonWhitespaceOffset(String source) => RegExp(r'\S').firstMatch(source)?.start ?? 0;

String hideIgnoredSyntax(String source) {
  var result = source;
  for (final expression in [
    _frontmatterBlock,
    RegExp(r'[\t ]*%%\{[\s\S]*?\}%%(?:\r?\n|(?!\S))'),
    RegExp(r'[\t ]*%%[^\n\r]*'),
  ]) {
    result = result.replaceAllMapped(expression, (match) {
      return _hideNonNewlines(match.group(0)!);
    });
  }
  return result;
}

CommonMetadata readCommonMetadata(String source) => CommonMetadata(
  title: _singleLineValue(source, 'title', separator: ' ') ?? _frontmatterTitle(source),
  accessibilityTitle: _singleLineValue(source, 'accTitle', separator: ':'),
  accessibilityDescription: _accessibilityDescriptionValue(source),
);

String? _frontmatterTitle(String source) {
  final contents = _frontmatterBlock.firstMatch(source)?.group(1);
  if (contents == null) return null;
  final document = loadYaml(contents);
  return document is YamlMap && document['title'] is String ? document['title'] as String : null;
}

final _frontmatterBlock = RegExp(r'^[\t ]*(?:\r?\n[\t ]*)*---[\t ]*\r?\n([\s\S]*?\r?\n)?---(?:\r?\n|(?!\S))');

/// Replaces common metadata with spaces while preserving source offsets.
String hideCommonMetadata(String source) {
  var result = source;
  for (final expression in [
    RegExp(r'^[\t ]*title(?:[\t ][^\n\r]*)?', multiLine: true),
    RegExp(r'^[\t ]*accTitle[\t ]*:[^\n\r]*', multiLine: true),
    RegExp(r'^[\t ]*accDescr[\t ]*(?::[^\n\r]*|\{[^}]*\})', multiLine: true),
  ]) {
    result = result.replaceAllMapped(expression, (match) {
      return _hideNonNewlines(match.group(0)!);
    });
  }
  return result;
}

Never throwParseFailure(String source, Failure failure) {
  throwParseError(source, failure.message, failure.position);
}

/// Reports a failure on the zero-based [line] of [source], for parsers that scan
/// line by line and have no offset inside the line to point at.
Never throwParseErrorOnLine(String source, int line, String message) {
  final safeLine = line.clamp(0, source.split(RegExp(r'\r?\n')).length - 1);
  throw MermaidParseException(message: message, source: source, offset: 0, line: safeLine + 1, column: 1);
}

Never throwParseError(String source, String message, int offset) {
  final location = sourceLocationAt(source, offset);
  throw MermaidParseException(
    message: message,
    source: source,
    offset: offset,
    line: location.line,
    column: location.column,
  );
}

SourceLocation sourceLocationAt(String source, int offset) {
  var line = 1;
  var column = 1;
  for (var index = 0; index < offset && index < source.length; index++) {
    if (source.codeUnitAt(index) == 10) {
      line++;
      column = 1;
    } else {
      column++;
    }
  }
  return SourceLocation(line: line, column: column);
}

String? _singleLineValue(String source, String keyword, {required String separator}) {
  final expression = separator == ' '
      ? RegExp('^[\\t ]*$keyword(?:[\\t ]([^\\n\\r]*))?[\\t ]*\$', multiLine: true)
      : RegExp('^[\\t ]*$keyword[\\t ]*${RegExp.escape(separator)}([^\\n\\r]*)', multiLine: true);
  final matches = expression.allMatches(source);
  final match = matches.isEmpty ? null : matches.last;
  return match == null ? null : normalizeSingleLine(match.group(1) ?? '');
}

String? _accessibilityDescriptionValue(String source) {
  final matches = RegExp(r'^[\t ]*accDescr[\t ]*(?::([^\n\r]*)|\{([^}]*)\})', multiLine: true).allMatches(source);
  final match = matches.isEmpty ? null : matches.last;
  if (match == null) return null;
  if (match.group(1) case final singleLine?) {
    return normalizeSingleLine(singleLine);
  }
  return match.group(2)!.split(RegExp(r'\r?\n')).map(normalizeSingleLine).where((line) => line.isNotEmpty).join('\n');
}

String normalizeSingleLine(String value) => value.trim().replaceAll(RegExp(r'[\t ]{2,}'), ' ');

String _metadataDescriptionValue(String lexeme) {
  final body = lexeme.substring('accDescr'.length).trim();
  if (body.startsWith(':')) return normalizeSingleLine(body.substring(1));
  return body
      .substring(1, body.length - 1)
      .split(RegExp(r'\r?\n|\r'))
      .map(normalizeSingleLine)
      .where((line) => line.isNotEmpty)
      .join('\n');
}

String decodeQuotedString(String lexeme) {
  final value = StringBuffer();
  for (var index = 1; index < lexeme.length - 1; index++) {
    final character = lexeme[index];
    if (character == '\\' && index + 1 < lexeme.length - 1) {
      final escaped = lexeme[++index];
      value.write(switch (escaped) {
        'n' => '\n',
        'r' => '\r',
        't' => '\t',
        _ => escaped,
      });
    } else {
      value.write(character);
    }
  }
  return value.toString();
}

/// Offsets of the non-overlapping [needle] occurrences in [value] that fall
/// outside a quoted run.
///
/// A run opens and closes on any character of [quotes], and while [escapes] is
/// set a backslash inside a run hides the character after it.
Iterable<int> _unquotedMatches(String value, String needle, String quotes, bool escapes) sync* {
  String? quote;
  for (var index = 0; index < value.length; index++) {
    final character = value[index];
    if (quote != null) {
      if (escapes && character == r'\') {
        index++;
      } else if (character == quote) {
        quote = null;
      }
    } else if (quotes.contains(character)) {
      quote = character;
    } else if (value.startsWith(needle, index)) {
      yield index;
      index += needle.length - 1;
    }
  }
}

/// Splits [value] on every [separator] outside a quoted run.
///
/// Segments keep their quotes and surrounding whitespace, and empty segments are
/// kept, so callers see exactly what the separators delimited.
List<String> splitOutsideQuotes(String value, String separator, {String quotes = '"\'', bool escapes = true}) {
  final result = <String>[];
  var start = 0;
  for (final index in _unquotedMatches(value, separator, quotes, escapes)) {
    result.add(value.substring(start, index));
    start = index + separator.length;
  }
  return result..add(value.substring(start));
}

/// The offset of the first [needle] in [value] outside a quoted run, or `-1`.
int indexOutsideQuotes(String value, String needle, {String quotes = '"\'', bool escapes = true}) =>
    _unquotedMatches(value, needle, quotes, escapes).firstOrNull ?? -1;

/// The offset of the last [needle] in [value] outside a quoted run, or `-1`.
int lastIndexOutsideQuotes(String value, String needle, {String quotes = '"\'', bool escapes = true}) =>
    _unquotedMatches(value, needle, quotes, escapes).lastOrNull ?? -1;

String _hideNonNewlines(String value) => value.replaceAll(RegExp(r'[^\r\n]'), ' ');
