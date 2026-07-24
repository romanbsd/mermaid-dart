import 'package:mermaid_dart/src/rendering/geometry/direction.dart';
import 'package:mermaid_dart/src/rendering/scene.dart';
import 'package:test/test.dart';

void main() {
  group('direction geometry', () {
    test('measures a unit direction and its segment length', () {
      final direction = Direction.between(const Point(1, 2), const Point(4, 6));

      expect(direction.distance, 5);
      expect(direction.x, 0.6);
      expect(direction.y, 0.8);
    });

    test('rotates the perpendicular a quarter turn from the direction', () {
      final direction = Direction.between(const Point(0, 0), const Point(1, 0));

      expect(direction.perpendicularX, 0);
      expect(direction.perpendicularY, 1);
    });

    test('falls back to the positive x axis for coincident points', () {
      final direction = Direction.between(const Point(3, 3), const Point(3, 3));

      expect(direction.distance, 0);
      expect(direction.x, 1);
      expect(direction.y, 0);
    });

    test('offsets along the direction and across its perpendicular', () {
      final direction = Direction.between(const Point(0, 0), const Point(0, 10));

      expect(direction.from(const Point(0, 0), 4), const Point(0, 4));
      expect(direction.from(const Point(0, 0), 4, 3), const Point(-3, 4));
      expect(direction.from(const Point(0, 0), 4, -3), const Point(3, 4));
    });

    test('walks toward a target but holds still when the points coincide', () {
      expect(pointToward(const Point(0, 0), const Point(10, 0), 4), const Point(4, 0));
      expect(pointToward(const Point(7, 7), const Point(7, 7), 4), const Point(7, 7));
    });
  });
}
