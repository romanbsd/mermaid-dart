import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart/src/rendering/geometry/packet.dart';
import 'package:test/test.dart';

void main() {
  group('Packet layout model', () {
    test('splits an absolute range at word boundaries', () {
      final model = buildPacketLayoutModel(
        const PacketAst(blocks: [PacketRangeBlockAst(start: 6, end: 10, label: 'crossing')]),
        bitsPerRow: 8,
      );

      expect(model.segments, const [
        PacketSegment(label: 'crossing', startBit: 6, endBit: 7, row: 0),
        PacketSegment(label: 'crossing', startBit: 8, endBit: 10, row: 1),
      ]);
      expect(model.cursor, 11);
      expect(model.rowCount, 2);
    });

    test('relative widths continue from the preceding block cursor', () {
      final model = buildPacketLayoutModel(
        const PacketAst(
          blocks: [
            PacketSingleBitBlockAst(bit: 3, label: 'flag'),
            PacketRelativeWidthBlockAst(bits: 6, label: 'payload'),
          ],
        ),
        bitsPerRow: 8,
      );

      expect(model.segments, const [
        PacketSegment(label: 'flag', startBit: 3, endBit: 3, row: 0),
        PacketSegment(label: 'payload', startBit: 4, endBit: 7, row: 0),
        PacketSegment(label: 'payload', startBit: 8, endBit: 9, row: 1),
      ]);
      expect(model.cursor, 10);
      expect(model.rowCount, 2);
    });

    test('a later absolute block resets the cursor used by relative widths', () {
      final model = buildPacketLayoutModel(
        const PacketAst(
          blocks: [
            PacketRangeBlockAst(start: 8, end: 9, label: 'high'),
            PacketRangeBlockAst(start: 1, end: 2, label: 'reset'),
            PacketRelativeWidthBlockAst(bits: 2, label: 'relative'),
          ],
        ),
        bitsPerRow: 8,
      );

      expect(model.segments.last, const PacketSegment(label: 'relative', startBit: 3, endBit: 4, row: 0));
      expect(model.cursor, 5);
      expect(model.rowCount, 1);
    });
  });
}
