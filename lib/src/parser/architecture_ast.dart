part of 'ast.dart';

/// Defines the supported architecture direction values.
enum ArchitectureDirection {
  /// Selects the left variant.
  left,

  /// Selects the right variant.
  right,

  /// Selects the top variant.
  top,

  /// Selects the bottom variant.
  bottom;

  /// Whether this direction lies on the vertical axis.
  bool get isVertical => this == top || this == bottom;

  /// `1` for right or bottom and `-1` for left or top.
  int get axisSign => this == right || this == bottom ? 1 : -1;

  /// The direction on the opposite side of the same axis.
  ArchitectureDirection get opposite => switch (this) {
    left => right,
    right => left,
    top => bottom,
    bottom => top,
  };
}

/// Defines the supported architecture alignment direction values.
enum ArchitectureAlignmentDirection {
  /// Selects the row variant.
  row,

  /// Selects the column variant.
  column,
}

/// Typed abstract syntax tree node for architecture syntax.
final class ArchitectureAst extends DiagramAst {
  /// Creates a typed [ArchitectureAst].
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

  /// The groups.
  final List<ArchitectureGroupAst> groups;

  /// The services.
  final List<ArchitectureServiceAst> services;

  /// The junctions.
  final List<ArchitectureJunctionAst> junctions;

  /// The edges.
  final List<ArchitectureEdgeAst> edges;

  /// The alignments.
  final List<ArchitectureAlignmentAst> alignments;

  @override
  List<Object?> get diagramFields => [groups, services, junctions, edges, alignments];
}

/// Typed abstract syntax tree node for architecture group syntax.
final class ArchitectureGroupAst with _AstValueEquality {
  /// Creates a typed [ArchitectureGroupAst].
  const ArchitectureGroupAst({required this.id, this.icon, this.title, this.parent});

  /// The id.
  final String id;

  /// The icon.
  final String? icon;

  /// The title.
  final String? title;

  /// The parent.
  final String? parent;

  @override
  List<Object?> get equalityFields => [id, icon, title, parent];
}

/// Typed abstract syntax tree node for architecture service syntax.
final class ArchitectureServiceAst with _AstValueEquality {
  /// Creates a typed [ArchitectureServiceAst].
  const ArchitectureServiceAst({required this.id, this.icon, this.iconText, this.title, this.parent});

  /// The id.
  final String id;

  /// The icon.
  final String? icon;

  /// The icon text.
  final String? iconText;

  /// The title.
  final String? title;

  /// The parent.
  final String? parent;

  @override
  List<Object?> get equalityFields => [id, icon, iconText, title, parent];
}

/// Typed abstract syntax tree node for architecture junction syntax.
final class ArchitectureJunctionAst with _AstValueEquality {
  /// Creates a typed [ArchitectureJunctionAst].
  const ArchitectureJunctionAst({required this.id, this.parent});

  /// The id.
  final String id;

  /// The parent.
  final String? parent;

  @override
  List<Object?> get equalityFields => [id, parent];
}

/// Typed abstract syntax tree node for architecture edge syntax.
final class ArchitectureEdgeAst with _AstValueEquality {
  /// Creates a typed [ArchitectureEdgeAst].
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

  /// The left id.
  final String leftId;

  /// The left direction.
  final ArchitectureDirection leftDirection;

  /// The left arrow.
  final bool leftArrow;

  /// The left group.
  final bool leftGroup;

  /// The right id.
  final String rightId;

  /// The right direction.
  final ArchitectureDirection rightDirection;

  /// The right arrow.
  final bool rightArrow;

  /// The right group.
  final bool rightGroup;

  /// The title.
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

/// Typed abstract syntax tree node for architecture alignment syntax.
final class ArchitectureAlignmentAst with _AstValueEquality {
  /// Creates a typed [ArchitectureAlignmentAst].
  const ArchitectureAlignmentAst({required this.direction, required this.members});

  /// The direction.
  final ArchitectureAlignmentDirection direction;

  /// The members.
  final List<String> members;

  @override
  List<Object?> get equalityFields => [direction, members];
}
