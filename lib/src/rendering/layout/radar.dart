part of '../layout.dart';

// Mermaid radar presentation and spacing defaults. Keeping them named makes
// the D3-derived geometry below readable and keeps style changes localized.
const _radarDefaultTicks = 5;
const _radarMinimumTicks = 1;
const _radarMaximumTicks = 1000;
const _radarLegendStrokeWidth = 1.0;
const _radarAxisLabelOffset = 4.0;
const _radarLegendTextOffset = 16.0;
const _radarLegendRowHeight = 20.0;
const _radarLegendPositionRatio = 3 / 4;
const _radarAxisDirectionTolerance = .01;
const _radarMinimumNormalizedValue = 0.0;
const _radarMaximumNormalizedValue = 1.0;
// Mermaid 11.16 exposes radar.legendBoxSize but still draws 12px swatches.
const _radarLegendBoxSize = 12.0;

_LayoutResult _layoutRadar(RadarAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const RadarRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  final seriesColors = config.resolveSeriesColors(context.options.theme);
  final labelStyle = _mermaidTextStyle(context, theme.axisLabelFontSize);
  final radius = config.radius ?? math.min(config.width, config.height) / 2;
  final center = Point(config.marginLeft + config.width / 2, config.marginTop + config.height / 2);
  final count = ast.axes.length;
  final ticks = (ast.options.whereType<RadarTicksOptionAst>().lastOrNull?.value.toInt() ?? _radarDefaultTicks).clamp(
    _radarMinimumTicks,
    _radarMaximumTicks,
  );
  final graticule = ast.options.whereType<RadarGraticuleOptionAst>().lastOrNull?.value ?? RadarGraticule.circle;
  final showLegend = ast.options.whereType<RadarShowLegendOptionAst>().lastOrNull?.value ?? true;
  final elements = <SceneElement>[];
  Point radialPoint(int index, double scale) => polarPoint(center, radius * scale, evenlySpacedAngle(index, count));

  if (count > 0) {
    for (var ring = 1; ring <= ticks; ring++) {
      final scale = ring / ticks;
      elements.add(
        _radarGraticule(
          context,
          graticule: graticule,
          center: center,
          radius: radius * scale,
          points: switch (graticule) {
            RadarGraticule.circle => const [],
            RadarGraticule.polygon => [for (var i = 0; i < count; i++) radialPoint(i, scale)],
          },
          theme: theme,
        ),
      );
    }
  }
  for (var i = 0; i < ast.axes.length; i++) {
    final angle = evenlySpacedAngle(i, count);
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    final end = radialPoint(i, config.axisScaleFactor);
    elements.add(
      SceneLine(
        id: context.id('radar-axis'),
        start: center,
        end: end,
        stroke: SceneStroke(color: theme.axisColor, width: theme.axisStrokeWidth),
        role: SemanticRole.edge,
        cssClasses: const ['radarAxisLine'],
      ),
    );
    final labelPoint = polarPoint(center, radius * config.axisLabelFactor + _radarAxisLabelOffset, angle);
    elements.add(
      _text(
        context,
        ast.axes[i].label ?? ast.axes[i].name,
        labelPoint.x,
        labelPoint.y,
        anchor: cosine > _radarAxisDirectionTolerance
            ? TextAnchor.start
            : (cosine < -_radarAxisDirectionTolerance ? TextAnchor.end : TextAnchor.middle),
        baseline: sine > _radarAxisDirectionTolerance
            ? TextBaseline.hanging
            : (sine < -_radarAxisDirectionTolerance ? TextBaseline.alphabetic : TextBaseline.middle),
        style: labelStyle,
        cssClasses: const ['radarAxisLabel'],
      ),
    );
  }
  final values = [
    for (final curve in ast.curves)
      for (final entry in curve.entries) entry.value.toDouble(),
  ];
  final minValue = ast.options.whereType<RadarMinOptionAst>().lastOrNull?.value.toDouble() ?? 0;
  final maxValue =
      ast.options.whereType<RadarMaxOptionAst>().lastOrNull?.value.toDouble() ??
      (values.isEmpty ? 1 : values.reduce(math.max));
  for (var curveIndex = 0; curveIndex < ast.curves.length; curveIndex++) {
    final curve = ast.curves[curveIndex];
    if (curve.entries.length != count || count == 0) continue;
    final entriesByAxis = <String, RadarEntryAst>{};
    for (final entry in curve.entries) {
      if (entry.axis case final axis?) {
        entriesByAxis[axis] ??= entry;
      }
    }
    final points = <Point>[];
    for (var i = 0; i < ast.axes.length; i++) {
      final entry = entriesByAxis[ast.axes[i].name] ?? curve.entries[i];
      final normalized = maxValue == minValue
          ? _radarMinimumNormalizedValue
          : ((entry.value.toDouble() - minValue) / (maxValue - minValue))
                .clamp(_radarMinimumNormalizedValue, _radarMaximumNormalizedValue)
                .toDouble();
      points.add(radialPoint(i, normalized));
    }
    final color = _radarSeriesColor(seriesColors, curveIndex);
    final fill = SolidFill(_colorWithOpacity(color, theme.curveOpacity));
    final stroke = SceneStroke(color: color, width: theme.curveStrokeWidth);
    elements.add(
      _radarCurve(
        context,
        graticule: graticule,
        points: points,
        tension: config.curveTension,
        fill: fill,
        stroke: stroke,
        curveIndex: curveIndex,
        label: curve.label ?? curve.name,
      ),
    );
  }
  if (showLegend) {
    final legendX = center.x + (config.width / 2 + config.marginRight) * _radarLegendPositionRatio;
    final legendY = center.y - (config.height / 2 + config.marginTop) * _radarLegendPositionRatio;
    for (var i = 0; i < ast.curves.length; i++) {
      final y = legendY + i * _radarLegendRowHeight;
      final color = _radarSeriesColor(seriesColors, i);
      elements.add(
        SceneRect(
          id: context.id('radar-legend-box'),
          bounds: Bounds(left: legendX, top: y, width: _radarLegendBoxSize, height: _radarLegendBoxSize),
          fill: SolidFill(_colorWithOpacity(color, theme.curveOpacity)),
          stroke: SceneStroke(color: color, width: _radarLegendStrokeWidth),
          role: SemanticRole.legend,
          cssClasses: ['radarLegendBox-$i'],
        ),
      );
      elements.add(
        _text(
          context,
          ast.curves[i].label ?? ast.curves[i].name,
          legendX + _radarLegendTextOffset,
          y,
          baseline: TextBaseline.hanging,
          role: SemanticRole.legend,
          style: SceneTextStyle(
            fontFamily: labelStyle.fontFamily,
            fontSize: theme.legendFontSize,
            color: labelStyle.color,
          ),
          cssClasses: const ['radarLegendText'],
        ),
      );
    }
  }
  if (ast.title != null) {
    elements.add(
      _text(
        context,
        ast.title!,
        center.x,
        center.y - config.height / 2 - config.marginTop,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.hanging,
        role: SemanticRole.title,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: context.options.theme.fontSize,
          color: context.options.theme.title,
        ),
        cssClasses: const ['radarTitle'],
      ),
    );
  }
  return _LayoutResult(
    config.width + config.marginLeft + config.marginRight,
    config.height + config.marginTop + config.marginBottom,
    elements,
  );
}

Color _radarSeriesColor(List<Color> colors, int index) {
  return colors[index % colors.length];
}

SceneElement _radarGraticule(
  _LayoutContext context, {
  required RadarGraticule graticule,
  required Point center,
  required double radius,
  required List<Point> points,
  required RadarTheme theme,
}) {
  final fill = SolidFill(_colorWithOpacity(theme.graticuleColor, theme.graticuleOpacity));
  final stroke = SceneStroke(color: theme.graticuleColor, width: theme.graticuleStrokeWidth);
  return switch (graticule) {
    RadarGraticule.circle => SceneCircle(
      id: context.id('radar-graticule'),
      center: center,
      radius: radius,
      fill: fill,
      stroke: stroke,
      cssClasses: const ['radarGraticule'],
    ),
    RadarGraticule.polygon => ScenePolygon(
      id: context.id('radar-graticule'),
      points: points,
      fill: fill,
      stroke: stroke,
      cssClasses: const ['radarGraticule'],
    ),
  };
}

SceneElement _radarCurve(
  _LayoutContext context, {
  required RadarGraticule graticule,
  required List<Point> points,
  required double tension,
  required SolidFill fill,
  required SceneStroke stroke,
  required int curveIndex,
  required String label,
}) {
  final id = context.id('radar-curve');
  final cssClasses = ['radarCurve-$curveIndex'];
  return switch (graticule) {
    RadarGraticule.circle => ScenePath(
      id: id,
      commands: closedCubicSplinePath(points, tension: tension),
      fill: fill,
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: cssClasses,
      label: label,
    ),
    RadarGraticule.polygon => ScenePolygon(
      id: id,
      points: points,
      fill: fill,
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: cssClasses,
      label: label,
    ),
  };
}
