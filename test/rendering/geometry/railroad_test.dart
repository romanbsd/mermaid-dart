import 'package:mermaid_dart/src/rendering/geometry/railroad.dart';
import 'package:mermaid_dart/src/rendering/scene.dart';
import 'package:test/test.dart';

void main() {
  group('Railroad route geometry', () {
    test('builds the shared upper bypass used by optional and zero-min repetition', () {
      final commands = railroadBypassCommands(width: 100, baselineY: 50, radius: 10);

      expect(commands, hasLength(8));
      expect(commands.first, const MoveTo(Point(0, 50)));
      expect(commands.whereType<ArcTo>().map((arc) => arc.clockwise), [false, true, true, false]);
      expect((commands[4] as LineTo).point, const Point(80, 0));
      expect((commands.last as ArcTo).end, const Point(100, 50));
    });

    test('uses straight connectors for a centered choice branch', () {
      final paths = railroadChoiceBranchCommands(
        width: 120,
        itemX: 30,
        itemWidth: 40,
        itemCenterY: 50,
        centerY: 50,
        radius: 10,
      );

      expect(paths.left, const [MoveTo(Point(0, 50)), LineTo(Point(30, 50))]);
      expect(paths.right, const [MoveTo(Point(70, 50)), LineTo(Point(120, 50))]);
    });

    test('mirrors arc directions around an upper choice branch', () {
      final paths = railroadChoiceBranchCommands(
        width: 120,
        itemX: 30,
        itemWidth: 40,
        itemCenterY: 20,
        centerY: 50,
        radius: 10,
      );

      expect(paths.left.whereType<ArcTo>().map((arc) => arc.clockwise), [false, true]);
      expect(paths.right.whereType<ArcTo>().map((arc) => arc.clockwise), [true, false]);
      expect((paths.left.last as LineTo).point, const Point(30, 20));
      expect((paths.right.last as ArcTo).end, const Point(120, 50));
    });

    test('builds the lower repetition loop around its item', () {
      final commands = railroadRepetitionLoopCommands(itemWidth: 40, baselineY: 30, loopY: 70, radius: 10);

      expect(commands, hasLength(8));
      expect(commands.first, const MoveTo(Point(60, 30)));
      expect(commands.whereType<ArcTo>(), hasLength(4));
      expect((commands[4] as LineTo).point, const Point(20, 80));
      expect((commands.last as ArcTo).end, const Point(20, 30));
    });
  });
}
