part of '../layout.dart';

_LayoutResult _layoutRadar(RadarAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const RadarRenderOptions());
  final labelStyle = _mermaidTextStyle(context, 12);
  final radius = config.radius ?? math.min(config.width, config.height) / 2;
  final center = Point(config.marginLeft + config.width / 2, config.marginTop + config.height / 2);
  final count = ast.axes.length;
  final ticks = (ast.options.whereType<RadarTicksOptionAst>().lastOrNull?.value.toInt() ?? 5).clamp(1, 1000);
  final graticule = ast.options.whereType<RadarGraticuleOptionAst>().lastOrNull?.value ?? RadarGraticule.circle;
  final showLegend = ast.options.whereType<RadarShowLegendOptionAst>().lastOrNull?.value ?? true;
  final elements = <SceneElement>[];
  Point polar(int index, double scale) {
    final angle = -math.pi / 2 + math.pi * 2 * index / count;
    return Point(center.x + math.cos(angle) * radius * scale, center.y + math.sin(angle) * radius * scale);
  }

  if (count > 0) {
    for (var ring = 1; ring <= ticks; ring++) {
      final scale = ring / ticks;
      elements.add(switch (graticule) {
        RadarGraticule.circle => SceneCircle(
          id: context.id('radar-graticule'),
          center: center,
          radius: radius * scale,
          fill: const NoFill(),
          stroke: _stroke(context, width: .7),
          cssClasses: const ['radarGraticule'],
        ),
        RadarGraticule.polygon => ScenePolygon(
          id: context.id('radar-graticule'),
          points: [for (var i = 0; i < count; i++) polar(i, scale)],
          fill: const NoFill(),
          stroke: _stroke(context, width: .7),
          cssClasses: const ['radarGraticule'],
        ),
      });
    }
  }
  for (var i = 0; i < ast.axes.length; i++) {
    final angle = -math.pi / 2 + math.pi * 2 * i / count;
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    final end = polar(i, config.axisScaleFactor);
    elements.add(
      SceneLine(
        id: context.id('radar-axis'),
        start: center,
        end: end,
        stroke: _stroke(context, width: .7),
        role: SemanticRole.edge,
        cssClasses: const ['radarAxisLine'],
      ),
    );
    final labelPoint = Point(
      center.x + radius * config.axisLabelFactor * cosine + 4 * cosine,
      center.y + radius * config.axisLabelFactor * sine + 4 * sine,
    );
    elements.add(
      _text(
        context,
        ast.axes[i].label ?? ast.axes[i].name,
        labelPoint.x,
        labelPoint.y,
        anchor: cosine > .01 ? TextAnchor.start : (cosine < -.01 ? TextAnchor.end : TextAnchor.middle),
        baseline: sine > .01 ? TextBaseline.hanging : (sine < -.01 ? TextBaseline.alphabetic : TextBaseline.middle),
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
    final points = <Point>[];
    for (var i = 0; i < ast.axes.length; i++) {
      final axis = ast.axes[i];
      final entry =
          curve.entries.where((entry) => entry.axis == axis.name).firstOrNull ??
          (i < curve.entries.length ? curve.entries[i] : null);
      final normalized = entry == null || maxValue == minValue
          ? 0.0
          : ((entry.value.toDouble() - minValue) / (maxValue - minValue)).clamp(0, 1).toDouble();
      points.add(polar(i, normalized));
    }
    final color = _palette[curveIndex % _palette.length];
    final fill = SolidFill(Color(color.red, color.green, color.blue, 80));
    final stroke = SceneStroke(color: color, width: 2);
    elements.add(switch (graticule) {
      RadarGraticule.circle => ScenePath(
        id: context.id('radar-curve'),
        commands: _closedRoundCurve(points, config.curveTension),
        fill: fill,
        stroke: stroke,
        role: SemanticRole.node,
        cssClasses: ['radarCurve-$curveIndex'],
        label: curve.label ?? curve.name,
      ),
      RadarGraticule.polygon => ScenePolygon(
        id: context.id('radar-curve'),
        points: points,
        fill: fill,
        stroke: stroke,
        role: SemanticRole.node,
        cssClasses: ['radarCurve-$curveIndex'],
        label: curve.label ?? curve.name,
      ),
    });
  }
  if (showLegend) {
    final legendX = center.x + ((config.width / 2 + config.marginRight) * 3) / 4;
    final legendY = center.y - ((config.height / 2 + config.marginTop) * 3) / 4;
    for (var i = 0; i < ast.curves.length; i++) {
      final y = legendY + i * 20;
      elements.add(
        SceneRect(
          id: context.id('radar-legend-box'),
          bounds: Bounds(left: legendX, top: y, width: 12, height: 12),
          fill: SolidFill(_palette[i % _palette.length]),
          role: SemanticRole.legend,
          cssClasses: ['radarLegendBox-$i'],
        ),
      );
      elements.add(
        _text(
          context,
          ast.curves[i].label ?? ast.curves[i].name,
          legendX + 16,
          y,
          baseline: TextBaseline.hanging,
          role: SemanticRole.legend,
          style: labelStyle,
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
        style: _mermaidTextStyle(context, 16),
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

List<PathCommand> _closedRoundCurve(List<Point> points, double tension) {
  if (points.isEmpty) return const [];
  final commands = <PathCommand>[MoveTo(points.first)];
  for (var i = 0; i < points.length; i++) {
    final p0 = points[(i - 1 + points.length) % points.length];
    final p1 = points[i];
    final p2 = points[(i + 1) % points.length];
    final p3 = points[(i + 2) % points.length];
    commands.add(
      CubicTo(
        Point(p1.x + (p2.x - p0.x) * tension, p1.y + (p2.y - p0.y) * tension),
        Point(p2.x - (p3.x - p1.x) * tension, p2.y - (p3.y - p1.y) * tension),
        p2,
      ),
    );
  }
  commands.add(const ClosePath());
  return commands;
}
