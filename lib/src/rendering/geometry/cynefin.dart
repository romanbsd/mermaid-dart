import '../scene.dart';

double cynefinSeededRandom(int seed) {
  var t = _int32(seed + 0x6d2b79f5);
  t = _imul(t ^ (_uint32(t) >> 15), t | 1);
  t = _int32(t ^ _int32(t + _imul(t ^ (_uint32(t) >> 7), t | 61)));
  return _uint32(t ^ (_uint32(t) >> 14)) / 4294967296;
}

int cynefinHashString(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = _int32((hash << 5) - hash + codeUnit);
  }
  return hash;
}

List<PathCommand> generateCynefinFoldPath(
  double width,
  double height,
  int seed, {
  double? amplitude,
  double offsetX = 0,
  double offsetY = 0,
}) {
  final centerX = width / 2;
  final resolvedAmplitude = amplitude ?? width * .015;
  const segments = 7;
  final segmentHeight = height / segments;
  final points = <Point>[
    for (var i = 0; i <= segments; i++)
      Point(
        offsetX + centerX + cynefinSeededRandom(seed + i * 17) * resolvedAmplitude * 2 - resolvedAmplitude,
        offsetY + i * segmentHeight,
      ),
  ];
  return <PathCommand>[
    MoveTo(points.first),
    for (var i = 0; i < points.length - 1; i++)
      CubicTo(
        Point(
          points[i].x + resolvedAmplitude * 1.5 * (i.isEven ? 1 : -1) * cynefinSeededRandom(seed + i * 31 + 7),
          (points[i].y + points[i + 1].y) / 2,
        ),
        Point(
          points[i + 1].x - resolvedAmplitude * 1.5 * (i.isEven ? 1 : -1) * cynefinSeededRandom(seed + i * 31 + 7),
          (points[i].y + points[i + 1].y) / 2,
        ),
        points[i + 1],
      ),
  ];
}

List<PathCommand> generateCynefinHorizontalPath(
  double width,
  double height,
  int seed, {
  double? amplitude,
  double offsetX = 0,
  double offsetY = 0,
}) {
  final centerY = height / 2;
  final resolvedAmplitude = amplitude ?? height * .015;
  const segments = 7;
  final segmentWidth = width / segments;
  final points = <Point>[
    for (var i = 0; i <= segments; i++)
      Point(
        offsetX + i * segmentWidth,
        offsetY + centerY + cynefinSeededRandom(seed + i * 23) * resolvedAmplitude * 2 - resolvedAmplitude,
      ),
  ];
  return <PathCommand>[
    MoveTo(points.first),
    for (var i = 0; i < points.length - 1; i++)
      CubicTo(
        Point(
          (points[i].x + points[i + 1].x) / 2,
          points[i].y + resolvedAmplitude * 1.5 * (i.isEven ? 1 : -1) * cynefinSeededRandom(seed + i * 37 + 11),
        ),
        Point(
          (points[i].x + points[i + 1].x) / 2,
          points[i + 1].y - resolvedAmplitude * 1.5 * (i.isEven ? 1 : -1) * cynefinSeededRandom(seed + i * 37 + 11),
        ),
        points[i + 1],
      ),
  ];
}

List<PathCommand> generateCynefinCliffPath(double width, double height, {double offsetX = 0, double offsetY = 0}) {
  final centerX = offsetX + width / 2;
  final top = offsetY + height * .5;
  final bottom = offsetY + height;
  final amplitude = width * .03;
  final range = bottom - top;
  return [
    MoveTo(Point(centerX, top)),
    CubicTo(
      Point(centerX + amplitude, top + range * .2),
      Point(centerX - amplitude * 1.5, top + range * .55),
      Point(centerX + amplitude * .5, top + range * .75),
    ),
    CubicTo(
      Point(centerX - amplitude, top + range * .85),
      Point(centerX + amplitude * .3, top + range * .95),
      Point(centerX, bottom),
    ),
  ];
}

List<PathCommand> generateCynefinConfusionPath(double centerX, double centerY, double radiusX, double radiusY) => [
  MoveTo(Point(centerX - radiusX, centerY)),
  ArcTo(radiusX: radiusX, radiusY: radiusY, largeArc: true, end: Point(centerX + radiusX, centerY)),
  ArcTo(radiusX: radiusX, radiusY: radiusY, largeArc: true, end: Point(centerX - radiusX, centerY)),
  const ClosePath(),
];

int _uint32(int value) => value & 0xffffffff;

int _int32(int value) {
  final unsigned = _uint32(value);
  return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
}

int _imul(int left, int right) => _int32(_uint32(left) * _uint32(right));
