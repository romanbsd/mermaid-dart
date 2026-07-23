import 'dart:math' as math;

import '../../parser/ast.dart';

/// One contiguous portion of a packet block positioned within a single row.
final class PacketSegment {
  const PacketSegment({required this.label, required this.startBit, required this.endBit, required this.row});

  final String label;
  final int startBit;
  final int endBit;
  final int row;

  int get bitCount => endBit - startBit + 1;
  bool get isSingleBit => startBit == endBit;

  @override
  bool operator ==(Object other) =>
      other is PacketSegment &&
      label == other.label &&
      startBit == other.startBit &&
      endBit == other.endBit &&
      row == other.row;

  @override
  int get hashCode => Object.hash(label, startBit, endBit, row);
}

/// Resolved packet statements and the final Mermaid bit cursor.
final class PacketLayoutModel {
  const PacketLayoutModel({required this.segments, required this.cursor, required this.rowCount});

  final List<PacketSegment> segments;
  final int cursor;
  final int rowCount;
}

/// Resolves absolute and relative blocks, splitting each at row boundaries.
PacketLayoutModel buildPacketLayoutModel(PacketAst ast, {required int bitsPerRow}) {
  final segments = <PacketSegment>[];
  var cursor = 0;
  for (final block in ast.blocks) {
    final (start, end) = switch (block) {
      PacketSingleBitBlockAst(:final bit) => (bit, bit),
      PacketRangeBlockAst(:final start, :final end) => (start, end),
      PacketRelativeWidthBlockAst(:final bits) => (cursor, cursor + bits - 1),
    };
    var segmentStart = start;
    while (segmentStart <= end) {
      final row = segmentStart ~/ bitsPerRow;
      final rowEnd = (row + 1) * bitsPerRow - 1;
      final segmentEnd = math.min(end, rowEnd);
      segments.add(PacketSegment(label: block.label, startBit: segmentStart, endBit: segmentEnd, row: row));
      segmentStart = segmentEnd + 1;
    }
    cursor = end + 1;
  }
  final rowCount = math.max(1, (cursor + bitsPerRow - 1) ~/ bitsPerRow);
  return PacketLayoutModel(segments: List.unmodifiable(segments), cursor: cursor, rowCount: rowCount);
}
