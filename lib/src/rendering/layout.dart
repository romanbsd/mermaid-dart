import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../parser/ast.dart';
import '../parser/diagram_type.dart';
import '../parser/parser.dart';
import 'options.dart';
import 'scene.dart';
import 'svg.dart';

const _palette = <Color>[
  Color(87, 103, 198),
  Color(241, 156, 74),
  Color(76, 175, 130),
  Color(218, 91, 91),
  Color(151, 104, 190),
  Color(72, 169, 197),
  Color(222, 190, 73),
];

DiagramScene layoutDiagram(
  DiagramAst diagram, {
  RenderOptions options = const RenderOptions(),
  TextMeasurer textMeasurer = const DeterministicTextMeasurer(),
  IconResolver iconResolver = const EmptyIconResolver(),
}) {
  final context = _LayoutContext(options, textMeasurer, iconResolver);
  final content = switch (diagram) {
    ArchitectureAst ast => _layoutArchitecture(ast, context),
    CynefinAst ast => _layoutCynefin(ast, context),
    EventModelingAst ast => _layoutEventModeling(ast, context),
    GitGraphAst ast => _layoutGitGraph(ast, context),
    InfoAst ast => _layoutInfo(ast, context),
    PacketAst ast => _layoutPacket(ast, context),
    PieAst ast => _layoutPie(ast, context),
    RadarAst ast => _layoutRadar(ast, context),
    RailroadAst ast => _layoutRailroad(ast, context),
    TreeViewAst ast => _layoutTree(ast, context),
    TreemapAst ast => _layoutTreemap(ast, context),
    WardleyAst ast => _layoutWardley(ast, context),
  };

  final rendererPositionsTitle = diagram is PacketAst || diagram is PieAst || diagram is RadarAst;
  final titleHeight = diagram.title == null || rendererPositionsTitle ? 0.0 : 38.0;
  final List<SceneElement> translated = titleHeight == 0
      ? content.elements
      : [
          _text(context, diagram.title!, content.width / 2, 24, anchor: TextAnchor.middle, role: SemanticRole.title),
          SceneGroup(id: context.id('content'), transforms: [Translate(0, titleHeight)], children: content.elements),
        ];
  final width = math.max(content.width, 1.0);
  final height = math.max(content.height + titleHeight, 1.0);
  final viewport = Bounds(left: 0, top: 0, width: width, height: height).expand(options.padding);
  return DiagramScene(
    viewport: viewport,
    bounds: Bounds(left: 0, top: 0, width: width, height: height),
    background: options.theme.background,
    title: diagram.title,
    description: diagram.accessibilityDescription,
    accessibilityTitle: diagram.accessibilityTitle ?? diagram.title,
    accessibilityDescription: diagram.accessibilityDescription,
    elements: translated,
  );
}

String renderDiagramSvg(
  DiagramType diagramType,
  String source, {
  RenderOptions options = const RenderOptions(),
  TextMeasurer textMeasurer = const DeterministicTextMeasurer(),
  IconResolver iconResolver = const EmptyIconResolver(),
  SvgRenderOptions svgOptions = const SvgRenderOptions(),
}) => renderSvg(
  layoutDiagram(parse(diagramType, source), options: options, textMeasurer: textMeasurer, iconResolver: iconResolver),
  options: svgOptions,
);

final class _LayoutContext {
  _LayoutContext(this.options, this.measurer, this.iconResolver);
  final RenderOptions options;
  final TextMeasurer measurer;
  final IconResolver iconResolver;
  int _nextId = 0;
  String id(String prefix) => '$prefix-${_nextId++}';
  SceneTextStyle get textStyle => SceneTextStyle(
    fontFamily: options.theme.fontFamily,
    fontSize: options.theme.fontSize,
    color: options.theme.primaryText,
  );
}

final class _LayoutResult {
  const _LayoutResult(this.width, this.height, this.elements);
  final double width;
  final double height;
  final List<SceneElement> elements;
}

SceneText _text(
  _LayoutContext context,
  String value,
  double x,
  double y, {
  TextAnchor anchor = TextAnchor.start,
  TextBaseline baseline = TextBaseline.middle,
  SemanticRole role = SemanticRole.label,
  SceneTextStyle? style,
  List<String> cssClasses = const [],
}) {
  final resolved = style ?? context.textStyle;
  final size = context.measurer.measure(value, resolved);
  final left = switch (anchor) {
    TextAnchor.start => x,
    TextAnchor.middle => x - size.width / 2,
    TextAnchor.end => x - size.width,
  };
  return SceneText(
    id: context.id(role.name),
    position: Point(x, y),
    text: value,
    bounds: Bounds(left: left, top: y - size.height / 2, width: size.width, height: size.height),
    style: resolved,
    anchor: anchor,
    baseline: baseline,
    role: role,
    cssClasses: cssClasses,
  );
}

SceneStroke _stroke(_LayoutContext context, {double width = 1.5, List<double> dashes = const []}) => SceneStroke(
  color: context.options.theme.line,
  width: width,
  dashes: dashes,
  cap: StrokeCap.round,
  join: StrokeJoin.round,
);

_LayoutResult _layoutInfo(InfoAst ast, _LayoutContext context) {
  const width = 240.0;
  const height = 80.0;
  return _LayoutResult(width, height, [
    SceneRect(
      id: context.id('info'),
      bounds: const Bounds(left: 0, top: 0, width: width, height: height),
      radiusX: 6,
      radiusY: 6,
      fill: SolidFill(context.options.theme.primary),
      stroke: SceneStroke(color: context.options.theme.primaryBorder),
      role: SemanticRole.node,
      cssClasses: const ['info'],
    ),
    _text(context, 'mermaid-dart', width / 2, height / 2, anchor: TextAnchor.middle),
  ]);
}

_LayoutResult _layoutPacket(PacketAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const PacketRenderOptions());
  final width = config.bitWidth * config.bitsPerRow + 2;
  final elements = <SceneElement>[];
  var cursor = 0;
  for (final block in ast.blocks) {
    final (start, end) = switch (block) {
      PacketSingleBitBlockAst(:final bit) => (bit, bit),
      PacketRangeBlockAst(:final start, :final end) => (start, end),
      PacketRelativeWidthBlockAst(:final bits) => (cursor, cursor + bits - 1),
    };
    var segmentStart = start;
    while (segmentStart <= end) {
      final row = segmentStart ~/ config.bitsPerRow;
      final rowEnd = (row + 1) * config.bitsPerRow - 1;
      final segmentEnd = math.min(end, rowEnd);
      final x = (segmentStart % config.bitsPerRow) * config.bitWidth + 1;
      final y = row * (config.rowHeight + config.paddingY) + config.paddingY;
      final blockWidth = (segmentEnd - segmentStart + 1) * config.bitWidth - config.paddingX;
      elements.add(
        SceneRect(
          id: context.id('packet-block'),
          bounds: Bounds(left: x, top: y, width: blockWidth, height: config.rowHeight),
          fill: SolidFill(context.options.theme.primary),
          stroke: _stroke(context, width: 1),
          role: SemanticRole.node,
          cssClasses: const ['packetBlock'],
          label: block.label,
        ),
      );
      elements.add(
        _text(
          context,
          block.label,
          x + blockWidth / 2,
          y + config.rowHeight / 2,
          anchor: TextAnchor.middle,
          cssClasses: const ['packetLabel'],
        ),
      );
      if (config.showBits) {
        final single = segmentStart == segmentEnd;
        elements.add(
          _text(
            context,
            '$segmentStart',
            x + (single ? blockWidth / 2 : 0),
            y - 2,
            anchor: single ? TextAnchor.middle : TextAnchor.start,
            baseline: TextBaseline.alphabetic,
            cssClasses: const ['packetByte', 'start'],
          ),
        );
        if (!single) {
          elements.add(
            _text(
              context,
              '$segmentEnd',
              x + blockWidth,
              y - 2,
              anchor: TextAnchor.end,
              baseline: TextBaseline.alphabetic,
              cssClasses: const ['packetByte', 'end'],
            ),
          );
        }
      }
      segmentStart = segmentEnd + 1;
    }
    cursor = end + 1;
  }
  final rows = math.max(1, (cursor + config.bitsPerRow - 1) ~/ config.bitsPerRow);
  final totalRowHeight = config.rowHeight + config.paddingY;
  final height = totalRowHeight * (rows + 1) - (ast.title == null ? config.rowHeight : 0);
  if (ast.title != null) {
    elements.add(
      _text(
        context,
        ast.title!,
        width / 2,
        height - totalRowHeight / 2,
        anchor: TextAnchor.middle,
        cssClasses: const ['packetTitle'],
        role: SemanticRole.title,
      ),
    );
  }
  return _LayoutResult(width, height, elements);
}

_LayoutResult _layoutPie(PieAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const PieRenderOptions());
  final radius = config.radius ?? config.size / 2 - config.margin;
  final total = ast.sections.fold<double>(0, (sum, section) => sum + math.max(0, section.value.toDouble()));
  final rendered = <({int index, PieSectionAst section})>[
    for (var i = 0; i < ast.sections.length; i++)
      if (total > 0 && math.max(0, ast.sections[i].value.toDouble()) / total * 100 >= 1)
        (index: i, section: ast.sections[i]),
  ];
  final arcTotal = rendered.fold<double>(0, (sum, entry) => sum + entry.section.value.toDouble());
  const legendRectSize = 18.0;
  const legendSpacing = 4.0;
  final legendLineHeight = legendRectSize + legendSpacing;
  final legendLabels = [
    for (final section in ast.sections) '${section.label}${ast.showData ? ' [${section.value}]' : ''}',
  ];
  final longestLegend = legendLabels
      .map((label) => context.measurer.measure(label, context.textStyle).width)
      .fold(0.0, math.max);
  final legendWidth = legendRectSize + legendSpacing + longestLegend;
  final totalLegendHeight = ast.sections.length * legendLineHeight;
  var width = config.size + config.margin;
  var height = config.size;
  var center = Point(config.size / 2, config.size / 2);
  var legendLeft = center.x + 12 * legendRectSize;
  var legendTop = center.y - totalLegendHeight / 2;
  switch (config.legendPosition) {
    case PieLegendPosition.top:
      height += totalLegendHeight;
      legendLeft = center.x - longestLegend / 2 - legendRectSize - legendSpacing;
      legendTop = config.margin;
      center = Point(center.x, center.y + totalLegendHeight + legendLineHeight);
    case PieLegendPosition.bottom:
      height += totalLegendHeight;
      legendLeft = center.x - longestLegend / 2 - legendRectSize - legendSpacing;
      legendTop = center.y + radius + legendLineHeight;
    case PieLegendPosition.left:
      width += legendWidth;
      legendLeft = legendRectSize;
      legendTop = center.y - totalLegendHeight / 2;
      center = Point(center.x + legendWidth + legendLineHeight, center.y);
    case PieLegendPosition.right:
      width += legendWidth;
    case PieLegendPosition.center:
      legendLeft = center.x - longestLegend / 2 - legendRectSize - legendSpacing;
      legendTop = center.y - totalLegendHeight / 2;
  }
  final elements = <SceneElement>[];
  elements.add(
    SceneCircle(
      id: context.id('pie-outer-circle'),
      center: center,
      radius: radius + 1,
      fill: const NoFill(),
      stroke: _stroke(context, width: 2),
      cssClasses: const ['pieOuterCircle'],
    ),
  );
  var angle = -math.pi / 2;
  final innerRadius = config.donutHole > 0 && config.donutHole <= .9 ? radius * config.donutHole : 0.0;
  for (final entry in rendered) {
    final section = entry.section;
    final sweep = section.value.toDouble() / arcTotal * math.pi * 2;
    final end = angle + sweep;
    final classes = <String>['pieCircle'];
    if (config.highlightSlice == 'hover') {
      classes.add('highlightedOnHover');
    } else if (config.highlightSlice == section.label) {
      classes.add('highlighted');
    }
    elements.add(
      ScenePath(
        id: context.id('pie-section'),
        commands: _pieArcCommands(center, radius, innerRadius, angle, end),
        fill: SolidFill(_palette[entry.index % _palette.length]),
        stroke: const SceneStroke(color: Color(255, 255, 255), width: 2),
        role: SemanticRole.node,
        cssClasses: classes,
        label: section.label,
      ),
    );
    final middle = angle + sweep / 2;
    final labelRadius = radius * config.textPosition.clamp(0, 1);
    elements.add(
      _text(
        context,
        '${(section.value.toDouble() / total * 100).round()}%',
        center.x + math.cos(middle) * labelRadius,
        center.y + math.sin(middle) * labelRadius,
        anchor: TextAnchor.middle,
        cssClasses: const ['slice'],
      ),
    );
    angle = end;
  }
  if (config.showLegend) {
    for (var i = 0; i < ast.sections.length; i++) {
      elements.add(
        SceneRect(
          id: context.id('legend-swatch'),
          bounds: Bounds(
            left: legendLeft,
            top: legendTop + i * legendLineHeight,
            width: legendRectSize,
            height: legendRectSize,
          ),
          fill: SolidFill(_palette[i % _palette.length]),
          stroke: SceneStroke(color: _palette[i % _palette.length]),
          role: SemanticRole.legend,
          cssClasses: const ['legend'],
        ),
      );
      elements.add(
        _text(
          context,
          legendLabels[i],
          legendLeft + legendRectSize + legendSpacing,
          legendTop + i * legendLineHeight + legendRectSize - legendSpacing,
          role: SemanticRole.legend,
          baseline: TextBaseline.alphabetic,
          cssClasses: const ['legendText'],
        ),
      );
    }
  }
  if (ast.title != null) {
    elements.add(
      _text(
        context,
        ast.title!,
        config.size / 2,
        25,
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
        cssClasses: const ['pieTitleText'],
      ),
    );
  }
  return _LayoutResult(width, height, elements);
}

List<PathCommand> _pieArcCommands(Point center, double outer, double inner, double start, double end) {
  Point polar(double radius, double angle) =>
      Point(center.x + radius * math.cos(angle), center.y + radius * math.sin(angle));
  final sweep = end - start;
  final full = sweep >= math.pi * 2 - 1e-9;
  final commands = <PathCommand>[MoveTo(polar(outer, start))];
  if (full) {
    commands
      ..add(ArcTo(radiusX: outer, radiusY: outer, end: polar(outer, start + math.pi)))
      ..add(ArcTo(radiusX: outer, radiusY: outer, end: polar(outer, end)));
  } else {
    commands.add(ArcTo(radiusX: outer, radiusY: outer, largeArc: sweep > math.pi, end: polar(outer, end)));
  }
  if (inner == 0) {
    commands.add(LineTo(center));
  } else {
    commands.add(LineTo(polar(inner, end)));
    if (full) {
      commands
        ..add(ArcTo(radiusX: inner, radiusY: inner, clockwise: false, end: polar(inner, start + math.pi)))
        ..add(ArcTo(radiusX: inner, radiusY: inner, clockwise: false, end: polar(inner, start)));
    } else {
      commands.add(
        ArcTo(radiusX: inner, radiusY: inner, largeArc: sweep > math.pi, clockwise: false, end: polar(inner, start)),
      );
    }
  }
  commands.add(const ClosePath());
  return commands;
}

_LayoutResult _layoutRadar(RadarAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const RadarRenderOptions());
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
          baseline: TextBaseline.alphabetic,
          role: SemanticRole.legend,
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
        role: SemanticRole.title,
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

_LayoutResult _layoutTree(TreeViewAst ast, _LayoutContext context) {
  const rowHeight = 34.0;
  const indentWidth = 30.0;
  final elements = <SceneElement>[];
  var maxWidth = 220.0;
  for (var i = 0; i < ast.nodes.length; i++) {
    final node = ast.nodes[i];
    final indent = node.indent ?? 0;
    final y = i * rowHeight + rowHeight / 2;
    final x = indent * indentWidth + 12;
    if (i > 0 && indent > 0) {
      elements.add(
        SceneLine(
          id: context.id('tree-edge'),
          start: Point(x - 16, y - rowHeight),
          end: Point(x - 16, y),
          stroke: _stroke(context, width: 1),
          role: SemanticRole.edge,
        ),
      );
      elements.add(
        SceneLine(
          id: context.id('tree-edge'),
          start: Point(x - 16, y),
          end: Point(x - 4, y),
          stroke: _stroke(context, width: 1),
          role: SemanticRole.edge,
        ),
      );
    }
    elements.add(
      SceneCircle(
        id: context.id('tree-node'),
        center: Point(x, y),
        radius: 4,
        fill: SolidFill(context.options.theme.primaryBorder),
        role: SemanticRole.node,
        cssClasses: [if (node.cssClass != null) node.cssClass!],
        label: node.name,
      ),
    );
    var labelX = x + 12;
    if (node.icon != null) {
      final geometry = _iconGeometry(context, node.icon!);
      elements.add(
        SceneIcon(
          id: context.id('tree-icon'),
          position: Point(labelX, y - geometry.bounds.height / 2),
          geometry: geometry,
          stroke: _stroke(context, width: 1),
          label: node.icon,
        ),
      );
      labelX += geometry.bounds.width + 7;
    }
    elements.add(
      _text(context, node.description == null ? node.name : '${node.name} — ${node.description}', labelX, y),
    );
    final measured = context.measurer.measure(node.name, context.textStyle).width + labelX + 18;
    maxWidth = math.max(maxWidth, measured);
  }
  return _LayoutResult(maxWidth, math.max(rowHeight, ast.nodes.length * rowHeight), elements);
}

IconGeometry _iconGeometry(_LayoutContext context, String reference) =>
    context.iconResolver.resolve(reference) ?? const PlaceholderIconResolver().resolve(reference);

final class _RailBox {
  const _RailBox(this.width, this.height, this.elements);
  final double width;
  final double height;
  final List<SceneElement> elements;
}

_RailBox _railNode(RailroadNodeAst node, _LayoutContext context) => switch (node) {
  RailroadTerminalAst(:final value) => _railLeaf(value, context, true),
  RailroadNonTerminalAst(:final name) => _railLeaf(name, context, false),
  RailroadSpecialAst(:final text) => _railLeaf(text, context, false),
  RailroadSequenceAst(:final elements) => _railSequence(elements, context),
  RailroadChoiceAst(:final alternatives) => _railChoice(alternatives, context),
  RailroadOptionalAst(:final element) => _railChoice([element, const RailroadSpecialAst('')], context),
  RailroadRepetitionAst(:final element, :final min, :final max) => _railRepetition(element, min, max, context),
};

_RailBox _railLeaf(String label, _LayoutContext context, bool terminal) {
  final measured = context.measurer.measure(label, context.textStyle);
  final width = math.max(30.0, measured.width + 20);
  const height = 34.0;
  return _RailBox(width, height, [
    SceneRect(
      id: context.id('rail-node'),
      bounds: Bounds(left: 0, top: 0, width: width, height: height),
      radiusX: terminal ? 10 : 2,
      radiusY: terminal ? 10 : 2,
      fill: SolidFill(terminal ? context.options.theme.primary : context.options.theme.secondary),
      stroke: _stroke(context),
      role: SemanticRole.node,
      label: label,
    ),
    _text(context, label, width / 2, height / 2, anchor: TextAnchor.middle),
  ]);
}

_RailBox _railSequence(List<RailroadNodeAst> nodes, _LayoutContext context) {
  if (nodes.isEmpty) return const _RailBox(20, 20, []);
  final boxes = nodes.map((node) => _railNode(node, context)).toList();
  const gap = 20.0;
  final height = boxes.map((box) => box.height).reduce(math.max);
  final elements = <SceneElement>[];
  var x = 0.0;
  for (var i = 0; i < boxes.length; i++) {
    final box = boxes[i];
    final y = (height - box.height) / 2;
    elements.add(SceneGroup(id: context.id('rail-item'), transforms: [Translate(x, y)], children: box.elements));
    x += box.width;
    if (i != boxes.length - 1) {
      elements.add(
        SceneLine(
          id: context.id('rail-line'),
          start: Point(x, height / 2),
          end: Point(x + gap, height / 2),
          stroke: _stroke(context),
          role: SemanticRole.edge,
        ),
      );
      x += gap;
    }
  }
  return _RailBox(x, height, elements);
}

_RailBox _railChoice(List<RailroadNodeAst> nodes, _LayoutContext context) {
  final boxes = nodes.map((node) => _railNode(node, context)).toList();
  if (boxes.isEmpty) return const _RailBox(20, 20, []);
  const gap = 18.0;
  const side = 24.0;
  final width = boxes.map((box) => box.width).fold(0.0, math.max) + side * 2;
  final height = boxes.fold(0.0, (sum, box) => sum + box.height) + gap * (boxes.length - 1);
  final elements = <SceneElement>[];
  var y = 0.0;
  for (final box in boxes) {
    final centerY = y + box.height / 2;
    elements.add(SceneGroup(id: context.id('rail-choice'), transforms: [Translate(side, y)], children: box.elements));
    elements.add(
      ScenePolyline(
        id: context.id('rail-branch'),
        points: [Point(0, height / 2), Point(side / 2, centerY), Point(side, centerY)],
        fill: const NoFill(),
        stroke: _stroke(context),
        role: SemanticRole.edge,
      ),
    );
    elements.add(
      ScenePolyline(
        id: context.id('rail-branch'),
        points: [Point(side + box.width, centerY), Point(width - side / 2, centerY), Point(width, height / 2)],
        fill: const NoFill(),
        stroke: _stroke(context),
        role: SemanticRole.edge,
      ),
    );
    y += box.height + gap;
  }
  return _RailBox(width, height, elements);
}

_RailBox _railRepetition(RailroadNodeAst node, int min, num max, _LayoutContext context) {
  final box = _railNode(node, context);
  final label = max == double.infinity ? '$min…∞' : '$min…$max';
  final elements = <SceneElement>[
    SceneGroup(id: context.id('rail-repeat-item'), transforms: const [Translate(20, 0)], children: box.elements),
    ScenePath(
      id: context.id('rail-repeat'),
      commands: [
        MoveTo(Point(20 + box.width, box.height / 2)),
        CubicTo(Point(20 + box.width + 15, box.height + 20), const Point(5, 54), Point(20, box.height / 2)),
      ],
      fill: const NoFill(),
      stroke: _stroke(context),
      role: SemanticRole.edge,
    ),
    _text(context, label, 20 + box.width / 2, box.height + 17, anchor: TextAnchor.middle),
  ];
  return _RailBox(box.width + 40, box.height + 32, elements);
}

_LayoutResult _layoutRailroad(RailroadAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final elements = <SceneElement>[];
  var y = 0.0;
  var width = 200.0;
  for (final rule in ast.rules) {
    final nameWidth = context.measurer.measure(rule.name, context.textStyle).width + 24;
    final box = _railNode(rule.definition, context);
    final rowHeight = math.max(36.0, box.height);
    elements.add(_text(context, rule.name, 0, y + rowHeight / 2, role: SemanticRole.title));
    elements.add(
      SceneLine(
        id: context.id('rail-start'),
        start: Point(nameWidth, y + rowHeight / 2),
        end: Point(nameWidth + config.horizontalGap, y + rowHeight / 2),
        stroke: _stroke(context),
        role: SemanticRole.edge,
      ),
    );
    elements.add(
      SceneGroup(
        id: context.id('rail-definition'),
        transforms: [Translate(nameWidth + config.horizontalGap, y + (rowHeight - box.height) / 2)],
        children: box.elements,
      ),
    );
    width = math.max(width, nameWidth + config.horizontalGap + box.width);
    y += rowHeight + config.verticalGap;
  }
  return _LayoutResult(width, math.max(50, y - config.verticalGap), elements);
}

_LayoutResult _layoutCynefin(CynefinAst ast, _LayoutContext context) {
  const width = 600.0;
  const height = 440.0;
  final positions = <CynefinDomain, Bounds>{
    CynefinDomain.complex: const Bounds(left: 0, top: 0, width: 300, height: 200),
    CynefinDomain.complicated: const Bounds(left: 300, top: 0, width: 300, height: 200),
    CynefinDomain.chaotic: const Bounds(left: 0, top: 200, width: 300, height: 200),
    CynefinDomain.clear: const Bounds(left: 300, top: 200, width: 300, height: 200),
    CynefinDomain.confusion: const Bounds(left: 240, top: 160, width: 120, height: 120),
  };
  final byDomain = {for (final domain in ast.domains) domain.domain: domain};
  final elements = <SceneElement>[];
  for (final domain in CynefinDomain.values) {
    final bounds = positions[domain]!;
    elements.add(
      SceneRect(
        id: context.id('cynefin-domain'),
        bounds: bounds,
        fill: SolidFill(_palette[domain.index % _palette.length]),
        stroke: const SceneStroke(color: Color(255, 255, 255), width: 3),
        role: SemanticRole.group,
        label: domain.name,
      ),
    );
    elements.add(
      _text(
        context,
        domain.name,
        bounds.center.x,
        bounds.top + 24,
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
      ),
    );
    final items = byDomain[domain]?.items ?? const [];
    for (var i = 0; i < items.length; i++) {
      elements.add(_text(context, '• ${items[i].label}', bounds.left + 20, bounds.top + 55 + i * 24));
    }
  }
  return _LayoutResult(width, height, elements);
}

_LayoutResult _layoutEventModeling(EventModelingAst ast, _LayoutContext context) {
  const columnWidth = 190.0;
  const rowHeight = 84.0;
  final entities = ast.modelEntities.isEmpty ? const [EventModelEntityAst(name: 'Timeline')] : ast.modelEntities;
  final elements = <SceneElement>[];
  for (var column = 0; column < entities.length; column++) {
    final x = column * columnWidth;
    elements.add(
      _text(
        context,
        entities[column].name,
        x + columnWidth / 2,
        18,
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
      ),
    );
  }
  for (var i = 0; i < ast.frames.length; i++) {
    final frame = ast.frames[i];
    final column = math.max(0, entities.indexWhere((entity) => entity.name == frame.entityIdentifier));
    final bounds = Bounds(
      left: column * columnWidth + 12,
      top: 42 + i * rowHeight,
      width: columnWidth - 24,
      height: 56,
    );
    elements.add(
      SceneRect(
        id: context.id('event-frame'),
        bounds: bounds,
        radiusX: 6,
        radiusY: 6,
        fill: SolidFill(_palette[frame.entityType.index % _palette.length]),
        stroke: _stroke(context),
        role: SemanticRole.node,
        label: frame.name,
      ),
    );
    elements.add(_text(context, frame.name, bounds.center.x, bounds.center.y, anchor: TextAnchor.middle));
    for (final source in frame.sourceFrames) {
      final sourceIndex = ast.frames.indexWhere((candidate) => candidate.name == source);
      if (sourceIndex >= 0) {
        final start = Point(column * columnWidth + columnWidth / 2, 42 + sourceIndex * rowHeight + 56);
        elements.add(
          SceneLine(
            id: context.id('event-edge'),
            start: start,
            end: Point(bounds.center.x, bounds.top),
            stroke: _stroke(context),
            role: SemanticRole.edge,
          ),
        );
      }
    }
  }
  return _LayoutResult(
    math.max(columnWidth, entities.length * columnWidth),
    math.max(90, ast.frames.length * rowHeight + 42),
    elements,
  );
}

_LayoutResult _layoutGitGraph(GitGraphAst ast, _LayoutContext context) {
  final branches = <String>['main'];
  final branchHeads = <String, Point>{};
  var current = 'main';
  var commitIndex = 0;
  final elements = <SceneElement>[];
  for (final statement in ast.statements) {
    switch (statement) {
      case GitGraphBranchAst(:final name):
        if (!branches.contains(name)) branches.add(name);
      case GitGraphCheckoutAst(:final branch):
        current = branch;
        if (!branches.contains(branch)) branches.add(branch);
      case GitGraphCommitAst(:final id, :final message, :final type):
        final lane = branches.indexOf(current);
        final point = Point(50 + commitIndex * 90, 50 + lane * 70);
        final previous = branchHeads[current];
        if (previous != null) {
          elements.add(
            SceneLine(
              id: context.id('git-edge'),
              start: previous,
              end: point,
              stroke: SceneStroke(color: _palette[lane % _palette.length], width: 3),
              role: SemanticRole.edge,
            ),
          );
        }
        elements.add(
          SceneCircle(
            id: context.id('git-commit'),
            center: point,
            radius: type == GitGraphCommitType.highlight ? 10 : 7,
            fill: SolidFill(_palette[lane % _palette.length]),
            stroke: _stroke(context),
            role: SemanticRole.node,
            label: message ?? id,
          ),
        );
        elements.add(
          _text(
            context,
            message ?? id ?? 'commit ${commitIndex + 1}',
            point.x,
            point.y - 18,
            anchor: TextAnchor.middle,
          ),
        );
        branchHeads[current] = point;
        commitIndex++;
      case GitGraphMergeAst(:final branch, :final id):
        final lane = branches.indexOf(current);
        final point = Point(50 + commitIndex * 90, 50 + lane * 70);
        final source = branchHeads[branch];
        final previous = branchHeads[current];
        if (source != null) {
          elements.add(
            SceneLine(
              id: context.id('git-merge'),
              start: source,
              end: point,
              stroke: _stroke(context),
              role: SemanticRole.edge,
            ),
          );
        }
        if (previous != null) {
          elements.add(
            SceneLine(
              id: context.id('git-edge'),
              start: previous,
              end: point,
              stroke: _stroke(context),
              role: SemanticRole.edge,
            ),
          );
        }
        elements.add(
          SceneCircle(
            id: context.id('git-commit'),
            center: point,
            radius: 8,
            fill: SolidFill(_palette[lane % _palette.length]),
            stroke: _stroke(context),
            role: SemanticRole.node,
            label: id,
          ),
        );
        branchHeads[current] = point;
        commitIndex++;
      case GitGraphCherryPickAst(:final id):
        final lane = branches.indexOf(current);
        final point = Point(50 + commitIndex * 90, 50 + lane * 70);
        elements.add(
          SceneCircle(
            id: context.id('git-cherry-pick'),
            center: point,
            radius: 7,
            fill: SolidFill(_palette[lane % _palette.length]),
            stroke: _stroke(context),
            role: SemanticRole.node,
            label: id,
          ),
        );
        branchHeads[current] = point;
        commitIndex++;
    }
  }
  for (var i = 0; i < branches.length; i++) {
    elements.add(_text(context, branches[i], 0, 50 + i * 70, anchor: TextAnchor.start, role: SemanticRole.legend));
  }
  return _LayoutResult(math.max(200, 100 + commitIndex * 90), math.max(100, 100 + branches.length * 70), elements);
}

final class _TreemapLayoutNode {
  _TreemapLayoutNode(this.label, {this.ownValue, this.cssClass});

  final String label;
  final double? ownValue;
  final String? cssClass;
  final children = <_TreemapLayoutNode>[];

  double get value => ownValue ?? children.fold(0, (sum, child) => sum + child.value);
}

_LayoutResult _layoutTreemap(TreemapAst ast, _LayoutContext context) {
  const width = 700.0;
  const height = 420.0;
  final root = _TreemapLayoutNode('root');
  final stack = <({int indent, _TreemapLayoutNode node})>[];
  for (final row in ast.rows.whereType<TreemapNodeRowAst>()) {
    final item = row.item;
    final node = switch (item) {
      TreemapSectionAst(:final name, :final classSelector) => _TreemapLayoutNode(name, cssClass: classSelector),
      TreemapLeafAst(:final name, :final value, :final classSelector) => _TreemapLayoutNode(
        name,
        ownValue: value.toDouble().abs(),
        cssClass: classSelector,
      ),
    };
    while (stack.isNotEmpty && stack.last.indent >= row.indent) {
      stack.removeLast();
    }
    (stack.isEmpty ? root : stack.last.node).children.add(node);
    if (item is TreemapSectionAst) {
      stack.add((indent: row.indent, node: node));
    }
  }

  final elements = <SceneElement>[];
  var colorIndex = 0;
  void layoutChildren(_TreemapLayoutNode parent, Bounds bounds, int depth) {
    if (parent.children.isEmpty) return;
    final total = parent.children.fold<double>(0, (sum, child) => sum + child.value);
    var offset = depth.isEven ? bounds.left : bounds.top;
    for (var i = 0; i < parent.children.length; i++) {
      final child = parent.children[i];
      final fraction = total == 0 ? 1 / parent.children.length : child.value / total;
      final childBounds = depth.isEven
          ? Bounds(
              left: offset,
              top: bounds.top,
              width: i == parent.children.length - 1 ? bounds.right - offset : bounds.width * fraction,
              height: bounds.height,
            )
          : Bounds(
              left: bounds.left,
              top: offset,
              width: bounds.width,
              height: i == parent.children.length - 1 ? bounds.bottom - offset : bounds.height * fraction,
            );
      final isLeaf = child.children.isEmpty;
      elements.add(
        SceneRect(
          id: context.id(isLeaf ? 'treemap-leaf' : 'treemap-section'),
          bounds: childBounds,
          fill: SolidFill(_palette[colorIndex++ % _palette.length]),
          stroke: const SceneStroke(color: Color(255, 255, 255), width: 2),
          role: isLeaf ? SemanticRole.node : SemanticRole.group,
          cssClasses: [if (child.cssClass != null) child.cssClass!],
          label: child.label,
        ),
      );
      if (isLeaf) {
        final value = child.ownValue;
        final displayValue = value?.toStringAsFixed(value % 1 == 0 ? 0 : 2);
        elements.add(
          _text(
            context,
            displayValue == null ? child.label : '${child.label}\n$displayValue',
            childBounds.center.x,
            childBounds.center.y,
            anchor: TextAnchor.middle,
          ),
        );
      } else {
        elements.add(_text(context, child.label, childBounds.left + 8, childBounds.top + 14));
        layoutChildren(
          child,
          Bounds(
            left: childBounds.left + 4,
            top: childBounds.top + 28,
            width: math.max(0, childBounds.width - 8),
            height: math.max(0, childBounds.height - 32),
          ),
          depth + 1,
        );
      }
      offset += depth.isEven ? childBounds.width : childBounds.height;
    }
  }

  layoutChildren(root, const Bounds(left: 0, top: 0, width: width, height: height), 0);
  if (root.children.isEmpty) {
    elements.add(_text(context, 'Treemap', width / 2, height / 2, anchor: TextAnchor.middle));
  }
  return _LayoutResult(width, height, elements);
}

_LayoutResult _layoutWardley(WardleyAst ast, _LayoutContext context) {
  final width = (ast.size?.width ?? 800).toDouble();
  final height = (ast.size?.height ?? 500).toDouble();
  final elements = <SceneElement>[];
  Point position(WardleyPositionAst value) =>
      Point(value.x.toDouble().clamp(0, 1) * width, (1 - value.y.toDouble().clamp(0, 1)) * height);
  final positions = <String, Point>{
    for (final anchor in ast.anchors) anchor.name: position(anchor.position),
    for (final component in ast.components) component.name: position(component.position),
  };
  for (final link in ast.links) {
    final from = positions[link.from];
    final to = positions[link.to];
    if (from == null || to == null) continue;
    elements.add(
      SceneLine(
        id: context.id('wardley-link'),
        start: from,
        end: to,
        stroke: _stroke(context, dashes: link.style == WardleyLinkStyle.dashed ? const [6, 4] : const []),
        role: SemanticRole.edge,
        label: link.label,
      ),
    );
    if (link.label != null) elements.add(_text(context, link.label!, (from.x + to.x) / 2, (from.y + to.y) / 2));
  }
  for (final entry in positions.entries) {
    elements.add(
      SceneCircle(
        id: context.id('wardley-component'),
        center: entry.value,
        radius: 7,
        fill: SolidFill(context.options.theme.primary),
        stroke: _stroke(context),
        role: SemanticRole.node,
        label: entry.key,
      ),
    );
    elements.add(_text(context, entry.key, entry.value.x + 10, entry.value.y - 12));
  }
  elements.add(
    SceneLine(
      id: context.id('wardley-axis'),
      start: Point(0, height),
      end: Point(width, height),
      stroke: _stroke(context),
      role: SemanticRole.edge,
    ),
  );
  elements.add(
    SceneLine(
      id: context.id('wardley-axis'),
      start: Point(0, 0),
      end: Point(0, height),
      stroke: _stroke(context),
      role: SemanticRole.edge,
    ),
  );
  for (final note in ast.notes) {
    final point = position(note.position);
    elements.add(_text(context, note.text, point.x, point.y, role: SemanticRole.annotation));
  }
  return _LayoutResult(width, height, elements);
}

_LayoutResult _layoutArchitecture(ArchitectureAst ast, _LayoutContext context) {
  const cellWidth = 190.0;
  const cellHeight = 120.0;
  final items = <({String id, String label, String? icon})>[
    for (final service in ast.services) (id: service.id, label: service.title ?? service.id, icon: service.icon),
    for (final junction in ast.junctions) (id: junction.id, label: junction.id, icon: null),
  ];
  final columns = math.max(1, math.sqrt(math.max(1, items.length)).ceil());
  final positions = <String, Point>{};
  final elements = <SceneElement>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    final x = (i % columns) * cellWidth + cellWidth / 2;
    final y = (i ~/ columns) * cellHeight + cellHeight / 2;
    positions[item.id] = Point(x, y);
  }
  for (final edge in ast.edges) {
    final left = positions[edge.leftId];
    final right = positions[edge.rightId];
    if (left != null && right != null) {
      elements.add(
        SceneLine(
          id: context.id('architecture-edge'),
          start: left,
          end: right,
          stroke: _stroke(context, width: 2),
          role: SemanticRole.edge,
          label: edge.title,
        ),
      );
      if (edge.title != null) elements.add(_text(context, edge.title!, (left.x + right.x) / 2, (left.y + right.y) / 2));
    }
  }
  for (final item in items) {
    final center = positions[item.id]!;
    final bounds = Bounds(left: center.x - 70, top: center.y - 35, width: 140, height: 70);
    elements.add(
      SceneRect(
        id: context.id('architecture-service'),
        bounds: bounds,
        radiusX: 8,
        radiusY: 8,
        fill: SolidFill(context.options.theme.primary),
        stroke: _stroke(context),
        role: SemanticRole.node,
        label: item.label,
      ),
    );
    if (item.icon != null) {
      final geometry = _iconGeometry(context, item.icon!);
      elements.add(
        SceneIcon(
          id: context.id('architecture-icon'),
          position: Point(bounds.left + 10, center.y - 9),
          geometry: geometry,
          stroke: _stroke(context),
          label: item.icon,
        ),
      );
    }
    elements.add(_text(context, item.label, center.x, center.y, anchor: TextAnchor.middle));
  }
  final rows = math.max(1, (items.length + columns - 1) ~/ columns);
  return _LayoutResult(columns * cellWidth, rows * cellHeight, elements);
}
