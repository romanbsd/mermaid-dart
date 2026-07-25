import 'ast.dart';
import 'common_syntax.dart';

enum RailroadCommentKind { cStyleBlock, isoEbnf, hashLine }

enum RailroadDialect {
  classic('railroad-beta', RailroadSyntax.classic, comments: {RailroadCommentKind.cStyleBlock}),
  ebnf(
    'railroad-ebnf-beta',
    RailroadSyntax.ebnf,
    comments: {RailroadCommentKind.cStyleBlock, RailroadCommentKind.isoEbnf},
  ),
  abnf('railroad-abnf-beta', RailroadSyntax.abnf, hideCommentLines: true),
  peg('railroad-peg-beta', RailroadSyntax.peg, comments: {RailroadCommentKind.hashLine});

  const RailroadDialect(this.header, this.syntax, {this.comments = const {}, this.hideCommentLines = false});

  final String header;
  final RailroadSyntax syntax;
  final Set<RailroadCommentKind> comments;
  final bool hideCommentLines;
}

final class RailroadDocumentContext {
  const RailroadDocumentContext({required this.scanner, required this.metadata});

  final RailroadScanner scanner;
  final CommonMetadata metadata;
}

RailroadAst parseRailroadRules(
  String source,
  RailroadDialect dialect,
  RailroadRuleAst Function(RailroadScanner scanner) parseRule,
) {
  final document = prepareRailroadDocument(source, dialect);
  final rules = <RailroadRuleAst>[];
  while (!document.scanner.isAtEnd) {
    rules.add(parseRule(document.scanner));
  }
  return railroadAst(document.metadata, rules, dialect.syntax);
}

RailroadDocumentContext prepareRailroadDocument(String source, RailroadDialect dialect) {
  final prepared = prepareDiagramSource(source, headers: [dialect.header]);
  var syntax = prepared.syntax;
  if (dialect.hideCommentLines) {
    syntax = syntax.replaceAllMapped(
      RegExp(r'^[\t ]*;[^\n\r]*', multiLine: true),
      (match) => match.group(0)!.replaceAll(RegExp(r'[^\r\n]'), ' '),
    );
  }
  return RailroadDocumentContext(
    scanner: RailroadScanner(source, syntax, comments: dialect.comments),
    metadata: CommonMetadata(
      title: _decodeTitle(prepared.metadata.title),
      accessibilityTitle: prepared.metadata.accessibilityTitle,
      accessibilityDescription: prepared.metadata.accessibilityDescription,
    ),
  );
}

RailroadAst railroadAst(CommonMetadata metadata, List<RailroadRuleAst> rules, RailroadSyntax syntax) => RailroadAst(
  syntax: syntax,
  rules: List.unmodifiable(rules),
  title: metadata.title,
  accessibilityTitle: metadata.accessibilityTitle,
  accessibilityDescription: metadata.accessibilityDescription,
);

/// The primary expression forms EBNF and PEG spell the same way: a quoted
/// terminal or a parenthesised group. Returns `null` when the scanner is at
/// neither, leaving the dialect's own forms to the caller.
RailroadNodeAst? railroadCommonPrimary(
  RailroadScanner scanner,
  RailroadNodeAst Function(RailroadScanner scanner) parseChoice,
) {
  final current = scanner.current;
  if (current == '"' || current == "'") return RailroadTerminalAst(scanner.quotedString());
  if (scanner.tryConsume('(')) {
    final node = parseChoice(scanner);
    scanner.expect(')');
    return node;
  }
  return null;
}

/// A `*` repetition: zero or more of [node].
RailroadNodeAst railroadZeroOrMore(RailroadNodeAst node) => RailroadRepetitionAst(node, min: 0, max: double.infinity);

/// A `+` repetition: one or more of [node].
RailroadNodeAst railroadOneOrMore(RailroadNodeAst node) => RailroadRepetitionAst(node, min: 1, max: double.infinity);

/// The `?`, `*`, or `+` suffix applied to [node], or `null` when the scanner is
/// not at one of them.
RailroadNodeAst? railroadPostfix(RailroadScanner scanner, RailroadNodeAst node) {
  if (scanner.tryConsume('?')) return RailroadOptionalAst(node);
  if (scanner.tryConsume('*')) return railroadZeroOrMore(node);
  if (scanner.tryConsume('+')) return railroadOneOrMore(node);
  return null;
}

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
