import 'ast.dart';
import 'common_syntax.dart';

/// Parses a Mermaid mindmap.
MindmapAst parseMindmap(String source) {
  final header = RegExp(r'^[\t \r\n]*mindmap(?=\s|$)', caseSensitive: false).firstMatch(hideIgnoredSyntax(source));
  if (header == null) {
    throwParseError(source, 'Expected mindmap', firstNonWhitespaceOffset(source));
  }
  final normalizedSource = source.replaceRange(header.start, header.end, header.group(0)!.toLowerCase());
  final prepared = prepareDiagramSource(normalizedSource, headers: const ['mindmap']);
  final stack = <({int level, _MutableMindmapNode node})>[];
  _MutableMindmapNode? root;
  int? baseIndent;

  for (final line in sourceLines(prepared.syntax)) {
    final text = line.text;
    final trimmed = text.trim();
    if (trimmed.isEmpty) continue;

    if (trimmed.startsWith('::icon(')) {
      if (stack.isEmpty || !trimmed.endsWith(')')) {
        throwParseError(source, 'Expected a mindmap node before icon decoration', line.offset);
      }
      stack.last.node.icon = trimmed.substring('::icon('.length, trimmed.length - 1).trim();
      continue;
    }
    if (trimmed.startsWith(':::')) {
      if (stack.isEmpty) {
        throwParseError(source, 'Expected a mindmap node before class decoration', line.offset);
      }
      stack.last.node.cssClasses.addAll(
        trimmed.substring(3).trim().split(RegExp(r'\s+')).where((value) => value.isNotEmpty),
      );
      continue;
    }

    final indent = _indentWidth(text);
    baseIndent ??= indent;
    final level = indent - baseIndent;
    final parsed = _parseMindmapNode(trimmed, source, line.offset);
    final node = _MutableMindmapNode(parsed);

    if (root == null) {
      root = node;
    } else {
      while (stack.isNotEmpty && stack.last.level >= level) {
        stack.removeLast();
      }
      if (stack.isEmpty) {
        throwParseError(source, 'There can be only one root; no parent was found for "${parsed.label}"', line.offset);
      }
      stack.last.node.children.add(node);
    }
    stack.add((level: level, node: node));
  }

  if (root == null) {
    throwParseError(source, 'Expected a mindmap root node', source.length);
  }
  return MindmapAst(
    root: root.freeze(),
    title: prepared.metadata.title,
    accessibilityTitle: prepared.metadata.accessibilityTitle,
    accessibilityDescription: prepared.metadata.accessibilityDescription,
  );
}

int _indentWidth(String line) {
  var width = 0;
  for (final unit in line.codeUnits) {
    if (unit == 32) {
      width++;
    } else if (unit == 9) {
      width += 4;
    } else {
      break;
    }
  }
  return width;
}

MindmapNodeAst _parseMindmapNode(String text, String source, int offset) {
  final forms = <({RegExp pattern, MindmapNodeShape shape})>[
    (pattern: RegExp(r'^(.*?)\(\((.*)\)\)$'), shape: MindmapNodeShape.circle),
    (pattern: RegExp(r'^(.*?)\{\{(.*)\}\}$'), shape: MindmapNodeShape.hexagon),
    (pattern: RegExp(r'^(.*?)\)\)(.*)\(\($'), shape: MindmapNodeShape.bang),
    (pattern: RegExp(r'^(.*?)\)(.*)\($'), shape: MindmapNodeShape.cloud),
    (pattern: RegExp(r'^(.*?)\[(.*)\]$'), shape: MindmapNodeShape.rectangle),
    (pattern: RegExp(r'^(.*?)\((.*)\)$'), shape: MindmapNodeShape.roundedRectangle),
  ];
  for (final form in forms) {
    final match = form.pattern.firstMatch(text);
    if (match == null) continue;
    final rawId = match.group(1)!.trim();
    final label = _unquoteMindmap(match.group(2)!.trim());
    if (label.isEmpty) throwParseError(source, 'Expected a mindmap node label', offset);
    return MindmapNodeAst(id: rawId.isEmpty ? label : rawId, label: label, shape: form.shape);
  }
  final label = _unquoteMindmap(text.trim());
  if (label.isEmpty) throwParseError(source, 'Expected a mindmap node', offset);
  return MindmapNodeAst(id: label, label: label);
}

String _unquoteMindmap(String value) {
  if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
    return value.substring(1, value.length - 1);
  }
  return value;
}

final class _MutableMindmapNode {
  _MutableMindmapNode(this.node);

  final MindmapNodeAst node;
  final children = <_MutableMindmapNode>[];
  final cssClasses = <String>[];
  String? icon;

  MindmapNodeAst freeze() => MindmapNodeAst(
    id: node.id,
    label: node.label,
    shape: node.shape,
    children: [for (final child in children) child.freeze()],
    icon: icon,
    cssClasses: List.unmodifiable(cssClasses),
  );
}
