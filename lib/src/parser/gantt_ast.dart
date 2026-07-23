part of 'ast.dart';

/// A parsed Mermaid Gantt diagram with resolved task dates.
final class GanttAst extends DiagramAst {
  /// Creates a typed [GanttAst].
  const GanttAst({
    this.dateFormat = '',
    this.axisFormat,
    this.tickInterval,
    this.inclusiveEndDates = false,
    this.topAxis = false,
    this.weekday = GanttWeekday.sunday,
    this.weekendStart = GanttWeekendStart.saturday,
    this.excludes = const [],
    this.includes = const [],
    this.todayMarker = '',
    this.sections = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.gantt;

  /// Day.js-compatible format used to parse task dates.
  final String dateFormat;

  /// D3-compatible format used for axis labels.
  final String? axisFormat;

  /// Explicit axis tick interval.
  final GanttTickInterval? tickInterval;

  /// Whether explicit end dates include the named final day.
  final bool inclusiveEndDates;

  /// Whether a second date axis is rendered above the task grid.
  final bool topAxis;

  /// First weekday used by week tick intervals.
  final GanttWeekday weekday;

  /// First day of the two-day weekend excluded by `excludes weekends`.
  final GanttWeekendStart weekendStart;

  /// Lowercase excluded weekday/date tokens in declaration order.
  final List<String> excludes;

  /// Lowercase included date tokens that override exclusions.
  final List<String> includes;

  /// Mermaid today-marker style, or `off`.
  final String todayMarker;

  /// Sections and their tasks in source order.
  final List<GanttSectionAst> sections;

  /// All tasks in source order.
  List<GanttTaskAst> get tasks => [for (final section in sections) ...section.tasks];

  @override
  List<Object?> get diagramFields => [
    dateFormat,
    axisFormat,
    tickInterval,
    inclusiveEndDates,
    topAxis,
    weekday,
    weekendStart,
    excludes,
    includes,
    todayMarker,
    sections,
  ];
}

/// One named Gantt section.
final class GanttSectionAst with _AstValueEquality {
  /// Creates a Gantt section.
  const GanttSectionAst({required this.name, this.tasks = const []});

  /// Section label.
  final String name;

  /// Tasks assigned to this section.
  final List<GanttTaskAst> tasks;

  @override
  List<Object?> get equalityFields => [name, tasks];
}

/// One fully resolved Gantt task.
final class GanttTaskAst with _AstValueEquality {
  /// Creates a Gantt task.
  const GanttTaskAst({
    required this.id,
    required this.label,
    required this.section,
    required this.start,
    required this.end,
    this.renderEnd,
    this.status = GanttTaskStatus.planned,
    this.critical = false,
    this.milestone = false,
    this.vertical = false,
    this.link,
    this.callback,
  });

  /// Stable task identifier.
  final String id;

  /// Visible task label.
  final String label;

  /// Owning section name.
  final String section;

  /// Resolved start time.
  final DateTime start;

  /// Resolved logical end time.
  final DateTime end;

  /// Last visible end before excluded days extended [end], when applicable.
  final DateTime? renderEnd;

  /// Planned, active, or completed state.
  final GanttTaskStatus status;

  /// Whether this task is on the critical path.
  final bool critical;

  /// Whether this task is drawn as a milestone diamond.
  final bool milestone;

  /// Whether this task is a vertical timeline marker.
  final bool vertical;

  /// Optional click destination.
  final String? link;

  /// Optional callback declaration retained for non-DOM consumers.
  final GanttCallbackAst? callback;

  @override
  List<Object?> get equalityFields => [
    id,
    label,
    section,
    start,
    end,
    renderEnd,
    status,
    critical,
    milestone,
    vertical,
    link,
    callback,
  ];
}

/// A parsed Gantt callback declaration.
final class GanttCallbackAst with _AstValueEquality {
  /// Creates a callback declaration.
  const GanttCallbackAst(this.name, [this.arguments = const []]);

  /// Callback name.
  final String name;

  /// Parsed argument lexemes.
  final List<String> arguments;

  @override
  List<Object?> get equalityFields => [name, arguments];
}

/// Closed task lifecycle states.
enum GanttTaskStatus { planned, active, done }

/// Supported tick interval units.
enum GanttTickUnit { millisecond, second, minute, hour, day, week, month }

/// A positive axis tick interval.
final class GanttTickInterval with _AstValueEquality {
  /// Creates an interval of [count] [unit]s.
  const GanttTickInterval(this.count, this.unit);

  /// Positive interval count.
  final int count;

  /// Interval unit.
  final GanttTickUnit unit;

  @override
  List<Object?> get equalityFields => [count, unit];
}

/// Weekday used for weekly axis ticks.
enum GanttWeekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

/// Supported weekend starting days.
enum GanttWeekendStart { friday, saturday }
