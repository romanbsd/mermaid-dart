import 'ast.dart';
import 'errors.dart';

const _numberPattern = r'[+-]?(?:\d+(?:\.\d+)?|\.\d+)';
final _range = RegExp('($_numberPattern)\\s*-->\\s*($_numberPattern)\\s*\$');
final _plotPoint = RegExp('^($_numberPattern)(?:\\s+("(?:[^"]*)"))?\$');

XyChartAst parseXyChart(String source) {
  final lines = source.split(RegExp(r'\r?\n'));
  var orientation = XyChartOrientation.vertical;
  String? title;
  String? accessibilityTitle;
  String? accessibilityDescription;
  String xTitle = '';
  String yTitle = '';
  XyChartAxisAst? xAxis;
  XyChartLinearAxisAst? yAxis;
  final plots = <XyChartPlotAst>[];
  var sawHeader = false;

  for (var index = 0; index < lines.length; index++) {
    var line = lines[index].trim();
    if (line.isEmpty || line.startsWith('%%')) continue;
    final comment = line.indexOf('%%');
    if (comment >= 0) line = line.substring(0, comment).trim();
    if (!sawHeader) {
      final match = RegExp(r'^xychart(?:-beta)?(?:\s+(vertical|horizontal))?$', caseSensitive: false).firstMatch(line);
      if (match == null) _fail(source, index, 'Expected xychart');
      orientation = match.group(1)?.toLowerCase() == 'horizontal'
          ? XyChartOrientation.horizontal
          : XyChartOrientation.vertical;
      sawHeader = true;
      continue;
    }
    if (line.startsWith('accDescr') && line.contains('{')) {
      final value = <String>[];
      while (++index < lines.length && !lines[index].contains('}')) {
        value.add(lines[index].trimRight());
      }
      if (index == lines.length) _fail(source, index - 1, 'Unterminated accDescr');
      accessibilityDescription = value.join('\n').trim();
      continue;
    }
    if (line.startsWith('accTitle:')) {
      accessibilityTitle = line.substring(line.indexOf(':') + 1).trim();
      continue;
    }
    if (line.startsWith('accDescr:')) {
      accessibilityDescription = line.substring(line.indexOf(':') + 1).trim();
      continue;
    }
    if (line.startsWith('title ')) {
      title = _text(line.substring(6).trim());
      continue;
    }
    if (line.startsWith('x-axis')) {
      final parsed = _axis(line.substring(6).trim(), source, index, allowBand: true);
      xTitle = parsed.$1;
      xAxis = parsed.$2;
      continue;
    }
    if (line.startsWith('y-axis')) {
      final parsed = _axis(line.substring(6).trim(), source, index, allowBand: false);
      yTitle = parsed.$1;
      yAxis = parsed.$2 as XyChartLinearAxisAst?;
      continue;
    }
    final plotMatch = RegExp(r'^(bar|line)\s+(.*?)\s*(\[[^\]]*\])\s*$', caseSensitive: false).firstMatch(line);
    if (plotMatch == null) _fail(source, index, 'Invalid XY chart statement');
    final values = _plotValues(plotMatch.group(3)!, source, index);
    plots.add(
      XyChartPlotAst(
        type: plotMatch.group(1)!.toLowerCase() == 'bar' ? XyChartPlotType.bar : XyChartPlotType.line,
        title: _text(plotMatch.group(2)!.trim()),
        points: List.unmodifiable(values.$1),
        pointLabels: values.$2.any((label) => label.isNotEmpty) ? List.unmodifiable(values.$2) : const [],
      ),
    );
  }
  if (!sawHeader) _fail(source, 0, 'Expected xychart');
  final visibleCount = switch (xAxis) {
    XyChartBandAxisAst axis => axis.categories.length,
    _ => plots.fold<int>(0, (length, plot) => plot.points.length > length ? plot.points.length : length),
  };
  xAxis ??= XyChartLinearAxisAst(title: xTitle, min: 1, max: visibleCount.toDouble());
  final visibleValues = <double>[
    for (final plot in plots) ...plot.points.take(xAxis is XyChartBandAxisAst ? visibleCount : plot.points.length),
  ];
  yAxis ??= XyChartLinearAxisAst(
    title: yTitle,
    min: visibleValues.isEmpty ? 0 : visibleValues.reduce((a, b) => a < b ? a : b),
    max: visibleValues.isEmpty ? 1 : visibleValues.reduce((a, b) => a > b ? a : b),
  );
  return XyChartAst(
    orientation: orientation,
    xAxis: xAxis,
    yAxis: yAxis,
    plots: List.unmodifiable(plots),
    title: title,
    accessibilityTitle: accessibilityTitle,
    accessibilityDescription: accessibilityDescription,
  );
}

(String, XyChartAxisAst?) _axis(String value, String source, int line, {required bool allowBand}) {
  final bandStart = value.indexOf('[');
  if (bandStart >= 0) {
    if (!allowBand || !value.endsWith(']')) _fail(source, line, 'Invalid axis data');
    final title = _text(value.substring(0, bandStart).trim());
    final categories = _split(value.substring(bandStart + 1, value.length - 1));
    if (categories.isEmpty) _fail(source, line, 'Axis categories cannot be empty');
    return (title, XyChartBandAxisAst(title: title, categories: categories.map(_text).toList()));
  }
  final match = _range.firstMatch(value);
  if (match != null) {
    final axisTitle = _text(value.substring(0, match.start).trim());
    return (
      axisTitle,
      XyChartLinearAxisAst(title: axisTitle, min: double.parse(match.group(1)!), max: double.parse(match.group(2)!)),
    );
  }
  return (_text(value), null);
}

(List<double>, List<String>) _plotValues(String value, String source, int line) {
  final items = _split(value.substring(1, value.length - 1));
  if (items.isEmpty) _fail(source, line, 'Plot data cannot be empty');
  final points = <double>[];
  final labels = <String>[];
  for (final item in items) {
    final match = _plotPoint.firstMatch(item.trim());
    if (match == null) _fail(source, line, 'Invalid plot data');
    points.add(double.parse(match.group(1)!));
    labels.add(match.group(2) == null ? '' : _text(match.group(2)!));
  }
  return (points, labels);
}

List<String> _split(String value) {
  final result = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    if (character == '"') quoted = !quoted;
    if (character == ',' && !quoted) {
      if (buffer.toString().trim().isEmpty) return const [];
      result.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(character);
    }
  }
  if (quoted || buffer.toString().trim().isEmpty) return const [];
  result.add(buffer.toString().trim());
  return result;
}

String _text(String value) => value.length >= 2 && value.startsWith('"') && value.endsWith('"')
    ? value.substring(1, value.length - 1)
    : value.replaceAll(RegExp(r'\s+'), '');

Never _fail(String source, int line, String message) {
  final safeLine = line.clamp(0, source.split(RegExp(r'\r?\n')).length - 1);
  throw MermaidParseException(message: message, source: source, offset: 0, line: safeLine + 1, column: 1);
}
