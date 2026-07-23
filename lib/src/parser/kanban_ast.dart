part of 'ast.dart';

/// Syntax tree for a Mermaid `kanban` diagram.
final class KanbanAst extends DiagramAst {
  /// Creates a typed [KanbanAst].
  const KanbanAst({this.sections = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  @override
  DiagramType get type => DiagramType.kanban;

  /// Board columns, in source order.
  final List<KanbanSectionAst> sections;

  @override
  List<Object?> get diagramFields => [sections];
}

/// A top-level Kanban column.
final class KanbanSectionAst with _AstValueEquality {
  /// Creates a typed [KanbanSectionAst].
  const KanbanSectionAst({
    required this.id,
    required this.label,
    this.cards = const [],
    this.cssClasses = const [],
    this.icon,
    this.ticket,
    this.assigned,
    this.priority,
  });

  /// Stable source identifier.
  final String id;

  /// Visible column label.
  final String label;

  /// Cards assigned to this column.
  final List<KanbanCardAst> cards;

  /// Mermaid class decorations applied with `:::`.
  final List<String> cssClasses;

  /// Optional Iconify-compatible icon reference.
  final String? icon;

  /// Optional external ticket identifier.
  final String? ticket;

  /// Optional assignee.
  final String? assigned;

  /// Optional priority.
  final KanbanPriority? priority;

  @override
  List<Object?> get equalityFields => [id, label, cards, cssClasses, icon, ticket, assigned, priority];
}

/// A card inside a Kanban column.
final class KanbanCardAst with _AstValueEquality {
  /// Creates a typed [KanbanCardAst].
  const KanbanCardAst({
    required this.id,
    required this.label,
    this.cssClasses = const [],
    this.icon,
    this.ticket,
    this.assigned,
    this.priority,
  });

  /// Stable source identifier.
  final String id;

  /// Visible card label.
  final String label;

  /// Mermaid class decorations applied with `:::`.
  final List<String> cssClasses;

  /// Optional Iconify-compatible icon reference.
  final String? icon;

  /// Optional external ticket identifier.
  final String? ticket;

  /// Optional assignee.
  final String? assigned;

  /// Optional priority.
  final KanbanPriority? priority;

  @override
  List<Object?> get equalityFields => [id, label, cssClasses, icon, ticket, assigned, priority];
}

/// Mermaid's closed set of Kanban priorities.
enum KanbanPriority {
  /// Highest urgency.
  veryHigh('Very High'),

  /// High urgency.
  high('High'),

  /// Default urgency.
  medium('Medium'),

  /// Low urgency.
  low('Low'),

  /// Lowest urgency.
  veryLow('Very Low');

  const KanbanPriority(this.wireName);

  /// Mermaid's serialized spelling.
  final String wireName;

  /// Parses Mermaid priority metadata case-insensitively.
  static KanbanPriority? tryParse(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    for (final priority in values) {
      if (priority.wireName.toLowerCase() == normalized) return priority;
    }
    return null;
  }
}
