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
    this.todayMarker = const GanttTodayMarkerStyle(),
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

  /// Excluded weekends, weekdays, and dates in declaration order.
  final List<GanttDateFilter> excludes;

  /// Dates that override [excludes], in declaration order.
  ///
  /// Mermaid only re-includes explicit dates, so weekend and weekday entries
  /// here never override an exclusion.
  final List<GanttDateFilter> includes;

  /// Whether and how the today marker is drawn.
  final GanttTodayMarker todayMarker;

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

/// One entry of a Gantt `excludes` or `includes` list.
sealed class GanttDateFilter with _AstValueEquality {
  const GanttDateFilter();

  /// Classifies one lowercase `excludes`/`includes` token.
  factory GanttDateFilter.fromToken(String token) {
    if (token == ganttWeekendsToken) return const GanttWeekendsFilter();
    final weekday = GanttWeekday.values.firstWhereOrNull((day) => day.name == token);
    return weekday == null ? GanttDateLiteralFilter(token) : GanttWeekdayFilter(weekday);
  }
}

/// Matches both days of the weekend selected by [GanttAst.weekendStart].
final class GanttWeekendsFilter extends GanttDateFilter {
  /// Creates a weekend filter.
  const GanttWeekendsFilter();

  @override
  List<Object?> get equalityFields => const [];
}

/// Matches every occurrence of one weekday.
final class GanttWeekdayFilter extends GanttDateFilter {
  /// Creates a filter matching [weekday].
  const GanttWeekdayFilter(this.weekday);

  /// The matched weekday.
  final GanttWeekday weekday;

  @override
  List<Object?> get equalityFields => [weekday];
}

/// Matches one calendar day written in [GanttAst.dateFormat] or as an ISO date.
final class GanttDateLiteralFilter extends GanttDateFilter {
  /// Creates a filter matching the lowercase date token [value].
  const GanttDateLiteralFilter(this.value);

  /// The lowercase date token as written in the diagram source.
  final String value;

  @override
  List<Object?> get equalityFields => [value];
}

/// Whether and how a Gantt diagram draws its today marker.
sealed class GanttTodayMarker with _AstValueEquality {
  const GanttTodayMarker();

  /// Classifies the value written after `todayMarker`.
  factory GanttTodayMarker.fromValue(String value) =>
      value.toLowerCase() == ganttTodayMarkerOffToken ? const GanttTodayMarkerOff() : GanttTodayMarkerStyle(value);
}

/// Suppresses the today marker.
final class GanttTodayMarkerOff extends GanttTodayMarker {
  /// Creates a suppressed today marker.
  const GanttTodayMarkerOff();

  @override
  List<Object?> get equalityFields => const [];
}

/// Draws the today marker, optionally with Mermaid style overrides.
final class GanttTodayMarkerStyle extends GanttTodayMarker {
  /// Creates a today marker styled by [styles], or the renderer default.
  const GanttTodayMarkerStyle([this.styles = '']);

  /// Raw CSS declarations from the diagram source, or empty for the default.
  final String styles;

  @override
  List<Object?> get equalityFields => [styles];
}
