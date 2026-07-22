import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../parser/ast.dart';
import '../parser/diagram_type.dart';
import '../parser/parser.dart';
import 'geometry/cynefin.dart';
import 'geometry/event_modeling.dart';
import 'geometry/treemap.dart';
import 'geometry/wardley.dart';
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

  final rendererPositionsTitle =
      diagram is PacketAst ||
      diagram is PieAst ||
      diagram is RadarAst ||
      diagram is TreemapAst ||
      diagram is CynefinAst ||
      diagram is WardleyAst;
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
  final config = context.options.optionsFor(const InfoRenderOptions());
  final style = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: 32,
    color: context.options.theme.primaryText,
  );
  return _LayoutResult(400, 100, [
    _text(
      context,
      'v${config.version}',
      100,
      40,
      anchor: TextAnchor.middle,
      style: style,
      cssClasses: const ['version'],
    ),
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
  final config = context.options.optionsFor(const TreeViewRenderOptions());
  if (ast.nodes.isEmpty) return const _LayoutResult(1, 1, []);
  final elements = <SceneElement>[];
  final indentStack = <int>[];
  final depths = <int>[];
  for (final node in ast.nodes) {
    final indent = node.indent ?? 0;
    while (indentStack.isNotEmpty && indentStack.last >= indent) {
      indentStack.removeLast();
    }
    depths.add(indentStack.length);
    indentStack.add(indent);
  }

  final labelRightEdges = <double>[];
  final rowTops = <double>[];
  final rowHeights = <double>[];
  final labelGroups = <List<SceneElement>>[];
  var totalHeight = 0.0;
  var totalWidth = 0.0;
  for (var i = 0; i < ast.nodes.length; i++) {
    final node = ast.nodes[i];
    final x = depths[i] * (config.rowIndent + config.paddingX);
    final measured = context.measurer.measure(node.name, context.textStyle);
    final height = measured.height + config.paddingY * 2;
    final centerY = totalHeight + height / 2;
    final children = <SceneElement>[];
    final hasIcon = node.icon != null;
    final labelX = x + config.paddingX + (hasIcon ? 18 : 0);
    if (node.icon != null) {
      final geometry = _iconGeometry(context, node.icon!);
      children.add(
        SceneIcon(
          id: context.id('tree-icon'),
          position: Point(x + config.paddingX, totalHeight + config.paddingY),
          geometry: geometry,
          stroke: _stroke(context, width: config.lineThickness),
          label: node.icon,
          cssClasses: const ['treeView-node-icon'],
        ),
      );
    }
    children.add(
      _text(
        context,
        node.name,
        labelX,
        centerY,
        cssClasses: ['treeView-node-label', if (node.cssClass != null) ...node.cssClass!.split(RegExp(r'\s+'))],
      ),
    );
    labelGroups.add(children);
    labelRightEdges.add(labelX + measured.width);
    rowTops.add(totalHeight);
    rowHeights.add(height);
    totalWidth = math.max(totalWidth, x + measured.width + config.paddingX * 2 + (hasIcon ? 18 : 0));
    totalHeight += height;
  }

  final descriptionIndices = <int>[
    for (var i = 0; i < ast.nodes.length; i++)
      if (ast.nodes[i].description != null) i,
  ];
  if (descriptionIndices.isNotEmpty) {
    final descriptionX = labelRightEdges.reduce(math.max) + 16;
    for (final i in descriptionIndices) {
      final description = ast.nodes[i].description!;
      labelGroups[i].add(
        _text(
          context,
          description,
          descriptionX,
          rowTops[i] + rowHeights[i] / 2,
          cssClasses: const ['treeView-node-description'],
        ),
      );
      totalWidth = math.max(
        totalWidth,
        descriptionX + context.measurer.measure(description, context.textStyle).width + config.paddingX,
      );
    }
  }

  for (var i = 0; i < ast.nodes.length; i++) {
    final node = ast.nodes[i];
    final depth = depths[i];
    final x = depth * (config.rowIndent + config.paddingX);
    final centerY = rowTops[i] + rowHeights[i] / 2;
    if (node.cssClass?.split(RegExp(r'\s+')).contains('highlight') ?? false) {
      final width = totalWidth - x + 8;
      labelGroups[i].insert(
        0,
        SceneRect(
          id: context.id('tree-highlight'),
          bounds: Bounds(left: x, top: rowTops[i] + 1, width: width, height: rowHeights[i] - 2),
          radiusX: 3,
          radiusY: 3,
          fill: SolidFill(context.options.theme.tertiary),
          cssClasses: const ['treeView-highlight-bg'],
        ),
      );
      totalWidth = math.max(totalWidth, x + width + 2);
    }
    elements.add(
      SceneLine(
        id: context.id('tree-edge'),
        start: Point(x - config.rowIndent, centerY),
        end: Point(x, centerY),
        stroke: _stroke(context, width: config.lineThickness),
        role: SemanticRole.edge,
        cssClasses: const ['treeView-node-line'],
      ),
    );
    var lastDescendant = i;
    while (lastDescendant + 1 < depths.length && depths[lastDescendant + 1] > depth) {
      lastDescendant++;
    }
    if (lastDescendant > i) {
      elements.add(
        SceneLine(
          id: context.id('tree-edge'),
          start: Point(x + config.paddingX, rowTops[i] + rowHeights[i]),
          end: Point(
            x + config.paddingX,
            rowTops[lastDescendant] + rowHeights[lastDescendant] / 2 + config.lineThickness / 2,
          ),
          stroke: _stroke(context, width: config.lineThickness),
          role: SemanticRole.edge,
          cssClasses: const ['treeView-node-line'],
        ),
      );
    }
    elements.add(
      SceneGroup(
        id: context.id('tree-node'),
        children: labelGroups[i],
        role: SemanticRole.node,
        label: node.name,
        cssClasses: const ['treeView-node'],
      ),
    );
  }
  return _LayoutResult(totalWidth, totalHeight, [
    SceneGroup(id: context.id('tree-view'), children: elements, cssClasses: const ['tree-view']),
  ]);
}

IconGeometry _iconGeometry(_LayoutContext context, String reference) =>
    context.iconResolver.resolve(reference) ?? const PlaceholderIconResolver().resolve(reference);

final class _RailBox {
  const _RailBox(this.width, this.height, this.up, this.down, this.elements);
  final double width;
  final double height;
  final double up;
  final double down;
  final List<SceneElement> elements;
}

_RailBox _railNode(RailroadNodeAst node, _LayoutContext context) => switch (node) {
  RailroadTerminalAst(:final value) => _railLeaf(value, context, true),
  RailroadNonTerminalAst(:final name) => _railLeaf(name, context, false),
  RailroadSpecialAst(:final text) => _railLeaf('? $text ?', context, false, special: true),
  RailroadSequenceAst(:final elements) => _railSequence(elements, context),
  RailroadChoiceAst(:final alternatives) => _railChoice(alternatives, context),
  RailroadOptionalAst(:final element) => _railOptional(element, context),
  RailroadRepetitionAst(:final element, :final min, :final max) => _railRepetition(element, min, max, context),
};

SceneTextStyle _railTextStyle(_LayoutContext context) {
  final config = context.options.optionsFor(const RailroadRenderOptions());
  return SceneTextStyle(
    fontFamily: config.fontFamily,
    fontSize: config.fontSize,
    color: context.options.theme.primaryText,
  );
}

SceneStroke _railStroke(_LayoutContext context, {bool dashed = false}) {
  final config = context.options.optionsFor(const RailroadRenderOptions());
  return _stroke(context, width: config.strokeWidth, dashes: dashed ? const [5, 5] : const []);
}

ScenePath _railPath(_LayoutContext context, List<PathCommand> commands) => ScenePath(
  id: context.id('railroad-line'),
  commands: commands,
  fill: const NoFill(),
  stroke: _railStroke(context),
  role: SemanticRole.edge,
  cssClasses: const ['railroad-line'],
);

_RailBox _railLeaf(String label, _LayoutContext context, bool terminal, {bool special = false}) {
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final style = _railTextStyle(context);
  final measured = context.measurer.measure(label, style);
  final width = measured.width + config.padding * 2;
  final height = measured.height + config.padding * 2;
  final groupClass = terminal ? 'railroad-terminal' : (special ? 'railroad-special' : 'railroad-nonterminal');
  return _RailBox(width, height, height / 2, height / 2, [
    SceneGroup(
      id: context.id(groupClass),
      cssClasses: [groupClass],
      role: SemanticRole.node,
      label: label,
      children: [
        SceneRect(
          id: context.id('railroad-node'),
          bounds: Bounds(left: 0, top: 0, width: width, height: height),
          radiusX: terminal ? 10 : 0,
          radiusY: terminal ? 10 : 0,
          fill: SolidFill(terminal ? context.options.theme.primary : context.options.theme.secondary),
          stroke: _railStroke(context, dashed: special),
          role: SemanticRole.node,
          label: label,
        ),
        _text(context, label, width / 2, height / 2, anchor: TextAnchor.middle, style: style),
      ],
    ),
  ]);
}

_RailBox _railSequence(List<RailroadNodeAst> nodes, _LayoutContext context) {
  if (nodes.isEmpty) return const _RailBox(0, 0, 0, 0, []);
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final boxes = nodes.map((node) => _railNode(node, context)).toList();
  final up = boxes.map((box) => box.up).reduce(math.max);
  final down = boxes.map((box) => box.down).reduce(math.max);
  final height = up + down;
  final elements = <SceneElement>[];
  var x = 0.0;
  for (var i = 0; i < boxes.length; i++) {
    final box = boxes[i];
    final y = up - box.up;
    elements.add(SceneGroup(id: context.id('rail-item'), transforms: [Translate(x, y)], children: box.elements));
    x += box.width;
    if (i != boxes.length - 1) {
      elements.add(_railPath(context, [MoveTo(Point(x, up)), LineTo(Point(x + config.horizontalSeparation, up))]));
      x += config.horizontalSeparation;
    }
  }
  return _RailBox(x, height, up, down, [
    SceneGroup(id: context.id('railroad-sequence'), children: elements, cssClasses: const ['railroad-sequence']),
  ]);
}

_RailBox _railChoice(List<RailroadNodeAst> nodes, _LayoutContext context) {
  final boxes = nodes.map((node) => _railNode(node, context)).toList();
  if (boxes.isEmpty) return const _RailBox(0, 0, 0, 0, []);
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final radius = config.arcRadius;
  final maxWidth = boxes.map((box) => box.width).fold(0.0, math.max);
  final height = boxes.fold(0.0, (sum, box) => sum + box.height) + config.verticalSeparation * (boxes.length - 1);
  final width = maxWidth + radius * 4;
  final centerY = height / 2;
  final elements = <SceneElement>[];
  var y = 0.0;
  for (final box in boxes) {
    final itemCenterY = y + box.up;
    final itemX = radius * 2 + (maxWidth - box.width) / 2;
    final below = itemCenterY > centerY;
    elements.add(
      SceneGroup(id: context.id('rail-choice-item'), transforms: [Translate(itemX, y)], children: box.elements),
    );
    final left = <PathCommand>[MoveTo(Point(0, centerY))];
    if (itemCenterY == centerY) {
      left.add(LineTo(Point(itemX, itemCenterY)));
    } else {
      left
        ..add(
          ArcTo(
            radiusX: radius,
            radiusY: radius,
            clockwise: below,
            end: Point(radius, centerY + (below ? radius : -radius)),
          ),
        )
        ..add(LineTo(Point(radius, itemCenterY - (below ? radius : -radius))))
        ..add(ArcTo(radiusX: radius, radiusY: radius, clockwise: !below, end: Point(radius * 2, itemCenterY)))
        ..add(LineTo(Point(itemX, itemCenterY)));
    }
    elements.add(_railPath(context, left));
    final rightStart = itemX + box.width;
    final right = <PathCommand>[MoveTo(Point(rightStart, itemCenterY))];
    if (itemCenterY == centerY) {
      right.add(LineTo(Point(width, centerY)));
    } else {
      right
        ..add(LineTo(Point(width - radius * 2, itemCenterY)))
        ..add(
          ArcTo(
            radiusX: radius,
            radiusY: radius,
            clockwise: !below,
            end: Point(width - radius, itemCenterY + (below ? -radius : radius)),
          ),
        )
        ..add(LineTo(Point(width - radius, centerY + (below ? radius : -radius))))
        ..add(ArcTo(radiusX: radius, radiusY: radius, clockwise: below, end: Point(width, centerY)));
    }
    elements.add(_railPath(context, right));
    y += box.height + config.verticalSeparation;
  }
  return _RailBox(width, height, centerY, height - centerY, [
    SceneGroup(id: context.id('railroad-choice'), children: elements, cssClasses: const ['railroad-choice']),
  ]);
}

_RailBox _railOptional(RailroadNodeAst node, _LayoutContext context) {
  final box = _railNode(node, context);
  final radius = context.options.optionsFor(const RailroadRenderOptions()).arcRadius;
  final width = box.width + radius * 4;
  final height = box.height + radius * 2;
  final itemY = radius * 2;
  final centerY = itemY + box.up;
  final elements = <SceneElement>[
    SceneGroup(
      id: context.id('rail-optional-item'),
      transforms: [Translate(radius * 2, itemY)],
      children: box.elements,
    ),
    _railPath(context, [MoveTo(Point(0, centerY)), LineTo(Point(radius * 2, centerY))]),
    _railPath(context, [MoveTo(Point(radius * 2 + box.width, centerY)), LineTo(Point(width, centerY))]),
    _railPath(context, [
      MoveTo(Point(0, centerY)),
      ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(radius, centerY - radius)),
      LineTo(Point(radius, radius)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2, 0)),
      LineTo(Point(width - radius * 2, 0)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(width - radius, radius)),
      LineTo(Point(width - radius, centerY - radius)),
      ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(width, centerY)),
    ]),
  ];
  return _RailBox(width, height, centerY, height - centerY, [
    SceneGroup(id: context.id('railroad-optional'), children: elements, cssClasses: const ['railroad-optional']),
  ]);
}

_RailBox _railRepetition(RailroadNodeAst node, int min, num max, _LayoutContext context) {
  final box = _railNode(node, context);
  final radius = context.options.optionsFor(const RailroadRenderOptions()).arcRadius;
  final hasBypass = min == 0;
  final itemY = hasBypass ? radius * 2 : 0.0;
  final width = box.width + radius * 4;
  final height = box.height + radius * 2 + (hasBypass ? radius * 2 : 0);
  final centerY = itemY + box.up;
  final loopY = itemY + box.height + radius;
  final elements = <SceneElement>[
    SceneGroup(id: context.id('rail-repeat-item'), transforms: [Translate(radius * 2, itemY)], children: box.elements),
    _railPath(context, [MoveTo(Point(0, centerY)), LineTo(Point(radius * 2, centerY))]),
    _railPath(context, [MoveTo(Point(radius * 2 + box.width, centerY)), LineTo(Point(width, centerY))]),
    _railPath(context, [
      MoveTo(Point(radius * 2 + box.width, centerY)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 3 + box.width, centerY + radius)),
      LineTo(Point(radius * 3 + box.width, loopY)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2 + box.width, loopY + radius)),
      LineTo(Point(radius * 2, loopY + radius)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius, loopY)),
      LineTo(Point(radius, centerY + radius)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2, centerY)),
    ]),
    if (hasBypass)
      _railPath(context, [
        MoveTo(Point(0, centerY)),
        ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(radius, centerY - radius)),
        LineTo(Point(radius, radius)),
        ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2, 0)),
        LineTo(Point(width - radius * 2, 0)),
        ArcTo(radiusX: radius, radiusY: radius, end: Point(width - radius, radius)),
        LineTo(Point(width - radius, centerY - radius)),
        ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(width, centerY)),
      ]),
  ];
  return _RailBox(width, height, centerY, height - centerY, [
    SceneGroup(id: context.id('railroad-repetition'), children: elements, cssClasses: const ['railroad-repetition']),
  ]);
}

_LayoutResult _layoutRailroad(RailroadAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const RailroadRenderOptions());
  if (ast.rules.isEmpty) return const _LayoutResult(200, 100, []);
  final style = _railTextStyle(context);
  final elements = <SceneElement>[];
  var y = config.padding;
  var width = 0.0;
  for (final rule in ast.rules) {
    final ruleName = '${rule.name} =';
    final nameWidth = context.measurer.measure(ruleName, style).width + 20;
    final definitionX = nameWidth + 20;
    final box = _railNode(rule.definition, context);
    final baselineY = math.max(20.0, box.up);
    final definitionY = baselineY - box.up;
    final endX = definitionX + box.width + 10;
    final ruleElements = <SceneElement>[
      SceneGroup(
        id: context.id('rail-definition'),
        transforms: [Translate(definitionX, definitionY)],
        children: box.elements,
      ),
      _text(
        context,
        ruleName,
        0,
        baselineY,
        role: SemanticRole.title,
        style: style,
        cssClasses: const ['railroad-rule-name'],
      ),
      if (config.showMarkers) ...[
        SceneCircle(
          id: context.id('railroad-start'),
          center: Point(nameWidth, baselineY),
          radius: config.markerRadius,
          fill: SolidFill(context.options.theme.line),
          cssClasses: const ['railroad-start'],
        ),
        SceneCircle(
          id: context.id('railroad-end'),
          center: Point(endX, baselineY),
          radius: config.markerRadius,
          fill: SolidFill(context.options.theme.line),
          cssClasses: const ['railroad-end'],
        ),
      ],
      _railPath(context, [
        MoveTo(Point(nameWidth + config.markerRadius, baselineY)),
        LineTo(Point(definitionX, baselineY)),
      ]),
      _railPath(context, [
        MoveTo(Point(definitionX + box.width, baselineY)),
        LineTo(Point(endX - config.markerRadius, baselineY)),
      ]),
    ];
    elements.add(
      SceneGroup(
        id: context.id('railroad-rule'),
        transforms: [Translate(0, y)],
        children: ruleElements,
        cssClasses: const ['railroad-rule'],
      ),
    );
    final rowHeight = math.max(40.0, definitionY + box.height + config.padding * 2);
    width = math.max(width, endX + config.markerRadius);
    y += rowHeight + config.verticalSeparation;
  }
  return _LayoutResult(width + config.padding * 2, y + config.padding, elements);
}

_LayoutResult _layoutCynefin(CynefinAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const CynefinRenderOptions());
  final width = config.width;
  final height = config.height;
  final padding = config.padding;
  final totalWidth = width + padding * 2;
  final totalHeight = height + padding * 2;
  final halfWidth = width / 2;
  final halfHeight = height / 2;
  final positions = <CynefinDomain, Bounds>{
    CynefinDomain.complex: Bounds(left: padding, top: padding, width: halfWidth, height: halfHeight),
    CynefinDomain.complicated: Bounds(left: padding + halfWidth, top: padding, width: halfWidth, height: halfHeight),
    CynefinDomain.chaotic: Bounds(left: padding, top: padding + halfHeight, width: halfWidth, height: halfHeight),
    CynefinDomain.clear: Bounds(
      left: padding + halfWidth,
      top: padding + halfHeight,
      width: halfWidth,
      height: halfHeight,
    ),
    CynefinDomain.confusion: Bounds(
      left: padding + halfWidth * .7,
      top: padding + halfHeight * .7,
      width: halfWidth * .6,
      height: halfHeight * .6,
    ),
  };
  final colors = <CynefinDomain, Color>{
    CynefinDomain.complex: config.complexColor,
    CynefinDomain.complicated: config.complicatedColor,
    CynefinDomain.chaotic: config.chaoticColor,
    CynefinDomain.clear: config.clearColor,
    CynefinDomain.confusion: config.confusionColor,
  };
  final byDomain = {for (final domain in ast.domains) domain.domain: domain};
  final elements = <SceneElement>[];
  const quadrants = [CynefinDomain.complex, CynefinDomain.complicated, CynefinDomain.chaotic, CynefinDomain.clear];
  for (final domain in quadrants) {
    final bounds = positions[domain]!;
    elements.add(
      SceneRect(
        id: context.id('cynefin-domain'),
        bounds: bounds,
        fill: SolidFill(colors[domain]!),
        role: SemanticRole.group,
        cssClasses: const ['cynefinDomain'],
        label: domain.name,
      ),
    );
  }

  final seed = config.seed == 0 ? cynefinHashString('cynefin') : config.seed;
  elements.addAll([
    ScenePath(
      id: context.id('cynefin-boundary'),
      commands: generateCynefinFoldPath(
        width,
        height,
        seed,
        amplitude: config.boundaryAmplitude,
        offsetX: padding,
        offsetY: padding,
      ),
      fill: const NoFill(),
      stroke: _stroke(context, width: 2),
      role: SemanticRole.edge,
      cssClasses: const ['cynefinBoundary'],
    ),
    ScenePath(
      id: context.id('cynefin-boundary'),
      commands: generateCynefinHorizontalPath(
        width,
        height,
        seed + 100,
        amplitude: config.boundaryAmplitude,
        offsetX: padding,
        offsetY: padding,
      ),
      fill: const NoFill(),
      stroke: _stroke(context, width: 2),
      role: SemanticRole.edge,
      cssClasses: const ['cynefinBoundary'],
    ),
    ScenePath(
      id: context.id('cynefin-cliff'),
      commands: generateCynefinCliffPath(width, height, offsetX: padding, offsetY: padding),
      fill: const NoFill(),
      stroke: SceneStroke(color: config.cliffColor, width: 4, cap: StrokeCap.round, join: StrokeJoin.round),
      role: SemanticRole.edge,
      cssClasses: const ['cynefinCliff'],
    ),
    ScenePath(
      id: context.id('cynefin-confusion'),
      commands: generateCynefinConfusionPath(padding + width / 2, padding + height / 2, width * .15, height * .15),
      fill: SolidFill(config.confusionColor),
      stroke: _stroke(context, width: 2),
      role: SemanticRole.group,
      cssClasses: const ['cynefinConfusion'],
      label: 'Confusion',
    ),
  ]);

  const descriptions = <CynefinDomain, (String, String)>{
    CynefinDomain.complex: ('Probe → Sense → Respond', 'Emergent Practices'),
    CynefinDomain.complicated: ('Sense → Analyse → Respond', 'Good Practices'),
    CynefinDomain.clear: ('Sense → Categorise → Respond', 'Best Practices'),
    CynefinDomain.chaotic: ('Act → Sense → Respond', 'Novel Practices'),
    CynefinDomain.confusion: ('', 'Disorder'),
  };
  for (final domain in CynefinDomain.values) {
    final bounds = positions[domain]!;
    final center = bounds.center;
    final isConfusion = domain == CynefinDomain.confusion;
    elements.add(
      _text(
        context,
        '${domain.name[0].toUpperCase()}${domain.name.substring(1)}',
        center.x,
        center.y - (config.showDomainDescriptions ? (isConfusion ? 10 : 30) : 0),
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: 16,
          weight: FontWeight.bold,
          color: context.options.theme.primaryText,
        ),
        cssClasses: const ['cynefinDomainLabel'],
      ),
    );
    if (config.showDomainDescriptions) {
      final (model, practice) = descriptions[domain]!;
      if (model.isNotEmpty) {
        elements.add(
          _text(
            context,
            model,
            center.x,
            center.y - 10,
            anchor: TextAnchor.middle,
            style: SceneTextStyle(
              fontFamily: context.options.theme.fontFamily,
              fontSize: 12,
              color: context.options.theme.primaryText,
            ),
            cssClasses: const ['cynefinSubtitle'],
          ),
        );
      }
      elements.add(
        _text(
          context,
          practice,
          center.x,
          center.y + (isConfusion ? 8 : 5),
          anchor: TextAnchor.middle,
          style: SceneTextStyle(
            fontFamily: context.options.theme.fontFamily,
            fontSize: 12,
            color: context.options.theme.primaryText,
          ),
          cssClasses: const ['cynefinSubtitle'],
        ),
      );
    }
  }

  final itemStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: 12,
    color: context.options.theme.primaryText,
  );
  for (final domain in CynefinDomain.values) {
    final items = byDomain[domain]?.items ?? const [];
    if (items.isEmpty) continue;
    final center = positions[domain]!.center;
    final isConfusion = domain == CynefinDomain.confusion;
    final renderedItems = isConfusion && items.length > 3 ? items.take(3).toList() : items;
    final startY =
        center.y +
        (isConfusion ? (config.showDomainDescriptions ? 22 : 14) : (config.showDomainDescriptions ? 25 : 15));
    for (var i = 0; i < renderedItems.length; i++) {
      _addCynefinBadge(
        context,
        elements,
        renderedItems[i].label,
        center.x,
        startY + i * 30,
        colors[domain]!,
        itemStyle,
        overflow: false,
      );
    }
    if (isConfusion && items.length > 3) {
      _addCynefinBadge(
        context,
        elements,
        '+${items.length - 3} more',
        center.x,
        startY + renderedItems.length * 30,
        colors[domain]!,
        itemStyle,
        overflow: true,
      );
    }
  }

  for (final transition in ast.transitions) {
    if (transition.from == transition.to) continue;
    final start = positions[transition.from]!.center;
    final end = positions[transition.to]!.center;
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) continue;
    final middle = Point((start.x + end.x) / 2, (start.y + end.y) / 2);
    final control = Point(middle.x - dy / length * length * .15, middle.y + dx / length * length * .15);
    elements.add(
      ScenePath(
        id: context.id('cynefin-arrow'),
        commands: [MoveTo(start), QuadraticTo(control, end)],
        fill: const NoFill(),
        stroke: _stroke(context, width: 2),
        role: SemanticRole.edge,
        cssClasses: const ['cynefinArrowLine'],
      ),
    );
    final tangentX = end.x - control.x;
    final tangentY = end.y - control.y;
    final tangentLength = math.sqrt(tangentX * tangentX + tangentY * tangentY);
    final unitX = tangentX / tangentLength;
    final unitY = tangentY / tangentLength;
    final base = Point(end.x - unitX * 9, end.y - unitY * 9);
    elements.add(
      ScenePolygon(
        id: context.id('cynefin-arrow-head'),
        points: [end, Point(base.x - unitY * 4, base.y + unitX * 4), Point(base.x + unitY * 4, base.y - unitX * 4)],
        fill: SolidFill(context.options.theme.line),
        role: SemanticRole.edge,
        cssClasses: const ['cynefinArrowHead'],
      ),
    );
    if (transition.label case final label?) {
      elements.add(
        _text(
          context,
          label,
          control.x,
          control.y - 6,
          anchor: TextAnchor.middle,
          style: itemStyle,
          cssClasses: const ['cynefinArrowLabel'],
        ),
      );
    }
  }

  if (ast.title case final title?) {
    elements.add(
      _text(
        context,
        title,
        totalWidth / 2,
        padding / 2,
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
        cssClasses: const ['cynefinTitle'],
      ),
    );
  }
  return _LayoutResult(totalWidth, totalHeight, elements);
}

void _addCynefinBadge(
  _LayoutContext context,
  List<SceneElement> elements,
  String label,
  double centerX,
  double top,
  Color fill,
  SceneTextStyle style, {
  required bool overflow,
}) {
  const height = 26.0;
  final width = context.measurer.measure(label, style).width + 20;
  final bounds = Bounds(left: centerX - width / 2, top: top, width: width, height: height);
  elements.add(
    SceneRect(
      id: context.id(overflow ? 'cynefin-item-overflow' : 'cynefin-item'),
      bounds: bounds,
      radiusX: 4,
      radiusY: 4,
      fill: SolidFill(
        overflow ? Color(fill.red, fill.green, fill.blue, 153) : Color(fill.red, fill.green, fill.blue, 242),
      ),
      role: SemanticRole.node,
      cssClasses: [overflow ? 'cynefinItemOverflow' : 'cynefinItem'],
      label: label,
    ),
  );
  elements.add(
    _text(
      context,
      label,
      centerX,
      top + height / 2,
      anchor: TextAnchor.middle,
      style: style,
      cssClasses: const ['cynefinItemText'],
    ),
  );
}

_LayoutResult _layoutEventModeling(EventModelingAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const EventModelingRenderOptions());
  final boxTextStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: context.options.theme.fontSize,
    weight: FontWeight.bold,
    color: context.options.theme.primaryText,
  );
  final layout = layoutEventModel(ast, config, context.measurer, boxTextStyle);
  final elements = <SceneElement>[];

  for (final lane in layout.lanes) {
    elements.add(
      SceneRect(
        id: context.id('event-swimlane'),
        bounds: Bounds(left: 0, top: lane.y, width: layout.maxRight + config.swimlanePadding, height: lane.height),
        radiusX: 3,
        radiusY: 3,
        fill: const SolidFill(Color(250, 250, 250)),
        stroke: const SceneStroke(color: Color(240, 240, 240)),
        role: SemanticRole.group,
        cssClasses: const ['em-swimlane-background'],
        label: lane.label,
      ),
    );
    elements.add(
      _text(context, lane.label, 30, lane.y + 30, style: boxTextStyle, cssClasses: const ['em-swimlane-label']),
    );
  }

  for (final box in layout.boxes) {
    final bounds = Bounds(
      left: box.bounds.left,
      top: box.lane.y + config.swimlanePadding,
      width: box.bounds.width,
      height: box.bounds.height,
    );
    elements.add(
      SceneRect(
        id: context.id('event-frame'),
        bounds: bounds,
        radiusX: 3,
        radiusY: 3,
        fill: SolidFill(box.fill),
        stroke: SceneStroke(color: box.stroke),
        role: SemanticRole.node,
        cssClasses: const ['em-box-rect'],
        label: box.text,
      ),
    );
    elements.add(
      _text(
        context,
        box.text,
        bounds.center.x,
        bounds.center.y,
        anchor: TextAnchor.middle,
        style: boxTextStyle,
        cssClasses: const ['em-box-label'],
      ),
    );
  }

  for (final relation in layout.relations) {
    final sourceTop = relation.source.lane.y + config.swimlanePadding;
    final targetTop = relation.target.lane.y + config.swimlanePadding;
    final upwards = sourceTop > targetTop;
    final start = Point(
      relation.source.bounds.left + relation.source.bounds.width * 2 / 3,
      upwards ? sourceTop : sourceTop + relation.source.bounds.height,
    );
    final end = Point(
      relation.target.bounds.left + relation.target.bounds.width / 3,
      upwards ? targetTop + relation.target.bounds.height : targetTop,
    );
    elements.add(
      ScenePath(
        id: context.id('event-edge'),
        commands: [MoveTo(start), LineTo(end)],
        fill: const NoFill(),
        stroke: SceneStroke(color: context.options.theme.line),
        role: SemanticRole.edge,
        cssClasses: const ['em-relation'],
      ),
    );
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length > 0) {
      final unitX = dx / length;
      final unitY = dy / length;
      final base = Point(end.x - unitX * 10, end.y - unitY * 10);
      elements.add(
        ScenePolygon(
          id: context.id('event-arrowhead'),
          points: [
            end,
            Point(base.x - unitY * 3.5, base.y + unitX * 3.5),
            Point(base.x + unitY * 3.5, base.y - unitX * 3.5),
          ],
          fill: SolidFill(context.options.theme.line),
          role: SemanticRole.edge,
          cssClasses: const ['em-arrowhead'],
        ),
      );
    }
  }

  return _LayoutResult(layout.maxRight + config.swimlanePadding, layout.height, elements);
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

final class _TreemapClassStyle {
  const _TreemapClassStyle({this.fill, this.stroke, this.text});

  final Color? fill;
  final Color? stroke;
  final Color? text;
}

_LayoutResult _layoutTreemap(TreemapAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const TreemapRenderOptions());
  final classStyles = <String, _TreemapClassStyle>{
    for (final definition in ast.rows.whereType<TreemapClassDefAst>())
      definition.name: _parseTreemapClassStyle(definition.style),
  };
  final artificialRoot = _TreemapLayoutNode('root');
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
    (stack.isEmpty ? artificialRoot : stack.last.node).children.add(node);
    if (item is TreemapSectionAst) {
      stack.add((indent: row.indent, node: node));
    }
  }

  void sortByValue(_TreemapLayoutNode node) {
    for (final child in node.children) {
      sortByValue(child);
    }
    node.children.sort((left, right) => right.value.compareTo(left.value));
  }

  final root = artificialRoot.children.length == 1 ? artificialRoot.children.single : artificialRoot;
  sortByValue(root);
  final titleHeight = ast.title == null ? 0.0 : 30.0;
  final width = config.width;
  final height = config.height;
  final elements = <SceneElement>[];
  if (ast.title case final title?) {
    elements.add(
      _text(
        context,
        title,
        width / 2,
        titleHeight / 2,
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
        cssClasses: const ['treemapTitle'],
      ),
    );
  }

  final container = <SceneElement>[];
  var nextColor = 0;
  final sectionColors = <_TreemapLayoutNode, Color>{root: _palette.first};

  void drawLeaf(_TreemapLayoutNode leaf, Bounds bounds, Color color, int index) {
    final customStyle = leaf.cssClass == null ? null : classStyles[leaf.cssClass];
    final fillColor = customStyle?.fill ?? color;
    final strokeColor = customStyle?.stroke ?? fillColor;
    final groupChildren = <SceneElement>[
      SceneRect(
        id: context.id('treemap-leaf'),
        bounds: bounds,
        fill: SolidFill(fillColor),
        stroke: SceneStroke(color: strokeColor, width: 3),
        role: SemanticRole.node,
        cssClasses: const ['treemapLeaf'],
        label: leaf.label,
      ),
    ];
    final complex = _countTreemapLeaves(root) > 20;
    final labelPadding = complex ? 2.0 : 4.0;
    final minimum = complex ? 4.0 : 8.0;
    final threshold = complex ? 8.0 : 10.0;
    final availableWidth = bounds.width - labelPadding * 2;
    final availableHeight = bounds.height - labelPadding * 2;
    var labelSize = complex ? 16.0 : 38.0;
    final labelColor = customStyle?.text ?? context.options.theme.primaryText;
    SceneTextStyle labelStyle() =>
        SceneTextStyle(fontFamily: context.options.theme.fontFamily, fontSize: labelSize, color: labelColor);
    while (labelSize > minimum && context.measurer.measure(leaf.label, labelStyle()).width > availableWidth) {
      labelSize--;
    }
    final spacing = complex ? 1.0 : 2.0;
    var valueSize = math.max(complex ? 4.0 : 6.0, math.min(complex ? 14.0 : 28.0, (labelSize * .6).roundToDouble()));
    while (labelSize > minimum && labelSize + spacing + valueSize > availableHeight) {
      labelSize--;
      valueSize = math.max(complex ? 4.0 : 6.0, math.min(complex ? 14.0 : 28.0, (labelSize * .6).roundToDouble()));
    }
    final labelFits =
        availableWidth >= threshold &&
        availableHeight >= threshold &&
        context.measurer.measure(leaf.label, labelStyle()).width <= availableWidth &&
        labelSize <= availableHeight;
    if (labelFits) {
      groupChildren.add(
        _text(
          context,
          leaf.label,
          bounds.center.x,
          bounds.center.y,
          anchor: TextAnchor.middle,
          style: labelStyle(),
          cssClasses: const ['treemapLabel'],
        ),
      );
      if (config.showValues && leaf.ownValue != null) {
        final value = _formatTreemapValue(leaf.ownValue!, config.valueFormat);
        final valueStyle = SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: valueSize,
          color: labelColor,
        );
        final valueY = bounds.center.y + labelSize / 2 + spacing;
        if (context.measurer.measure(value, valueStyle).width <= availableWidth &&
            valueY + valueSize <= bounds.bottom - 4) {
          groupChildren.add(
            _text(
              context,
              value,
              bounds.center.x,
              valueY,
              anchor: TextAnchor.middle,
              baseline: TextBaseline.hanging,
              style: valueStyle,
              cssClasses: const ['treemapValue'],
            ),
          );
        }
      }
    }
    container.add(
      SceneGroup(
        id: context.id('treemap-leaf-group'),
        children: groupChildren,
        role: SemanticRole.node,
        label: leaf.label,
        cssClasses: ['treemapNode', 'treemapLeafGroup', 'leaf$index', if (leaf.cssClass != null) leaf.cssClass!],
      ),
    );
  }

  void layoutChildren(_TreemapLayoutNode parent, Bounds parentBounds, int depth) {
    if (parent.children.isEmpty) return;
    final inner = Bounds(
      left: parentBounds.left + config.sectionPadding,
      top: parentBounds.top + config.sectionHeaderHeight + config.sectionPadding,
      width: math.max(0, parentBounds.width - config.sectionPadding * 2),
      height: math.max(0, parentBounds.height - config.sectionHeaderHeight - config.sectionPadding * 2),
    );
    final tiles = squarifyTreemap(
      [for (final child in parent.children) TreemapItem(child.value, child)],
      inner,
      innerPadding: config.innerPadding,
    );
    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      final child = tile.data;
      final bounds = tile.bounds;
      if (child.children.isEmpty) {
        drawLeaf(child, bounds, sectionColors[parent] ?? _palette.first, i);
        continue;
      }
      final color = _palette[(++nextColor) % _palette.length];
      final customStyle = child.cssClass == null ? null : classStyles[child.cssClass];
      final fillColor = customStyle?.fill ?? color;
      final strokeColor = customStyle?.stroke ?? fillColor;
      final textColor = customStyle?.text ?? context.options.theme.primaryText;
      sectionColors[child] = fillColor;
      container.add(
        SceneRect(
          id: context.id('treemap-section'),
          bounds: bounds,
          fill: SolidFill(fillColor),
          stroke: SceneStroke(color: strokeColor, width: 2),
          role: SemanticRole.group,
          cssClasses: ['treemapSection', 'section$nextColor', if (child.cssClass != null) child.cssClass!],
          label: child.label,
        ),
      );
      container.add(
        _text(
          context,
          child.label,
          bounds.left + 6,
          bounds.top + config.sectionHeaderHeight / 2,
          style: SceneTextStyle(
            fontFamily: context.options.theme.fontFamily,
            fontSize: 12,
            weight: FontWeight.bold,
            color: textColor,
          ),
          cssClasses: const ['treemapSectionLabel'],
        ),
      );
      if (config.showValues) {
        container.add(
          _text(
            context,
            _formatTreemapValue(child.value, config.valueFormat),
            bounds.right - 10,
            bounds.top + config.sectionHeaderHeight / 2,
            anchor: TextAnchor.end,
            style: SceneTextStyle(
              fontFamily: context.options.theme.fontFamily,
              fontSize: 10,
              style: FontStyle.italic,
              color: textColor,
            ),
            cssClasses: const ['treemapSectionValue'],
          ),
        );
      }
      layoutChildren(child, bounds, depth + 1);
    }
  }

  if (root.children.isEmpty && root.ownValue != null) {
    drawLeaf(root, Bounds(left: 0, top: titleHeight, width: width, height: height), _palette.first, 0);
  } else {
    layoutChildren(root, Bounds(left: 0, top: titleHeight, width: width, height: height), 0);
  }
  elements.add(
    SceneGroup(id: context.id('treemap-container'), children: container, cssClasses: const ['treemapContainer']),
  );
  return _LayoutResult(width, height + titleHeight, elements);
}

int _countTreemapLeaves(_TreemapLayoutNode node) =>
    node.children.isEmpty ? 1 : node.children.fold(0, (sum, child) => sum + _countTreemapLeaves(child));

String _formatTreemapValue(double value, TreemapValueFormat format) {
  final decimals = value % 1 == 0 ? 0 : 2;
  final plain = value.toStringAsFixed(decimals);
  if (format == TreemapValueFormat.plain) return plain;
  final parts = plain.split('.');
  final grouped = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final result = parts.length == 1 ? grouped : '$grouped.${parts.last}';
  return format == TreemapValueFormat.currencyGrouped ? '\$$result' : result;
}

_TreemapClassStyle _parseTreemapClassStyle(String? source) {
  Color? fill;
  Color? stroke;
  Color? text;
  for (final declaration in (source ?? '').split(RegExp(r'[,;]'))) {
    final separator = declaration.indexOf(':');
    if (separator < 0) continue;
    final property = declaration.substring(0, separator).trim().toLowerCase();
    final value = declaration.substring(separator + 1).trim();
    final color = _parseCssColor(value);
    if (color == null) continue;
    switch (property) {
      case 'fill':
        fill = color;
      case 'stroke':
        stroke = color;
      case 'color':
        text = color;
    }
  }
  return _TreemapClassStyle(fill: fill, stroke: stroke, text: text);
}

Color? _parseCssColor(String value) {
  if (RegExp(r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(value)) {
    return Color.fromHex(value);
  }
  return switch (value.toLowerCase()) {
    'black' => const Color(0, 0, 0),
    'white' => const Color(255, 255, 255),
    'red' => const Color(255, 0, 0),
    'green' => const Color(0, 128, 0),
    'blue' => const Color(0, 0, 255),
    'yellow' => const Color(255, 255, 0),
    _ => null,
  };
}

_LayoutResult _layoutWardley(WardleyAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const WardleyRenderOptions());
  final width = ast.size?.width.toDouble() ?? config.width;
  final height = ast.size?.height.toDouble() ?? config.height;
  final chartWidth = width - config.padding * 2;
  final chartHeight = height - config.padding * 2;
  final model = buildWardleyModel(ast);
  final elements = <SceneElement>[];
  final axisStroke = SceneStroke(color: config.axisColor);
  final componentStroke = SceneStroke(color: config.componentStroke);
  final axisStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: config.axisFontSize,
    color: config.axisTextColor,
  );
  final labelStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: config.labelFontSize,
    color: config.componentLabelColor,
  );
  Point project(double x, double y) => Point(
    config.padding + x.clamp(0, 100) / 100 * chartWidth,
    height - config.padding - y.clamp(0, 100) / 100 * chartHeight,
  );
  Point positioned(WardleyPositionAst value) => project(value.x.toDouble(), value.y.toDouble());
  final positions = <String, Point>{for (final node in model.nodes) node.id: project(node.x, node.y)};

  elements.add(
    SceneRect(
      id: context.id('wardley-background'),
      bounds: Bounds(left: 0, top: 0, width: width, height: height),
      fill: SolidFill(config.backgroundColor),
      role: SemanticRole.group,
      cssClasses: const ['wardley-background'],
    ),
  );
  if (ast.title case final title?) {
    elements.add(
      _text(
        context,
        title,
        width / 2,
        config.padding / 2,
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: config.axisFontSize * 1.05,
          weight: FontWeight.bold,
          color: config.axisTextColor,
        ),
        cssClasses: const ['wardley-title'],
      ),
    );
  }

  elements.addAll([
    SceneLine(
      id: context.id('wardley-axis'),
      start: Point(config.padding, height - config.padding),
      end: Point(width - config.padding, height - config.padding),
      stroke: axisStroke,
      role: SemanticRole.edge,
      cssClasses: const ['wardley-axis'],
    ),
    SceneLine(
      id: context.id('wardley-axis'),
      start: Point(config.padding, config.padding),
      end: Point(config.padding, height - config.padding),
      stroke: axisStroke,
      role: SemanticRole.edge,
      cssClasses: const ['wardley-axis'],
    ),
    _text(
      context,
      'Evolution',
      config.padding + chartWidth / 2,
      height - config.padding / 4,
      anchor: TextAnchor.middle,
      style: SceneTextStyle(
        fontFamily: axisStyle.fontFamily,
        fontSize: axisStyle.fontSize,
        weight: FontWeight.bold,
        color: axisStyle.color,
      ),
      cssClasses: const ['wardley-axis-label', 'wardley-axis-label-x'],
    ),
  ]);
  final yLabelCenter = Point(config.padding / 3, config.padding + chartHeight / 2);
  elements.add(
    SceneGroup(
      id: context.id('wardley-y-label'),
      transforms: [Rotate(-90, center: yLabelCenter)],
      cssClasses: const ['wardley-axis-label-y-group'],
      children: [
        _text(
          context,
          'Visibility',
          yLabelCenter.x,
          yLabelCenter.y,
          anchor: TextAnchor.middle,
          style: SceneTextStyle(
            fontFamily: axisStyle.fontFamily,
            fontSize: axisStyle.fontSize,
            weight: FontWeight.bold,
            color: axisStyle.color,
          ),
          cssClasses: const ['wardley-axis-label', 'wardley-axis-label-y'],
        ),
      ],
    ),
  );

  final stages = ast.evolutionStages.isEmpty
      ? const [
          WardleyEvolutionStageAst(name: 'Genesis'),
          WardleyEvolutionStageAst(name: 'Custom Built'),
          WardleyEvolutionStageAst(name: 'Product'),
          WardleyEvolutionStageAst(name: 'Commodity'),
        ]
      : ast.evolutionStages;
  final hasCompleteBoundaries = stages.every((stage) => stage.boundary != null);
  var stageStart = 0.0;
  for (var i = 0; i < stages.length; i++) {
    final stage = stages[i];
    final stageEnd = hasCompleteBoundaries ? stage.boundary!.toDouble() : (i + 1) / stages.length;
    final startX = config.padding + stageStart * chartWidth;
    final endX = config.padding + stageEnd * chartWidth;
    if (i > 0) {
      elements.add(
        SceneLine(
          id: context.id('wardley-stage-boundary'),
          start: Point(startX, config.padding),
          end: Point(startX, height - config.padding),
          stroke: SceneStroke(color: config.axisColor, dashes: const [5, 5]),
          role: SemanticRole.edge,
          cssClasses: const ['wardley-stage-boundary'],
        ),
      );
    }
    elements.add(
      _text(
        context,
        stage.secondName == null ? stage.name : '${stage.name} / ${stage.secondName}',
        (startX + endX) / 2,
        height - config.padding / 1.5,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.alphabetic,
        style: SceneTextStyle(
          fontFamily: axisStyle.fontFamily,
          fontSize: config.axisFontSize - 2,
          color: config.axisTextColor,
        ),
        cssClasses: const ['wardley-stage-label'],
      ),
    );
    stageStart = stageEnd;
  }

  if (config.showGrid) {
    for (var i = 1; i < 4; i++) {
      final ratio = i / 4;
      elements.addAll([
        SceneLine(
          id: context.id('wardley-grid'),
          start: Point(config.padding + chartWidth * ratio, config.padding),
          end: Point(config.padding + chartWidth * ratio, height - config.padding),
          stroke: SceneStroke(color: config.gridColor, dashes: const [2, 6]),
          role: SemanticRole.edge,
          cssClasses: const ['wardley-grid-line'],
        ),
        SceneLine(
          id: context.id('wardley-grid'),
          start: Point(config.padding, height - config.padding - chartHeight * ratio),
          end: Point(width - config.padding, height - config.padding - chartHeight * ratio),
          stroke: SceneStroke(color: config.gridColor, dashes: const [2, 6]),
          role: SemanticRole.edge,
          cssClasses: const ['wardley-grid-line'],
        ),
      ]);
    }
  }

  final squareSize = config.nodeRadius * 1.6;
  for (final pipeline in model.pipelines) {
    final components =
        pipeline.componentIds
            .map((id) => model.nodes.firstWhereOrNull((node) => node.id == id))
            .whereType<WardleyNodeModel>()
            .toList()
          ..sort((left, right) => left.x.compareTo(right.x));
    for (var i = 0; i < components.length - 1; i++) {
      elements.add(
        SceneLine(
          id: context.id('wardley-pipeline-link'),
          start: positions[components[i].id]!,
          end: positions[components[i + 1].id]!,
          stroke: SceneStroke(color: config.linkStroke, dashes: const [4, 4]),
          role: SemanticRole.edge,
          cssClasses: const ['wardley-pipeline-evolution-link'],
        ),
      );
    }
    if (components.isEmpty) continue;
    final componentPositions = components.map((node) => positions[node.id]!).toList();
    final minX = componentPositions.map((point) => point.x).reduce(math.min);
    final maxX = componentPositions.map((point) => point.x).reduce(math.max);
    final y = componentPositions.last.y;
    final pipelineHeight = config.nodeRadius * 4;
    final boxTop = y - pipelineHeight / 2;
    positions[pipeline.parentId] = Point((minX + maxX) / 2, boxTop - squareSize / 6);
    elements.add(
      SceneRect(
        id: context.id('wardley-pipeline-box'),
        bounds: Bounds(left: minX - 15, top: boxTop, width: maxX - minX + 30, height: pipelineHeight),
        radiusX: 4,
        radiusY: 4,
        fill: const NoFill(),
        stroke: SceneStroke(color: config.axisColor, width: 1.5),
        role: SemanticRole.group,
        cssClasses: const ['wardley-pipeline-box'],
      ),
    );
  }

  final pipelineChildren = <String, Set<String>>{
    for (final pipeline in model.pipelines) pipeline.parentId: pipeline.componentIds.toSet(),
  };
  for (final link in model.links) {
    if (pipelineChildren[link.targetId]?.contains(link.sourceId) ?? false) continue;
    final source = positions[link.sourceId];
    final target = positions[link.targetId];
    if (source == null || target == null) continue;
    final dx = target.x - source.x;
    final dy = target.y - source.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) continue;
    final sourceNode = model.nodes.firstWhere((node) => node.id == link.sourceId);
    final targetNode = model.nodes.firstWhere((node) => node.id == link.targetId);
    final sourceRadius = sourceNode.isPipelineParent ? squareSize / math.sqrt2 : config.nodeRadius;
    final targetRadius = targetNode.isPipelineParent ? squareSize / math.sqrt2 : config.nodeRadius;
    final start = Point(source.x + dx / distance * sourceRadius, source.y + dy / distance * sourceRadius);
    final end = Point(target.x - dx / distance * targetRadius, target.y - dy / distance * targetRadius);
    elements.add(
      ScenePath(
        id: context.id('wardley-link'),
        commands: [MoveTo(start), LineTo(end)],
        fill: const NoFill(),
        stroke: SceneStroke(
          color: config.linkStroke,
          dashes: link.style == WardleyLinkStyle.dashed ? const [6, 6] : const [],
        ),
        role: SemanticRole.edge,
        cssClasses: const ['wardley-link'],
        label: link.label,
      ),
    );
    if (link.flow case WardleyLinkFlow.forward || WardleyLinkFlow.bidirectional) {
      elements.add(_wardleyArrow(context, end, start, config.linkStroke, 'wardley-link-arrow'));
    }
    if (link.flow case WardleyLinkFlow.backward || WardleyLinkFlow.bidirectional) {
      elements.add(_wardleyArrow(context, start, end, config.linkStroke, 'wardley-link-arrow'));
    }
    if (link.label case final label?) {
      final midpoint = Point((source.x + target.x) / 2, (source.y + target.y) / 2);
      final labelPoint = Point(midpoint.x + dy / distance * 8, midpoint.y - dx / distance * 8);
      elements.add(
        _text(
          context,
          label,
          labelPoint.x,
          labelPoint.y,
          anchor: TextAnchor.middle,
          style: labelStyle,
          cssClasses: const ['wardley-link-label'],
        ),
      );
    }
  }

  for (final trend in model.trends) {
    final origin = positions[trend.nodeId];
    if (origin == null) continue;
    final target = project(trend.targetX, trend.targetY);
    final dx = target.x - origin.x;
    final dy = target.y - origin.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final shorten = config.nodeRadius + 2;
    final end = distance > shorten
        ? Point(target.x - dx / distance * shorten, target.y - dy / distance * shorten)
        : target;
    elements.add(
      ScenePath(
        id: context.id('wardley-trend'),
        commands: [MoveTo(origin), LineTo(end)],
        fill: const NoFill(),
        stroke: SceneStroke(color: config.evolutionStroke, dashes: const [4, 4]),
        role: SemanticRole.edge,
        cssClasses: const ['wardley-trend'],
      ),
    );
    if (distance > 0) {
      elements.add(_wardleyArrow(context, end, origin, config.evolutionStroke, 'wardley-trend-arrow'));
    }
  }

  for (final node in model.nodes) {
    final point = positions[node.id]!;
    if (node.strategy case final strategy?) {
      switch (strategy) {
        case WardleyStrategy.build || WardleyStrategy.buy || WardleyStrategy.outsource:
          final fill = switch (strategy) {
            WardleyStrategy.build => const Color(238, 238, 238),
            WardleyStrategy.buy => const Color(204, 204, 204),
            WardleyStrategy.outsource => const Color(102, 102, 102),
            WardleyStrategy.market => throw StateError('handled separately'),
          };
          elements.add(
            SceneCircle(
              id: context.id('wardley-strategy'),
              center: point,
              radius: config.nodeRadius * 2,
              fill: SolidFill(fill),
              stroke: componentStroke,
              role: SemanticRole.node,
              cssClasses: ['wardley-${strategy.name}-overlay'],
            ),
          );
        case WardleyStrategy.market:
          _addWardleyMarket(elements, context, point, config);
      }
    }
    if (node.isPipelineParent) {
      elements.add(
        SceneRect(
          id: context.id('wardley-pipeline-parent'),
          bounds: Bounds(
            left: point.x - squareSize / 2,
            top: point.y - squareSize / 2,
            width: squareSize,
            height: squareSize,
          ),
          fill: SolidFill(config.componentFill),
          stroke: componentStroke,
          role: SemanticRole.node,
          cssClasses: const ['wardley-pipeline-parent'],
          label: node.label,
        ),
      );
    } else if (node.kind != WardleyNodeKind.anchor && node.strategy != WardleyStrategy.market) {
      elements.add(
        SceneCircle(
          id: context.id('wardley-component'),
          center: point,
          radius: config.nodeRadius,
          fill: SolidFill(config.componentFill),
          stroke: componentStroke,
          role: SemanticRole.node,
          cssClasses: const ['wardley-component'],
          label: node.label,
        ),
      );
    }
    if (node.inertia) {
      var offset = node.isPipelineParent ? squareSize / 2 + 15 : config.nodeRadius + 15;
      if (node.strategy != null) offset += config.nodeRadius + 10;
      final lineHeight = node.isPipelineParent ? squareSize : config.nodeRadius * 2;
      elements.add(
        SceneLine(
          id: context.id('wardley-inertia'),
          start: Point(point.x + offset, point.y - lineHeight / 2),
          end: Point(point.x + offset, point.y + lineHeight / 2),
          stroke: SceneStroke(color: config.componentStroke, width: 6),
          role: SemanticRole.annotation,
          cssClasses: const ['wardley-inertia'],
        ),
      );
    }
    final isAnchor = node.kind == WardleyNodeKind.anchor;
    final strategySpacing = node.strategy == null ? 0.0 : 10.0;
    final labelX = point.x + (node.labelOffsetX ?? (isAnchor ? 0 : config.nodeLabelOffset + strategySpacing));
    final labelY = point.y + (node.labelOffsetY ?? (isAnchor ? -3 : -config.nodeLabelOffset - strategySpacing));
    elements.add(
      _text(
        context,
        node.label,
        labelX,
        labelY,
        anchor: isAnchor ? TextAnchor.middle : TextAnchor.start,
        style: SceneTextStyle(
          fontFamily: labelStyle.fontFamily,
          fontSize: labelStyle.fontSize,
          weight: isAnchor ? FontWeight.bold : FontWeight.normal,
          color: isAnchor ? config.axisColor : config.componentLabelColor,
        ),
        cssClasses: const ['wardley-node-label'],
      ),
    );
  }

  for (final annotation in ast.annotations) {
    final point = positioned(annotation.position);
    elements.add(
      SceneCircle(
        id: context.id('wardley-annotation'),
        center: point,
        radius: 10,
        fill: const SolidFill(Color(255, 255, 255)),
        stroke: SceneStroke(color: config.axisColor, width: 1.5),
        role: SemanticRole.annotation,
        cssClasses: const ['wardley-annotation-circle'],
      ),
    );
    elements.add(
      _text(
        context,
        '${annotation.number}',
        point.x,
        point.y,
        anchor: TextAnchor.middle,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: 10,
          weight: FontWeight.bold,
          color: config.axisTextColor,
        ),
        cssClasses: const ['wardley-annotation-number'],
      ),
    );
  }
  if (ast.annotationsBox != null && ast.annotations.isNotEmpty) {
    final sorted = ast.annotations.where((annotation) => annotation.text.isNotEmpty).toList()
      ..sort((left, right) => left.number.compareTo(right.number));
    if (sorted.isNotEmpty) {
      const boxPadding = 10.0;
      const lineHeight = 16.0;
      final annotationStyle = SceneTextStyle(
        fontFamily: context.options.theme.fontFamily,
        fontSize: 11,
        color: config.axisTextColor,
      );
      final maxWidth = sorted
          .map(
            (annotation) => context.measurer.measure('${annotation.number}. ${annotation.text}', annotationStyle).width,
          )
          .reduce(math.max);
      final textHeight = sorted
          .map(
            (annotation) =>
                context.measurer.measure('${annotation.number}. ${annotation.text}', annotationStyle).height,
          )
          .reduce(math.max);
      final boxWidth = maxWidth + boxPadding * 2 + 105;
      final boxHeight = sorted.length * lineHeight + boxPadding * 2 + textHeight / 2;
      final requested = positioned(ast.annotationsBox!);
      final boxX = requested.x.clamp(config.padding, width - config.padding - boxWidth);
      final boxY = requested.y.clamp(config.padding, height - config.padding - boxHeight);
      elements.add(
        SceneRect(
          id: context.id('wardley-annotations-box'),
          bounds: Bounds(left: boxX, top: boxY, width: boxWidth, height: boxHeight),
          radiusX: 4,
          radiusY: 4,
          fill: const SolidFill(Color(255, 255, 255)),
          stroke: SceneStroke(color: config.axisColor, width: 1.5),
          role: SemanticRole.annotation,
          cssClasses: const ['wardley-annotations-box'],
        ),
      );
      for (var i = 0; i < sorted.length; i++) {
        elements.add(
          _text(
            context,
            '${sorted[i].number}. ${sorted[i].text}',
            boxX + boxPadding,
            boxY + boxPadding + (i + 1) * lineHeight,
            style: annotationStyle,
            cssClasses: const ['wardley-annotation-text'],
          ),
        );
      }
    }
  }

  for (final note in ast.notes) {
    final point = positioned(note.position);
    elements.add(
      _text(
        context,
        note.text,
        point.x,
        point.y,
        role: SemanticRole.annotation,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: 11,
          weight: FontWeight.bold,
          color: config.axisTextColor,
        ),
        cssClasses: const ['wardley-note'],
      ),
    );
  }
  for (final marker in ast.markers) {
    final point = positioned(marker.position);
    final right = marker is WardleyAcceleratorAst;
    elements.add(
      ScenePath(
        id: context.id('wardley-marker'),
        commands: _wardleyMarkerCommands(point, right: right),
        fill: const SolidFill(Color(255, 255, 255)),
        stroke: componentStroke,
        role: SemanticRole.annotation,
        cssClasses: const ['wardley-marker'],
        label: marker.name,
      ),
    );
    elements.add(
      _text(
        context,
        marker.name,
        point.x + 30,
        point.y + 30,
        anchor: TextAnchor.middle,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: 10,
          weight: FontWeight.bold,
          color: config.axisTextColor,
        ),
        cssClasses: const ['wardley-marker-label'],
      ),
    );
  }
  return _LayoutResult(width, height, elements);
}

ScenePolygon _wardleyArrow(_LayoutContext context, Point tip, Point tail, Color color, String cssClass) {
  final dx = tip.x - tail.x;
  final dy = tip.y - tail.y;
  final length = math.sqrt(dx * dx + dy * dy);
  final unitX = length == 0 ? 1.0 : dx / length;
  final unitY = length == 0 ? 0.0 : dy / length;
  final base = Point(tip.x - unitX * 6, tip.y - unitY * 6);
  return ScenePolygon(
    id: context.id('wardley-arrow'),
    points: [tip, Point(base.x - unitY * 3, base.y + unitX * 3), Point(base.x + unitY * 3, base.y - unitX * 3)],
    fill: SolidFill(color),
    role: SemanticRole.edge,
    cssClasses: [cssClass],
  );
}

void _addWardleyMarket(List<SceneElement> elements, _LayoutContext context, Point center, WardleyRenderOptions config) {
  final outerRadius = config.nodeRadius * 2;
  final dotRadius = config.nodeRadius * .7;
  final triangleRadius = config.nodeRadius * 1.2;
  final left = Point(
    center.x - triangleRadius * math.cos(math.pi / 6),
    center.y + triangleRadius * math.sin(math.pi / 6),
  );
  final right = Point(
    center.x + triangleRadius * math.cos(math.pi / 6),
    center.y + triangleRadius * math.sin(math.pi / 6),
  );
  final top = Point(center.x, center.y - triangleRadius);
  final stroke = SceneStroke(color: config.componentStroke);
  elements.add(
    SceneCircle(
      id: context.id('wardley-market'),
      center: center,
      radius: outerRadius,
      fill: const SolidFill(Color(255, 255, 255)),
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: const ['wardley-market-overlay'],
    ),
  );
  for (final (start, end) in [(top, left), (left, right), (right, top)]) {
    elements.add(
      SceneLine(
        id: context.id('wardley-market-line'),
        start: start,
        end: end,
        stroke: stroke,
        role: SemanticRole.node,
        cssClasses: const ['wardley-market-line'],
      ),
    );
  }
  for (final point in [top, left, right]) {
    elements.add(
      SceneCircle(
        id: context.id('wardley-market-dot'),
        center: point,
        radius: dotRadius,
        fill: const SolidFill(Color(255, 255, 255)),
        stroke: SceneStroke(color: config.componentStroke, width: 2),
        role: SemanticRole.node,
        cssClasses: const ['wardley-market-dot'],
      ),
    );
  }
}

List<PathCommand> _wardleyMarkerCommands(Point origin, {required bool right}) {
  const width = 60.0;
  const height = 30.0;
  const headWidth = 20.0;
  if (right) {
    return [
      MoveTo(Point(origin.x, origin.y - height / 2)),
      LineTo(Point(origin.x + width - headWidth, origin.y - height / 2)),
      LineTo(Point(origin.x + width - headWidth, origin.y - height / 2 - 8)),
      LineTo(Point(origin.x + width, origin.y)),
      LineTo(Point(origin.x + width - headWidth, origin.y + height / 2 + 8)),
      LineTo(Point(origin.x + width - headWidth, origin.y + height / 2)),
      LineTo(Point(origin.x, origin.y + height / 2)),
      const ClosePath(),
    ];
  }
  return [
    MoveTo(Point(origin.x + width, origin.y - height / 2)),
    LineTo(Point(origin.x + headWidth, origin.y - height / 2)),
    LineTo(Point(origin.x + headWidth, origin.y - height / 2 - 8)),
    LineTo(Point(origin.x, origin.y)),
    LineTo(Point(origin.x + headWidth, origin.y + height / 2 + 8)),
    LineTo(Point(origin.x + headWidth, origin.y + height / 2)),
    LineTo(Point(origin.x + width, origin.y + height / 2)),
    const ClosePath(),
  ];
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
