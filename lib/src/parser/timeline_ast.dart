part of 'ast.dart';

/// A parsed Mermaid timeline.
final class TimelineAst extends DiagramAst {
  /// Creates a timeline.
  const TimelineAst({
    this.direction = TimelineDirection.leftRight,
    this.sections = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.timeline;

  /// Timeline flow direction.
  final TimelineDirection direction;

  /// Sections in source order. An unnamed section owns ungrouped periods.
  final List<TimelineSectionAst> sections;

  /// All periods in source order.
  List<TimelinePeriodAst> get periods => [for (final section in sections) ...section.periods];

  @override
  List<Object?> get diagramFields => [direction, sections];
}

/// Timeline orientation.
enum TimelineDirection { leftRight, topDown }

/// One named timeline section.
final class TimelineSectionAst with _AstValueEquality {
  /// Creates a timeline section.
  const TimelineSectionAst({required this.name, this.periods = const []});

  /// Visible section label, or empty for ungrouped periods.
  final String name;

  /// Periods assigned to this section.
  final List<TimelinePeriodAst> periods;

  @override
  List<Object?> get equalityFields => [name, periods];
}

/// One timeline period and its events.
final class TimelinePeriodAst with _AstValueEquality {
  /// Creates a timeline period.
  const TimelinePeriodAst({required this.label, this.events = const []});

  /// Visible period label.
  final String label;

  /// Event labels in declaration order.
  final List<String> events;

  @override
  List<Object?> get equalityFields => [label, events];
}
