import 'ast.dart';
import 'railroad_parser_base.dart';

final _identifier = RegExp(r'[A-Z_a-z][\w-]*');

RailroadAst parseRailroadEbnf(String source) {
  final document = prepareRailroadDocument(
    source,
    'railroad-ebnf-beta',
    comments: const {RailroadCommentKind.cStyleBlock, RailroadCommentKind.isoEbnf},
  );
  final scanner = document.scanner;
  final rules = <RailroadRuleAst>[];
  while (!scanner.isAtEnd) {
    final name = scanner.identifier(_identifier, description: 'rule name');
    if (!scanner.tryConsume('::=')) scanner.expect('=');
    final definition = _parseChoice(scanner);
    scanner.expect(';');
    rules.add(RailroadRuleAst(name: name, definition: definition));
  }
  return railroadAst(document.metadata, rules);
}

RailroadNodeAst _parseChoice(RailroadScanner scanner) {
  final alternatives = <RailroadNodeAst>[_parseSequence(scanner)];
  while (scanner.tryConsume('|')) {
    alternatives.add(_parseSequence(scanner));
  }
  return railroadChoice(alternatives);
}

RailroadNodeAst _parseSequence(RailroadScanner scanner) {
  final elements = <RailroadNodeAst>[_parseTerm(scanner)];
  while (true) {
    final hadComma = scanner.tryConsume(',');
    if (_isBoundary(scanner.current)) {
      if (hadComma) scanner.fail('Expected expression after comma');
      break;
    }
    elements.add(_parseTerm(scanner));
  }
  return railroadSequence(elements);
}

RailroadNodeAst _parseTerm(RailroadScanner scanner) {
  var node = _parsePrimary(scanner);
  while (true) {
    if (scanner.tryConsume('?')) {
      node = RailroadOptionalAst(node);
    } else if (scanner.tryConsume('*')) {
      node = RailroadRepetitionAst(node, min: 0, max: double.infinity);
    } else if (scanner.tryConsume('+')) {
      node = RailroadRepetitionAst(node, min: 1, max: double.infinity);
    } else if (scanner.tryConsume('-')) {
      node = RailroadSequenceAst([node, const RailroadTerminalAst('-'), _parsePrimary(scanner)]);
    } else {
      return node;
    }
  }
}

RailroadNodeAst _parsePrimary(RailroadScanner scanner) {
  final current = scanner.current;
  if (current == '"' || current == "'") {
    return RailroadTerminalAst(scanner.quotedString());
  }
  if (scanner.tryConsume('(')) {
    final node = _parseChoice(scanner);
    scanner.expect(')');
    return node;
  }
  if (scanner.tryConsume('[')) {
    final node = RailroadOptionalAst(_parseChoice(scanner));
    scanner.expect(']');
    return node;
  }
  if (scanner.tryConsume('{')) {
    final node = RailroadRepetitionAst(_parseChoice(scanner), min: 0, max: double.infinity);
    scanner.expect('}');
    return node;
  }
  if (scanner.tryConsume('?')) {
    final start = scanner.position;
    final end = scanner.source.indexOf('?', start);
    if (end < 0 ||
        scanner.source.substring(start, end).trim().isEmpty ||
        scanner.source.substring(start, end).contains(';')) {
      scanner.fail('Invalid EBNF special sequence', at: start - 1);
    }
    scanner.position = end + 1;
    return RailroadSpecialAst(scanner.source.substring(start, end).trim());
  }
  return RailroadNonTerminalAst(scanner.identifier(_identifier));
}

bool _isBoundary(String? character) => character == null || ';|)]}'.contains(character);
