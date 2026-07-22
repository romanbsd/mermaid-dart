import 'ast.dart';
import 'common_syntax.dart';

final RegExp _annotationStart = RegExp(r'[ \t]+(?=:::[ \t]*[A-Za-z_]|icon\(|##)');
final RegExp _classAnnotation = RegExp(r'^:::[ \t]*([A-Za-z_][A-Za-z0-9_-]*)');
final RegExp _iconAnnotation = RegExp(r'^icon\(([A-Za-z0-9_-]*(?::[A-Za-z0-9_-]+)?)\)');
final RegExp _descriptionAnnotation = RegExp(r'^##([^\r\n]*)');

TreeViewAst parseTreeView(String source) {
  final prepared = prepareDiagramSource(source, headers: const ['treeView-beta']);
  final nodes = [
    for (final line in sourceLines(prepared.syntax))
      if (line.text.trim().isNotEmpty) _parseNode(line.text, source, line.offset),
  ];

  return TreeViewAst(
    nodes: List.unmodifiable(nodes),
    title: prepared.metadata.title,
    accessibilityTitle: prepared.metadata.accessibilityTitle,
    accessibilityDescription: prepared.metadata.accessibilityDescription,
  );
}

TreeViewNodeAst _parseNode(String line, String source, int lineOffset) {
  final indentation = RegExp(r'^[\t ]*').firstMatch(line)!.group(0)!;
  final indent = indentation.isEmpty ? null : indentation.length;
  final content = line.substring(indentation.length);
  if (content.startsWith('"') || content.startsWith("'")) {
    return _parseQuotedNode(content, indent, source, lineOffset + indentation.length);
  }
  return _parseBareNode(content, indent, source, lineOffset + indentation.length);
}

TreeViewNodeAst _parseQuotedNode(String content, int? indent, String source, int contentOffset) {
  final quote = content[0];
  final closingQuote = content.indexOf(quote, 1);
  if (closingQuote < 0) {
    throwParseError(source, 'Expected closing $quote', contentOffset + content.length);
  }
  return _nodeWithAnnotations(
    name: content.substring(1, closingQuote),
    indent: indent,
    annotations: content.substring(closingQuote + 1),
    source: source,
    annotationsOffset: contentOffset + closingQuote + 1,
  );
}

TreeViewNodeAst _parseBareNode(String content, int? indent, String source, int contentOffset) {
  if (content.isEmpty || content.startsWith('"') || content.startsWith("'")) {
    throwParseError(source, 'Expected tree node name', contentOffset);
  }
  if (content.startsWith(':::') || content.startsWith('icon(') || content.startsWith('##')) {
    throwParseError(source, 'Expected tree node name', contentOffset);
  }
  final annotationStart = _annotationStart.firstMatch(content)?.start;
  final nameEnd = annotationStart ?? content.length;
  final name = content.substring(0, nameEnd).replaceFirst(RegExp(r'[\t ]+$'), '');
  if (name.isEmpty) throwParseError(source, 'Expected tree node name', contentOffset);
  return _nodeWithAnnotations(
    name: name,
    indent: indent,
    annotations: content.substring(nameEnd),
    source: source,
    annotationsOffset: contentOffset + nameEnd,
  );
}

TreeViewNodeAst _nodeWithAnnotations({
  required String name,
  required int? indent,
  required String annotations,
  required String source,
  required int annotationsOffset,
}) {
  String? cssClass;
  String? icon;
  String? description;
  var remainder = annotations;
  var consumed = 0;

  while (remainder.isNotEmpty) {
    final whitespace = RegExp(r'^[\t ]+').firstMatch(remainder);
    if (whitespace == null) {
      throwParseError(source, 'Expected tree node annotation', annotationsOffset + consumed);
    }
    consumed += whitespace.end;
    remainder = remainder.substring(whitespace.end);
    if (remainder.isEmpty) break;

    if (_classAnnotation.firstMatch(remainder) case final match?) {
      cssClass = match.group(1)!;
      consumed += match.end;
      remainder = remainder.substring(match.end);
      continue;
    }
    if (_iconAnnotation.firstMatch(remainder) case final match?) {
      icon = match.group(1)!;
      consumed += match.end;
      remainder = remainder.substring(match.end);
      continue;
    }
    if (_descriptionAnnotation.firstMatch(remainder) case final match?) {
      description = match.group(1)!.trim();
      remainder = '';
      continue;
    }
    throwParseError(source, 'Invalid tree node annotation', annotationsOffset + consumed);
  }

  return TreeViewNodeAst(name: name, indent: indent, cssClass: cssClass, icon: icon, description: description);
}
