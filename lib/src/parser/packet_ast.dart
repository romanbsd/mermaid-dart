part of 'ast.dart';

/// Syntax tree for a `packet` diagram.
final class PacketAst extends DiagramAst {
  const PacketAst({this.blocks = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  final List<PacketBlockAst> blocks;

  @override
  List<Object?> get diagramFields => [blocks];
}

/// A bit range or relative-width block in a [PacketAst].
final class PacketBlockAst with _AstValueEquality {
  const PacketBlockAst({this.start, this.end, this.bits, required this.label});

  final int? start;
  final int? end;
  final int? bits;
  final String label;

  @override
  List<Object?> get equalityFields => [start, end, bits, label];

  @override
  String toString() => 'PacketBlockAst(start: $start, end: $end, bits: $bits, label: $label)';
}
