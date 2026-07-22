import 'ast.dart';
import 'common_syntax.dart';

final _numberPattern = RegExp(r'^[0-9]+(?:\.[0-9]+)?$');
final _decimalPattern = RegExp(r'^[0-9]+\.[0-9]+$');
final _bareNamePattern = RegExp(r'^[A-Za-z](?:[A-Za-z0-9_()&-]|[ \t]+[A-Za-z(])*$');

WardleyAst parseWardley(String source) {
  final prepared = prepareDiagramSource(source, headers: const ['wardley-beta']);

  final lines = sourceLines(prepared.syntax);
  final result = _WardleyCollector();
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final content = line.text.trim();
    if (content.isEmpty) continue;

    if (content.startsWith('pipeline ')) {
      final parsed = _parsePipeline(source, lines, index);
      result.pipelines.add(parsed.pipeline);
      index = parsed.lastLine;
      continue;
    }
    _parseStatement(source, content, line.offset, result);
  }

  final componentNames = result.components.map((component) => component.name).toSet();
  for (final pipeline in result.pipelines) {
    if (!componentNames.contains(pipeline.parent)) {
      throwParseError(source, 'Pipeline "${pipeline.parent}" must reference a component', 0);
    }
  }

  return WardleyAst(
    size: result.size,
    evolutionStages: List.unmodifiable(result.evolutionStages),
    anchors: List.unmodifiable(result.anchors),
    components: List.unmodifiable(result.components),
    links: List.unmodifiable(result.links),
    evolves: List.unmodifiable(result.evolves),
    pipelines: List.unmodifiable(result.pipelines),
    notes: List.unmodifiable(result.notes),
    annotationsBox: result.annotationsBox,
    annotations: List.unmodifiable(result.annotations),
    markers: List.unmodifiable(result.markers),
    title: prepared.metadata.title,
    accessibilityTitle: prepared.metadata.accessibilityTitle,
    accessibilityDescription: prepared.metadata.accessibilityDescription,
  );
}

void _parseStatement(String source, String line, int offset, _WardleyCollector result) {
  if (line.startsWith('size ')) {
    result.size = _parseSize(source, line, offset);
  } else if (line.startsWith('evolution ')) {
    result.evolutionStages
      ..clear()
      ..addAll(_parseEvolution(source, line.substring('evolution '.length), offset));
  } else if (line.startsWith('anchor ')) {
    result.anchors.add(_parseAnchor(source, line.substring('anchor '.length), offset));
  } else if (line.startsWith('component ')) {
    result.components.add(_parseComponent(source, line.substring('component '.length), offset));
  } else if (line.startsWith('evolve ')) {
    result.evolves.add(_parseEvolve(source, line.substring('evolve '.length), offset));
  } else if (line.startsWith('note ')) {
    result.notes.add(_parseNote(source, line.substring('note '.length), offset));
  } else if (line.startsWith('annotations ')) {
    result.annotationsBox ??= _parseCoordinateDirective(
      source,
      line.substring('annotations '.length),
      offset,
      'annotations',
    );
  } else if (line.startsWith('annotation ')) {
    result.annotations.add(_parseAnnotation(source, line.substring('annotation '.length), offset));
  } else if (line.startsWith('accelerator ')) {
    final value = _parseNamedPosition(source, line.substring('accelerator '.length), offset, 'accelerator');
    result.markers.add(WardleyAcceleratorAst(name: value.name, position: value.position));
  } else if (line.startsWith('deaccelerator ')) {
    final value = _parseNamedPosition(source, line.substring('deaccelerator '.length), offset, 'deaccelerator');
    result.markers.add(WardleyDeacceleratorAst(name: value.name, position: value.position));
  } else {
    result.links.add(_parseLink(source, line, offset));
  }
}

WardleySizeAst _parseSize(String source, String line, int offset) {
  final match = RegExp(r'^size[ \t]*\[[ \t]*([0-9]+)[ \t]*,[ \t]*([0-9]+)[ \t]*\]$').firstMatch(line);
  if (match == null) throwParseError(source, 'Invalid Wardley size', offset);
  return WardleySizeAst(width: int.parse(match.group(1)!), height: int.parse(match.group(2)!));
}

List<WardleyEvolutionStageAst> _parseEvolution(String source, String value, int offset) {
  final parts = _splitOutsideQuotes(value, '->');
  if (parts.length < 2) throwParseError(source, 'Evolution requires at least two stages', offset);
  return parts
      .map((part) {
        final labels = _splitOutsideQuotes(part, '/');
        if (labels.length > 2) throwParseError(source, 'Invalid evolution stage', offset);
        final primary = labels.first.trim();
        final at = _lastOutsideQuotes(primary, '@');
        final nameText = at < 0 ? primary : primary.substring(0, at).trim();
        final boundary = at < 0 ? null : _decimal(source, primary.substring(at + 1).trim(), offset);
        return WardleyEvolutionStageAst(
          name: _name(source, nameText, offset),
          secondName: labels.length == 2 ? _name(source, labels[1].trim(), offset) : null,
          boundary: boundary,
        );
      })
      .toList(growable: false);
}

WardleyAnchorAst _parseAnchor(String source, String value, int offset) {
  final parsed = _namedBracket(source, value, offset, expectedValues: 2, context: 'anchor');
  _expectEmptySuffix(source, parsed.suffix, offset, 'anchor');
  return WardleyAnchorAst(
    name: parsed.name,
    position: _position(source, parsed.values[0], parsed.values[1], offset, 'anchor'),
  );
}

WardleyComponentAst _parseComponent(String source, String value, int offset) {
  final parsed = _namedBracket(source, value, offset, expectedValues: 2, context: 'component');
  var suffix = parsed.suffix.trim();
  WardleyLabelAst? label;
  final labelMatch = RegExp(r'\blabel[ \t]*\[[ \t]*(-?[0-9]+)[ \t]*,[ \t]*(-?[0-9]+)[ \t]*\]').firstMatch(suffix);
  if (labelMatch != null) {
    label = WardleyLabelAst(offsetX: int.parse(labelMatch.group(1)!), offsetY: int.parse(labelMatch.group(2)!));
    suffix = suffix.replaceRange(labelMatch.start, labelMatch.end, ' ').trim();
  }

  WardleyStrategy? strategy;
  final strategyMatch = RegExp(r'\((build|buy|outsource|market)\)').firstMatch(suffix);
  if (strategyMatch != null) {
    strategy = WardleyStrategy.values.byName(strategyMatch.group(1)!);
    suffix = suffix.replaceRange(strategyMatch.start, strategyMatch.end, ' ').trim();
  }
  var inertia = false;
  final inertiaMatch = RegExp(r'(?:\(inertia\)|\binertia\b)').firstMatch(suffix);
  if (inertiaMatch != null) {
    inertia = true;
    suffix = suffix.replaceRange(inertiaMatch.start, inertiaMatch.end, ' ').trim();
  }
  _expectEmptySuffix(source, suffix, offset, 'component');

  return WardleyComponentAst(
    name: parsed.name,
    position: _position(source, parsed.values[0], parsed.values[1], offset, 'component'),
    label: label,
    inertia: inertia,
    strategy: strategy,
  );
}

WardleyEvolveAst _parseEvolve(String source, String value, int offset) {
  final match = RegExp(r'^(.*?)[ \t]+([0-9]+\.[0-9]+)$').firstMatch(value.trim());
  if (match == null) throwParseError(source, 'Invalid evolve statement', offset);
  return WardleyEvolveAst(
    component: _name(source, match.group(1)!, offset),
    target: _percent(source, _number(source, match.group(2)!, offset), offset, 'evolve target'),
  );
}

WardleyNoteAst _parseNote(String source, String value, int offset) {
  final parsed = _namedBracket(source, value, offset, expectedValues: 2, context: 'note', quotedOnly: true);
  _expectEmptySuffix(source, parsed.suffix, offset, 'note');
  return WardleyNoteAst(
    text: parsed.name,
    position: _position(source, parsed.values[0], parsed.values[1], offset, 'note'),
  );
}

WardleyPositionAst _parseCoordinateDirective(String source, String value, int offset, String context) {
  final match = RegExp(
    r'^\[[ \t]*([0-9]+(?:\.[0-9]+)?)[ \t]*,[ \t]*([0-9]+(?:\.[0-9]+)?)[ \t]*\]$',
  ).firstMatch(value.trim());
  if (match == null) throwParseError(source, 'Invalid $context coordinates', offset);
  return _position(
    source,
    _number(source, match.group(1)!, offset),
    _number(source, match.group(2)!, offset),
    offset,
    context,
  );
}

WardleyAnnotationAst _parseAnnotation(String source, String value, int offset) {
  final match = RegExp(
    r'''^([0-9]+)[ \t]*,[ \t]*\[[ \t]*([0-9]+(?:\.[0-9]+)?)[ \t]*,[ \t]*([0-9]+(?:\.[0-9]+)?)[ \t]*\][ \t]*("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*')$''',
  ).firstMatch(value.trim());
  if (match == null) throwParseError(source, 'Invalid annotation', offset);
  return WardleyAnnotationAst(
    number: int.parse(match.group(1)!),
    position: _position(
      source,
      _number(source, match.group(2)!, offset),
      _number(source, match.group(3)!, offset),
      offset,
      'annotation',
    ),
    text: decodeQuotedString(match.group(4)!),
  );
}

({String name, WardleyPositionAst position}) _parseNamedPosition(
  String source,
  String value,
  int offset,
  String context,
) {
  final parsed = _namedBracket(source, value, offset, expectedValues: 2, context: context);
  _expectEmptySuffix(source, parsed.suffix, offset, context);
  return (name: parsed.name, position: _position(source, parsed.values[0], parsed.values[1], offset, context));
}

({WardleyPipelineAst pipeline, int lastLine}) _parsePipeline(String source, List<SourceLine> lines, int firstLine) {
  final header = lines[firstLine];
  final match = RegExp(r'^pipeline[ \t]+(.+?)[ \t]*\{$').firstMatch(header.text.trim());
  if (match == null) throwParseError(source, 'Invalid pipeline declaration', header.offset);
  final parent = _name(source, match.group(1)!, header.offset);
  final components = <WardleyPipelineComponentAst>[];
  var index = firstLine + 1;
  for (; index < lines.length; index++) {
    final content = lines[index].text.trim();
    if (content.isEmpty) continue;
    if (content == '}') break;
    if (!content.startsWith('component ')) {
      throwParseError(source, 'Expected pipeline component or "}"', lines[index].offset);
    }
    final parsed = _namedBracket(
      source,
      content.substring('component '.length),
      lines[index].offset,
      expectedValues: 1,
      context: 'pipeline component',
    );
    var suffix = parsed.suffix.trim();
    WardleyLabelAst? label;
    final labelMatch = RegExp(r'^label[ \t]*\[[ \t]*(-?[0-9]+)[ \t]*,[ \t]*(-?[0-9]+)[ \t]*\]$').firstMatch(suffix);
    if (labelMatch != null) {
      label = WardleyLabelAst(offsetX: int.parse(labelMatch.group(1)!), offsetY: int.parse(labelMatch.group(2)!));
      suffix = '';
    }
    _expectEmptySuffix(source, suffix, lines[index].offset, 'pipeline component');
    components.add(
      WardleyPipelineComponentAst(
        name: parsed.name,
        evolution: _percent(source, parsed.values.single, lines[index].offset, 'pipeline component evolution'),
        label: label,
      ),
    );
  }
  if (index >= lines.length) throwParseError(source, 'Unterminated pipeline', header.offset);
  if (components.isEmpty) throwParseError(source, 'Pipeline requires a component', header.offset);
  return (pipeline: WardleyPipelineAst(parent: parent, components: List.unmodifiable(components)), lastLine: index);
}

WardleyLinkAst _parseLink(String source, String line, int offset) {
  final semicolon = _firstOutsideQuotes(line, ';');
  final annotation = semicolon < 0 ? null : line.substring(semicolon + 1).trim();
  final expression = (semicolon < 0 ? line : line.substring(0, semicolon)).trim();
  final operators = _linkOperators(expression);
  if (operators.isEmpty) throwParseError(source, 'Invalid Wardley statement', offset);

  final first = operators.first;
  var separatorEnd = first.end;
  var flow = first.flow;
  var arrowLabel = first.label;
  var dashed = first.kind == _LinkOperatorKind.dashedArrow;
  var operatorIndex = 1;
  if (first.kind == _LinkOperatorKind.port && operators.length > 1) {
    final next = operators[1];
    if (expression.substring(first.end, next.start).trim().isEmpty && next.kind != _LinkOperatorKind.port) {
      separatorEnd = next.end;
      dashed = next.kind == _LinkOperatorKind.dashedArrow;
      flow ??= next.flow;
      arrowLabel ??= next.label;
      operatorIndex = 2;
    }
  }

  var targetEnd = expression.length;
  if (operators.length > operatorIndex) {
    final trailing = operators.last;
    if (trailing.kind == _LinkOperatorKind.port && expression.substring(trailing.end).trim().isEmpty) {
      targetEnd = trailing.start;
      if (first.kind != _LinkOperatorKind.port) flow = trailing.flow;
    }
  }
  final from = _name(source, expression.substring(0, first.start).trim(), offset);
  final to = _name(source, expression.substring(separatorEnd, targetEnd).trim(), offset);
  return WardleyLinkAst(
    from: from,
    to: to,
    style: dashed ? WardleyLinkStyle.dashed : WardleyLinkStyle.solid,
    flow: flow,
    label: arrowLabel ?? (annotation == null || annotation.isEmpty ? null : annotation),
  );
}

List<_LinkOperator> _linkOperators(String value) {
  final operators = <_LinkOperator>[];
  String? quote;
  for (var index = 0; index < value.length;) {
    final character = value[index];
    if (quote != null) {
      if (character == '\\') {
        index += 2;
      } else {
        if (character == quote) quote = null;
        index++;
      }
      continue;
    }
    if (character == '"' || character == "'") {
      quote = character;
      index++;
      continue;
    }
    final special = RegExp(r"^\+'([^']*)'(<>|<|>)").firstMatch(value.substring(index));
    if (special != null) {
      final direction = special.group(2)!;
      operators.add(
        _LinkOperator(
          start: index,
          end: index + special.end,
          kind: _LinkOperatorKind.flowArrow,
          flow: _flow(direction),
          label: special.group(1),
        ),
      );
      index += special.end;
      continue;
    }
    final token = _operatorAt(value, index);
    if (token != null) {
      operators.add(token);
      index = token.end;
    } else {
      index++;
    }
  }
  return operators;
}

_LinkOperator? _operatorAt(String value, int index) {
  for (final entry in const [
    ('-.->', _LinkOperatorKind.dashedArrow),
    ('-->', _LinkOperatorKind.arrow),
    ('->', _LinkOperatorKind.arrow),
    ('+<>', _LinkOperatorKind.port),
    ('+>', _LinkOperatorKind.port),
    ('+<', _LinkOperatorKind.port),
    ('>', _LinkOperatorKind.arrow),
  ]) {
    if (value.startsWith(entry.$1, index)) {
      return _LinkOperator(
        start: index,
        end: index + entry.$1.length,
        kind: entry.$2,
        flow: entry.$2 == _LinkOperatorKind.port ? _flow(entry.$1.substring(1)) : null,
      );
    }
  }
  return null;
}

WardleyLinkFlow _flow(String value) => switch (value) {
  '<>' => WardleyLinkFlow.bidirectional,
  '<' => WardleyLinkFlow.backward,
  '>' => WardleyLinkFlow.forward,
  _ => throw StateError('Unknown Wardley flow $value'),
};

({String name, List<num> values, String suffix}) _namedBracket(
  String source,
  String value,
  int offset, {
  required int expectedValues,
  required String context,
  bool quotedOnly = false,
}) {
  final open = _firstOutsideQuotes(value, '[');
  final close = open < 0 ? -1 : value.indexOf(']', open + 1);
  if (open < 0 || close < 0) throwParseError(source, 'Invalid $context coordinates', offset);
  final nameText = value.substring(0, open).trim();
  if (quotedOnly && (nameText.isEmpty || (nameText[0] != '"' && nameText[0] != "'"))) {
    throwParseError(source, '$context text must be quoted', offset);
  }
  final values = value
      .substring(open + 1, close)
      .split(',')
      .map((part) {
        return _decimal(source, part.trim(), offset + open + 1);
      })
      .toList(growable: false);
  if (values.length != expectedValues) {
    throwParseError(source, '$context requires $expectedValues coordinate values', offset + open);
  }
  return (name: _name(source, nameText, offset), values: values, suffix: value.substring(close + 1));
}

WardleyPositionAst _position(String source, num visibility, num evolution, int offset, String context) =>
    WardleyPositionAst(
      x: _percent(source, evolution, offset, '$context evolution'),
      y: _percent(source, visibility, offset, '$context visibility'),
    );

num _percent(String source, num value, int offset, String context) {
  final normalized = value <= 1 ? value * 100 : value;
  if (normalized < 0 || normalized > 100) {
    throwParseError(source, '$context must be between 0-1 or 0-100', offset);
  }
  return normalized == normalized.truncateToDouble() ? normalized.toInt() : normalized;
}

num _number(String source, String value, int offset) {
  if (!_numberPattern.hasMatch(value)) throwParseError(source, 'Expected Wardley number', offset);
  return num.parse(value);
}

num _decimal(String source, String value, int offset) {
  if (!_decimalPattern.hasMatch(value)) throwParseError(source, 'Expected Wardley decimal', offset);
  return double.parse(value);
}

String _name(String source, String value, int offset) {
  final trimmed = value.trim();
  if (trimmed.length >= 2 && (trimmed[0] == '"' || trimmed[0] == "'") && trimmed[trimmed.length - 1] == trimmed[0]) {
    return decodeQuotedString(trimmed);
  }
  if (!_bareNamePattern.hasMatch(trimmed)) throwParseError(source, 'Invalid Wardley name', offset);
  return trimmed;
}

void _expectEmptySuffix(String source, String suffix, int offset, String context) {
  if (suffix.trim().isNotEmpty) throwParseError(source, 'Unexpected $context content', offset);
}

List<String> _splitOutsideQuotes(String value, String separator) {
  final result = <String>[];
  String? quote;
  var start = 0;
  for (var index = 0; index <= value.length - separator.length; index++) {
    final character = value[index];
    if (quote != null) {
      if (character == '\\') {
        index++;
      } else if (character == quote) {
        quote = null;
      }
    } else if (character == '"' || character == "'") {
      quote = character;
    } else if (value.startsWith(separator, index)) {
      result.add(value.substring(start, index));
      start = index + separator.length;
      index += separator.length - 1;
    }
  }
  result.add(value.substring(start));
  return result;
}

int _firstOutsideQuotes(String value, String needle) {
  String? quote;
  for (var index = 0; index < value.length; index++) {
    final character = value[index];
    if (quote != null) {
      if (character == '\\') {
        index++;
      } else if (character == quote) {
        quote = null;
      }
    } else if (character == '"' || character == "'") {
      quote = character;
    } else if (value.startsWith(needle, index)) {
      return index;
    }
  }
  return -1;
}

int _lastOutsideQuotes(String value, String needle) {
  var result = -1;
  var start = 0;
  while (start < value.length) {
    final found = _firstOutsideQuotes(value.substring(start), needle);
    if (found < 0) break;
    result = start + found;
    start = result + needle.length;
  }
  return result;
}

enum _LinkOperatorKind { port, arrow, dashedArrow, flowArrow }

final class _LinkOperator {
  const _LinkOperator({required this.start, required this.end, required this.kind, this.flow, this.label});

  final int start;
  final int end;
  final _LinkOperatorKind kind;
  final WardleyLinkFlow? flow;
  final String? label;
}

final class _WardleyCollector {
  WardleySizeAst? size;
  final evolutionStages = <WardleyEvolutionStageAst>[];
  final anchors = <WardleyAnchorAst>[];
  final components = <WardleyComponentAst>[];
  final links = <WardleyLinkAst>[];
  final evolves = <WardleyEvolveAst>[];
  final pipelines = <WardleyPipelineAst>[];
  final notes = <WardleyNoteAst>[];
  WardleyPositionAst? annotationsBox;
  final annotations = <WardleyAnnotationAst>[];
  final markers = <WardleyMarkerAst>[];
}
