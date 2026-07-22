import 'ast.dart';
import 'common_syntax.dart';

final _className = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');
final _number = RegExp(r'^[0-9_.,]+');

TreemapAst parseTreemap(String source) {
  final metadata = readCommonMetadata(source);
  var syntax = hideIgnoredSyntax(source);
  final header = RegExp(r'^([\t \r\n]*)(treemap-beta|treemap)(?=\s|$)').firstMatch(syntax);
  if (header == null) {
    throwParseError(source, 'Expected treemap or treemap-beta', _firstContentOffset(syntax));
  }
  syntax = syntax.replaceRange(header.start, header.end, header.group(0)!.replaceAll(RegExp(r'[^\r\n]'), ' '));
  syntax = hideCommonMetadata(syntax);

  final rows = <TreemapRowAst>[];
  var offset = 0;
  for (final match in RegExp(r'.*(?:\r\n|\n|\r|$)').allMatches(syntax)) {
    final lexeme = match.group(0)!;
    final line = lexeme.replaceFirst(RegExp(r'[\r\n]+$'), '');
    if (line.trim().isNotEmpty) {
      rows.add(_parseRow(source, line, offset));
    }
    offset = match.end;
    if (match.start == match.end) break;
  }

  return TreemapAst(
    rows: List.unmodifiable(rows),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}

TreemapRowAst _parseRow(String source, String line, int lineOffset) {
  final indentation = RegExp(r'^[ \t]*').firstMatch(line)!.group(0)!;
  final content = line.substring(indentation.length);
  if (content.startsWith('classDef')) {
    return _parseClassDefinition(source, content, lineOffset + indentation.length);
  }
  return TreemapNodeRowAst(
    indent: indentation.length,
    item: _parseItem(source, content, lineOffset + indentation.length),
  );
}

TreemapClassDefAst _parseClassDefinition(String source, String content, int offset) {
  final match = RegExp(r'^classDef[ \t]+([A-Za-z_][A-Za-z0-9_]*)(?:[ \t]+([^;\r\n]*?))?;?[ \t]*$').firstMatch(content);
  if (match == null) throwParseError(source, 'Invalid classDef statement', offset);
  final style = match.group(2)?.trim();
  return TreemapClassDefAst(name: match.group(1)!, style: style == null || style.isEmpty ? null : style);
}

TreemapItemAst _parseItem(String source, String content, int offset) {
  if (content.isEmpty || (content[0] != '"' && content[0] != "'")) {
    throwParseError(source, 'Expected quoted treemap item', offset);
  }
  final quote = content[0];
  final closingQuote = content.indexOf(quote, 1);
  if (closingQuote < 0) throwParseError(source, 'Unterminated treemap item', offset);
  final name = content.substring(1, closingQuote);
  var rest = content.substring(closingQuote + 1).trimLeft();

  if (rest.isEmpty || rest.startsWith(':::')) {
    return TreemapSectionAst(name: name, classSelector: _parseClassSelector(source, rest, offset + closingQuote + 1));
  }

  if (rest[0] != ':' && rest[0] != ',') {
    throwParseError(source, 'Expected ":", ",", or class selector', offset + closingQuote + 1);
  }
  rest = rest.substring(1).trimLeft();
  final numberMatch = _number.firstMatch(rest);
  if (numberMatch == null) {
    throwParseError(source, 'Expected treemap value', offset + content.length - rest.length);
  }
  final numberLexeme = numberMatch.group(0)!;
  final value = _parseNumber(numberLexeme);
  final suffix = rest.substring(numberMatch.end).trimLeft();
  return TreemapLeafAst(
    name: name,
    value: value,
    classSelector: _parseClassSelector(source, suffix, offset + content.length - suffix.length),
  );
}

String? _parseClassSelector(String source, String suffix, int offset) {
  if (suffix.isEmpty) return null;
  if (!suffix.startsWith(':::')) {
    throwParseError(source, 'Unexpected treemap row content', offset);
  }
  final selector = suffix.substring(3).trim();
  if (!_className.hasMatch(selector)) {
    throwParseError(source, 'Invalid treemap class selector', offset + 3);
  }
  return selector;
}

num _parseNumber(String lexeme) {
  final normalized = lexeme.replaceAll(',', '');
  final prefix = RegExp(r'^(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)').firstMatch(normalized)?.group(0);
  // JavaScript's parseFloat returns NaN when NUMBER2 contains no numeric
  // prefix; preserve that upstream converter behavior.
  if (prefix == null) return double.nan;
  final value = double.parse(prefix);
  return value == value.truncateToDouble() ? value.toInt() : value;
}

int _firstContentOffset(String source) => RegExp(r'\S').firstMatch(source)?.start ?? 0;
