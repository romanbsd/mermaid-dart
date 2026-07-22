import 'ast.dart';
import 'railroad_parser_base.dart';

final _ruleName = RegExp(r'[A-Za-z][A-Za-z0-9-]*');
final _repeat = RegExp(r'(?:[0-9]*\*[0-9]*|[0-9]+)');
final _numVal = RegExp(r'%[xXdDbB][0-9A-Fa-f]+(?:[-.][0-9A-Fa-f]+)*');

RailroadAst parseRailroadAbnf(String source) {
  final document = prepareRailroadDocument(source, 'railroad-abnf-beta', hideAbnfCommentLines: true);
  final scanner = document.scanner;
  final rules = <RailroadRuleAst>[];
  while (!scanner.isAtEnd) {
    final name = scanner.identifier(_ruleName, description: 'rule name');
    scanner.expect('=');
    final definition = _parseAlternation(scanner);
    scanner.expect(';');
    rules.add(RailroadRuleAst(name: name, definition: definition));
  }
  return railroadAst(document.metadata, rules);
}

RailroadNodeAst _parseAlternation(RailroadScanner scanner) {
  final alternatives = <RailroadNodeAst>[_parseConcatenation(scanner)];
  while (scanner.tryConsume('/')) {
    alternatives.add(_parseConcatenation(scanner));
  }
  return railroadChoice(alternatives);
}

RailroadNodeAst _parseConcatenation(RailroadScanner scanner) {
  final elements = <RailroadNodeAst>[_parseElement(scanner)];
  while (!_isBoundary(scanner.current)) {
    elements.add(_parseElement(scanner));
  }
  return railroadSequence(elements);
}

RailroadNodeAst _parseElement(RailroadScanner scanner) {
  scanner.skipTrivia();
  final repeat = _repeat.matchAsPrefix(scanner.source, scanner.position);
  String? repeatText;
  if (repeat != null) {
    repeatText = repeat.group(0)!;
    scanner.position = repeat.end;
  }
  final primary = _parsePrimary(scanner);
  if (repeatText == null) return primary;

  final (min, max) = _parseRepeat(repeatText);
  if (min == 0 && max == 1) return RailroadOptionalAst(primary);
  return RailroadRepetitionAst(primary, min: min, max: max);
}

RailroadNodeAst _parsePrimary(RailroadScanner scanner) {
  final current = scanner.current;
  if (current == '"') {
    return RailroadTerminalAst(scanner.quotedString(allowSingle: false, decodeEscapes: false));
  }
  if (scanner.tryConsume('(')) {
    final node = _parseAlternation(scanner);
    scanner.expect(')');
    return node;
  }
  if (scanner.tryConsume('[')) {
    final node = RailroadOptionalAst(_parseAlternation(scanner));
    scanner.expect(']');
    return node;
  }
  scanner.skipTrivia();
  final numeric = _numVal.matchAsPrefix(scanner.source, scanner.position);
  if (numeric != null) {
    scanner.position = numeric.end;
    return RailroadTerminalAst(numeric.group(0)!);
  }
  return RailroadNonTerminalAst(scanner.identifier(_ruleName));
}

(int, num) _parseRepeat(String repeat) {
  if (!repeat.contains('*')) {
    final exact = int.parse(repeat);
    return (exact, exact);
  }
  final parts = repeat.split('*');
  return (parts[0].isEmpty ? 0 : int.parse(parts[0]), parts[1].isEmpty ? double.infinity : int.parse(parts[1]));
}

bool _isBoundary(String? character) => character == null || ';/)]'.contains(character);
