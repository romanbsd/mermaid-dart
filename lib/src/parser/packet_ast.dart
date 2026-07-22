part of 'ast.dart';

/// Syntax tree for a `packet` diagram.
final class PacketAst extends DiagramAst {
  const PacketAst({this.blocks = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  final List<PacketBlockAst> blocks;

  @override
  List<Object?> get diagramFields => [blocks];
}

/// A bit allocation block in a [PacketAst].
sealed class PacketBlockAst with _AstValueEquality {
  const PacketBlockAst({required this.label});

  final String label;
}

final class PacketRangeBlockAst extends PacketBlockAst {
  const PacketRangeBlockAst({required this.start, required this.end, required super.label});

  final int start;
  final int end;

  @override
  List<Object?> get equalityFields => [start, end, label];

  @override
  String toString() => 'PacketRangeBlockAst(start: $start, end: $end, label: $label)';
}

final class PacketSingleBitBlockAst extends PacketBlockAst {
  const PacketSingleBitBlockAst({required this.bit, required super.label});

  final int bit;

  @override
  List<Object?> get equalityFields => [bit, label];

  @override
  String toString() => 'PacketSingleBitBlockAst(bit: $bit, label: $label)';
}

final class PacketRelativeWidthBlockAst extends PacketBlockAst {
  const PacketRelativeWidthBlockAst({required this.bits, required super.label});

  final int bits;

  @override
  List<Object?> get equalityFields => [bits, label];

  @override
  String toString() => 'PacketRelativeWidthBlockAst(bits: $bits, label: $label)';
}
