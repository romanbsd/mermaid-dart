import 'ast.dart';
import 'common_syntax.dart';

const _quadrantNumberPattern = r'(?:1|0(?:\.\d+)?)';
final _pointPattern = RegExp(
  '^(.+?)(?:\\s*:::\\s*(\\w+))?\\s*:\\s*\\[\\s*($_quadrantNumberPattern)\\s*,\\s*'
  '($_quadrantNumberPattern)\\s*\\]\\s*(.*)\$',
);
final _axisDelimiter = RegExp(r'\s*--+>\s*');
final _axisStatement = RegExp(r'^(x-axis|y-axis)\s+(.*)$', caseSensitive: false);
final _quadrantStatement = RegExp(r'^quadrant-([1-4])\s+(.*)$', caseSensitive: false);
final _classStatement = RegExp(r'^classDef\s+(\w+)\s+(.+)$', caseSensitive: false);
final _hexColor = RegExp(r'^#?(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})$');
final _pixelSize = RegExp(r'^\d+px$');
final _integer = RegExp(r'^\d+$');

/// Parses Mermaid's `quadrantChart` grammar.
QuadrantChartAst parseQuadrantChart(String source) {
  final prepared = prepareDiagramSource(source, headers: const ['quadrantChart']);
  final lines = sourceLines(prepared.syntax);
  QuadrantAxisAst? xAxis;
  QuadrantAxisAst? yAxis;
  final quadrants = <Quadrant, String>{};
  final points = <QuadrantPointAst>[];
  final classes = <String, QuadrantPointStyleAst>{};

  for (var index = 0; index < lines.length; index++) {
    for (final statement in lines[index].text.split(';')) {
      final line = statement.trim();
      if (line.isEmpty) continue;

      final axisMatch = _axisStatement.firstMatch(line);
      if (axisMatch != null) {
        final axis = _parseAxis(axisMatch.group(2)!);
        if (axisMatch.group(1)!.toLowerCase() == 'x-axis') {
          xAxis = axis;
        } else {
          yAxis = axis;
        }
        continue;
      }

      final quadrantMatch = _quadrantStatement.firstMatch(line);
      if (quadrantMatch != null) {
        final quadrant = Quadrant.values[int.parse(quadrantMatch.group(1)!) - 1];
        quadrants[quadrant] = _text(quadrantMatch.group(2)!);
        continue;
      }

      final classMatch = _classStatement.firstMatch(line);
      if (classMatch != null) {
        classes[classMatch.group(1)!] = _parseStyles(classMatch.group(2)!, source, index);
        continue;
      }

      final pointMatch = _pointPattern.firstMatch(line);
      if (pointMatch != null) {
        points.add(
          QuadrantPointAst(
            label: _text(pointMatch.group(1)!),
            className: pointMatch.group(2),
            x: double.parse(pointMatch.group(3)!),
            y: double.parse(pointMatch.group(4)!),
            style: _parseStyles(pointMatch.group(5)!, source, index),
          ),
        );
        continue;
      }

      throwParseErrorOnLine(source, index, 'Invalid quadrant chart statement');
    }
  }

  return QuadrantChartAst(
    xAxis: xAxis,
    yAxis: yAxis,
    quadrants: Map.unmodifiable(quadrants),
    points: List.unmodifiable(points),
    classDefinitions: Map.unmodifiable(classes),
    title: prepared.metadata.title,
    accessibilityTitle: prepared.metadata.accessibilityTitle,
    accessibilityDescription: prepared.metadata.accessibilityDescription,
  );
}

QuadrantAxisAst _parseAxis(String source) {
  final parts = source.split(_axisDelimiter);
  return QuadrantAxisAst(
    start: _text(parts.first),
    end: parts.length > 1 && parts[1].trim().isNotEmpty ? _text(parts.sublist(1).join('-->')) : null,
  );
}

QuadrantPointStyleAst _parseStyles(String source, String diagramSource, int line) {
  if (source.trim().isEmpty) return const QuadrantPointStyleAst();
  double? radius;
  String? color;
  String? strokeColor;
  double? strokeWidth;
  for (final declaration in source.split(',')) {
    final separator = declaration.indexOf(':');
    if (separator < 0) throwParseErrorOnLine(diagramSource, line, 'Invalid quadrant point style');
    final name = declaration.substring(0, separator).trim().toLowerCase();
    final value = declaration.substring(separator + 1).trim();
    switch (name) {
      case 'radius':
        if (!_integer.hasMatch(value)) throwParseErrorOnLine(diagramSource, line, 'Invalid radius');
        radius = double.parse(value);
      case 'color':
        if (!_hexColor.hasMatch(value)) throwParseErrorOnLine(diagramSource, line, 'Invalid color');
        color = _normalizedColor(value);
      case 'stroke-color':
        if (!_hexColor.hasMatch(value)) throwParseErrorOnLine(diagramSource, line, 'Invalid stroke-color');
        strokeColor = _normalizedColor(value);
      case 'stroke-width':
        if (!_pixelSize.hasMatch(value)) throwParseErrorOnLine(diagramSource, line, 'Invalid stroke-width');
        strokeWidth = double.parse(value.substring(0, value.length - 2));
      default:
        throwParseErrorOnLine(diagramSource, line, 'Unsupported quadrant point style $name');
    }
  }
  return QuadrantPointStyleAst(radius: radius, color: color, strokeColor: strokeColor, strokeWidth: strokeWidth);
}

String _normalizedColor(String value) => (value.startsWith('#') ? value : '#$value').toLowerCase();

String _text(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"')) {
    final unquoted = trimmed.substring(1, trimmed.length - 1);
    return unquoted.length >= 2 && unquoted.startsWith('`') && unquoted.endsWith('`')
        ? unquoted.substring(1, unquoted.length - 1)
        : unquoted;
  }
  return trimmed;
}
