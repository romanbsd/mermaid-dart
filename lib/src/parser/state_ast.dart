part of 'ast.dart';

/// A parsed Mermaid state diagram.
final class StateDiagramAst extends DiagramAst {
  /// Creates a state-diagram AST.
  const StateDiagramAst({
    this.direction = GraphDirection.topDown,
    this.states = const [],
    this.transitions = const [],
    this.hideEmptyDescriptions = false,
    this.classDefinitions = const {},
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.stateDiagram;

  /// Global graph direction.
  final GraphDirection direction;

  /// Top-level states in first-declaration order.
  final List<StateAst> states;

  /// Top-level transitions in source order.
  final List<StateTransitionAst> transitions;

  /// Whether empty state descriptions should be suppressed.
  final bool hideEmptyDescriptions;

  /// CSS-like style properties keyed by class definition name.
  final Map<String, Map<String, String>> classDefinitions;

  @override
  List<Object?> get diagramFields => [direction, states, transitions, hideEmptyDescriptions, classDefinitions];
}

/// Closed set of Mermaid state node types.
enum StateType { normal, start, end, fork, join, choice, divider }

/// Placement of an attached state note.
enum StateNotePosition { left, right }

/// One state, including optional composite-state contents.
final class StateAst with _AstValueEquality {
  /// Creates a state node.
  const StateAst({
    required this.id,
    required this.label,
    this.type = StateType.normal,
    this.descriptions = const [],
    this.children = const [],
    this.transitions = const [],
    this.direction,
    this.note,
    this.cssClasses = const [],
    this.styles = const {},
  });

  /// Stable state identifier.
  final String id;

  /// Visible state label.
  final String label;

  /// State geometry and semantics.
  final StateType type;

  /// Additional description rows.
  final List<String> descriptions;

  /// Nested states for a composite state.
  final List<StateAst> children;

  /// Transitions scoped to this composite state.
  final List<StateTransitionAst> transitions;

  /// Optional explicit direction inside a composite state.
  final GraphDirection? direction;

  /// Optional attached note.
  final StateNoteAst? note;

  /// CSS classes assigned to the state.
  final List<String> cssClasses;

  /// Inline style properties.
  final Map<String, String> styles;

  @override
  List<Object?> get equalityFields => [
    id,
    label,
    type,
    descriptions,
    children,
    transitions,
    direction,
    note,
    cssClasses,
    styles,
  ];
}

/// One directed transition between states.
final class StateTransitionAst with _AstValueEquality {
  /// Creates a state transition.
  const StateTransitionAst({required this.from, required this.to, this.label});

  /// Source state identifier.
  final String from;

  /// Destination state identifier.
  final String to;

  /// Optional transition label.
  final String? label;

  @override
  List<Object?> get equalityFields => [from, to, label];
}

/// A note attached to a state.
final class StateNoteAst with _AstValueEquality {
  /// Creates a state note.
  const StateNoteAst({required this.text, required this.position});

  /// Visible note text.
  final String text;

  /// Side of the state where the note is placed.
  final StateNotePosition position;

  @override
  List<Object?> get equalityFields => [text, position];
}
