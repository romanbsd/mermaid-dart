part of 'ast.dart';

/// Day.js format applied when a Gantt diagram declares no `dateFormat`.
const ganttDefaultDateFormat = 'YYYY-MM-DD';

/// Token that `excludes` uses to skip both weekend days.
const ganttWeekendsToken = 'weekends';

/// Value that suppresses the `todayMarker`.
const ganttTodayMarkerOffToken = 'off';

/// One Day.js format token understood by Mermaid's Gantt date handling.
///
/// Declaration order is match order for both parsing and formatting: a longer
/// token must precede every shorter token it starts with, so `YYYY` is never
/// matched as two `YY` tokens.
enum GanttDateToken {
  /// Four-digit calendar year.
  year4('YYYY', digits: 4, pad: 4),

  /// Three-digit milliseconds.
  millisecond('SSS', digits: 3, pad: 3),

  /// Two-digit year within the 2000s.
  year2('YY', pad: 2),

  /// Zero-padded month.
  month2('MM', pad: 2),

  /// Zero-padded day of month.
  day2('DD', pad: 2),

  /// Zero-padded hour.
  hour2('HH', pad: 2),

  /// Zero-padded minute.
  minute2('mm', pad: 2),

  /// Zero-padded second.
  second2('ss', pad: 2),

  /// Unpadded month.
  month('M'),

  /// Unpadded day of month.
  day('D'),

  /// Unpadded hour.
  hour('H'),

  /// Unpadded minute.
  minute('m'),

  /// Unpadded second.
  second('s');

  const GanttDateToken(this.pattern, {this.digits, this.pad = 0});

  /// Literal token text as it appears inside a `dateFormat` declaration.
  final String pattern;

  /// Exact digit count matched while parsing, or `null` for one or two digits.
  final int? digits;

  /// Zero-padding width applied while formatting, or `0` for none.
  final int pad;

  /// Regular expression group matching this token's digits.
  String get _group => digits == null ? r'(\d{1,2})' : '(\\d{$digits})';
}

final _ganttDateTokens = RegExp(GanttDateToken.values.map((token) => token.pattern).join('|'));
final _ganttDateTokensByPattern = {for (final token in GanttDateToken.values) token.pattern: token};

/// Formats [date] with the Day.js-compatible Gantt [format].
///
/// An empty [format] falls back to [ganttDefaultDateFormat]. Characters that
/// are not part of a [GanttDateToken] are copied verbatim.
String formatGanttDate(DateTime date, String format) =>
    _ganttPattern(format).replaceAllMapped(_ganttDateTokens, (match) {
      final token = _ganttDateTokensByPattern[match.group(0)]!;
      return _ganttTokenValue(date, token).toString().padLeft(token.pad, '0');
    });

/// Formats [date] as `YYYY-MM-DD`, the canonical form `excludes` also accepts.
String ganttIsoDate(DateTime date) => formatGanttDate(date, ganttDefaultDateFormat);

/// Parses [value] with the Day.js-compatible Gantt [format], or returns `null`.
///
/// The Day.js epoch formats `x` (milliseconds) and `X` (seconds) are supported
/// in addition to token patterns. Component values that a [DateTime] would
/// silently roll over, such as `2025-02-30`, are rejected.
DateTime? tryParseGanttDate(String value, String format) {
  final trimmed = value.trim();
  final trimmedFormat = format.trim();
  if (trimmedFormat == 'x' || trimmedFormat == 'X') {
    final number = int.tryParse(trimmed);
    if (number == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(trimmedFormat == 'X' ? number * 1000 : number);
  }
  final pattern = _ganttPattern(format);
  final tokens = <GanttDateToken>[];
  final expression = StringBuffer('^');
  for (var index = 0; index < pattern.length;) {
    final token = GanttDateToken.values.firstWhereOrNull((token) => pattern.startsWith(token.pattern, index));
    if (token == null) {
      expression.write(RegExp.escape(pattern[index]));
      index++;
    } else {
      tokens.add(token);
      expression.write(token._group);
      index += token.pattern.length;
    }
  }
  expression.write(r'$');
  final match = RegExp(expression.toString()).firstMatch(trimmed);
  if (match == null) return null;

  final parts = _GanttDateParts();
  for (var index = 0; index < tokens.length; index++) {
    parts.apply(tokens[index], int.parse(match.group(index + 1)!));
  }
  return parts.toDateTime();
}

/// Whether [date] is hidden by Mermaid's Gantt `excludes` and `includes` lists.
///
/// Only [GanttDateLiteralFilter] entries in [includes] override an exclusion,
/// matching Mermaid, which re-includes explicit dates but not whole weekdays.
bool ganttDateExcluded(
  DateTime date, {
  required String dateFormat,
  required List<GanttDateFilter> excludes,
  required List<GanttDateFilter> includes,
  required GanttWeekendStart weekendStart,
}) {
  final formatted = formatGanttDate(date, dateFormat).toLowerCase();
  final iso = ganttIsoDate(date);
  bool matchesLiteral(GanttDateFilter filter) =>
      filter is GanttDateLiteralFilter && (filter.value == formatted || filter.value == iso);
  bool matches(GanttDateFilter filter) => switch (filter) {
    GanttWeekendsFilter() => _isGanttWeekend(date, weekendStart),
    GanttWeekdayFilter(:final weekday) => date.weekday == weekday.index + 1,
    GanttDateLiteralFilter() => matchesLiteral(filter),
  };
  if (includes.any(matchesLiteral)) return false;
  return excludes.any(matches);
}

bool _isGanttWeekend(DateTime date, GanttWeekendStart weekendStart) {
  final first = weekendStart == GanttWeekendStart.friday ? DateTime.friday : DateTime.saturday;
  final second = first == DateTime.saturday ? DateTime.sunday : DateTime.saturday;
  return date.weekday == first || date.weekday == second;
}

String _ganttPattern(String format) => format.trim().isEmpty ? ganttDefaultDateFormat : format.trim();

int _ganttTokenValue(DateTime date, GanttDateToken token) => switch (token) {
  GanttDateToken.year4 => date.year,
  GanttDateToken.year2 => date.year % 100,
  GanttDateToken.month2 || GanttDateToken.month => date.month,
  GanttDateToken.day2 || GanttDateToken.day => date.day,
  GanttDateToken.hour2 || GanttDateToken.hour => date.hour,
  GanttDateToken.minute2 || GanttDateToken.minute => date.minute,
  GanttDateToken.second2 || GanttDateToken.second => date.second,
  GanttDateToken.millisecond => date.millisecond,
};

/// Mutable date components collected while parsing, defaulting to the epoch.
final class _GanttDateParts {
  int year = 1970;
  int month = 1;
  int day = 1;
  int hour = 0;
  int minute = 0;
  int second = 0;
  int millisecond = 0;

  void apply(GanttDateToken token, int number) {
    switch (token) {
      case GanttDateToken.year4:
        year = number;
      case GanttDateToken.year2:
        year = 2000 + number;
      case GanttDateToken.month2 || GanttDateToken.month:
        month = number;
      case GanttDateToken.day2 || GanttDateToken.day:
        day = number;
      case GanttDateToken.hour2 || GanttDateToken.hour:
        hour = number;
      case GanttDateToken.minute2 || GanttDateToken.minute:
        minute = number;
      case GanttDateToken.second2 || GanttDateToken.second:
        second = number;
      case GanttDateToken.millisecond:
        millisecond = number;
    }
  }

  /// The assembled date, or `null` when a component rolled over into the next
  /// month, hour, or year.
  DateTime? toDateTime() {
    final result = DateTime(year, month, day, hour, minute, second, millisecond);
    if (result.year != year ||
        result.month != month ||
        result.day != day ||
        result.hour != hour ||
        result.minute != minute ||
        result.second != second) {
      return null;
    }
    return result;
  }
}
