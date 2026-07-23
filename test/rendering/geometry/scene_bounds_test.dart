import 'dart:math' as math;

import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('pathBounds', () {
    test('uses quadratic and cubic extrema instead of control-point bounds', () {
      expect(
        pathBounds(const [MoveTo(Point(0, 0)), QuadraticTo(Point(10, 20), Point(20, 0))]),
        const Bounds(left: 0, top: 0, width: 20, height: 10),
      );
      expect(
        pathBounds(const [MoveTo(Point(0, 0)), CubicTo(Point(0, 30), Point(30, 30), Point(30, 0))]),
        const Bounds(left: 0, top: 0, width: 30, height: 22.5),
      );
    });

    test('includes SVG arc extrema for both sweep directions', () {
      _expectBoundsClose(
        pathBounds(const [MoveTo(Point(0, 0)), ArcTo(radiusX: 10, radiusY: 20, clockwise: true, end: Point(20, 0))])!,
        const Bounds(left: 0, top: -20, width: 20, height: 20),
      );
      _expectBoundsClose(
        pathBounds(const [MoveTo(Point(0, 0)), ArcTo(radiusX: 10, radiusY: 20, clockwise: false, end: Point(20, 0))])!,
        const Bounds(left: 0, top: 0, width: 20, height: 20),
      );
    });

    test('bounds a complete rotated ellipse assembled from two arcs', () {
      final endpoint = Point(10 * math.cos(math.pi / 6), 10 * math.sin(math.pi / 6));
      final bounds = pathBounds([
        MoveTo(endpoint),
        ArcTo(radiusX: 10, radiusY: 20, rotation: 30, clockwise: true, end: Point(-endpoint.x, -endpoint.y)),
        ArcTo(radiusX: 10, radiusY: 20, rotation: 30, clockwise: true, end: endpoint),
      ])!;
      final horizontalRadius = math.sqrt(175);
      final verticalRadius = math.sqrt(325);

      expect(bounds.left, closeTo(-horizontalRadius, 1e-9));
      expect(bounds.right, closeTo(horizontalRadius, 1e-9));
      expect(bounds.top, closeTo(-verticalRadius, 1e-9));
      expect(bounds.bottom, closeTo(verticalRadius, 1e-9));
    });

    test('honors the large-arc flag and SVG radius correction', () {
      _expectBoundsClose(
        pathBounds(const [
          MoveTo(Point(10, 0)),
          ArcTo(radiusX: 10, radiusY: 10, largeArc: true, clockwise: true, end: Point(0, 10)),
        ])!,
        const Bounds(left: 0, top: 0, width: 20, height: 20),
      );
      _expectBoundsClose(
        pathBounds(const [MoveTo(Point(0, 0)), ArcTo(radiusX: 10, radiusY: 5, clockwise: true, end: Point(30, 0))])!,
        const Bounds(left: 0, top: -7.5, width: 30, height: 7.5),
      );
    });

    test('handles close paths, empty paths, and degenerate arcs', () {
      expect(pathBounds(const []), isNull);
      expect(
        pathBounds(const [MoveTo(Point(5, 5)), LineTo(Point(10, 10)), ClosePath()]),
        const Bounds(left: 5, top: 5, width: 5, height: 5),
      );
      expect(
        pathBounds(const [MoveTo(Point(2, 3)), ArcTo(radiusX: 0, radiusY: 10, end: Point(8, 9))]),
        const Bounds(left: 2, top: 3, width: 6, height: 6),
      );
    });
  });

  test('sceneGeometryBounds applies group transforms to exact path bounds', () {
    final bounds = sceneGeometryBounds(const [
      SceneGroup(
        id: 'curve-group',
        transforms: [Translate(5, 7), Scale(2)],
        children: [
          ScenePath(id: 'curve', commands: [MoveTo(Point(0, 0)), QuadraticTo(Point(10, 20), Point(20, 0))]),
        ],
      ),
    ]);

    expect(bounds, const Bounds(left: 5, top: 7, width: 40, height: 20));
  });

  test('sceneGeometryBounds includes measured text unless explicitly excluded', () {
    const text = SceneText(
      id: 'label',
      position: Point(10, 20),
      text: 'label',
      bounds: Bounds(left: 10, top: 12, width: 40, height: 16),
    );

    expect(sceneGeometryBounds(const [text]), text.bounds);
    expect(sceneGeometryBounds(const [text], includeText: false), isNull);
  });
}

void _expectBoundsClose(Bounds actual, Bounds expected) {
  expect(actual.left, closeTo(expected.left, 1e-9));
  expect(actual.top, closeTo(expected.top, 1e-9));
  expect(actual.width, closeTo(expected.width, 1e-9));
  expect(actual.height, closeTo(expected.height, 1e-9));
}
