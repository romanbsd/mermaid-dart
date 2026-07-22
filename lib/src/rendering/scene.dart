import 'package:characters/characters.dart';
import 'package:collection/collection.dart';

const _deepEquality = DeepCollectionEquality();

mixin _SceneValue {
  List<Object?> get fields;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType && other is _SceneValue && _deepEquality.equals(fields, other.fields);

  @override
  int get hashCode => Object.hash(runtimeType, _deepEquality.hash(fields));
}

final class Point with _SceneValue {
  const Point(this.x, this.y);
  final double x;
  final double y;
  @override
  List<Object?> get fields => [x, y];
}

final class Size with _SceneValue {
  const Size(this.width, this.height);
  final double width;
  final double height;
  @override
  List<Object?> get fields => [width, height];
}

final class Bounds with _SceneValue {
  const Bounds({required this.left, required this.top, required this.width, required this.height});
  Bounds.fromSize(Size size) : this(left: 0, top: 0, width: size.width, height: size.height);

  final double left;
  final double top;
  final double width;
  final double height;
  double get right => left + width;
  double get bottom => top + height;
  Point get center => Point(left + width / 2, top + height / 2);

  Bounds expand(double amount) =>
      Bounds(left: left - amount, top: top - amount, width: width + amount * 2, height: height + amount * 2);

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

final class Color with _SceneValue {
  const Color(this.red, this.green, this.blue, [this.alpha = 255])
    : assert(red >= 0 && red <= 255),
      assert(green >= 0 && green <= 255),
      assert(blue >= 0 && blue <= 255),
      assert(alpha >= 0 && alpha <= 255);

  factory Color.fromHex(String value) {
    final hex = value.replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) throw FormatException('Expected RRGGBB or RRGGBBAA', value);
    final number = int.parse(hex, radix: 16);
    return hex.length == 6
        ? Color(number >> 16, (number >> 8) & 255, number & 255)
        : Color(number >> 24, (number >> 16) & 255, (number >> 8) & 255, number & 255);
  }

  final int red;
  final int green;
  final int blue;
  final int alpha;

  String get hex =>
      '#${red.toRadixString(16).padLeft(2, '0')}${green.toRadixString(16).padLeft(2, '0')}${blue.toRadixString(16).padLeft(2, '0')}';

  @override
  List<Object?> get fields => [red, green, blue, alpha];
}

sealed class SceneFill {
  const SceneFill();
}

final class SolidFill extends SceneFill with _SceneValue {
  const SolidFill(this.color);
  final Color color;
  @override
  List<Object?> get fields => [color];
}

final class NoFill extends SceneFill with _SceneValue {
  const NoFill();
  @override
  List<Object?> get fields => const [];
}

enum StrokeCap { butt, round, square }

enum StrokeJoin { miter, round, bevel }

final class SceneStroke with _SceneValue {
  const SceneStroke({
    required this.color,
    this.width = 1,
    this.dashes = const [],
    this.cap = StrokeCap.butt,
    this.join = StrokeJoin.miter,
  });
  final Color color;
  final double width;
  final List<double> dashes;
  final StrokeCap cap;
  final StrokeJoin join;
  @override
  List<Object?> get fields => [color, width, dashes, cap, join];
}

enum FontWeight { normal, medium, semibold, bold }

enum FontStyle { normal, italic }

enum TextAnchor { start, middle, end }

enum TextBaseline { alphabetic, middle, hanging }

final class SceneTextStyle with _SceneValue {
  const SceneTextStyle({
    this.fontFamily = 'Arial, sans-serif',
    this.fontSize = 16,
    this.weight = FontWeight.normal,
    this.style = FontStyle.normal,
    this.color = const Color(51, 51, 51),
    this.lineHeight = 1.2,
  });
  final String fontFamily;
  final double fontSize;
  final FontWeight weight;
  final FontStyle style;
  final Color color;
  final double lineHeight;
  @override
  List<Object?> get fields => [fontFamily, fontSize, weight, style, color, lineHeight];
}

enum SemanticRole { diagram, group, node, edge, label, title, legend, icon, annotation, background }

sealed class SceneTransform {
  const SceneTransform();
}

final class Translate extends SceneTransform with _SceneValue {
  const Translate(this.x, this.y);
  final double x;
  final double y;
  @override
  List<Object?> get fields => [x, y];
}

final class Scale extends SceneTransform with _SceneValue {
  const Scale(this.x, [this.y]);
  final double x;
  final double? y;
  @override
  List<Object?> get fields => [x, y];
}

final class Rotate extends SceneTransform with _SceneValue {
  const Rotate(this.degrees, {this.center});
  final double degrees;
  final Point? center;
  @override
  List<Object?> get fields => [degrees, center];
}

final class MatrixTransform extends SceneTransform with _SceneValue {
  const MatrixTransform(this.a, this.b, this.c, this.d, this.e, this.f);
  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;
  @override
  List<Object?> get fields => [a, b, c, d, e, f];
}

sealed class PathCommand {
  const PathCommand();
}

final class MoveTo extends PathCommand with _SceneValue {
  const MoveTo(this.point);
  final Point point;
  @override
  List<Object?> get fields => [point];
}

final class LineTo extends PathCommand with _SceneValue {
  const LineTo(this.point);
  final Point point;
  @override
  List<Object?> get fields => [point];
}

final class CubicTo extends PathCommand with _SceneValue {
  const CubicTo(this.control1, this.control2, this.end);
  final Point control1;
  final Point control2;
  final Point end;
  @override
  List<Object?> get fields => [control1, control2, end];
}

final class QuadraticTo extends PathCommand with _SceneValue {
  const QuadraticTo(this.control, this.end);
  final Point control;
  final Point end;
  @override
  List<Object?> get fields => [control, end];
}

final class ArcTo extends PathCommand with _SceneValue {
  const ArcTo({
    required this.radiusX,
    required this.radiusY,
    this.rotation = 0,
    this.largeArc = false,
    this.clockwise = true,
    required this.end,
  });
  final double radiusX;
  final double radiusY;
  final double rotation;
  final bool largeArc;
  final bool clockwise;
  final Point end;
  @override
  List<Object?> get fields => [radiusX, radiusY, rotation, largeArc, clockwise, end];
}

final class ClosePath extends PathCommand with _SceneValue {
  const ClosePath();
  @override
  List<Object?> get fields => const [];
}

sealed class SceneElement {
  const SceneElement({required this.id, this.role, this.cssClasses = const [], this.label});
  final String id;
  final SemanticRole? role;
  final List<String> cssClasses;
  final String? label;
}

final class SceneGroup extends SceneElement with _SceneValue {
  const SceneGroup({
    required super.id,
    this.children = const [],
    this.transforms = const [],
    super.role,
    super.cssClasses,
    super.label,
  });
  final List<SceneElement> children;
  final List<SceneTransform> transforms;
  @override
  List<Object?> get fields => [id, children, transforms, role, cssClasses, label];
}

final class SceneLine extends SceneElement with _SceneValue {
  const SceneLine({
    required super.id,
    required this.start,
    required this.end,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });
  final Point start;
  final Point end;
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, start, end, stroke, role, cssClasses, label];
}

final class SceneRect extends SceneElement with _SceneValue {
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
  final Bounds bounds;
  final double radiusX;
  final double radiusY;
  final SceneFill? fill;
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, bounds, radiusX, radiusY, fill, stroke, role, cssClasses, label];
}

final class SceneCircle extends SceneElement with _SceneValue {
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
  final Point center;
  final double radius;
  final SceneFill? fill;
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, center, radius, fill, stroke, role, cssClasses, label];
}

final class SceneEllipse extends SceneElement with _SceneValue {
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
  final Point center;
  final double radiusX;
  final double radiusY;
  final SceneFill? fill;
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, center, radiusX, radiusY, fill, stroke, role, cssClasses, label];
}

final class ScenePolygon extends SceneElement with _SceneValue {
  const ScenePolygon({
    required super.id,
    required this.points,
    this.fill,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });
  final List<Point> points;
  final SceneFill? fill;
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, points, fill, stroke, role, cssClasses, label];
}

final class ScenePolyline extends SceneElement with _SceneValue {
  const ScenePolyline({
    required super.id,
    required this.points,
    this.fill,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });
  final List<Point> points;
  final SceneFill? fill;
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, points, fill, stroke, role, cssClasses, label];
}

final class ScenePath extends SceneElement with _SceneValue {
  const ScenePath({
    required super.id,
    required this.commands,
    this.fill,
    this.stroke,
    super.role,
    super.cssClasses,
    super.label,
  });
  final List<PathCommand> commands;
  final SceneFill? fill;
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, commands, fill, stroke, role, cssClasses, label];
}

final class SceneText extends SceneElement with _SceneValue {
  const SceneText({
    required super.id,
    required this.position,
    required this.text,
    required this.bounds,
    this.style = const SceneTextStyle(),
    this.anchor = TextAnchor.start,
    this.baseline = TextBaseline.alphabetic,
    super.role,
    super.cssClasses,
    super.label,
  });
  final Point position;
  final String text;
  final Bounds bounds;
  final SceneTextStyle style;
  final TextAnchor anchor;
  final TextBaseline baseline;
  @override
  List<Object?> get fields => [id, position, text, bounds, style, anchor, baseline, role, cssClasses, label];
}

final class IconGeometry with _SceneValue {
  const IconGeometry({required this.bounds, this.paths = const []});
  final Bounds bounds;
  final List<List<PathCommand>> paths;
  @override
  List<Object?> get fields => [bounds, paths];
}

final class SceneIcon extends SceneElement with _SceneValue {
  const SceneIcon({
    required super.id,
    required this.position,
    required this.geometry,
    this.fill,
    this.stroke,
    super.role = SemanticRole.icon,
    super.cssClasses,
    super.label,
  });
  final Point position;
  final IconGeometry geometry;
  final SceneFill? fill;
  final SceneStroke? stroke;
  @override
  List<Object?> get fields => [id, position, geometry, fill, stroke, role, cssClasses, label];
}

final class SceneClip with _SceneValue {
  const SceneClip({required this.id, required this.path});
  final String id;
  final ScenePath path;
  @override
  List<Object?> get fields => [id, path];
}

final class DiagramScene with _SceneValue {
  const DiagramScene({
    required this.viewport,
    required this.bounds,
    this.background = const Color(255, 255, 255, 0),
    this.title,
    this.description,
    this.accessibilityTitle,
    this.accessibilityDescription,
    this.elements = const [],
    this.clips = const [],
  });
  final Bounds viewport;
  final Bounds bounds;
  final Color background;
  final String? title;
  final String? description;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
  final List<SceneElement> elements;
  final List<SceneClip> clips;
  @override
  List<Object?> get fields => [
    viewport,
    bounds,
    background,
    title,
    description,
    accessibilityTitle,
    accessibilityDescription,
    elements,
    clips,
  ];
}

abstract interface class TextMeasurer {
  Size measure(String text, SceneTextStyle style);
}

final class DeterministicTextMeasurer implements TextMeasurer {
  const DeterministicTextMeasurer({this.averageGlyphWidth = .6});
  final double averageGlyphWidth;

  @override
  Size measure(String text, SceneTextStyle style) {
    final lines = text.split('\n');
    final width = lines.map((line) => line.characters.length).fold(0, (a, b) => a > b ? a : b);
    return Size(width * style.fontSize * averageGlyphWidth, lines.length * style.fontSize * style.lineHeight);
  }
}

abstract interface class IconResolver {
  IconGeometry? resolve(String reference);
}

final class EmptyIconResolver implements IconResolver {
  const EmptyIconResolver();
  @override
  IconGeometry? resolve(String reference) => null;
}

/// Resolves every unknown icon to a deterministic crossed-box placeholder.
final class PlaceholderIconResolver implements IconResolver {
  const PlaceholderIconResolver({this.size = 18});
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
