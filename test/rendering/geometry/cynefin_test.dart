import 'package:mermaid_dart/src/rendering/geometry/cynefin.dart';
import 'package:mermaid_dart/src/rendering/scene.dart';
import 'package:test/test.dart';

void main() {
  group('Cynefin geometry', () {
    test('seeded random and string hashes are deterministic', () {
      expect(cynefinSeededRandom(42), cynefinSeededRandom(42));
      expect(cynefinSeededRandom(42), isNot(cynefinSeededRandom(43)));
      expect(cynefinHashString('cynefin'), cynefinHashString('cynefin'));
      expect(cynefinHashString('cynefin'), isNot(cynefinHashString('Cynefin')));
    });

    test('fold and horizontal boundaries contain seven cubic segments', () {
      final fold = generateCynefinFoldPath(800, 600, 42);
      final horizontal = generateCynefinHorizontalPath(800, 600, 42);

      for (final path in [fold, horizontal]) {
        expect(path.first, isA<MoveTo>());
        expect(path.whereType<CubicTo>(), hasLength(7));
        expect(path, hasLength(8));
      }
    });

    test('zero amplitude produces straight centered boundaries', () {
      final fold = generateCynefinFoldPath(400, 300, 42, amplitude: 0);
      final horizontal = generateCynefinHorizontalPath(400, 300, 42, amplitude: 0);

      expect((fold.first as MoveTo).point, const Point(200, 0));
      for (final command in fold.whereType<CubicTo>()) {
        expect(command.control1.x, 200);
        expect(command.control2.x, 200);
        expect(command.end.x, 200);
      }

      expect((horizontal.first as MoveTo).point, const Point(0, 150));
      for (final command in horizontal.whereType<CubicTo>()) {
        expect(command.control1.y, 150);
        expect(command.control2.y, 150);
        expect(command.end.y, 150);
      }
    });

    test('cliff and confusion paths use typed curves and close the center', () {
      final cliff = generateCynefinCliffPath(800, 600);
      final confusion = generateCynefinConfusionPath(400, 300, 120, 90);

      expect(cliff, hasLength(3));
      expect(cliff.first, isA<MoveTo>());
      expect(cliff.skip(1), everyElement(isA<CubicTo>()));
      expect(confusion, hasLength(4));
      expect(confusion.whereType<ArcTo>(), hasLength(2));
      expect(confusion.last, isA<ClosePath>());
    });
  });
}
