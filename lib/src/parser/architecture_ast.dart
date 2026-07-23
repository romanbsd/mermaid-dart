part of 'ast.dart';

enum ArchitectureDirection {
  left,
  right,
  top,
  bottom;

  bool get isVertical => this == top || this == bottom;

  int get axisSign => this == right || this == bottom ? 1 : -1;

  ArchitectureDirection get opposite => switch (this) {
    left => right,
    right => left,
    top => bottom,
    bottom => top,
  };
}

enum ArchitectureAlignmentDirection { row, column }

final class ArchitectureAst extends DiagramAst {
  const ArchitectureAst({
    this.groups = const [],
    this.services = const [],
    this.junctions = const [],
    this.edges = const [],
    this.alignments = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.architecture;

  final List<ArchitectureGroupAst> groups;
  final List<ArchitectureServiceAst> services;
  final List<ArchitectureJunctionAst> junctions;
  final List<ArchitectureEdgeAst> edges;
  final List<ArchitectureAlignmentAst> alignments;

  @override
  List<Object?> get diagramFields => [groups, services, junctions, edges, alignments];
}

final class ArchitectureGroupAst with _AstValueEquality {
  const ArchitectureGroupAst({required this.id, this.icon, this.title, this.parent});

  final String id;
  final String? icon;
  final String? title;
  final String? parent;

  @override
  List<Object?> get equalityFields => [id, icon, title, parent];
}

final class ArchitectureServiceAst with _AstValueEquality {
  const ArchitectureServiceAst({required this.id, this.icon, this.iconText, this.title, this.parent});

  final String id;
  final String? icon;
  final String? iconText;
  final String? title;
  final String? parent;

  @override
  List<Object?> get equalityFields => [id, icon, iconText, title, parent];
}

final class ArchitectureJunctionAst with _AstValueEquality {
  const ArchitectureJunctionAst({required this.id, this.parent});

  final String id;
  final String? parent;

  @override
  List<Object?> get equalityFields => [id, parent];
}

final class ArchitectureEdgeAst with _AstValueEquality {
  const ArchitectureEdgeAst({
    required this.leftId,
    required this.leftDirection,
    this.leftArrow = false,
    this.leftGroup = false,
    required this.rightId,
    required this.rightDirection,
    this.rightArrow = false,
    this.rightGroup = false,
    this.title,
  });

  final String leftId;
  final ArchitectureDirection leftDirection;
  final bool leftArrow;
  final bool leftGroup;
  final String rightId;
  final ArchitectureDirection rightDirection;
  final bool rightArrow;
  final bool rightGroup;
  final String? title;

  @override
  List<Object?> get equalityFields => [
    leftId,
    leftDirection,
    leftArrow,
    leftGroup,
    rightId,
    rightDirection,
    rightArrow,
    rightGroup,
    title,
  ];
}

final class ArchitectureAlignmentAst with _AstValueEquality {
  const ArchitectureAlignmentAst({required this.direction, required this.members});

  final ArchitectureAlignmentDirection direction;
  final List<String> members;

  @override
  List<Object?> get equalityFields => [direction, members];
}
