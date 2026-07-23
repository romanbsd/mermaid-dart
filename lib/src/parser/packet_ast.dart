part of 'ast.dart';

/// Syntax tree for a `packet` diagram.
final class PacketAst extends DiagramAst {
  /// Creates a typed [PacketAst].
  const PacketAst({this.blocks = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  @override
  DiagramType get type => DiagramType.packet;

  /// The blocks.
  final List<PacketBlockAst> blocks;

  @override
  List<Object?> get diagramFields => [blocks];
}

/// A bit allocation block in a [PacketAst].
sealed class PacketBlockAst with _AstValueEquality {
  const PacketBlockAst({required this.label});

  /// The label.
  final String label;
}

/// Typed abstract syntax tree node for packet range block syntax.
final class PacketRangeBlockAst extends PacketBlockAst {
  /// Creates a typed [PacketRangeBlockAst].
  const PacketRangeBlockAst({required this.start, required this.end, required super.label});

  /// The start.
  final int start;

  /// The end.
  final int end;

  @override
  List<Object?> get equalityFields => [start, end, label];

  @override
  String toString() => 'PacketRangeBlockAst(start: $start, end: $end, label: $label)';
}

/// Typed abstract syntax tree node for packet single bit block syntax.
final class PacketSingleBitBlockAst extends PacketBlockAst {
  /// Creates a typed [PacketSingleBitBlockAst].
  const PacketSingleBitBlockAst({required this.bit, required super.label});

  /// The bit.
  final int bit;

  @override
  List<Object?> get equalityFields => [bit, label];

  @override
  String toString() => 'PacketSingleBitBlockAst(bit: $bit, label: $label)';
}

/// Typed abstract syntax tree node for packet relative width block syntax.
final class PacketRelativeWidthBlockAst extends PacketBlockAst {
  /// Creates a typed [PacketRelativeWidthBlockAst].
  const PacketRelativeWidthBlockAst({required this.bits, required super.label});

  /// The bits.
  final int bits;

  @override
  List<Object?> get equalityFields => [bits, label];

  @override
  String toString() => 'PacketRelativeWidthBlockAst(bits: $bits, label: $label)';
}
