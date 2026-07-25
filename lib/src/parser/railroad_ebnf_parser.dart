import 'ast.dart';
import 'railroad_parser_base.dart';

final _identifier = RegExp(r'[A-Z_a-z][\w-]*');

RailroadAst parseRailroadEbnf(String source) => parseRailroadRules(source, RailroadDialect.ebnf, _parseRule);

RailroadRuleAst _parseRule(RailroadScanner scanner) {
  final name = scanner.identifier(_identifier, description: 'rule name');
  if (!scanner.tryConsume('::=')) scanner.expect('=');
  final definition = _parseChoice(scanner);
  scanner.expect(';');
  return RailroadRuleAst(name: name, definition: definition);
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
    if (railroadPostfix(scanner, node) case final repeated?) {
      node = repeated;
    } else if (scanner.tryConsume('-')) {
      node = RailroadSequenceAst([node, const RailroadTerminalAst('-'), _parsePrimary(scanner)]);
    } else {
      return node;
    }
  }
}

RailroadNodeAst _parsePrimary(RailroadScanner scanner) {
  if (railroadCommonPrimary(scanner, _parseChoice) case final node?) return node;
  if (scanner.tryConsume('[')) {
    final node = RailroadOptionalAst(_parseChoice(scanner));
    scanner.expect(']');
    return node;
  }
  if (scanner.tryConsume('{')) {
    final node = railroadZeroOrMore(_parseChoice(scanner));
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
