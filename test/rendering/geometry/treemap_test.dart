import 'package:mermaid_dart/src/rendering/geometry/treemap.dart';
import 'package:mermaid_dart/src/rendering/scene.dart';
import 'package:test/test.dart';

void main() {
  group('squarifyTreemap', () {
    test('sort-ready weights produce deterministic padded tiles', () {
      final tiles = squarifyTreemap(
        const [TreemapItem(3, 'large'), TreemapItem(1, 'small')],
        const Bounds(left: 10, top: 35, width: 940, height: 455),
        innerPadding: 10,
      );

      expect(tiles.map((tile) => tile.data), ['large', 'small']);
      expect(tiles[0].bounds, const Bounds(left: 10, top: 35, width: 703, height: 455));
      expect(tiles[1].bounds, const Bounds(left: 723, top: 35, width: 227, height: 455));
      expect(tiles[0].bounds.right + 10, tiles[1].bounds.left);
    });

    test('assigns equal area to an all-zero row', () {
      final tiles = squarifyTreemap(const [
        TreemapItem(0, 'a'),
        TreemapItem(0, 'b'),
      ], const Bounds(left: 0, top: 0, width: 100, height: 50));

      expect(tiles, hasLength(2));
      expect(tiles.fold<double>(0, (sum, tile) => sum + tile.bounds.width * tile.bounds.height), 5000);
    });
  });
}
