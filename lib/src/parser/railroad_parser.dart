import 'ast.dart';
import 'railroad_parser_base.dart';

final _identifier = RegExp(r'[A-Z_a-z][\w-]*');

RailroadAst parseRailroad(String source) => parseRailroadRules(source, RailroadDialect.classic, _parseRule);

RailroadRuleAst _parseRule(RailroadScanner scanner) {
  final name = scanner.identifier(_identifier, description: 'rule name');
  scanner.expect('=');
  final definition = _parseExpression(scanner);
  scanner.expect(';');
  return RailroadRuleAst(name: name, definition: definition);
}

RailroadNodeAst _parseExpression(RailroadScanner scanner) {
  final function = scanner.identifier(_identifier, description: 'railroad expression');
  scanner.expect('(');
  final node = switch (function) {
    'terminal' => RailroadTerminalAst(scanner.quotedString()),
    'nonterminal' => RailroadNonTerminalAst(scanner.quotedString()),
    'special' => RailroadSpecialAst(scanner.quotedString()),
    'optional' => RailroadOptionalAst(_parseExpression(scanner)),
    'oneOrMore' => RailroadRepetitionAst(_parseExpression(scanner), min: 1, max: double.infinity),
    'zeroOrMore' => RailroadRepetitionAst(_parseExpression(scanner), min: 0, max: double.infinity),
    'sequence' => railroadSequence(_parseExpressionList(scanner)),
    'choice' => railroadChoice(_parseExpressionList(scanner)),
    _ => scanner.fail('Unsupported railroad expression "$function"'),
  };
  scanner.expect(')');
  return node;
}

List<RailroadNodeAst> _parseExpressionList(RailroadScanner scanner) {
  final nodes = <RailroadNodeAst>[_parseExpression(scanner)];
  while (scanner.tryConsume(',')) {
    nodes.add(_parseExpression(scanner));
  }
  return nodes;
}
