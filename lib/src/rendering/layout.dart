import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../parser/ast.dart';
import '../parser/diagram_type.dart';
import '../parser/parser.dart';
import 'geometry/architecture.dart';
import 'geometry/cynefin.dart';
import 'geometry/event_modeling.dart';
import 'geometry/git_graph.dart';
import 'geometry/treemap.dart';
import 'geometry/wardley.dart';
import 'options.dart';
import 'scene.dart';
import 'svg.dart';

part 'layout/architecture.dart';
part 'layout/cynefin.dart';
part 'layout/event_modeling.dart';
part 'layout/git_graph.dart';
part 'layout/info.dart';
part 'layout/packet.dart';
part 'layout/pie.dart';
part 'layout/radar.dart';
part 'layout/railroad.dart';
part 'layout/tree_view.dart';
part 'layout/treemap.dart';
part 'layout/wardley.dart';

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

  final rendererHandlesTitle =
      diagram is ArchitectureAst ||
      diagram is PacketAst ||
      diagram is PieAst ||
      diagram is RadarAst ||
      diagram is TreemapAst ||
      diagram is CynefinAst ||
      diagram is GitGraphAst ||
      diagram is WardleyAst;
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
  final diagramOptions = switch (diagram) {
    ArchitectureAst() => options.optionsFor(const ArchitectureRenderOptions()),
    CynefinAst() => options.optionsFor(const CynefinRenderOptions()),
    EventModelingAst() => options.optionsFor(const EventModelingRenderOptions()),
    GitGraphAst() => options.optionsFor(const GitGraphRenderOptions()),
    InfoAst() => options.optionsFor(const InfoRenderOptions()),
    PacketAst() => options.optionsFor(const PacketRenderOptions()),
    PieAst() => options.optionsFor(const PieRenderOptions()),
    RadarAst() => options.optionsFor(const RadarRenderOptions()),
    RailroadAst() => options.optionsFor(const RailroadRenderOptions()),
    TreeViewAst() => options.optionsFor(const TreeViewRenderOptions()),
    TreemapAst() => options.optionsFor(const TreemapRenderOptions()),
    WardleyAst() => options.optionsFor(const WardleyRenderOptions()),
  };
  return DiagramScene(
    viewport: viewport,
    bounds: contentBounds,
    widthPolicy: diagramOptions.useMaxWidth == true ? SceneWidthPolicy.fitContainer : SceneWidthPolicy.fixed,
    background: options.theme.background,
    title: diagram.title,
    description: diagram.accessibilityDescription,
    accessibilityTitle: diagram.accessibilityTitle ?? diagram.title,
    accessibilityDescription: diagram.accessibilityDescription,
    elements: elements,
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
  const _LayoutResult(this.width, this.height, this.elements, {this.bounds, this.viewportPadding = 0});
  final double width;
  final double height;
  final List<SceneElement> elements;
  final Bounds? bounds;
  final double viewportPadding;
}

Bounds? _sceneGeometryBounds(Iterable<SceneElement> elements) {
  Bounds? result;
  for (final element in elements) {
    final bounds = _sceneElementBounds(element);
    if (bounds != null) result = result == null ? bounds : result.union(bounds);
  }
  return result;
}

Bounds? _sceneElementBounds(SceneElement element) => switch (element) {
  SceneGroup(:final children, :final transforms) => switch (_sceneGeometryBounds(children)) {
    final bounds? => _transformBounds(bounds, transforms),
    null => null,
  },
  SceneLine(:final start, :final end) => _pointsBounds([start, end]),
  SceneRect(:final bounds) => bounds,
  SceneCircle(:final center, :final radius) => Bounds(
    left: center.x - radius,
    top: center.y - radius,
    width: radius * 2,
    height: radius * 2,
  ),
  SceneEllipse(:final center, :final radiusX, :final radiusY) => Bounds(
    left: center.x - radiusX,
    top: center.y - radiusY,
    width: radiusX * 2,
    height: radiusY * 2,
  ),
  ScenePolygon(:final points) || ScenePolyline(:final points) => _pointsBounds(points),
  ScenePath(:final commands) => _pointsBounds([
    for (final command in commands)
      ...switch (command) {
        MoveTo(:final point) || LineTo(:final point) => [point],
        CubicTo(:final control1, :final control2, :final end) => [control1, control2, end],
        QuadraticTo(:final control, :final end) => [control, end],
        ArcTo(:final end) => [end],
        ClosePath() => const <Point>[],
      },
  ]),
  SceneText() => null,
  SceneIcon(:final position, :final geometry) => geometry.bounds.translated(position.x, position.y),
};

Bounds _transformBounds(Bounds bounds, List<SceneTransform> transforms) => _pointsBounds(
  [
    Point(bounds.left, bounds.top),
    Point(bounds.right, bounds.top),
    Point(bounds.right, bounds.bottom),
    Point(bounds.left, bounds.bottom),
  ].map((point) => transforms.reversed.fold(point, _transformPoint)).toList(),
)!;

Point _transformPoint(Point point, SceneTransform transform) => switch (transform) {
  Translate(:final x, :final y) => Point(point.x + x, point.y + y),
  Scale(:final x, :final y) => Point(point.x * x, point.y * (y ?? x)),
  Rotate(:final degrees, :final center) => () {
    final origin = center ?? const Point(0, 0);
    final radians = degrees * math.pi / 180;
    final cosine = math.cos(radians);
    final sine = math.sin(radians);
    final x = point.x - origin.x;
    final y = point.y - origin.y;
    return Point(origin.x + x * cosine - y * sine, origin.y + x * sine + y * cosine);
  }(),
  MatrixTransform(:final a, :final b, :final c, :final d, :final e, :final f) => Point(
    a * point.x + c * point.y + e,
    b * point.x + d * point.y + f,
  ),
};

Bounds? _pointsBounds(List<Point> points) {
  if (points.isEmpty) return null;
  var left = points.first.x;
  var right = left;
  var top = points.first.y;
  var bottom = top;
  for (final point in points.skip(1)) {
    left = math.min(left, point.x);
    right = math.max(right, point.x);
    top = math.min(top, point.y);
    bottom = math.max(bottom, point.y);
  }
  return Bounds(left: left, top: top, width: right - left, height: bottom - top);
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

// Scene colors store alpha as an eight-bit channel while Mermaid options use
// normalized CSS opacity values.
const _colorAlphaMaximum = 255;

Color _colorWithOpacity(Color color, double opacity) => Color(
  color.red,
  color.green,
  color.blue,
  (color.alpha / _colorAlphaMaximum * opacity.clamp(0, 1) * _colorAlphaMaximum).round(),
);

SceneTextStyle _mermaidTextStyle(_LayoutContext context, double fontSize, {Color? color}) => SceneTextStyle(
  fontFamily: context.options.theme.resolveFontFamily(fallback: _mermaidFontFamily),
  fontSize: fontSize,
  color: color ?? context.options.theme.primaryText,
);

IconGeometry _iconGeometry(_LayoutContext context, String reference) =>
    context.iconResolver.resolve(reference) ?? const PlaceholderIconResolver().resolve(reference);

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
