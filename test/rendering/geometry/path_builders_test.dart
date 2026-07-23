import 'dart:math' as math;

import 'package:mermaid_dart/src/rendering/geometry/path_builders.dart';
import 'package:mermaid_dart/src/rendering/geometry/polar.dart';
import 'package:mermaid_dart/src/rendering/scene.dart';
import 'package:test/test.dart';

void main() {
  group('typed path builders', () {
    test('annularSectorPath builds a partial pie wedge', () {
      final commands = annularSectorPath(
        center: const Point(10, 20),
        outerRadius: 10,
        innerRadius: 0,
        startAngle: 0,
        endAngle: math.pi / 2,
      );

      expect(commands, hasLength(4));
      expect((commands.first as MoveTo).point, const Point(20, 20));
      final arc = commands[1] as ArcTo;
      expect(arc.largeArc, isFalse);
      expect(arc.clockwise, isTrue);
      expect(arc.end.x, closeTo(10, 1e-12));
      expect(arc.end.y, closeTo(30, 1e-12));
      expect((commands[2] as LineTo).point, const Point(10, 20));
      expect(commands.last, const ClosePath());
    });

    test('annularSectorPath reverses the inner edge of a large donut sector', () {
      final commands = annularSectorPath(
        center: const Point(0, 0),
        outerRadius: 10,
        innerRadius: 4,
        startAngle: 0,
        endAngle: math.pi * 3 / 2,
      );

      expect(commands, hasLength(5));
      final outerArc = commands[1] as ArcTo;
      final innerArc = commands[3] as ArcTo;
      expect(outerArc.largeArc, isTrue);
      expect(outerArc.clockwise, isTrue);
      expect(innerArc.largeArc, isTrue);
      expect(innerArc.clockwise, isFalse);
      expect(innerArc.end, const Point(4, 0));
    });

    test('annularSectorPath splits a full donut into SVG-compatible half arcs', () {
      final commands = annularSectorPath(
        center: const Point(5, 7),
        outerRadius: 10,
        innerRadius: 4,
        startAngle: topAngleRadians,
        endAngle: topAngleRadians + fullTurnRadians,
      );
      final arcs = commands.whereType<ArcTo>().toList();

      expect(commands, hasLength(7));
      expect(arcs, hasLength(4));
      expect(arcs.take(2).every((arc) => arc.clockwise), isTrue);
      expect(arcs.skip(2).every((arc) => !arc.clockwise), isTrue);
      expect(arcs.every((arc) => !arc.largeArc), isTrue);
      expect(arcs[2].end.x, closeTo(5, 1e-12));
      expect(arcs[2].end.y, closeTo(11, 1e-12));
      expect(arcs[3].end.x, closeTo(5, 1e-12));
      expect(arcs[3].end.y, closeTo(3, 1e-12));
      expect(commands.last, const ClosePath());
    });

    test('closedCubicSplinePath closes a deterministic cubic loop', () {
      final commands = closedCubicSplinePath(const [
        Point(0, 0),
        Point(10, 0),
        Point(10, 10),
        Point(0, 10),
      ], tension: .2);

      expect(commands, hasLength(6));
      expect(commands.first, const MoveTo(Point(0, 0)));
      final firstCurve = commands[1] as CubicTo;
      expect(firstCurve.control1, const Point(2, -2));
      expect(firstCurve.control2, const Point(8, -2));
      expect(firstCurve.end, const Point(10, 0));
      expect(commands.whereType<CubicTo>(), hasLength(4));
      expect(commands.last, const ClosePath());
    });

    test('closedCubicSplinePath leaves an empty point set empty', () {
      expect(closedCubicSplinePath(const [], tension: .2), isEmpty);
    });
  });
}
