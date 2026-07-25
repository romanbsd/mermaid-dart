import 'ast.dart';
import 'railroad_parser_base.dart';

final _identifier = RegExp(r'[A-Z_a-z][\w-]*');

RailroadAst parseRailroadPeg(String source) => parseRailroadRules(source, RailroadDialect.peg, _parseRule);

RailroadRuleAst _parseRule(RailroadScanner scanner) {
  final name = scanner.identifier(_identifier, description: 'rule name');
  scanner.expect('<-');
  final definition = _parseChoice(scanner);
  scanner.expect(';');
  return RailroadRuleAst(name: name, definition: definition);
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
  final primary = _parsePrimary(scanner);
  final node = railroadPostfix(scanner, primary) ?? primary;
  return prefix == null ? node : RailroadSpecialAst('$prefix${_nodeLabel(node)}');
}

RailroadNodeAst _parsePrimary(RailroadScanner scanner) {
  if (railroadCommonPrimary(scanner, _parseChoice) case final node?) return node;
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
