import 'package:characters/characters.dart';
import 'package:collection/collection.dart';

import '../parser/diagram_type.dart';

const _deepEquality = DeepCollectionEquality();

mixin _SceneValue {
  List<Object?> get fields;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType && other is _SceneValue && _deepEquality.equals(fields, other.fields);

  @override
  int get hashCode => Object.hash(runtimeType, _deepEquality.hash(fields));
}

/// A two-dimensional point in backend-neutral scene units.
final class Point with _SceneValue {
  /// Creates a point with horizontal coordinate [x] and vertical coordinate [y].
  const Point(this.x, this.y);

  /// The horizontal coordinate.
  final double x;

  /// The vertical coordinate.
  final double y;

  /// Returns this point translated by [deltaX] and [deltaY].
  Point translated(double deltaX, double deltaY) => Point(x + deltaX, y + deltaY);

  @override
  List<Object?> get fields => [x, y];
}

/// A width and height in backend-neutral scene units.
final class Size with _SceneValue {
  /// Creates a size with the given [width] and [height].
  const Size(this.width, this.height);

  /// The horizontal extent.
  final double width;

  /// The vertical extent.
  final double height;
  @override
  List<Object?> get fields => [width, height];
}

/// An axis-aligned rectangle in backend-neutral scene coordinates.
final class Bounds with _SceneValue {
  /// Creates bounds from the top-left position and dimensions.
  const Bounds({required this.left, required this.top, required this.width, required this.height});

  /// Creates origin-aligned bounds from [size].
  Bounds.fromSize(Size size) : this(left: 0, top: 0, width: size.width, height: size.height);

  /// Creates bounds of [size] centered on [center].
  Bounds.fromCenter(Point center, Size size)
    : this(left: center.x - size.width / 2, top: center.y - size.height / 2, width: size.width, height: size.height);

  /// The minimum horizontal coordinate.
  final double left;

  /// The minimum vertical coordinate.
  final double top;

  /// The horizontal extent.
  final double width;

  /// The vertical extent.
  final double height;

  /// The maximum horizontal coordinate.
  double get right => left + width;

  /// The maximum vertical coordinate.
  double get bottom => top + height;

  /// The center point.
  Point get center => Point(left + width / 2, top + height / 2);

  /// Returns these bounds translated by [deltaX] and [deltaY].
  Bounds translated(double deltaX, double deltaY) =>
      Bounds(left: left + deltaX, top: top + deltaY, width: width, height: height);

  /// Returns bounds expanded by [amount] on every side.
  Bounds expand(double amount) =>
      Bounds(left: left - amount, top: top - amount, width: width + amount * 2, height: height + amount * 2);

  /// Returns the smallest bounds containing this rectangle and [other].
  Bounds union(Bounds other) {
    final x = left < other.left ? left : other.left;
    final y = top < other.top ? top : other.top;
    final r = right > other.right ? right : other.right;
    final b = bottom > other.bottom ? bottom : other.bottom;
    return Bounds(left: x, top: y, width: r - x, height: b - y);
  }

  @override
  List<Object?> get fields => [left, top, width, height];
}

/// An sRGB color with eight-bit red, green, blue, and alpha channels.
final class Color with _SceneValue {
  /// Creates a color from channel values in the inclusive range 0–255.
  const Color(this.red, this.green, this.blue, [this.alpha = 255])
    : assert(red >= 0 && red <= 255),
      assert(green >= 0 && green <= 255),
      assert(blue >= 0 && blue <= 255),
      assert(alpha >= 0 && alpha <= 255);

  /// Parses `RRGGBB`, `#RRGGBB`, `RRGGBBAA`, or `#RRGGBBAA`.
  ///
  /// Throws [FormatException] when [value] has an unsupported length or
  /// contains non-hexadecimal characters.
  factory Color.fromHex(String value) {
    final hex = value.replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) throw FormatException('Expected RRGGBB or RRGGBBAA', value);
    final number = int.parse(hex, radix: 16);
    return hex.length == 6
        ? Color(number >> 16, (number >> 8) & 255, number & 255)
        : Color(number >> 24, (number >> 16) & 255, (number >> 8) & 255, number & 255);
  }

  /// The red channel, from 0 to 255.
  final int red;

  /// The green channel, from 0 to 255.
  final int green;

  /// The blue channel, from 0 to 255.
  final int blue;

  /// The alpha channel, from transparent 0 to opaque 255.
  final int alpha;

  /// The opaque `#rrggbb` representation; alpha is serialized separately.
  String get hex =>
      '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}';

  @override
  List<Object?> get fields => [red, green, blue, alpha];
}

/// Backend-neutral scene fill in a laid-out diagram scene.
sealed class SceneFill {
  const SceneFill();
}

/// A scene fill painted with one [color].
final class SolidFill extends SceneFill with _SceneValue {
  /// Creates a typed [SolidFill].
  const SolidFill(this.color);

  /// The color.
  final Color color;
  @override
  List<Object?> get fields => [color];
}

/// An explicit absence of fill paint.
final class NoFill extends SceneFill with _SceneValue {
  /// Creates a typed [NoFill].
  const NoFill();
  @override
  List<Object?> get fields => const [];
}

/// Defines the supported stroke cap values.
enum StrokeCap {
  /// Selects the butt variant.
  butt,

  /// Selects the round variant.
  round,

  /// Selects the square variant.
  square,
}

/// Defines the supported stroke join values.
enum StrokeJoin {
  /// Selects the miter variant.
  miter,

  /// Selects the round variant.
  round,

  /// Selects the bevel variant.
  bevel,
}

/// Backend-neutral scene stroke in a laid-out diagram scene.
final class SceneStroke with _SceneValue {
  /// Creates a typed [SceneStroke].
  const SceneStroke({
    required this.color,
    this.width = 1,
    this.dashes = const [],
    this.cap = StrokeCap.butt,
    this.join = StrokeJoin.miter,
  });

  /// The color.
  final Color color;

  /// The width.
  final double width;

  /// The dashes.
  final List<double> dashes;

  /// The cap.
  final StrokeCap cap;

  /// The join.
  final StrokeJoin join;
  @override
  List<Object?> get fields => [color, width, dashes, cap, join];
}

/// Defines the supported font weight values.
enum FontWeight {
  /// Selects the normal variant.
  normal,

  /// Selects the medium variant.
  medium,

  /// Selects the semibold variant.
  semibold,

  /// Selects the bold variant.
  bold,
}

/// Defines the supported font style values.
enum FontStyle {
  /// Selects the normal variant.
  normal,

  /// Selects the italic variant.
  italic,
}

/// Defines the supported text anchor values.
enum TextAnchor {
  /// Selects the start variant.
  start,

  /// Selects the middle variant.
  middle,

  /// Selects the end variant.
  end,
}

/// Defines the supported text baseline values.
enum TextBaseline {
  /// Selects the alphabetic variant.
  alphabetic,

  /// Selects the central variant.
  central,

  /// Selects the middle variant.
  middle,

  /// Selects the hanging variant.
  hanging,
}

/// Backend-neutral scene text style in a laid-out diagram scene.
final class SceneTextStyle with _SceneValue {
  /// Creates a typed [SceneTextStyle].
  const SceneTextStyle({
    this.fontFamily = 'Arial, sans-serif',
    this.fontSize = 16,
    this.weight = FontWeight.normal,
    this.style = FontStyle.normal,
    this.color = const Color(51, 51, 51),
    this.lineHeight = 1.2,
  });

  /// The font family.
  final String fontFamily;

  /// The font size.
  final double fontSize;

  /// The weight.
  final FontWeight weight;

  /// The style.
  final FontStyle style;

  /// The color.
  final Color color;

  /// The line height.
  final double lineHeight;
  @override
  List<Object?> get fields => [fontFamily, fontSize, weight, style, color, lineHeight];
}

/// Defines the supported semantic role values.
enum SemanticRole {
  /// Selects the diagram variant.
  diagram,

  /// Selects the group variant.
  group,

  /// Selects the node variant.
  node,

  /// Selects the edge variant.
  edge,

  /// Selects the label variant.
  label,

  /// Selects the title variant.
  title,

  /// Selects the legend variant.
  legend,

  /// Selects the icon variant.
  icon,

  /// Selects the annotation variant.
  annotation,

  /// Selects the background variant.
  background,
}

/// Backend-neutral scene transform in a laid-out diagram scene.
sealed class SceneTransform {
  const SceneTransform();
}

/// Translates subsequent scene geometry by [x] and [y].
final class Translate extends SceneTransform with _SceneValue {
  /// Creates a typed [Translate].
  const Translate(this.x, this.y);

  /// The x.
  final double x;

  /// The y.
  final double y;
  @override
  List<Object?> get fields => [x, y];
}

/// Scales subsequent scene geometry horizontally by [x] and vertically by [y].
///
/// When [y] is omitted, [x] is used for both axes.
final class Scale extends SceneTransform with _SceneValue {
  /// Creates a typed [Scale].
  const Scale(this.x, [this.y]);

  /// The x.
  final double x;

  /// The y.
  final double? y;
  @override
  List<Object?> get fields => [x, y];
}

/// Rotates subsequent scene geometry by [degrees] around [center].
final class Rotate extends SceneTransform with _SceneValue {
  /// Creates a typed [Rotate].
  const Rotate(this.degrees, {this.center});

  /// The degrees.
  final double degrees;

  /// The center.
  final Point? center;
  @override
  List<Object?> get fields => [degrees, center];
}

/// Applies an SVG-compatible two-dimensional affine transformation matrix.
final class MatrixTransform extends SceneTransform with _SceneValue {
  /// Creates a typed [MatrixTransform].
  const MatrixTransform(this.a, this.b, this.c, this.d, this.e, this.f);

  /// The a.
  final double a;

  /// The b.
  final double b;

  /// The c.
  final double c;

  /// The d.
  final double d;

  /// The e.
  final double e;

  /// The f.
  final double f;
  @override
  List<Object?> get fields => [a, b, c, d, e, f];
}

/// Base class for typed SVG-compatible path commands.
sealed class PathCommand {
  const PathCommand();
}

/// Starts a new path subpath at [point] without drawing.
final class MoveTo extends PathCommand with _SceneValue {
  /// Creates a typed [MoveTo].
  const MoveTo(this.point);

  /// The point.
  final Point point;
  @override
  List<Object?> get fields => [point];
}

/// Draws a straight segment from the current point to [point].
final class LineTo extends PathCommand with _SceneValue {
  /// Creates a typed [LineTo].
  const LineTo(this.point);

  /// The point.
  final Point point;
  @override
  List<Object?> get fields => [point];
}

/// Draws a cubic Bézier segment through [control1] and [control2] to [end].
final class CubicTo extends PathCommand with _SceneValue {
  /// Creates a typed [CubicTo].
  const CubicTo(this.control1, this.control2, this.end);

  /// The first Bézier control point.
  final Point control1;

  /// The second Bézier control point.
  final Point control2;

  /// The segment endpoint.
  final Point end;
  @override
  List<Object?> get fields => [control1, control2, end];
}

/// Draws a quadratic Bézier segment through [control] to [end].
final class QuadraticTo extends PathCommand with _SceneValue {
  /// Creates a typed [QuadraticTo].
  const QuadraticTo(this.control, this.end);

  /// The control.
  final Point control;

  /// The end.
  final Point end;
  @override
  List<Object?> get fields => [control, end];
}

/// Draws an SVG endpoint-parameterized elliptical arc to [end].
final class ArcTo extends PathCommand with _SceneValue {
  /// Creates a typed [ArcTo].
  const ArcTo({
    required this.radiusX,
    required this.radiusY,
    this.rotation = 0,
    this.largeArc = false,
    this.clockwise = true,
    required this.end,
  });

  /// The ellipse's horizontal radius.
  final double radiusX;

  /// The ellipse's vertical radius.
  final double radiusY;

  /// The ellipse-axis rotation in degrees.
  final double rotation;

  /// Whether to choose the sweep spanning more than 180 degrees.
  final bool largeArc;

  /// Whether the selected sweep proceeds clockwise.
  final bool clockwise;

  /// The end.
  final Point end;
  @override
  List<Object?> get fields => [radiusX, radiusY, rotation, largeArc, clockwise, end];
}

/// Closes the current subpath with a segment back to its starting point.
final class ClosePath extends PathCommand with _SceneValue {
  /// Creates a typed [ClosePath].
  const ClosePath();
  @override
  List<Object?> get fields => const [];
}

/// Backend-neutral scene element in a laid-out diagram scene.
sealed class SceneElement {
  const SceneElement({required this.id, this.role, this.cssClasses = const [], this.label});

  /// The stable backend identifier for this element.
  final String id;

  /// The semantic purpose exposed to rendering backends.
  final SemanticRole? role;

  /// Optional Mermaid-compatible CSS class names.
  final List<String> cssClasses;

  /// An accessible label describing the element.
  final String? label;
}

/// Backend-neutral scene group in a laid-out diagram scene.
final class SceneGroup extends SceneElement with _SceneValue {
  /// Creates a typed [SceneGroup].
  const SceneGroup({
    required super.id,
    this.children = const [],
    this.transforms = const [],
    this.clipId,
    super.role,
    super.cssClasses,
    super.label,
  });

  /// Child elements rendered in list order.
  final List<SceneElement> children;

  /// Transforms serialized in SVG transform-list order.
  final List<SceneTransform> transforms;

  /// The referenced [SceneClip.id], if the group is clipped.
  final String? clipId;
  @override
  List<Object?> get fields => [id, children, transforms, clipId, role, cssClasses, label];
}

/// Backend-neutral scene line in a laid-out diagram scene.
final class SceneLine extends SceneElement with _SceneValue {
  /// Creates a typed [SceneLine].
  const SceneLine({
    required super.id,
    required this.start,
    required this.end,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });

  /// The start.
  final Point start;

  /// The end.
  final Point end;

  /// The stroke.
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, start, end, stroke, role, cssClasses, label];
}

/// Backend-neutral scene rect in a laid-out diagram scene.
final class SceneRect extends SceneElement with _SceneValue {
  /// Creates a typed [SceneRect].
  const SceneRect({
    required super.id,
    required this.bounds,
    this.radiusX = 0,
    this.radiusY = 0,
    this.fill,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });

  /// The bounds.
  final Bounds bounds;

  /// The radius x.
  final double radiusX;

  /// The radius y.
  final double radiusY;

  /// The fill.
  final SceneFill? fill;

  /// The stroke.
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, bounds, radiusX, radiusY, fill, stroke, role, cssClasses, label];
}

/// Backend-neutral scene circle in a laid-out diagram scene.
final class SceneCircle extends SceneElement with _SceneValue {
  /// Creates a typed [SceneCircle].
  const SceneCircle({
    required super.id,
    required this.center,
    required this.radius,
    this.fill,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });

  /// The center.
  final Point center;

  /// The radius.
  final double radius;

  /// The fill.
  final SceneFill? fill;

  /// The stroke.
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, center, radius, fill, stroke, role, cssClasses, label];
}

/// Backend-neutral scene ellipse in a laid-out diagram scene.
final class SceneEllipse extends SceneElement with _SceneValue {
  /// Creates a typed [SceneEllipse].
  const SceneEllipse({
    required super.id,
    required this.center,
    required this.radiusX,
    required this.radiusY,
    this.fill,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });

  /// The center.
  final Point center;

  /// The radius x.
  final double radiusX;

  /// The radius y.
  final double radiusY;

  /// The fill.
  final SceneFill? fill;

  /// The stroke.
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, center, radiusX, radiusY, fill, stroke, role, cssClasses, label];
}

/// Backend-neutral scene polygon in a laid-out diagram scene.
final class ScenePolygon extends SceneElement with _SceneValue {
  /// Creates a typed [ScenePolygon].
  const ScenePolygon({
    required super.id,
    required this.points,
    this.fill,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });

  /// The points.
  final List<Point> points;

  /// The fill.
  final SceneFill? fill;

  /// The stroke.
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, points, fill, stroke, role, cssClasses, label];
}

/// Backend-neutral scene polyline in a laid-out diagram scene.
final class ScenePolyline extends SceneElement with _SceneValue {
  /// Creates a typed [ScenePolyline].
  const ScenePolyline({
    required super.id,
    required this.points,
    this.fill,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });

  /// The points.
  final List<Point> points;

  /// The fill.
  final SceneFill? fill;

  /// The stroke.
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, points, fill, stroke, role, cssClasses, label];
}

/// Backend-neutral scene path in a laid-out diagram scene.
final class ScenePath extends SceneElement with _SceneValue {
  /// Creates a typed [ScenePath].
  const ScenePath({
    required super.id,
    required this.commands,
    this.fill,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });

  /// The commands.
  final List<PathCommand> commands;

  /// The fill.
  final SceneFill? fill;

  /// The stroke.
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, commands, fill, stroke, role, cssClasses, label];
}

/// Backend-neutral scene text in a laid-out diagram scene.
final class SceneText extends SceneElement with _SceneValue {
  /// Creates a typed [SceneText].
  const SceneText({
    required super.id,
    required this.position,
    required this.text,
    required this.bounds,
    this.style = const SceneTextStyle(),
    this.anchor = TextAnchor.start,
    this.baseline = TextBaseline.alphabetic,
    this.stroke,
    this.link,
    super.role,
    super.cssClasses,
    super.label,
  });

  /// The position.
  final Point position;

  /// The text.
  final String text;

  /// The bounds.
  final Bounds bounds;

  /// The style.
  final SceneTextStyle style;

  /// The anchor.
  final TextAnchor anchor;

  /// The baseline.
  final TextBaseline baseline;

  /// Optional outline applied to the text glyphs.
  final SceneStroke? stroke;

  /// Optional destination represented by interactive backends.
  final String? link;

  @override
  List<Object?> get fields => [
    id,
    position,
    text,
    bounds,
    style,
    anchor,
    baseline,
    stroke,
    link,
    role,
    cssClasses,
    label,
  ];
}

/// One independently styled vector path inside an icon.
final class IconPath with _SceneValue {
  /// Creates a styled icon path.
  const IconPath({required this.commands, this.fill, this.stroke});

  /// The drawable path commands.
  final List<PathCommand> commands;

  /// The path fill, independent from other icon paths.
  final SceneFill? fill;

  /// The path stroke, independent from other icon paths.
  final SceneStroke? stroke;

  @override
  List<Object?> get fields => [commands, fill, stroke];
}

/// Resolved, backend-neutral vector geometry for an icon.
final class IconGeometry with _SceneValue {
  /// Creates a typed [IconGeometry].
  const IconGeometry({required this.bounds, this.paths = const [], this.styledPaths = const []});

  /// The icon's local coordinate bounds.
  final Bounds bounds;

  /// The icon's drawable path components.
  ///
  /// These legacy paths inherit [SceneIcon.fill] and [SceneIcon.stroke].
  final List<List<PathCommand>> paths;

  /// Independently painted paths for multi-color icons.
  final List<IconPath> styledPaths;

  @override
  List<Object?> get fields => [bounds, paths, styledPaths];
}

/// Backend-neutral scene icon in a laid-out diagram scene.
final class SceneIcon extends SceneElement with _SceneValue {
  /// Creates a typed [SceneIcon].
  const SceneIcon({
    required super.id,
    required this.reference,
    required this.position,
    required this.geometry,
    this.fill,
    this.stroke,
    super.role = SemanticRole.icon,
    super.cssClasses,
    super.label,
  });

  /// The source icon reference used to resolve backend-specific rendering.
  final String reference;

  /// The position.
  final Point position;

  /// The geometry.
  final IconGeometry geometry;

  /// The fill.
  final SceneFill? fill;

  /// The stroke.
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, reference, position, geometry, fill, stroke, role, cssClasses, label];
}

/// Backend-neutral scene clip in a laid-out diagram scene.
final class SceneClip with _SceneValue {
  /// Creates a typed [SceneClip].
  const SceneClip({required this.id, required this.path});

  /// The id.
  final String id;

  /// The path.
  final ScenePath path;
  @override
  List<Object?> get fields => [id, path];
}

/// Backend-neutral policy for sizing a scene within its host container.
enum SceneWidthPolicy {
  /// Preserve the scene viewport's intrinsic width and height.
  fixed,

  /// Fill the available width without growing beyond the intrinsic viewport.
  fitContainer,
}

/// A geometry-complete, backend-neutral Mermaid diagram scene.
final class DiagramScene with _SceneValue {
  /// Creates a typed [DiagramScene].
  const DiagramScene({
    required this.diagramType,
    required this.viewport,
    required this.bounds,
    this.widthPolicy = SceneWidthPolicy.fixed,
    this.background = const Color(255, 255, 255, 0),
    this.title,
    this.description,
    this.accessibilityTitle,
    this.accessibilityDescription,
    this.elements = const [],
    this.clips = const [],
  });

  /// The grammar and renderer family represented by this scene.
  final DiagramType diagramType;

  /// The SVG-style viewport, including renderer and global padding.
  final Bounds viewport;

  /// The unpadded bounds of visible scene content.
  final Bounds bounds;

  /// The preferred host-container sizing policy.
  final SceneWidthPolicy widthPolicy;

  /// The scene background color; a zero alpha omits background paint.
  final Color background;

  /// The diagram title parsed from Mermaid source.
  final String? title;

  /// The human-readable diagram description.
  final String? description;

  /// The accessible title, overriding [title] when present.
  final String? accessibilityTitle;

  /// The accessible description, overriding [description] when present.
  final String? accessibilityDescription;

  /// Top-level scene elements in paint order.
  final List<SceneElement> elements;

  /// Reusable clipping paths referenced by scene groups.
  final List<SceneClip> clips;
  @override
  List<Object?> get fields => [
    diagramType,
    viewport,
    bounds,
    widthPolicy,
    background,
    title,
    description,
    accessibilityTitle,
    accessibilityDescription,
    elements,
    clips,
  ];
}

/// Measures text before layout without coupling the package to a UI toolkit.
abstract interface class TextMeasurer {
  /// Returns the measured size of [text] when painted with [style].
  Size measure(String text, SceneTextStyle style);
}

/// A deterministic fallback measurer based on grapheme count and font size.
///
/// Inject platform font metrics for pixel-accurate output. This implementation
/// is suitable for tests, server-side rendering, and repeatable fallback layout.
final class DeterministicTextMeasurer implements TextMeasurer {
  /// Creates a typed [DeterministicTextMeasurer].
  const DeterministicTextMeasurer({this.averageGlyphWidth = .6});

  /// Average glyph width as a fraction of the configured font size.
  final double averageGlyphWidth;

  @override
  Size measure(String text, SceneTextStyle style) {
    final lines = text.split('\n');
    final width = lines.map((line) => line.characters.length).fold(0, (a, b) => a > b ? a : b);
    return Size(width * style.fontSize * averageGlyphWidth, lines.length * style.fontSize * style.lineHeight);
  }
}

/// Resolves Mermaid icon references into backend-neutral vector geometry.
abstract interface class IconResolver {
  /// Returns geometry for [reference], or `null` when it is unavailable.
  IconGeometry? resolve(String reference);
}

/// An icon resolver that deliberately resolves no references.
final class EmptyIconResolver implements IconResolver {
  /// Creates a typed [EmptyIconResolver].
  const EmptyIconResolver();
  @override
  IconGeometry? resolve(String reference) => null;
}

/// Resolves every unknown icon to a deterministic crossed-box placeholder.
final class PlaceholderIconResolver implements IconResolver {
  /// Creates a typed [PlaceholderIconResolver].
  const PlaceholderIconResolver({this.size = 18});

  /// The width and height of the square placeholder geometry.
  final double size;

  @override
  IconGeometry resolve(String reference) => IconGeometry(
    bounds: Bounds(left: 0, top: 0, width: size, height: size),
    paths: [
      [
        const MoveTo(Point(0, 0)),
        LineTo(Point(size, 0)),
        LineTo(Point(size, size)),
        LineTo(Point(0, size)),
        const ClosePath(),
      ],
      [const MoveTo(Point(0, 0)), LineTo(Point(size, size))],
      [MoveTo(Point(size, 0)), LineTo(Point(0, size))],
    ],
  );
}
