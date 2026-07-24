import 'ast.dart';
import 'common_syntax.dart';

final _flowchartIdentifier = RegExp(r'[A-Za-z0-9_][A-Za-z0-9_.:-]*');
final _flowchartClassName = RegExp(r'[A-Za-z0-9_-]+');

/// Parses Mermaid's classic `flowchart` and `graph` syntax.
FlowchartAst parseFlowchart(String source) {
  final prepared = prepareDiagramSource(source, headers: const ['flowchart', 'graph']);
  final nodes = <String, _MutableFlowchartNode>{};
  final edges = <FlowchartEdgeAst>[];
  final subgraphs = <_MutableFlowchartSubgraph>[];
  final openSubgraphs = <_MutableFlowchartSubgraph>[];
  final classDefinitions = <String, Map<String, String>>{};
  final classAssignments = <({List<String> ids, List<String> classes})>[];
  final styles = <String, Map<String, String>>{};
  final linkStyles = <({List<int>? indices, Map<String, String> properties})>[];
  var direction = FlowchartDirection.topDown;
  var directionRead = false;

  void rememberNode(_ParsedFlowchartNode parsed) {
    for (final subgraph in openSubgraphs) {
      subgraph.nodeIds.add(parsed.id);
    }

    final existing = nodes[parsed.id];
    if (existing == null) {
      nodes[parsed.id] = _MutableFlowchartNode(
        id: parsed.id,
        label: parsed.label,
        shape: parsed.shape,
        cssClasses: [...parsed.cssClasses],
      );
    } else if (parsed.explicitShape) {
      existing
        ..label = parsed.label
        ..shape = parsed.shape;
      existing.cssClasses.addAll(parsed.cssClasses);
    }
  }

  for (final statement in _flowchartStatements(prepared.syntax)) {
    final text = statement.text.trim();
    if (text.isEmpty) continue;
    final statementOffset = statement.offset + statement.text.indexOf(text);

    final parsedDirection = _tryFlowchartDirection(
      text.startsWith('direction ') ? text.substring('direction '.length) : text,
    );
    if (parsedDirection != null && (!directionRead || openSubgraphs.isNotEmpty)) {
      if (openSubgraphs.isEmpty) {
        direction = parsedDirection;
        directionRead = true;
      } else {
        openSubgraphs.last.direction = parsedDirection;
      }
      continue;
    }

    if (text.startsWith('subgraph') && (text.length == 8 || text.codeUnitAt(8) <= 32)) {
      final subgraph = _parseSubgraph(source, text.substring(8).trim(), statementOffset + 8);
      subgraphs.add(subgraph);
      openSubgraphs.add(subgraph);
      continue;
    }
    if (text == 'end') {
      if (openSubgraphs.isEmpty) throwParseError(source, 'Unexpected end', statementOffset);
      openSubgraphs.removeLast();
      continue;
    }
    if (text.startsWith('classDef ')) {
      final body = text.substring('classDef '.length).trim();
      final separator = body.indexOf(RegExp(r'\s'));
      if (separator < 0) throwParseError(source, 'Expected class properties', statementOffset);
      final name = body.substring(0, separator);
      classDefinitions[name] = _parseStyleProperties(body.substring(separator + 1));
      continue;
    }
    if (text.startsWith('class ')) {
      final body = text.substring('class '.length).trim();
      final separator = body.indexOf(RegExp(r'\s'));
      if (separator < 0) throwParseError(source, 'Expected class name', statementOffset);
      classAssignments.add((
        ids: _commaSeparated(body.substring(0, separator)),
        classes: _commaSeparated(body.substring(separator + 1)),
      ));
      continue;
    }
    if (text.startsWith('style ')) {
      final body = text.substring('style '.length).trim();
      final separator = body.indexOf(RegExp(r'\s'));
      if (separator < 0) throwParseError(source, 'Expected style properties', statementOffset);
      styles[body.substring(0, separator)] = _parseStyleProperties(body.substring(separator + 1));
      continue;
    }
    if (text.startsWith('linkStyle ')) {
      final body = text.substring('linkStyle '.length).trim();
      final separator = body.indexOf(RegExp(r'\s'));
      if (separator < 0) throwParseError(source, 'Expected link style properties', statementOffset);
      final selector = body.substring(0, separator);
      final indices = selector == 'default'
          ? null
          : _commaSeparated(selector).map(int.tryParse).whereType<int>().toList();
      if (indices != null && indices.isEmpty) {
        throwParseError(source, 'Expected link indexes or default', statementOffset);
      }
      linkStyles.add((indices: indices, properties: _parseStyleProperties(body.substring(separator + 1))));
      continue;
    }

    final chain = _parseFlowchartChain(source, text, statementOffset);
    for (final node in chain.nodes) {
      rememberNode(node);
    }
    edges.addAll(chain.edges);
  }

  if (openSubgraphs.isNotEmpty) {
    throwParseError(source, 'Unterminated subgraph ${openSubgraphs.last.id}', source.length);
  }

  for (final assignment in classAssignments) {
    for (final id in assignment.ids) {
      final node = nodes[id] ??= _MutableFlowchartNode(id: id, label: id);
      node.cssClasses.addAll(assignment.classes);
    }
  }
  for (final MapEntry(key: id, value: properties) in styles.entries) {
    (nodes[id] ??= _MutableFlowchartNode(id: id, label: id)).styles.addAll(properties);
  }

  final styledEdges = <FlowchartEdgeAst>[
    for (final (index, edge) in edges.indexed)
      FlowchartEdgeAst(
        from: edge.from,
        to: edge.to,
        id: edge.id,
        label: edge.label,
        stroke: edge.stroke,
        startMarker: edge.startMarker,
        endMarker: edge.endMarker,
        length: edge.length,
        styles: Map.unmodifiable({
          for (final assignment in linkStyles)
            if (assignment.indices == null || assignment.indices!.contains(index)) ...assignment.properties,
        }),
      ),
  ];
  return FlowchartAst(
    direction: direction,
    nodes: List.unmodifiable(nodes.values.map((node) => node.freeze())),
    edges: List.unmodifiable(styledEdges),
    subgraphs: List.unmodifiable(subgraphs.map((subgraph) => subgraph.freeze())),
    classDefinitions: Map.unmodifiable({
      for (final MapEntry(key: name, value: properties) in classDefinitions.entries)
        name: Map<String, String>.unmodifiable(properties),
    }),
    title: prepared.metadata.title,
    accessibilityTitle: prepared.metadata.accessibilityTitle,
    accessibilityDescription: prepared.metadata.accessibilityDescription,
  );
}

List<SourceLine> _flowchartStatements(String source) {
  final statements = <SourceLine>[];
  var start = 0;
  var quote = '';
  final closings = <String>[];
  for (var index = 0; index < source.length; index++) {
    final character = source[index];
    if (quote.isNotEmpty) {
      if (character == quote && (index == 0 || source[index - 1] != r'\')) quote = '';
      continue;
    }
    if (character == '"' || character == "'") {
      quote = character;
      continue;
    }
    if (closings.isNotEmpty && source.startsWith(closings.last, index)) {
      index += closings.removeLast().length - 1;
      continue;
    }
    final opening = switch (character) {
      '[' => ']',
      '(' => ')',
      '{' => '}',
      _ => null,
    };
    if (opening != null) {
      closings.add(opening);
      continue;
    }
    if (closings.isEmpty && (character == ';' || character == '\n' || character == '\r')) {
      statements.add(SourceLine(text: source.substring(start, index), offset: start));
      if (character == '\r' && index + 1 < source.length && source[index + 1] == '\n') index++;
      start = index + 1;
    }
  }
  if (start < source.length) statements.add(SourceLine(text: source.substring(start), offset: start));
  return statements;
}

FlowchartDirection? _tryFlowchartDirection(String value) => switch (value.trim()) {
  'TB' || 'TD' => FlowchartDirection.topDown,
  'BT' => FlowchartDirection.bottomTop,
  'LR' => FlowchartDirection.leftRight,
  'RL' => FlowchartDirection.rightLeft,
  _ => null,
};

_MutableFlowchartSubgraph _parseSubgraph(String source, String value, int offset) {
  if (value.isEmpty) throwParseError(source, 'Expected subgraph identifier', offset);
  final bracket = value.indexOf('[');
  if (bracket >= 0) {
    if (!value.endsWith(']')) throwParseError(source, 'Unterminated subgraph title', offset + bracket);
    final id = value.substring(0, bracket).trim();
    final title = _unquoteFlowchart(value.substring(bracket + 1, value.length - 1).trim());
    return _MutableFlowchartSubgraph(id: id.isEmpty ? title : id, title: title);
  }
  final quoted = value.startsWith('"') || value.startsWith("'");
  final title = quoted ? _unquoteFlowchart(value) : value;
  final id = quoted ? title.replaceAll(RegExp(r'\s+'), '_') : value.split(RegExp(r'\s+')).first;
  return _MutableFlowchartSubgraph(id: id, title: title);
}

({List<_ParsedFlowchartNode> nodes, List<FlowchartEdgeAst> edges}) _parseFlowchartChain(
  String source,
  String text,
  int offset,
) {
  final nodes = <_ParsedFlowchartNode>[];
  final edges = <FlowchartEdgeAst>[];
  var cursor = 0;
  var current = _parseFlowchartNode(source, text, cursor, offset);
  nodes.add(current.node);
  cursor = current.end;
  while (true) {
    cursor = _skipFlowchartSpaces(text, cursor);
    if (cursor >= text.length) break;
    final parsedEdge = _parseFlowchartEdge(source, text, cursor, offset);
    cursor = _skipFlowchartSpaces(text, parsedEdge.end);
    final next = _parseFlowchartNode(source, text, cursor, offset);
    nodes.add(next.node);
    edges.add(
      FlowchartEdgeAst(
        from: current.node.id,
        to: next.node.id,
        id: parsedEdge.id,
        label: parsedEdge.label,
        stroke: parsedEdge.stroke,
        startMarker: parsedEdge.startMarker,
        endMarker: parsedEdge.endMarker,
        length: parsedEdge.length,
      ),
    );
    current = next;
    cursor = next.end;
  }
  return (nodes: nodes, edges: edges);
}

({_ParsedFlowchartNode node, int end}) _parseFlowchartNode(String source, String text, int start, int offset) {
  var cursor = _skipFlowchartSpaces(text, start);
  final idMatch = _flowchartIdentifier.matchAsPrefix(text, cursor);
  if (idMatch == null) throwParseError(source, 'Expected flowchart node', offset + cursor);
  final id = idMatch.group(0)!;
  cursor = idMatch.end;
  var shape = FlowchartNodeShape.rectangle;
  var label = id;
  var explicitShape = false;

  const delimiters = <(String, String, FlowchartNodeShape)>[
    ('(((', ')))', FlowchartNodeShape.doubleCircle),
    ('[[', ']]', FlowchartNodeShape.subroutine),
    ('[(', ')]', FlowchartNodeShape.cylinder),
    ('((', '))', FlowchartNodeShape.circle),
    ('{{', '}}', FlowchartNodeShape.hexagon),
    ('([', '])', FlowchartNodeShape.stadium),
    ('[/', '/]', FlowchartNodeShape.parallelogram),
    ('[\\', '\\]', FlowchartNodeShape.parallelogramAlt),
    ('[/', '\\]', FlowchartNodeShape.trapezoid),
    ('[\\', '/]', FlowchartNodeShape.trapezoidAlt),
    ('[', ']', FlowchartNodeShape.rectangle),
    ('(', ')', FlowchartNodeShape.rounded),
    ('{', '}', FlowchartNodeShape.diamond),
    ('>', ']', FlowchartNodeShape.asymmetric),
  ];
  var matchedOpening = false;
  for (final (opening, closing, candidateShape) in delimiters) {
    if (!text.startsWith(opening, cursor)) continue;
    matchedOpening = true;
    final end = _flowchartClosing(text, cursor + opening.length, closing);
    if (end < 0) continue;
    label = _flowchartLabel(text.substring(cursor + opening.length, end).trim());
    shape = candidateShape;
    explicitShape = true;
    cursor = end + closing.length;
    break;
  }
  if (matchedOpening && !explicitShape) {
    throwParseError(source, 'Unterminated Flowchart node', offset + cursor);
  }

  final cssClasses = <String>[];
  if (text.startsWith(':::', cursor)) {
    cursor += 3;
    while (cursor < text.length) {
      final match = _flowchartClassName.matchAsPrefix(text, cursor);
      if (match == null) break;
      cssClasses.add(match.group(0)!);
      cursor = match.end;
      if (cursor >= text.length || text[cursor] != ',') break;
      cursor++;
    }
  }
  return (
    node: _ParsedFlowchartNode(
      id: id,
      label: label,
      shape: shape,
      explicitShape: explicitShape,
      cssClasses: cssClasses,
    ),
    end: cursor,
  );
}

int _flowchartClosing(String text, int start, String closing) {
  var quote = '';
  for (var index = start; index <= text.length - closing.length; index++) {
    final character = text[index];
    if (quote.isNotEmpty) {
      if (character == quote && text[index - 1] != r'\') quote = '';
    } else if (character == '"' || character == "'") {
      quote = character;
    } else if (text.startsWith(closing, index)) {
      return index;
    }
  }
  return -1;
}

({
  String? id,
  String? label,
  FlowchartEdgeStroke stroke,
  FlowchartEdgeMarker startMarker,
  FlowchartEdgeMarker endMarker,
  int length,
  int end,
})
_parseFlowchartEdge(String source, String text, int start, int offset) {
  var cursor = start;
  String? id;
  final idMatch = RegExp(r'[A-Za-z0-9_][A-Za-z0-9_.:-]*@').matchAsPrefix(text, cursor);
  if (idMatch != null) {
    id = idMatch.group(0)!.substring(0, idMatch.group(0)!.length - 1);
    cursor = idMatch.end;
  }

  final labeled = RegExp(
    r'^(x--|o--|<--|--|==|-\.)\s+(.+?)\s+(--x|--o|-->|==x|==o|==>|\.-x|\.-o|\.->)',
  ).firstMatch(text.substring(cursor));
  String operator;
  String? label;
  if (labeled != null) {
    operator = '${labeled.group(1)}${labeled.group(3)}';
    label = labeled.group(2)!.trim();
    cursor += labeled.end;
  } else {
    final operatorMatch = RegExp(
      r'^(?:x--x|o--o|<-->|x==x|o==o|<==>|x-\.->|o-\.->|<-.->|-->|==>|-\.->|--x|--o|==x|==o|-\.x|-\.o|---+|===+|-\.+-)',
    ).firstMatch(text.substring(cursor));
    if (operatorMatch == null) throwParseError(source, 'Expected flowchart edge', offset + cursor);
    operator = operatorMatch.group(0)!;
    cursor += operator.length;
    if (cursor < text.length && text[cursor] == '|') {
      final labelEnd = text.indexOf('|', cursor + 1);
      if (labelEnd < 0) throwParseError(source, 'Unterminated edge label', offset + cursor);
      label = text.substring(cursor + 1, labelEnd).trim();
      cursor = labelEnd + 1;
    }
  }

  final stroke = operator.contains('=')
      ? FlowchartEdgeStroke.thick
      : operator.contains('.')
      ? FlowchartEdgeStroke.dotted
      : FlowchartEdgeStroke.normal;
  final startMarker = operator.startsWith('o')
      ? FlowchartEdgeMarker.circle
      : operator.startsWith('x')
      ? FlowchartEdgeMarker.cross
      : operator.startsWith('<')
      ? FlowchartEdgeMarker.arrow
      : FlowchartEdgeMarker.none;
  final endMarker = operator.endsWith('o')
      ? FlowchartEdgeMarker.circle
      : operator.endsWith('x')
      ? FlowchartEdgeMarker.cross
      : operator.endsWith('>')
      ? FlowchartEdgeMarker.arrow
      : FlowchartEdgeMarker.none;
  final lineCharacters = operator.replaceAll(RegExp(r'[ox<>.]'), '');
  final length = labeled == null ? (lineCharacters.length - 2).clamp(1, 1000) : 1;
  return (
    id: id,
    label: label,
    stroke: stroke,
    startMarker: startMarker,
    endMarker: endMarker,
    length: length,
    end: cursor,
  );
}

int _skipFlowchartSpaces(String text, int start) {
  var cursor = start;
  while (cursor < text.length && text.codeUnitAt(cursor) <= 32) {
    cursor++;
  }
  return cursor;
}

String _unquoteFlowchart(String value) {
  if (value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'")))) {
    return decodeQuotedString(value);
  }
  return value;
}

String _flowchartLabel(String value) {
  final label = _unquoteFlowchart(value);
  return label.length >= 2 && label.startsWith('`') && label.endsWith('`')
      ? label.substring(1, label.length - 1)
      : label;
}

List<String> _commaSeparated(String value) =>
    value.split(',').map((part) => part.trim()).where((part) => part.isNotEmpty).toList();

Map<String, String> _parseStyleProperties(String value) => {
  for (final property in value.split(','))
    if (property.indexOf(':') case final separator when separator > 0)
      property.substring(0, separator).trim(): property.substring(separator + 1).trim(),
};

final class _ParsedFlowchartNode {
  const _ParsedFlowchartNode({
    required this.id,
    required this.label,
    required this.shape,
    required this.explicitShape,
    required this.cssClasses,
  });

  final String id;
  final String label;
  final FlowchartNodeShape shape;
  final bool explicitShape;
  final List<String> cssClasses;
}

final class _MutableFlowchartNode {
  _MutableFlowchartNode({
    required this.id,
    required this.label,
    this.shape = FlowchartNodeShape.rectangle,
    List<String> cssClasses = const [],
    Map<String, String>? styles,
  }) : cssClasses = {...cssClasses},
       styles = styles ?? {};

  final String id;
  String label;
  FlowchartNodeShape shape;
  final Set<String> cssClasses;
  final Map<String, String> styles;

  FlowchartNodeAst freeze() => FlowchartNodeAst(
    id: id,
    label: label,
    shape: shape,
    cssClasses: List.unmodifiable(cssClasses),
    styles: Map.unmodifiable(styles),
  );
}

final class _MutableFlowchartSubgraph {
  _MutableFlowchartSubgraph({required this.id, required this.title});

  final String id;
  final String title;
  FlowchartDirection? direction;
  final Set<String> nodeIds = {};

  FlowchartSubgraphAst freeze() =>
      FlowchartSubgraphAst(id: id, title: title, direction: direction, nodeIds: List.unmodifiable(nodeIds));
}
