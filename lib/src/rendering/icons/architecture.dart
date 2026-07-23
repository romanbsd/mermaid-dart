import '../scene.dart';

const _architectureIconBounds = Bounds(left: 0, top: 0, width: 80, height: 80);
const _architectureIconBlue = Color(8, 126, 191);
const _architectureIconWhite = Color(255, 255, 255);
const _architectureIconStroke = SceneStroke(color: _architectureIconWhite, width: 2);
const _architectureIconThinStroke = SceneStroke(color: _architectureIconWhite);

/// Resolves Mermaid.js's bundled Architecture diagram icons.
///
/// Mermaid defines these icons in an 80×80 coordinate space with a `#087ebf`
/// background and white vector details. Explicitly prefixed third-party icon
/// references are left to an injected application resolver.
final class ArchitectureIconResolver implements IconResolver {
  /// Creates the built-in Architecture icon resolver.
  const ArchitectureIconResolver();

  @override
  IconGeometry? resolve(String reference) {
    final name = reference.startsWith('mermaid-architecture:')
        ? reference.substring('mermaid-architecture:'.length)
        : reference.contains(':')
        ? null
        : reference;
    return name == null ? null : _architectureIcons[name];
  }
}

final _architectureIcons = <String, IconGeometry>{
  'cloud': IconGeometry(
    bounds: _architectureIconBounds,
    styledPaths: [
      _background(),
      IconPath(
        commands: const [
          MoveTo(Point(65, 47.5)),
          CubicTo(Point(65, 50.26), Point(62.76, 52.5), Point(60, 52.5)),
          LineTo(Point(20, 52.5)),
          CubicTo(Point(17.24, 52.5), Point(15, 50.26), Point(15, 47.5)),
          CubicTo(Point(15, 45.63), Point(16.03, 43.99), Point(17.56, 43.14)),
          CubicTo(Point(17.52, 42.93), Point(17.5, 42.72), Point(17.5, 42.5)),
          CubicTo(Point(17.5, 39.9), Point(19.98, 37.76), Point(23.15, 37.53)),
          CubicTo(Point(24.8, 33.02), Point(29.49, 29.77), Point(35, 29.77)),
          CubicTo(Point(35.86, 29.77), Point(36.69, 29.85), Point(37.5, 30)),
          CubicTo(Point(39.59, 28.43), Point(42.19, 27.5), Point(45, 27.5)),
          CubicTo(Point(51.1, 27.5), Point(56.19, 31.88), Point(57.28, 37.67)),
          CubicTo(Point(59.42, 38.23), Point(61, 40.18), Point(61, 42.5)),
          CubicTo(Point(61, 42.53), Point(61, 42.57), Point(60.99, 42.6)),
          CubicTo(Point(63.28, 43.06), Point(65, 45.08), Point(65, 47.5)),
          ClosePath(),
        ],
        fill: const NoFill(),
        stroke: _architectureIconStroke,
      ),
    ],
  ),
  'internet': IconGeometry(
    bounds: _architectureIconBounds,
    styledPaths: [
      _background(),
      IconPath(
        commands: [
          ..._ellipse(40, 40, 22.5, 22.5),
          const MoveTo(Point(40, 17.5)),
          const LineTo(Point(40, 62.5)),
          const MoveTo(Point(17.5, 40)),
          const LineTo(Point(62.5, 40)),
          const MoveTo(Point(39.99, 17.51)),
          const CubicTo(Point(24.71, 28.61), Point(24.71, 51.39), Point(39.99, 62.49)),
          const MoveTo(Point(40.01, 17.51)),
          const CubicTo(Point(55.29, 28.61), Point(55.29, 51.39), Point(40.01, 62.49)),
          const MoveTo(Point(19.75, 30.1)),
          const LineTo(Point(60.25, 30.1)),
          const MoveTo(Point(19.75, 49.9)),
          const LineTo(Point(60.25, 49.9)),
        ],
        fill: const NoFill(),
        stroke: _architectureIconStroke,
      ),
    ],
  ),
  'database': IconGeometry(
    bounds: _architectureIconBounds,
    styledPaths: [
      _background(),
      IconPath(
        commands: [
          ..._databaseLevel(57.86),
          ..._databaseLevel(45.95),
          ..._databaseLevel(34.05),
          ..._ellipse(40, 22.14, 20, 7.14),
          const MoveTo(Point(20, 57.86)),
          const LineTo(Point(20, 22.14)),
          const MoveTo(Point(60, 57.86)),
          const LineTo(Point(60, 22.14)),
        ],
        fill: const NoFill(),
        stroke: _architectureIconStroke,
      ),
    ],
  ),
  'server': IconGeometry(
    bounds: _architectureIconBounds,
    styledPaths: [
      _background(),
      IconPath(
        commands: [
          ..._roundedRectangle(17.5, 17.5, 62.5, 62.5, 2),
          const MoveTo(Point(17.5, 32.5)),
          const LineTo(Point(62.5, 32.5)),
          const MoveTo(Point(17.5, 47.5)),
          const LineTo(Point(62.5, 47.5)),
        ],
        fill: const NoFill(),
        stroke: _architectureIconStroke,
      ),
      IconPath(
        commands: const [
          MoveTo(Point(43.75, 25)),
          LineTo(Point(56.25, 25)),
          MoveTo(Point(43.75, 40)),
          LineTo(Point(56.25, 40)),
          MoveTo(Point(43.75, 55)),
          LineTo(Point(56.25, 55)),
        ],
        fill: const NoFill(),
        stroke: _architectureIconThinStroke,
      ),
      IconPath(
        commands: [
          for (final y in const [25.0, 40.0, 55.0])
            for (final x in const [22.5, 27.5, 32.5]) ..._ellipse(x, y, .75, .75),
        ],
        fill: const SolidFill(_architectureIconWhite),
      ),
    ],
  ),
  'disk': IconGeometry(
    bounds: _architectureIconBounds,
    styledPaths: [
      _background(),
      IconPath(
        commands: [
          ..._roundedRectangle(20, 15, 60, 65, 1),
          ..._ellipse(24, 19.17, .8, .83),
          ..._ellipse(56, 19.17, .8, .83),
          ..._ellipse(24, 60.83, .8, .83),
          ..._ellipse(56, 60.83, .8, .83),
          ..._ellipse(40, 33.75, 14, 14.58),
        ],
        fill: const NoFill(),
        stroke: _architectureIconStroke,
      ),
      IconPath(
        commands: [
          ..._ellipse(40, 33.75, 4, 4.17),
          const MoveTo(Point(37.51, 42.52)),
          const LineTo(Point(32.68, 55.74)),
          const CubicTo(Point(32.42, 56.45), Point(31.58, 56.76), Point(30.92, 56.38)),
          const LineTo(Point(26.74, 53.96)),
          const CubicTo(Point(26.08, 53.58), Point(25.93, 52.7), Point(26.41, 52.12)),
          const LineTo(Point(35.42, 41.32)),
          const CubicTo(Point(36.3, 40.27), Point(37.98, 41.24), Point(37.51, 42.52)),
          const ClosePath(),
        ],
        fill: const SolidFill(_architectureIconWhite),
      ),
    ],
  ),
};

IconPath _background() => IconPath(
  commands: const [MoveTo(Point(0, 0)), LineTo(Point(80, 0)), LineTo(Point(80, 80)), LineTo(Point(0, 80)), ClosePath()],
  fill: const SolidFill(_architectureIconBlue),
);

List<PathCommand> _ellipse(double centerX, double centerY, double radiusX, double radiusY) => [
  MoveTo(Point(centerX + radiusX, centerY)),
  ArcTo(radiusX: radiusX, radiusY: radiusY, largeArc: true, end: Point(centerX - radiusX, centerY)),
  ArcTo(radiusX: radiusX, radiusY: radiusY, largeArc: true, end: Point(centerX + radiusX, centerY)),
  const ClosePath(),
];

List<PathCommand> _databaseLevel(double y) => [
  MoveTo(Point(20, y)),
  CubicTo(Point(20, y + 3.94), Point(28.95, y + 7.14), Point(40, y + 7.14)),
  CubicTo(Point(51.05, y + 7.14), Point(60, y + 3.94), Point(60, y)),
];

List<PathCommand> _roundedRectangle(double left, double top, double right, double bottom, double radius) => [
  MoveTo(Point(left + radius, top)),
  LineTo(Point(right - radius, top)),
  QuadraticTo(Point(right, top), Point(right, top + radius)),
  LineTo(Point(right, bottom - radius)),
  QuadraticTo(Point(right, bottom), Point(right - radius, bottom)),
  LineTo(Point(left + radius, bottom)),
  QuadraticTo(Point(left, bottom), Point(left, bottom - radius)),
  LineTo(Point(left, top + radius)),
  QuadraticTo(Point(left, top), Point(left + radius, top)),
  const ClosePath(),
];
