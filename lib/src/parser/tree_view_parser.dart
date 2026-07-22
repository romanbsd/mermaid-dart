import 'ast.dart';
import 'common_syntax.dart';

final RegExp _header = RegExp(r'^[\t \r\n]*treeView-beta(?![\w-])');
final RegExp _annotationStart = RegExp(r'[ \t]+(?=:::[ \t]*[A-Za-z_]|icon\(|##)');
final RegExp _classAnnotation = RegExp(r'^:::[ \t]*([A-Za-z_][A-Za-z0-9_-]*)');
final RegExp _iconAnnotation = RegExp(r'^icon\(([A-Za-z0-9_-]*(?::[A-Za-z0-9_-]+)?)\)');
final RegExp _descriptionAnnotation = RegExp(r'^##([^\r\n]*)');

TreeViewAst parseTreeView(String source) {
  final visibleSource = hideIgnoredSyntax(source);
  final header = _header.firstMatch(visibleSource);
  if (header == null) {
    final offset = RegExp(r'\S').firstMatch(visibleSource)?.start ?? 0;
    throwParseError(source, 'Expected "treeView-beta"', offset);
  }

  final metadata = readCommonMetadata(visibleSource);
  final bodyOffset = header.end;
  final body = visibleSource.substring(bodyOffset);
  final syntaxBody = hideCommonMetadata(body);
  final nodes = <TreeViewNodeAst>[];

  var offset = 0;
  while (offset < syntaxBody.length) {
    final newline = syntaxBody.indexOf('\n', offset);
    final end = newline < 0 ? syntaxBody.length : newline;
    var line = syntaxBody.substring(offset, end);
    if (line.endsWith('\r')) line = line.substring(0, line.length - 1);
    if (line.trim().isNotEmpty) {
      nodes.add(_parseNode(line, source, bodyOffset + offset));
    }
    if (newline < 0) break;
    offset = newline + 1;
  }

  return TreeViewAst(
    nodes: List.unmodifiable(nodes),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
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
