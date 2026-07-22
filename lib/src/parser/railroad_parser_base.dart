import 'ast.dart';
import 'common_syntax.dart';

enum RailroadCommentKind { cStyleBlock, isoEbnf, hashLine }

final class RailroadDocumentContext {
  const RailroadDocumentContext({required this.scanner, required this.metadata});

  final RailroadScanner scanner;
  final CommonMetadata metadata;
}

RailroadDocumentContext prepareRailroadDocument(
  String source,
  String header, {
  Set<RailroadCommentKind> comments = const {},
  bool hideAbnfCommentLines = false,
}) {
  final metadata = readCommonMetadata(source);
  var syntax = hideIgnoredSyntax(source);
  final headerMatch = RegExp('^([\\t \\r\\n]*)${RegExp.escape(header)}(?=\\s|\$)').firstMatch(syntax);
  if (headerMatch == null) {
    throwParseError(source, 'Expected $header', _firstNonWhitespace(syntax));
  }
  syntax = syntax.replaceRange(
    headerMatch.start,
    headerMatch.end,
    headerMatch.group(0)!.replaceAll(RegExp(r'[^\r\n]'), ' '),
  );
  syntax = hideCommonMetadata(syntax);
  if (hideAbnfCommentLines) {
    syntax = syntax.replaceAllMapped(
      RegExp(r'^[\t ]*;[^\n\r]*', multiLine: true),
      (match) => match.group(0)!.replaceAll(RegExp(r'[^\r\n]'), ' '),
    );
  }
  return RailroadDocumentContext(
    scanner: RailroadScanner(source, syntax, comments: comments),
    metadata: CommonMetadata(
      title: _decodeTitle(metadata.title),
      accessibilityTitle: metadata.accessibilityTitle,
      accessibilityDescription: metadata.accessibilityDescription,
    ),
  );
}

RailroadAst railroadAst(CommonMetadata metadata, List<RailroadRuleAst> rules) => RailroadAst(
  rules: List.unmodifiable(rules),
  title: metadata.title,
  accessibilityTitle: metadata.accessibilityTitle,
  accessibilityDescription: metadata.accessibilityDescription,
);

RailroadNodeAst railroadSequence(List<RailroadNodeAst> elements) =>
    elements.length == 1 ? elements.single : RailroadSequenceAst(List.unmodifiable(elements));

RailroadNodeAst railroadChoice(List<RailroadNodeAst> alternatives) =>
    alternatives.length == 1 ? alternatives.single : RailroadChoiceAst(List.unmodifiable(alternatives));

String? _decodeTitle(String? title) {
  if (title == null || title.length < 2) return title;
  final first = title[0];
  if ((first == '"' || first == "'") && title[title.length - 1] == first) {
    return decodeQuotedString(title);
  }
  return title;
}

int _firstNonWhitespace(String source) {
  final match = RegExp(r'\S').firstMatch(source);
  return match?.start ?? 0;
}

base class RailroadScanner {
  RailroadScanner(this.originalSource, this.source, {this.comments = const {}});

  final String originalSource;
  final String source;
  final Set<RailroadCommentKind> comments;
  int position = 0;

  bool get isAtEnd {
    skipTrivia();
    return position >= source.length;
  }

  bool get isRawAtEnd => position >= source.length;

  String? get current {
    skipTrivia();
    return position < source.length ? source[position] : null;
  }

  void skipTrivia() {
    while (position < source.length) {
      final start = position;
      while (position < source.length && _isWhitespace(source.codeUnitAt(position))) {
        position++;
      }
      if (comments.contains(RailroadCommentKind.cStyleBlock) && startsWith('/*', skip: false)) {
        _skipBlockComment('*/');
      } else if (comments.contains(RailroadCommentKind.isoEbnf) && startsWith('(*', skip: false)) {
        _skipBlockComment('*)');
      } else if (comments.contains(RailroadCommentKind.hashLine) && startsWith('#', skip: false)) {
        while (position < source.length && source[position] != '\n' && source[position] != '\r') {
          position++;
        }
      }
      if (position == start) return;
    }
  }

  bool startsWith(String value, {bool skip = true}) {
    if (skip) skipTrivia();
    return source.startsWith(value, position);
  }

  bool tryConsume(String value) {
    skipTrivia();
    if (!source.startsWith(value, position)) return false;
    position += value.length;
    return true;
  }

  void expect(String value) {
    if (!tryConsume(value)) fail('Expected "$value"');
  }

  String identifier(RegExp pattern, {String description = 'identifier'}) {
    skipTrivia();
    final match = pattern.matchAsPrefix(source, position);
    if (match == null) fail('Expected $description');
    position = match.end;
    return match.group(0)!;
  }

  String quotedString({bool allowSingle = true, bool decodeEscapes = true}) {
    skipTrivia();
    if (position >= source.length || (source[position] != '"' && (!allowSingle || source[position] != "'"))) {
      fail('Expected string literal');
    }
    final quote = source[position];
    final start = position++;
    while (position < source.length) {
      if (source[position] == '\\' && decodeEscapes) {
        position += 2;
        continue;
      }
      if (source[position++] == quote) {
        final lexeme = source.substring(start, position);
        return decodeEscapes ? decodeQuotedString(lexeme) : lexeme.substring(1, lexeme.length - 1);
      }
    }
    fail('Unterminated string literal', at: start);
  }

  String takeWhile(bool Function(int codeUnit) predicate) {
    skipTrivia();
    final start = position;
    while (position < source.length && predicate(source.codeUnitAt(position))) {
      position++;
    }
    return source.substring(start, position);
  }

  Never fail(String message, {int? at}) => throwParseError(originalSource, message, at ?? position);

  void _skipBlockComment(String terminator) {
    final start = position;
    position += 2;
    final end = source.indexOf(terminator, position);
    if (end < 0) fail('Unterminated comment', at: start);
    position = end + terminator.length;
  }
}

bool _isWhitespace(int codeUnit) => codeUnit == 0x20 || codeUnit == 0x09 || codeUnit == 0x0a || codeUnit == 0x0d;
