import 'package:yaml/yaml.dart';

import 'ast.dart';
import 'common_syntax.dart';

final _indentation = RegExp(r'^[ \t]*');
final _classWhitespace = RegExp(r'\s+');
final _iconDecoration = RegExp(r'^::icon\(([^)]*)\)[ \t]*$', caseSensitive: false);

KanbanAst parseKanban(String source) {
  final visibleSource = hideIgnoredSyntax(source);
  final header = RegExp(r'^[\t \r\n]*(kanban)(?=\s|$)', caseSensitive: false).firstMatch(visibleSource);
  final prepared = prepareDiagramSource(source, headers: [header?.group(1) ?? 'kanban']);
  final syntax = _restoreCardMetadata(source, prepared.syntax);
  final nodes = <_MutableKanbanNode>[];
  final lines = sourceLines(syntax);

  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final indentLexeme = _indentation.firstMatch(line.text)!.group(0)!;
    var content = line.text.substring(indentLexeme.length).trimRight();
    if (content.isEmpty) continue;

    final iconMatch = _iconDecoration.firstMatch(content);
    if (iconMatch != null) {
      if (nodes.isEmpty) {
        throwParseError(source, 'Kanban icon decoration requires a preceding node', line.offset + indentLexeme.length);
      }
      nodes.last.icon = iconMatch.group(1)!.trim();
      continue;
    }
    if (content.startsWith(':::')) {
      if (nodes.isEmpty) {
        throwParseError(source, 'Kanban class decoration requires a preceding node', line.offset + indentLexeme.length);
      }
      final classes = content.substring(3).trim().split(_classWhitespace).where((value) => value.isNotEmpty);
      nodes.last.cssClasses.addAll(classes);
      continue;
    }

    final metadataStart = _metadataStart(content);
    String? metadata;
    if (metadataStart >= 0) {
      final collected = _collectMetadata(source, lines, index, indentLexeme.length, metadataStart);
      metadata = collected.metadata;
      content = content.substring(0, metadataStart).trimRight();
      index = collected.lastLineIndex;
    }
    if (content.isEmpty) {
      throwParseError(source, 'Expected Kanban node before metadata', line.offset + indentLexeme.length);
    }

    final parsed = _parseNode(source, content, line.offset + indentLexeme.length);
    final node = _MutableKanbanNode(
      indent: indentLexeme.length,
      offset: line.offset + indentLexeme.length,
      id: parsed.id,
      label: parsed.label,
    );
    if (metadata != null) {
      _applyMetadata(source, node, metadata, line.offset + indentLexeme.length + metadataStart);
    }
    nodes.add(node);
  }

  final sections = _buildSections(source, nodes);
  return KanbanAst(
    sections: List.unmodifiable(sections),
    title: prepared.metadata.title,
    accessibilityTitle: prepared.metadata.accessibilityTitle,
    accessibilityDescription: prepared.metadata.accessibilityDescription,
  );
}

String _restoreCardMetadata(String source, String syntax) {
  final result = StringBuffer();
  var cursor = 0;
  for (var start = source.indexOf('@{'); start >= 0; start = source.indexOf('@{', cursor)) {
    final end = _matchingMetadataBrace(source, start);
    if (end < 0) break;
    final lineStart = source.lastIndexOf('\n', start - 1) + 1;
    if (source.substring(lineStart, start).contains('%%')) {
      result.write(syntax.substring(cursor, end + 1));
      cursor = end + 1;
      continue;
    }
    result
      ..write(syntax.substring(cursor, start))
      ..write(source.substring(start, end + 1));
    cursor = end + 1;
  }
  result.write(syntax.substring(cursor));
  return result.toString();
}

int _metadataStart(String content) {
  var quote = '';
  for (var index = 0; index + 1 < content.length; index++) {
    final character = content[index];
    if (quote.isNotEmpty) {
      if (character == quote && (index == 0 || content[index - 1] != r'\')) quote = '';
      continue;
    }
    if (character == '"' || character == "'") {
      quote = character;
    } else if (character == '@' && content[index + 1] == '{') {
      return index;
    }
  }
  return -1;
}

({String metadata, int lastLineIndex}) _collectMetadata(
  String source,
  List<SourceLine> lines,
  int firstLineIndex,
  int contentOffset,
  int metadataStart,
) {
  final absoluteStart = lines[firstLineIndex].offset + contentOffset + metadataStart;
  final absoluteEnd = _matchingMetadataBrace(source, absoluteStart);
  if (absoluteEnd < 0) throwParseError(source, 'Unterminated Kanban metadata', absoluteStart);
  var lastLineIndex = firstLineIndex;
  while (lastLineIndex + 1 < lines.length && lines[lastLineIndex + 1].offset <= absoluteEnd) {
    lastLineIndex++;
  }
  return (metadata: source.substring(absoluteStart + 2, absoluteEnd), lastLineIndex: lastLineIndex);
}

int _matchingMetadataBrace(String source, int start) {
  var quote = '';
  for (var index = start + 2; index < source.length; index++) {
    final character = source[index];
    if (quote.isNotEmpty) {
      if (character == quote && source[index - 1] != r'\') quote = '';
    } else if (character == '"' || character == "'") {
      quote = character;
    } else if (character == '}') {
      return index;
    }
  }
  return -1;
}

({String id, String label}) _parseNode(String source, String content, int offset) {
  const delimiters = <(String, String)>[('((', '))'), ('{{', '}}'), ('(-', '-)'), ('-)', '(-'), ('[', ']'), ('(', ')')];
  var openingIndex = -1;
  var opening = '';
  var closing = '';
  for (final delimiter in delimiters) {
    final candidate = content.indexOf(delimiter.$1);
    if (candidate >= 0 && (openingIndex < 0 || candidate < openingIndex)) {
      openingIndex = candidate;
      opening = delimiter.$1;
      closing = delimiter.$2;
    }
  }
  if (openingIndex < 0) {
    final value = content.trim();
    return (id: value, label: value);
  }

  final closingIndex = _closingDelimiter(content, openingIndex + opening.length, closing);
  if (closingIndex < 0) throwParseError(source, 'Unterminated Kanban node', offset + openingIndex);
  if (content.substring(closingIndex + closing.length).trim().isNotEmpty) {
    throwParseError(source, 'Unexpected Kanban node content', offset + closingIndex + closing.length);
  }
  final rawLabel = content.substring(openingIndex + opening.length, closingIndex).trim();
  final label = _unquote(rawLabel);
  final explicitId = content.substring(0, openingIndex).trim();
  return (id: explicitId.isEmpty ? label : explicitId, label: label);
}

int _closingDelimiter(String content, int start, String delimiter) {
  var quote = '';
  for (var index = start; index <= content.length - delimiter.length; index++) {
    final character = content[index];
    if (quote.isNotEmpty) {
      if (character == quote && content[index - 1] != r'\') quote = '';
    } else if (character == '"' || character == "'") {
      quote = character;
    } else if (content.startsWith(delimiter, index)) {
      return index;
    }
  }
  return -1;
}

String _unquote(String value) {
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'")))) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

void _applyMetadata(String source, _MutableKanbanNode node, String metadata, int offset) {
  Object? document;
  try {
    final trimmed = metadata.trim();
    document = loadYaml(metadata.contains('\n') ? _dedentMetadata(metadata) : '{$trimmed}');
  } on YamlException catch (error) {
    throwParseError(source, 'Invalid Kanban metadata: ${error.message}', offset);
  }
  if (document is! YamlMap) throwParseError(source, 'Kanban metadata must be a map', offset);
  final values = document;

  String? stringValue(String key) {
    final value = values[key];
    return value?.toString();
  }

  node
    ..label = stringValue('label') ?? node.label
    ..icon = stringValue('icon')
    ..assigned = stringValue('assigned')
    ..ticket = stringValue('ticket');
  if (values['priority'] case final value?) {
    node.priority = KanbanPriority.tryParse(value);
    if (node.priority == null) {
      throwParseError(source, 'Unknown Kanban priority: $value', offset);
    }
  }
  if (values['shape'] case final Object value) {
    final shape = value.toString();
    if (shape != shape.toLowerCase() || shape.contains('_')) {
      throwParseError(source, 'No such shape: $shape. Shape names should be lowercase.', offset);
    }
  }
}

String _dedentMetadata(String metadata) {
  final lines = metadata.split(RegExp(r'\r?\n'));
  final nonEmpty = lines.where((line) => line.trim().isNotEmpty);
  final indentation =
      nonEmpty
          .map((line) => _indentation.firstMatch(line)!.group(0)!.length)
          .fold<int?>(null, (minimum, value) => minimum == null || value < minimum ? value : minimum) ??
      0;
  return lines.map((line) => line.length < indentation ? '' : line.substring(indentation)).join('\n');
}

List<KanbanSectionAst> _buildSections(String source, List<_MutableKanbanNode> nodes) {
  if (nodes.isEmpty) return const [];
  final sectionIndent = nodes.first.indent;
  final sections = <_MutableKanbanSection>[];
  for (final node in nodes) {
    if (node.indent < sectionIndent) {
      throwParseError(source, 'Items without section detected, found section ("${node.label}")', node.offset);
    }
    if (node.indent == sectionIndent) {
      sections.add(_MutableKanbanSection(node));
    } else {
      if (sections.isEmpty) {
        throwParseError(source, 'Kanban item requires a preceding section', node.offset);
      }
      sections.last.cards.add(node);
    }
  }
  return [
    for (final section in sections)
      KanbanSectionAst(
        id: section.node.id,
        label: section.node.label,
        cards: List.unmodifiable([
          for (final card in section.cards)
            KanbanCardAst(
              id: card.id,
              label: card.label,
              cssClasses: List.unmodifiable(card.cssClasses),
              icon: card.icon,
              ticket: card.ticket,
              assigned: card.assigned,
              priority: card.priority,
            ),
        ]),
        cssClasses: List.unmodifiable(section.node.cssClasses),
        icon: section.node.icon,
        ticket: section.node.ticket,
        assigned: section.node.assigned,
        priority: section.node.priority,
      ),
  ];
}

final class _MutableKanbanNode {
  _MutableKanbanNode({required this.indent, required this.offset, required this.id, required this.label});

  final int indent;
  final int offset;
  final String id;
  String label;
  final List<String> cssClasses = [];
  String? icon;
  String? ticket;
  String? assigned;
  KanbanPriority? priority;
}

final class _MutableKanbanSection {
  _MutableKanbanSection(this.node);

  final _MutableKanbanNode node;
  final List<_MutableKanbanNode> cards = [];
}
