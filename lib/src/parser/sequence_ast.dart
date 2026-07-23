part of 'ast.dart';

/// Mermaid sequence participant shapes.
enum SequenceParticipantKind { participant, actor, boundary, control, entity, database, collections, queue }

/// Mermaid sequence message line and endpoint variants.
enum SequenceArrow {
  solidOpen,
  dottedOpen,
  solid,
  dotted,
  bidirectionalSolid,
  bidirectionalDotted,
  solidCross,
  dottedCross,
  solidPoint,
  dottedPoint,
  solidTop,
  solidBottom,
  stickTop,
  stickBottom,
  solidTopDotted,
  solidBottomDotted,
  stickTopDotted,
  stickBottomDotted,
  solidTopReverse,
  solidBottomReverse,
  stickTopReverse,
  stickBottomReverse,
  solidTopReverseDotted,
  solidBottomReverseDotted,
  stickTopReverseDotted,
  stickBottomReverseDotted;

  /// Whether the message line uses Mermaid's dashed stroke.
  bool get isDotted => switch (this) {
    dottedOpen ||
    dotted ||
    bidirectionalDotted ||
    dottedCross ||
    dottedPoint ||
    solidTopDotted ||
    solidBottomDotted ||
    stickTopDotted ||
    stickBottomDotted ||
    solidTopReverseDotted ||
    solidBottomReverseDotted ||
    stickTopReverseDotted ||
    stickBottomReverseDotted => true,
    _ => false,
  };

  /// Whether the source endpoint also receives an arrow marker.
  bool get isBidirectional => this == bidirectionalSolid || this == bidirectionalDotted;
}

/// Placement of a note relative to its participants.
enum SequenceNotePlacement { leftOf, rightOf, over }

/// Structured sequence frame kinds.
enum SequenceBlockKind { loop, opt, alt, par, parOver, critical, breakBlock }

/// A parsed Mermaid sequence diagram.
final class SequenceAst extends DiagramAst {
  /// Creates a typed sequence AST.
  const SequenceAst({
    this.participants = const [],
    this.statements = const [],
    this.boxes = const [],
    this.autoNumber,
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.sequence;

  /// Participants in first-reference order.
  final List<SequenceParticipantAst> participants;

  /// Messages, notes, activations, and frames in source order.
  final List<SequenceStatementAst> statements;

  /// Participant grouping boxes.
  final List<SequenceBoxAst> boxes;

  /// Optional automatic message numbering configuration.
  final SequenceAutoNumberAst? autoNumber;

  @override
  List<Object?> get diagramFields => [participants, statements, boxes, autoNumber];
}

/// One participant in a sequence diagram.
final class SequenceParticipantAst with _AstValueEquality {
  /// Creates a participant.
  const SequenceParticipantAst({
    required this.id,
    required this.label,
    this.kind = SequenceParticipantKind.participant,
    this.createdAt,
    this.destroyedAt,
    this.links = const {},
    this.properties = const {},
  });

  /// Stable source identifier.
  final String id;

  /// Visible participant label.
  final String label;

  /// Participant shape.
  final SequenceParticipantKind kind;

  /// Zero-based index of the message that creates this participant.
  final int? createdAt;

  /// Zero-based index of the message that destroys this participant.
  final int? destroyedAt;

  /// Optional labeled destinations associated with this participant.
  final Map<String, String> links;

  /// Optional structured participant metadata.
  final Map<String, Object?> properties;

  @override
  List<Object?> get equalityFields => [id, label, kind, createdAt, destroyedAt, links, properties];
}

/// A participant grouping box.
final class SequenceBoxAst with _AstValueEquality {
  /// Creates a participant box.
  const SequenceBoxAst({required this.label, required this.participantIds, this.color = 'transparent'});

  /// Visible box label.
  final String label;

  /// CSS color supplied by Mermaid source.
  final String color;

  /// Participants contained by the box.
  final List<String> participantIds;

  @override
  List<Object?> get equalityFields => [label, color, participantIds];
}

/// Automatic sequence-number settings.
final class SequenceAutoNumberAst with _AstValueEquality {
  /// Creates automatic numbering settings.
  const SequenceAutoNumberAst({this.start = 1, this.step = 1, this.visible = true});

  /// First displayed number.
  final num start;

  /// Increment between messages.
  final num step;

  /// Whether numbers are visible.
  final bool visible;

  @override
  List<Object?> get equalityFields => [start, step, visible];
}

/// Base type for sequence statements.
sealed class SequenceStatementAst with _AstValueEquality {
  const SequenceStatementAst();
}

/// One message between participants.
final class SequenceMessageAst extends SequenceStatementAst {
  /// Creates a sequence message.
  const SequenceMessageAst({
    required this.from,
    required this.to,
    required this.text,
    this.arrow = SequenceArrow.solid,
    this.activateTarget = false,
    this.deactivateSource = false,
  });

  /// Source participant identifier.
  final String from;

  /// Destination participant identifier.
  final String to;

  /// Visible message label.
  final String text;

  /// Line and endpoint style.
  final SequenceArrow arrow;

  /// Whether the destination activation begins after this message.
  final bool activateTarget;

  /// Whether the source activation ends after this message.
  final bool deactivateSource;

  @override
  List<Object?> get equalityFields => [from, to, text, arrow, activateTarget, deactivateSource];
}

/// An activation start or end.
final class SequenceActivationAst extends SequenceStatementAst {
  /// Creates an activation statement.
  const SequenceActivationAst({required this.participantId, required this.active});

  /// Participant whose activation changes.
  final String participantId;

  /// Whether this starts rather than ends an activation.
  final bool active;

  @override
  List<Object?> get equalityFields => [participantId, active];
}

/// A note attached to one or two participants.
final class SequenceNoteAst extends SequenceStatementAst {
  /// Creates a note.
  const SequenceNoteAst({required this.participantIds, required this.text, required this.placement});

  /// Referenced participant identifiers.
  final List<String> participantIds;

  /// Visible note text.
  final String text;

  /// Note placement.
  final SequenceNotePlacement placement;

  @override
  List<Object?> get equalityFields => [participantIds, text, placement];
}

/// One labeled section inside a sequence frame.
final class SequenceBlockSectionAst with _AstValueEquality {
  /// Creates a frame section.
  const SequenceBlockSectionAst({required this.label, this.statements = const []});

  /// Section condition or label.
  final String label;

  /// Nested statements.
  final List<SequenceStatementAst> statements;

  @override
  List<Object?> get equalityFields => [label, statements];
}

/// A loop, alternative, parallel, critical, optional, or break frame.
final class SequenceBlockAst extends SequenceStatementAst {
  /// Creates a structured frame.
  const SequenceBlockAst({required this.kind, this.sections = const []});

  /// Frame behavior.
  final SequenceBlockKind kind;

  /// One or more labeled sections.
  final List<SequenceBlockSectionAst> sections;

  @override
  List<Object?> get equalityFields => [kind, sections];
}

/// A colored background region around nested statements.
final class SequenceRectAst extends SequenceStatementAst {
  /// Creates a colored region.
  const SequenceRectAst({required this.color, this.statements = const []});

  /// CSS color from the `rect` statement.
  final String color;

  /// Nested statements.
  final List<SequenceStatementAst> statements;

  @override
  List<Object?> get equalityFields => [color, statements];
}
