import 'dart:math' as math;

import '../scene.dart';

const _fullCircleRadians = math.pi * 2;
const _degreesPerHalfTurn = 180.0;

// Floating-point trigonometry can place an analytically exact arc extremum a
// few ulps outside its sweep. This tolerance is angular and measured in radians.
const _arcAngleTolerance = 1e-12;

/// Returns the backend-neutral geometry bounds of [elements].
///
/// Set [includeText] to false when a renderer has already accounted for text
/// through dedicated measured layout boxes.
Bounds? sceneGeometryBounds(Iterable<SceneElement> elements, {bool includeText = true}) {
  final bounds = _BoundsAccumulator();
  for (final element in elements) {
    bounds.addBounds(sceneElementGeometryBounds(element, includeText: includeText));
  }
  return bounds.value;
}

/// Returns the backend-neutral geometry bounds of [element].
///
/// Stroke width is intentionally excluded, matching SVG's default geometric
/// bounding-box behavior.
Bounds? sceneElementGeometryBounds(SceneElement element, {bool includeText = true}) => switch (element) {
  SceneGroup(:final children, :final transforms) => switch (sceneGeometryBounds(children, includeText: includeText)) {
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
  ScenePath(:final commands) => pathBounds(commands),
  SceneText(:final bounds) => includeText ? bounds : null,
  SceneIcon(:final position, :final geometry) => geometry.bounds.translated(position.x, position.y),
};

/// Calculates exact axis-aligned bounds for an SVG-style typed path.
///
/// Quadratic and cubic extrema are found from their derivatives. Elliptical
/// arcs use the SVG endpoint-to-center conversion and include every rotated
/// ellipse extremum that lies within the selected sweep.
Bounds? pathBounds(Iterable<PathCommand> commands) {
  final bounds = _BoundsAccumulator();
  var current = const Point(0, 0);
  var subpathStart = current;
  var hasCurrentSubpath = false;

  for (final command in commands) {
    switch (command) {
      case MoveTo(:final point):
        current = point;
        subpathStart = point;
        hasCurrentSubpath = true;
        bounds.addPoint(point);
      case LineTo(:final point):
        bounds
          ..addPoint(current)
          ..addPoint(point);
        current = point;
      case QuadraticTo(:final control, :final end):
        _addQuadraticBounds(bounds, current, control, end);
        current = end;
      case CubicTo(:final control1, :final control2, :final end):
        _addCubicBounds(bounds, current, control1, control2, end);
        current = end;
      case ArcTo(:final radiusX, :final radiusY, :final rotation, :final largeArc, :final clockwise, :final end):
        _addArcBounds(
          bounds,
          current,
          end,
          radiusX: radiusX,
          radiusY: radiusY,
          rotation: rotation,
          largeArc: largeArc,
          clockwise: clockwise,
        );
        current = end;
      case ClosePath():
        if (hasCurrentSubpath) {
          bounds
            ..addPoint(current)
            ..addPoint(subpathStart);
          current = subpathStart;
        }
    }
  }
  return bounds.value;
}

void _addQuadraticBounds(_BoundsAccumulator bounds, Point start, Point control, Point end) {
  bounds
    ..addPoint(start)
    ..addPoint(end);
  final parameters = <double>{
    ..._quadraticExtrema(start.x, control.x, end.x),
    ..._quadraticExtrema(start.y, control.y, end.y),
  };
  for (final parameter in parameters) {
    bounds.addPoint(_quadraticPoint(start, control, end, parameter));
  }
}

Iterable<double> _quadraticExtrema(double start, double control, double end) sync* {
  final denominator = start - 2 * control + end;
  if (denominator == 0) return;
  final parameter = (start - control) / denominator;
  if (parameter > 0 && parameter < 1) yield parameter;
}

Point _quadraticPoint(Point start, Point control, Point end, double parameter) {
  final remaining = 1 - parameter;
  return Point(
    remaining * remaining * start.x + 2 * remaining * parameter * control.x + parameter * parameter * end.x,
    remaining * remaining * start.y + 2 * remaining * parameter * control.y + parameter * parameter * end.y,
  );
}

void _addCubicBounds(_BoundsAccumulator bounds, Point start, Point control1, Point control2, Point end) {
  bounds
    ..addPoint(start)
    ..addPoint(end);
  final parameters = <double>{
    ..._cubicExtrema(start.x, control1.x, control2.x, end.x),
    ..._cubicExtrema(start.y, control1.y, control2.y, end.y),
  };
  for (final parameter in parameters) {
    bounds.addPoint(_cubicPoint(start, control1, control2, end, parameter));
  }
}

Iterable<double> _cubicExtrema(double start, double control1, double control2, double end) sync* {
  final cubic = -start + 3 * control1 - 3 * control2 + end;
  final quadratic = 3 * start - 6 * control1 + 3 * control2;
  final linear = -3 * start + 3 * control1;
  yield* _unitIntervalQuadraticRoots(3 * cubic, 2 * quadratic, linear);
}

Iterable<double> _unitIntervalQuadraticRoots(double quadratic, double linear, double constant) sync* {
  if (quadratic == 0) {
    if (linear == 0) return;
    final root = -constant / linear;
    if (root > 0 && root < 1) yield root;
    return;
  }
  final discriminant = linear * linear - 4 * quadratic * constant;
  if (discriminant < 0) return;
  final root = math.sqrt(discriminant);
  final denominator = 2 * quadratic;
  final first = (-linear + root) / denominator;
  final second = (-linear - root) / denominator;
  if (first > 0 && first < 1) yield first;
  if (second > 0 && second < 1 && second != first) yield second;
}

Point _cubicPoint(Point start, Point control1, Point control2, Point end, double parameter) {
  final remaining = 1 - parameter;
  final remainingSquared = remaining * remaining;
  final parameterSquared = parameter * parameter;
  return Point(
    remainingSquared * remaining * start.x +
        3 * remainingSquared * parameter * control1.x +
        3 * remaining * parameterSquared * control2.x +
        parameterSquared * parameter * end.x,
    remainingSquared * remaining * start.y +
        3 * remainingSquared * parameter * control1.y +
        3 * remaining * parameterSquared * control2.y +
        parameterSquared * parameter * end.y,
  );
}

void _addArcBounds(
  _BoundsAccumulator bounds,
  Point start,
  Point end, {
  required double radiusX,
  required double radiusY,
  required double rotation,
  required bool largeArc,
  required bool clockwise,
}) {
  bounds
    ..addPoint(start)
    ..addPoint(end);
  if (start == end) return;

  var horizontalRadius = radiusX.abs();
  var verticalRadius = radiusY.abs();
  if (horizontalRadius == 0 || verticalRadius == 0) return;

  final rotationRadians = rotation * math.pi / _degreesPerHalfTurn;
  final cosine = math.cos(rotationRadians);
  final sine = math.sin(rotationRadians);
  final midpointDeltaX = (start.x - end.x) / 2;
  final midpointDeltaY = (start.y - end.y) / 2;
  final transformedStartX = cosine * midpointDeltaX + sine * midpointDeltaY;
  final transformedStartY = -sine * midpointDeltaX + cosine * midpointDeltaY;

  final radiusScale =
      transformedStartX * transformedStartX / (horizontalRadius * horizontalRadius) +
      transformedStartY * transformedStartY / (verticalRadius * verticalRadius);
  if (radiusScale > 1) {
    final scale = math.sqrt(radiusScale);
    horizontalRadius *= scale;
    verticalRadius *= scale;
  }

  final horizontalRadiusSquared = horizontalRadius * horizontalRadius;
  final verticalRadiusSquared = verticalRadius * verticalRadius;
  final transformedStartXSquared = transformedStartX * transformedStartX;
  final transformedStartYSquared = transformedStartY * transformedStartY;
  final centerDenominator =
      horizontalRadiusSquared * transformedStartYSquared + verticalRadiusSquared * transformedStartXSquared;
  final centerNumerator =
      horizontalRadiusSquared * verticalRadiusSquared -
      horizontalRadiusSquared * transformedStartYSquared -
      verticalRadiusSquared * transformedStartXSquared;
  final centerScaleSign = largeArc == clockwise ? -1.0 : 1.0;
  final centerScale = centerScaleSign * math.sqrt(math.max(0, centerNumerator / centerDenominator));
  final transformedCenterX = centerScale * horizontalRadius * transformedStartY / verticalRadius;
  final transformedCenterY = -centerScale * verticalRadius * transformedStartX / horizontalRadius;
  final center = Point(
    cosine * transformedCenterX - sine * transformedCenterY + (start.x + end.x) / 2,
    sine * transformedCenterX + cosine * transformedCenterY + (start.y + end.y) / 2,
  );

  final startVector = Point(
    (transformedStartX - transformedCenterX) / horizontalRadius,
    (transformedStartY - transformedCenterY) / verticalRadius,
  );
  final endVector = Point(
    (-transformedStartX - transformedCenterX) / horizontalRadius,
    (-transformedStartY - transformedCenterY) / verticalRadius,
  );
  final startAngle = math.atan2(startVector.y, startVector.x);
  var sweepAngle = _vectorAngle(startVector, endVector);
  if (clockwise && sweepAngle < 0) {
    sweepAngle += _fullCircleRadians;
  } else if (!clockwise && sweepAngle > 0) {
    sweepAngle -= _fullCircleRadians;
  }

  final horizontalExtremum = math.atan2(-verticalRadius * sine, horizontalRadius * cosine);
  final verticalExtremum = math.atan2(verticalRadius * cosine, horizontalRadius * sine);
  for (final angle in [
    horizontalExtremum,
    horizontalExtremum + math.pi,
    verticalExtremum,
    verticalExtremum + math.pi,
  ]) {
    if (_angleIsInSweep(angle, startAngle, sweepAngle)) {
      bounds.addPoint(_ellipsePoint(center, horizontalRadius, verticalRadius, rotationRadians, angle));
    }
  }
}

double _vectorAngle(Point start, Point end) =>
    math.atan2(start.x * end.y - start.y * end.x, start.x * end.x + start.y * end.y);

bool _angleIsInSweep(double angle, double start, double sweep) {
  final distance = sweep >= 0 ? _normalizeAngle(angle - start) : _normalizeAngle(start - angle);
  return distance <= sweep.abs() + _arcAngleTolerance;
}

double _normalizeAngle(double angle) {
  final normalized = angle % _fullCircleRadians;
  return normalized < 0 ? normalized + _fullCircleRadians : normalized;
}

Point _ellipsePoint(Point center, double radiusX, double radiusY, double rotation, double angle) {
  final cosineRotation = math.cos(rotation);
  final sineRotation = math.sin(rotation);
  final cosineAngle = math.cos(angle);
  final sineAngle = math.sin(angle);
  return Point(
    center.x + radiusX * cosineRotation * cosineAngle - radiusY * sineRotation * sineAngle,
    center.y + radiusX * sineRotation * cosineAngle + radiusY * cosineRotation * sineAngle,
  );
}

Bounds _transformBounds(Bounds bounds, List<SceneTransform> transforms) => _pointsBounds(
  [
    Point(bounds.left, bounds.top),
    Point(bounds.right, bounds.top),
    Point(bounds.right, bounds.bottom),
    Point(bounds.left, bounds.bottom),
  ].map((point) => transforms.reversed.fold(point, _transformPoint)),
)!;

Point _transformPoint(Point point, SceneTransform transform) => switch (transform) {
  Translate(:final x, :final y) => Point(point.x + x, point.y + y),
  Scale(:final x, :final y) => Point(point.x * x, point.y * (y ?? x)),
  Rotate(:final degrees, :final center) => () {
    final origin = center ?? const Point(0, 0);
    final radians = degrees * math.pi / _degreesPerHalfTurn;
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

Bounds? _pointsBounds(Iterable<Point> points) {
  final bounds = _BoundsAccumulator();
  for (final point in points) {
    bounds.addPoint(point);
  }
  return bounds.value;
}

final class _BoundsAccumulator {
  double? _left;
  double? _right;
  double? _top;
  double? _bottom;

  void addPoint(Point point) {
    _left = _left == null ? point.x : math.min(_left!, point.x);
    _right = _right == null ? point.x : math.max(_right!, point.x);
    _top = _top == null ? point.y : math.min(_top!, point.y);
    _bottom = _bottom == null ? point.y : math.max(_bottom!, point.y);
  }

  void addBounds(Bounds? bounds) {
    if (bounds == null) return;
    addPoint(Point(bounds.left, bounds.top));
    addPoint(Point(bounds.right, bounds.bottom));
  }

  Bounds? get value => switch ((_left, _right, _top, _bottom)) {
    (final left?, final right?, final top?, final bottom?) => Bounds(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    ),
    _ => null,
  };
}
