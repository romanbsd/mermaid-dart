import 'dart:math' as math;

import 'package:mermaid_dart/src/rendering/geometry/polar.dart';
import 'package:mermaid_dart/src/rendering/scene.dart';
import 'package:test/test.dart';

void main() {
  group('polar geometry', () {
    test('evenly spaced angles start at twelve o’clock and complete one turn', () {
      expect(evenlySpacedAngle(0, 4), topAngleRadians);
      expect(evenlySpacedAngle(1, 4), 0);
      expect(evenlySpacedAngle(2, 4), math.pi / 2);
      expect(evenlySpacedAngle(3, 4), math.pi);
      expect(evenlySpacedAngle(4, 4), topAngleRadians + fullTurnRadians);
    });

    test('rejects a non-positive position count', () {
      expect(() => evenlySpacedAngle(0, 0), throwsArgumentError);
      expect(() => evenlySpacedAngle(0, -1), throwsArgumentError);
    });

    test('projects radius and angle around an arbitrary center', () {
      const center = Point(10, 20);

      expect(polarPoint(center, 5, 0), const Point(15, 20));
      final bottom = polarPoint(center, 5, math.pi / 2);
      expect(bottom.x, closeTo(10, 1e-12));
      expect(bottom.y, closeTo(25, 1e-12));
    });
  });
}
