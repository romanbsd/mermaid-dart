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
