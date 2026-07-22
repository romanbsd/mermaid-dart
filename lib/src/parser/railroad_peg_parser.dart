import 'ast.dart';
import 'railroad_parser_base.dart';

final _identifier = RegExp(r'[A-Z_a-z][\w-]*');

RailroadAst parseRailroadPeg(String source) {
  final document = prepareRailroadDocument(source, RailroadDialect.peg);
  final scanner = document.scanner;
  final rules = <RailroadRuleAst>[];
  while (!scanner.isAtEnd) {
    final name = scanner.identifier(_identifier, description: 'rule name');
    scanner.expect('<-');
    final definition = _parseChoice(scanner);
    scanner.expect(';');
    rules.add(RailroadRuleAst(name: name, definition: definition));
  }
  return railroadAst(document.metadata, rules);
}

RailroadNodeAst _parseChoice(RailroadScanner scanner) {
  final alternatives = <RailroadNodeAst>[_parseSequence(scanner)];
  while (scanner.tryConsume('/')) {
    alternatives.add(_parseSequence(scanner));
  }
  return railroadChoice(alternatives);
}

RailroadNodeAst _parseSequence(RailroadScanner scanner) {
  final elements = <RailroadNodeAst>[_parsePrefix(scanner)];
  while (!_isBoundary(scanner.current)) {
    elements.add(_parsePrefix(scanner));
  }
  return railroadSequence(elements);
}

RailroadNodeAst _parsePrefix(RailroadScanner scanner) {
  String? prefix;
  if (scanner.tryConsume('&')) {
    prefix = '&';
  } else if (scanner.tryConsume('!')) {
    prefix = '!';
  }
  var node = _parsePrimary(scanner);
  if (scanner.tryConsume('?')) {
    node = RailroadOptionalAst(node);
  } else if (scanner.tryConsume('*')) {
    node = RailroadRepetitionAst(node, min: 0, max: double.infinity);
  } else if (scanner.tryConsume('+')) {
    node = RailroadRepetitionAst(node, min: 1, max: double.infinity);
  }
  return prefix == null ? node : RailroadSpecialAst('$prefix${_nodeLabel(node)}');
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
  if (scanner.tryConsume('.')) return const RailroadSpecialAst('.');
  return RailroadNonTerminalAst(scanner.identifier(_identifier));
}

String _nodeLabel(RailroadNodeAst node) => switch (node) {
  RailroadTerminalAst(:final value) => '"$value"',
  RailroadNonTerminalAst(:final name) => name,
  RailroadSpecialAst(:final text) => text,
  _ => '(...)',
};

bool _isBoundary(String? character) => character == null || ';/)'.contains(character);
