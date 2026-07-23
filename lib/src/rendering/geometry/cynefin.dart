import '../scene.dart';

// Mermaid uses Mulberry32-compatible seeded noise so CLI and browser renders
// produce identical fold paths.
const _cynefinRandomIncrement = 0x6d2b79f5;
const _cynefinRandomFirstShift = 15;
const _cynefinRandomSecondShift = 7;
const _cynefinRandomFinalShift = 14;
const _cynefinRandomSecondMultiplier = 61;
const _cynefinRandomOddMask = 1;
const _cynefinUint32Range = 4294967296;
const _cynefinHashShift = 5;
const _cynefinUint32Mask = 0xffffffff;
const _cynefinInt32SignBit = 0x80000000;

// Fixed boundary sampling and shaping parameters from Mermaid's renderer.
const _cynefinBoundarySegments = 7;
const _cynefinBoundaryAmplitudeScale = .015;
const _cynefinBoundaryControlScale = 1.5;
const _cynefinVerticalPointSeedStep = 17;
const _cynefinVerticalControlSeedStep = 31;
const _cynefinVerticalControlSeedOffset = 7;
const _cynefinHorizontalPointSeedStep = 23;
const _cynefinHorizontalControlSeedStep = 37;
const _cynefinHorizontalControlSeedOffset = 11;

// The lower fold is a fixed two-curve cliff profile.
const _cynefinCliffTopRatio = .5;
const _cynefinCliffAmplitudeScale = .03;
const _cynefinCliffFirstControlRatio = .2;
const _cynefinCliffSecondControlRatio = .55;
const _cynefinCliffFirstEndRatio = .75;
const _cynefinCliffThirdControlRatio = .85;
const _cynefinCliffFourthControlRatio = .95;
const _cynefinCliffSecondControlScale = 1.5;
const _cynefinCliffFirstEndScale = .5;
const _cynefinCliffFourthControlScale = .3;

double cynefinSeededRandom(int seed) {
  var t = _int32(seed + _cynefinRandomIncrement);
  t = _imul(t ^ (_uint32(t) >> _cynefinRandomFirstShift), t | _cynefinRandomOddMask);
  t = _int32(t ^ _int32(t + _imul(t ^ (_uint32(t) >> _cynefinRandomSecondShift), t | _cynefinRandomSecondMultiplier)));
  return _uint32(t ^ (_uint32(t) >> _cynefinRandomFinalShift)) / _cynefinUint32Range;
}

int cynefinHashString(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = _int32((hash << _cynefinHashShift) - hash + codeUnit);
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
}) => _generateCynefinBoundaryPath(
  width,
  height,
  seed,
  orientation: _CynefinBoundaryOrientation.vertical,
  amplitude: amplitude,
  offsetX: offsetX,
  offsetY: offsetY,
);

List<PathCommand> generateCynefinHorizontalPath(
  double width,
  double height,
  int seed, {
  double? amplitude,
  double offsetX = 0,
  double offsetY = 0,
}) => _generateCynefinBoundaryPath(
  width,
  height,
  seed,
  orientation: _CynefinBoundaryOrientation.horizontal,
  amplitude: amplitude,
  offsetX: offsetX,
  offsetY: offsetY,
);

List<PathCommand> generateCynefinCliffPath(double width, double height, {double offsetX = 0, double offsetY = 0}) {
  final centerX = offsetX + width / 2;
  final top = offsetY + height * _cynefinCliffTopRatio;
  final bottom = offsetY + height;
  final amplitude = width * _cynefinCliffAmplitudeScale;
  final range = bottom - top;
  return [
    MoveTo(Point(centerX, top)),
    CubicTo(
      Point(centerX + amplitude, top + range * _cynefinCliffFirstControlRatio),
      Point(centerX - amplitude * _cynefinCliffSecondControlScale, top + range * _cynefinCliffSecondControlRatio),
      Point(centerX + amplitude * _cynefinCliffFirstEndScale, top + range * _cynefinCliffFirstEndRatio),
    ),
    CubicTo(
      Point(centerX - amplitude, top + range * _cynefinCliffThirdControlRatio),
      Point(centerX + amplitude * _cynefinCliffFourthControlScale, top + range * _cynefinCliffFourthControlRatio),
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

List<PathCommand> _generateCynefinBoundaryPath(
  double width,
  double height,
  int seed, {
  required _CynefinBoundaryOrientation orientation,
  double? amplitude,
  required double offsetX,
  required double offsetY,
}) {
  final vertical = orientation.isVertical;
  final primaryExtent = vertical ? height : width;
  final crossExtent = vertical ? width : height;
  final resolvedAmplitude = amplitude ?? crossExtent * _cynefinBoundaryAmplitudeScale;
  final segmentExtent = primaryExtent / _cynefinBoundarySegments;
  final pointSeedStep = vertical ? _cynefinVerticalPointSeedStep : _cynefinHorizontalPointSeedStep;
  final controlSeedStep = vertical ? _cynefinVerticalControlSeedStep : _cynefinHorizontalControlSeedStep;
  final controlSeedOffset = vertical ? _cynefinVerticalControlSeedOffset : _cynefinHorizontalControlSeedOffset;

  Point point(double primary, double cross) =>
      vertical ? Point(offsetX + cross, offsetY + primary) : Point(offsetX + primary, offsetY + cross);

  final points = <Point>[
    for (var i = 0; i <= _cynefinBoundarySegments; i++)
      point(
        i * segmentExtent,
        crossExtent / 2 + cynefinSeededRandom(seed + i * pointSeedStep) * resolvedAmplitude * 2 - resolvedAmplitude,
      ),
  ];
  return [
    MoveTo(points.first),
    for (var i = 0; i < points.length - 1; i++)
      _cynefinBoundaryCurve(
        points[i],
        points[i + 1],
        vertical: vertical,
        bend:
            resolvedAmplitude *
            _cynefinBoundaryControlScale *
            (i.isEven ? 1 : -1) *
            cynefinSeededRandom(seed + i * controlSeedStep + controlSeedOffset),
      ),
  ];
}

CubicTo _cynefinBoundaryCurve(Point start, Point end, {required bool vertical, required double bend}) {
  final midpoint = Point((start.x + end.x) / 2, (start.y + end.y) / 2);
  return vertical
      ? CubicTo(Point(start.x + bend, midpoint.y), Point(end.x - bend, midpoint.y), end)
      : CubicTo(Point(midpoint.x, start.y + bend), Point(midpoint.x, end.y - bend), end);
}

int _uint32(int value) => value & _cynefinUint32Mask;

int _int32(int value) {
  final unsigned = _uint32(value);
  return unsigned >= _cynefinInt32SignBit ? unsigned - _cynefinUint32Range : unsigned;
}

int _imul(int left, int right) => _int32(_uint32(left) * _uint32(right));

enum _CynefinBoundaryOrientation {
  vertical,
  horizontal;

  bool get isVertical => this == vertical;
}
