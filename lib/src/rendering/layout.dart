import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:fcose/fcose.dart';

import '../parser/ast.dart';
import '../parser/diagram_type.dart';
import '../parser/parser.dart';
import 'geometry/architecture.dart';
import 'geometry/cynefin.dart';
import 'geometry/event_modeling.dart';
import 'geometry/git_graph.dart';
import 'geometry/packet.dart';
import 'geometry/path_builders.dart';
import 'geometry/polar.dart';
import 'geometry/railroad.dart';
import 'geometry/scene_bounds.dart';
import 'geometry/treemap.dart';
import 'geometry/wardley.dart';
import 'icons/architecture.dart';
import 'options.dart';
import 'scene.dart';
import 'svg.dart';

part 'layout/architecture.dart';
part 'layout/class.dart';
part 'layout/cynefin.dart';
part 'layout/er.dart';
part 'layout/event_modeling.dart';
part 'layout/flowchart.dart';
part 'layout/graph_common.dart';
part 'layout/gantt.dart';
part 'layout/git_graph.dart';
part 'layout/info.dart';
part 'layout/kanban.dart';
part 'layout/mindmap.dart';
part 'layout/packet.dart';
part 'layout/pie.dart';
part 'layout/radar.dart';
part 'layout/railroad.dart';
part 'layout/sequence.dart';
part 'layout/state.dart';
part 'layout/timeline.dart';
part 'layout/tree_view.dart';
part 'layout/treemap.dart';
part 'layout/wardley.dart';
part 'layout/xy_chart.dart';

const _palette = <Color>[
  Color(87, 103, 198),
  Color(241, 156, 74),
  Color(76, 175, 130),
  Color(218, 91, 91),
  Color(151, 104, 190),
  Color(72, 169, 197),
  Color(222, 190, 73),
];
const _mermaidFontFamily = MermaidTheme.defaultFontFamily;

// Mermaid reserves a fixed header band for renderers that do not position
// their own title. The baseline leaves the remaining space below the glyphs.
const _diagramTitleBandHeight = 38.0;
const _diagramTitleBaselineY = 24.0;
const _minimumSceneExtent = 1.0;

/// Lays out layout diagram.
/// Lays out a typed Mermaid [diagram] into backend-neutral scene geometry.
///
/// [textMeasurer] controls label metrics and therefore exact geometry.
/// [iconResolver] supplies vector icon paths without coupling layout to an
/// asset system. The returned scene contains absolute bounds, transforms,
/// semantic roles, accessibility metadata, and the requested width policy.
DiagramScene layoutDiagram(
  DiagramAst diagram, {
  RenderOptions options = const RenderOptions(),
  TextMeasurer textMeasurer = const DeterministicTextMeasurer(),
  IconResolver iconResolver = const EmptyIconResolver(),
}) {
  final context = _LayoutContext(options, textMeasurer, iconResolver);
  final (:content, :diagramOptions, :rendererHandlesTitle) = switch (diagram) {
    ArchitectureAst ast => (
      content: _layoutArchitecture(ast, context),
      diagramOptions: options.optionsFor(const ArchitectureRenderOptions()),
      rendererHandlesTitle: true,
    ),
    ClassDiagramAst ast => (
      content: _layoutClassDiagram(ast, context),
      diagramOptions: options.optionsFor(const ClassRenderOptions()),
      rendererHandlesTitle: false,
    ),
    CynefinAst ast => (
      content: _layoutCynefin(ast, context),
      diagramOptions: options.optionsFor(const CynefinRenderOptions()),
      rendererHandlesTitle: true,
    ),
    EventModelingAst ast => (
      content: _layoutEventModeling(ast, context),
      diagramOptions: options.optionsFor(const EventModelingRenderOptions()),
      rendererHandlesTitle: false,
    ),
    ErDiagramAst ast => (
      content: _layoutErDiagram(ast, context),
      diagramOptions: options.optionsFor(const ErRenderOptions()),
      rendererHandlesTitle: false,
    ),
    FlowchartAst ast => (
      content: _layoutFlowchart(ast, context),
      diagramOptions: options.optionsFor(const FlowchartRenderOptions()),
      rendererHandlesTitle: true,
    ),
    GanttAst ast => (
      content: _layoutGantt(ast, context),
      diagramOptions: options.optionsFor(const GanttRenderOptions()),
      rendererHandlesTitle: true,
    ),
    GitGraphAst ast => (
      content: _layoutGitGraph(ast, context),
      diagramOptions: options.optionsFor(const GitGraphRenderOptions()),
      rendererHandlesTitle: true,
    ),
    InfoAst ast => (
      content: _layoutInfo(ast, context),
      diagramOptions: options.optionsFor(const InfoRenderOptions()),
      rendererHandlesTitle: false,
    ),
    KanbanAst ast => (
      content: _layoutKanban(ast, context),
      diagramOptions: options.optionsFor(const KanbanRenderOptions()),
      rendererHandlesTitle: false,
    ),
    MindmapAst ast => (
      content: _layoutMindmap(ast, context),
      diagramOptions: options.optionsFor(const MindmapRenderOptions()),
      rendererHandlesTitle: false,
    ),
    PacketAst ast => (
      content: _layoutPacket(ast, context),
      diagramOptions: options.optionsFor(const PacketRenderOptions()),
      rendererHandlesTitle: true,
    ),
    PieAst ast => (
      content: _layoutPie(ast, context),
      diagramOptions: options.optionsFor(const PieRenderOptions()),
      rendererHandlesTitle: true,
    ),
    RadarAst ast => (
      content: _layoutRadar(ast, context),
      diagramOptions: options.optionsFor(const RadarRenderOptions()),
      rendererHandlesTitle: true,
    ),
    RailroadAst ast => (
      content: _layoutRailroad(ast, context),
      diagramOptions: options.optionsFor(const RailroadRenderOptions()),
      rendererHandlesTitle: false,
    ),
    SequenceAst ast => (
      content: _layoutSequence(ast, context),
      diagramOptions: options.optionsFor(const SequenceRenderOptions()),
      rendererHandlesTitle: false,
    ),
    StateDiagramAst ast => (
      content: _layoutStateDiagram(ast, context),
      diagramOptions: options.optionsFor(const StateRenderOptions()),
      rendererHandlesTitle: false,
    ),
    TimelineAst ast => (
      content: _layoutTimeline(ast, context),
      diagramOptions: options.optionsFor(const TimelineRenderOptions()),
      rendererHandlesTitle: true,
    ),
    TreeViewAst ast => (
      content: _layoutTree(ast, context),
      diagramOptions: options.optionsFor(const TreeViewRenderOptions()),
      rendererHandlesTitle: false,
    ),
    TreemapAst ast => (
      content: _layoutTreemap(ast, context),
      diagramOptions: options.optionsFor(const TreemapRenderOptions()),
      rendererHandlesTitle: true,
    ),
    WardleyAst ast => (
      content: _layoutWardley(ast, context),
      diagramOptions: options.optionsFor(const WardleyRenderOptions()),
      rendererHandlesTitle: true,
    ),
    XyChartAst ast => (
      content: _layoutXyChart(ast, context),
      diagramOptions: options.optionsFor(const XyChartRenderOptions()),
      rendererHandlesTitle: true,
    ),
  };

  final positionsSharedTitle = diagram.title != null && !rendererHandlesTitle;
  final width = math.max(content.width, _minimumSceneExtent);
  final height = math.max(content.height, _minimumSceneExtent);
  final baseBounds = content.bounds ?? Bounds(left: 0, top: 0, width: width, height: height);
  final SceneText? sharedTitle = positionsSharedTitle
      ? _text(
          context,
          diagram.title!,
          content.width / 2,
          _diagramTitleBaselineY,
          anchor: TextAnchor.middle,
          role: SemanticRole.title,
        )
      : null;
  final List<SceneElement> elements = sharedTitle == null
      ? content.elements
      : [
          sharedTitle,
          SceneGroup(
            id: context.id('content'),
            transforms: const [Translate(0, _diagramTitleBandHeight)],
            children: content.elements,
          ),
        ];
  final contentBounds = sharedTitle == null
      ? baseBounds
      : sharedTitle.bounds.union(baseBounds.translated(0, _diagramTitleBandHeight));
  final viewport = contentBounds.expand(options.padding + content.viewportPadding);
  return DiagramScene(
    diagramType: diagram.type,
    viewport: viewport,
    bounds: contentBounds,
    widthPolicy: diagramOptions.useMaxWidth == true ? SceneWidthPolicy.fitContainer : SceneWidthPolicy.fixed,
    background: options.theme.background,
    title: diagram.title,
    description: diagram.accessibilityDescription,
    accessibilityTitle: diagram.accessibilityTitle ?? diagram.title,
    accessibilityDescription: diagram.accessibilityDescription,
    elements: elements,
    clips: content.clips,
  );
}

/// Renders render diagram svg.
/// Parses, lays out, and renders Mermaid [source] as SVG.
///
/// This convenience method is equivalent to calling [parse], [layoutDiagram],
/// and [renderSvg]. Supply the same injected measurer and icon resolver used by
/// other backends when deterministic cross-backend geometry is required.
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
  late final SceneTextStyle textStyle = SceneTextStyle(
    fontFamily: options.theme.fontFamily,
    fontSize: options.theme.fontSize,
    color: options.theme.primaryText,
  );
}

final class _LayoutResult {
  const _LayoutResult(
    this.width,
    this.height,
    this.elements, {
    this.bounds,
    this.viewportPadding = 0,
    this.clips = const [],
  });
  final double width;
  final double height;
  final List<SceneElement> elements;
  final Bounds? bounds;
  final double viewportPadding;
  final List<SceneClip> clips;
}

SceneText _text(
  _LayoutContext context,
  String value,
  double x,
  double y, {
  TextAnchor anchor = TextAnchor.start,
  TextBaseline baseline = TextBaseline.central,
  SemanticRole role = SemanticRole.label,
  SceneTextStyle? style,
  SceneStroke? stroke,
  String? link,
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
    stroke: stroke,
    link: link,
    role: role,
    cssClasses: cssClasses,
  );
}

// Scene colors store alpha as an eight-bit channel while Mermaid options use
// normalized CSS opacity values.
const _colorAlphaMaximum = 255;

Color _colorWithOpacity(Color color, double opacity) => Color(
  color.red,
  color.green,
  color.blue,
  (color.alpha / _colorAlphaMaximum * opacity.clamp(0, 1) * _colorAlphaMaximum).round(),
);

List<PathCommand> _rectanglePathCommands(Bounds bounds) => [
  MoveTo(Point(bounds.left, bounds.top)),
  LineTo(Point(bounds.right, bounds.top)),
  LineTo(Point(bounds.right, bounds.bottom)),
  LineTo(Point(bounds.left, bounds.bottom)),
  const ClosePath(),
];

ScenePolygon _triangleArrow(
  _LayoutContext context, {
  required Point tip,
  required Point tail,
  required double length,
  required double halfWidth,
  required Color color,
  required String idPrefix,
  String idSuffix = 'arrow',
  required List<String> cssClasses,
}) {
  final dx = tip.x - tail.x;
  final dy = tip.y - tail.y;
  final distance = math.sqrt(dx * dx + dy * dy);
  final unitX = distance == 0 ? 1.0 : dx / distance;
  final unitY = distance == 0 ? 0.0 : dy / distance;
  final base = Point(tip.x - unitX * length, tip.y - unitY * length);
  return ScenePolygon(
    id: context.id('$idPrefix-$idSuffix'),
    points: [
      tip,
      Point(base.x - unitY * halfWidth, base.y + unitX * halfWidth),
      Point(base.x + unitY * halfWidth, base.y - unitX * halfWidth),
    ],
    fill: SolidFill(color),
    role: SemanticRole.edge,
    cssClasses: cssClasses,
  );
}

SceneTextStyle _mermaidTextStyle(_LayoutContext context, double fontSize, {Color? color}) => SceneTextStyle(
  fontFamily: context.options.theme.resolveFontFamily(fallback: _mermaidFontFamily),
  fontSize: fontSize,
  color: color ?? context.options.theme.primaryText,
);

IconGeometry _iconGeometry(_LayoutContext context, String reference) =>
    context.iconResolver.resolve(reference) ??
    const ArchitectureIconResolver().resolve(reference) ??
    const PlaceholderIconResolver().resolve(reference);

SceneGroup _scaledIcon(
  _LayoutContext context,
  String reference,
  Point position,
  double size, {
  required String idPrefix,
  SceneFill? fill,
  SceneStroke? stroke,
  List<String> cssClasses = const [],
}) {
  final geometry = _iconGeometry(context, reference);
  final scaleX = geometry.bounds.width == 0 ? 1.0 : size / geometry.bounds.width;
  final scaleY = geometry.bounds.height == 0 ? 1.0 : size / geometry.bounds.height;
  return SceneGroup(
    id: context.id('$idPrefix-icon'),
    children: [
      SceneIcon(
        id: context.id('$idPrefix-icon-geometry'),
        reference: reference,
        position: Point(-geometry.bounds.left, -geometry.bounds.top),
        geometry: geometry,
        fill: fill,
        stroke: stroke,
        label: reference,
      ),
    ],
    transforms: [Translate(position.x, position.y), Scale(scaleX, scaleY)],
    role: SemanticRole.icon,
    label: reference,
    cssClasses: cssClasses,
  );
}
