import 'ast.dart';
import 'common_syntax.dart';

GraphDirection? tryParseGraphDirection(String source) => switch (source.trim().toUpperCase()) {
  'TB' || 'TD' => GraphDirection.topDown,
  'BT' => GraphDirection.bottomTop,
  'LR' => GraphDirection.leftRight,
  'RL' => GraphDirection.rightLeft,
  _ => null,
};

GraphDirection? parseGraphDirectionStatement(String source) {
  final match = RegExp(r'^direction\s+(TB|TD|BT|LR|RL)$', caseSensitive: false).firstMatch(source);
  return match == null ? null : tryParseGraphDirection(match.group(1)!);
}

({List<String> names, Map<String, String> styles})? parseGraphClassDefinition(
  String source, {
  bool caseSensitive = false,
}) {
  final match = RegExp(r'^classDef\s+([^\s]+)\s+(.+)$', caseSensitive: caseSensitive).firstMatch(source);
  if (match == null) return null;
  return (
    names: match.group(1)!.split(',').map((name) => name.trim()).where((name) => name.isNotEmpty).toList(),
    styles: parseStyleProperties(match.group(2)!),
  );
}

({List<String> ids, List<String> cssClasses})? parseGraphClassAssignment(String source, {bool caseSensitive = false}) {
  final match = RegExp(r'^class\s+(.+?)\s+([^\s]+)$', caseSensitive: caseSensitive).firstMatch(source);
  if (match == null) return null;
  return (ids: splitQuotedList(match.group(1)!), cssClasses: parseCssClasses(match.group(2)!));
}

({List<String> ids, Map<String, String> styles})? parseGraphStyleAssignment(
  String source, {
  bool caseSensitive = false,
}) {
  final match = RegExp(r'^style\s+(.+?)\s+(.+)$', caseSensitive: caseSensitive).firstMatch(source);
  if (match == null) return null;
  return (ids: splitQuotedList(match.group(1)!), styles: parseStyleProperties(match.group(2)!));
}

Map<String, String> parseStyleProperties(String source) {
  final result = <String, String>{};
  for (final property in source.split(',')) {
    final separator = property.indexOf(':');
    if (separator <= 0) continue;
    result[property.substring(0, separator).trim()] = property.substring(separator + 1).trim();
  }
  return result;
}

List<String> parseCssClasses(String source) =>
    source.split(',').map((value) => value.trim()).where((value) => value.isNotEmpty).toList();

void mergeCssClasses(List<String> target, Iterable<String> additions) {
  for (final cssClass in additions) {
    if (!target.contains(cssClass)) target.add(cssClass);
  }
}

Map<String, Map<String, String>> freezeGraphClassDefinitions(Map<String, Map<String, String>> definitions) =>
    Map<String, Map<String, String>>.unmodifiable({
      for (final entry in definitions.entries) entry.key: Map<String, String>.unmodifiable(entry.value),
    });

Never throwGraphLineError(String source, SourceLine line, String message) {
  final column = line.text.indexOf(RegExp(r'\S'));
  throwParseError(source, message, line.offset + (column < 0 ? 0 : column));
}

List<String> splitQuotedList(String source) {
  final values = <String>[];
  final buffer = StringBuffer();
  String? quote;
  for (var index = 0; index < source.length; index++) {
    final character = source[index];
    if (quote != null) {
      if (character == quote && (index == 0 || source[index - 1] != r'\')) {
        quote = null;
      } else {
        buffer.write(character);
      }
      continue;
    }
    if (character == '"' || character == "'" || character == '`') {
      quote = character;
    } else if (character == ',') {
      final value = buffer.toString().trim();
      if (value.isNotEmpty) values.add(value);
      buffer.clear();
    } else {
      buffer.write(character);
    }
  }
  final value = buffer.toString().trim();
  if (value.isNotEmpty) values.add(value);
  return values;
}

String unquoteGraphText(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 2) {
    final first = trimmed[0];
    final last = trimmed[trimmed.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'") || (first == '`' && last == '`')) {
      return trimmed.substring(1, trimmed.length - 1);
    }
  }
  return trimmed;
}
