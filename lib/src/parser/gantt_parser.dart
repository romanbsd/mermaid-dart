import 'ast.dart';
import 'common_syntax.dart';

final _ganttHeader = RegExp(r'^[\t \r\n]*(gantt)(?=\s|$)', caseSensitive: false);
final _tickInterval = RegExp(r'^([1-9]\d*)(millisecond|second|minute|hour|day|week|month)$', caseSensitive: false);
final _duration = RegExp(r'^(\d+(?:\.\d+)?)(ms|[Mdhmswy])$');
final _after = RegExp(r'^after\s+([\d\w-]+(?:\s+[\d\w-]+)*)$', caseSensitive: false);
final _until = RegExp(r'^until\s+([\d\w-]+(?:\s+[\d\w-]+)*)$', caseSensitive: false);
final _click = RegExp(r'^click\s+(\S+)\s+(.+)$', caseSensitive: false);
final _href = RegExp(r'\bhref\s+"([^"]*)"', caseSensitive: false);
final _callback = RegExp(r'\bcall\s+([^( \t]+)\s*\(([^)]*)\)', caseSensitive: false);
final _tokenSeparator = RegExp(r'[\s,]+');

/// Parses Mermaid's Gantt syntax and resolves task dependencies.
GanttAst parseGantt(String source) {
  final visible = hideIgnoredSyntax(source);
  final header = _ganttHeader.firstMatch(visible);
  final prepared = prepareDiagramSource(source, headers: [header?.group(1) ?? 'gantt']);
  final collector = _GanttCollector(source, prepared.metadata);

  for (final line in sourceLines(prepared.syntax)) {
    final content = line.text.trim();
    if (content.isEmpty) continue;
    collector.addLine(content, line.offset + line.text.indexOf(content));
  }
  return collector.build();
}

final class _GanttCollector {
  _GanttCollector(this.source, this.metadata);

  final String source;
  final CommonMetadata metadata;
  String dateFormat = '';
  String? axisFormat;
  GanttTickInterval? tickInterval;
  bool inclusiveEndDates = false;
  bool topAxis = false;
  GanttWeekday weekday = GanttWeekday.sunday;
  GanttWeekendStart weekendStart = GanttWeekendStart.saturday;
  String todayMarker = '';
  final excludes = <String>[];
  final includes = <String>[];
  final sections = <_RawSection>[];
  final interactions = <_Interaction>[];
  _RawSection? currentSection;
  int generatedId = 0;

  void addLine(String content, int offset) {
    final keyword = RegExp(r'^\S+').firstMatch(content)!.group(0)!.toLowerCase();
    switch (keyword) {
      case 'dateformat':
        dateFormat = _requiredValue(content, 'dateFormat', offset);
      case 'axisformat':
        axisFormat = _requiredValue(content, 'axisFormat', offset);
      case 'tickinterval':
        final value = _requiredValue(content, 'tickInterval', offset);
        final match = _tickInterval.firstMatch(value);
        if (match == null) throwParseError(source, 'Invalid Gantt tick interval: $value', offset);
        tickInterval = GanttTickInterval(
          int.parse(match.group(1)!),
          GanttTickUnit.values.byName(match.group(2)!.toLowerCase()),
        );
      case 'inclusiveenddates':
        _requireBareKeyword(content, 'inclusiveEndDates', offset);
        inclusiveEndDates = true;
      case 'topaxis':
        _requireBareKeyword(content, 'topAxis', offset);
        topAxis = true;
      case 'weekday':
        final value = _requiredValue(content, 'weekday', offset).toLowerCase();
        try {
          weekday = GanttWeekday.values.byName(value);
        } on ArgumentError {
          throwParseError(source, 'Invalid Gantt weekday: $value', offset);
        }
      case 'weekend':
        final value = _requiredValue(content, 'weekend', offset).toLowerCase();
        try {
          weekendStart = GanttWeekendStart.values.byName(value);
        } on ArgumentError {
          throwParseError(source, 'Invalid Gantt weekend: $value', offset);
        }
      case 'excludes':
        _mergeTokens(excludes, _requiredValue(content, 'excludes', offset));
      case 'includes':
        _mergeTokens(includes, _requiredValue(content, 'includes', offset));
      case 'todaymarker':
        todayMarker = _requiredValue(content, 'todayMarker', offset);
      case 'section':
        final name = _requiredValue(content, 'section', offset);
        currentSection = _RawSection(name);
        sections.add(currentSection!);
      case 'click':
        _addInteraction(content, offset);
      default:
        _addTask(content, offset);
    }
  }

  String _requiredValue(String content, String keyword, int offset) {
    final value = content.substring(keyword.length).trim();
    if (value.isEmpty) throwParseError(source, 'Expected a value after $keyword', offset + keyword.length);
    return value;
  }

  void _requireBareKeyword(String content, String keyword, int offset) {
    if (content.length != keyword.length) {
      throwParseError(source, 'Unexpected content after $keyword', offset + keyword.length);
    }
  }

  void _mergeTokens(List<String> target, String value) {
    for (final token in value.toLowerCase().split(_tokenSeparator).where((token) => token.isNotEmpty)) {
      if (!target.contains(token)) target.add(token);
    }
  }

  void _addTask(String content, int offset) {
    final separator = content.indexOf(':');
    if (separator < 0) throwParseError(source, 'Expected Gantt task data after ":"', offset);
    final label = content.substring(0, separator).trim();
    final data = content.substring(separator + 1).trim();
    if (label.isEmpty || data.isEmpty) throwParseError(source, 'Invalid Gantt task', offset);

    currentSection ??= _RawSection('');
    if (!sections.contains(currentSection)) sections.add(currentSection!);
    final fields = data.split(',').map((field) => field.trim()).toList();
    var status = GanttTaskStatus.planned;
    var critical = false;
    var milestone = false;
    var vertical = false;
    while (fields.isNotEmpty) {
      switch (fields.first.toLowerCase()) {
        case 'active':
          status = GanttTaskStatus.active;
        case 'done':
          status = GanttTaskStatus.done;
        case 'crit':
          critical = true;
        case 'milestone':
          milestone = true;
        case 'vert':
          vertical = true;
        default:
          break;
      }
      if (!const {'active', 'done', 'crit', 'milestone', 'vert'}.contains(fields.first.toLowerCase())) break;
      fields.removeAt(0);
    }
    if (fields.isEmpty || fields.length > 3) {
      throwParseError(source, 'Gantt task data requires one to three fields', offset + separator + 1);
    }

    String id;
    String? startData;
    late String endData;
    switch (fields.length) {
      case 1:
        id = 'task${++generatedId}';
        endData = fields[0];
      case 2:
        id = 'task${++generatedId}';
        startData = fields[0];
        endData = fields[1];
      case 3:
        id = fields[0];
        startData = fields[1];
        endData = fields[2];
      default:
        throw StateError('Checked task field count');
    }
    if (id.isEmpty || endData.isEmpty) throwParseError(source, 'Invalid Gantt task data', offset + separator + 1);
    currentSection!.tasks.add(
      _RawTask(
        id: id,
        label: label,
        section: currentSection!.name,
        startData: startData,
        endData: endData,
        status: status,
        critical: critical,
        milestone: milestone,
        vertical: vertical,
        offset: offset,
      ),
    );
  }

  void _addInteraction(String content, int offset) {
    final match = _click.firstMatch(content);
    if (match == null) throwParseError(source, 'Invalid Gantt click declaration', offset);
    final command = match.group(2)!;
    final href = _href.firstMatch(command)?.group(1);
    final callbackMatch = _callback.firstMatch(command);
    if (href == null && callbackMatch == null) {
      throwParseError(source, 'Expected href or call after Gantt click target', offset);
    }
    final callback = callbackMatch == null
        ? null
        : GanttCallbackAst(
            callbackMatch.group(1)!,
            List.unmodifiable(_splitCallbackArguments(callbackMatch.group(2)!)),
          );
    interactions.add(_Interaction(match.group(1)!.split(','), href, callback, offset));
  }

  GanttAst build() {
    final rawTasks = [for (final section in sections) ...section.tasks];
    final previousIds = <_RawTask, String?>{
      for (final (index, task) in rawTasks.indexed) task: index == 0 ? null : rawTasks[index - 1].id,
    };
    final resolved = <String, GanttTaskAst>{};
    final result = <String, GanttTaskAst>{};
    final pending = [...rawTasks];

    for (var pass = 0; pending.isNotEmpty && pass <= rawTasks.length; pass++) {
      var progress = false;
      for (final raw in [...pending]) {
        final previous = switch (previousIds[raw]) {
          final String id => result[id],
          null => null,
        };
        final task = _tryResolve(raw, previous, resolved);
        if (task == null) continue;
        resolved[task.id] = task;
        result[task.id] = task;
        pending.remove(raw);
        progress = true;
      }
      if (!progress) break;
    }
    if (pending.isNotEmpty) {
      throwParseError(source, 'Unresolved Gantt task dependency for ${pending.first.id}', pending.first.offset);
    }

    for (final interaction in interactions) {
      for (final id in interaction.ids) {
        final task = result[id];
        if (task == null) throwParseError(source, 'Unknown Gantt click target: $id', interaction.offset);
        result[id] = _copyTask(task, link: interaction.href, callback: interaction.callback);
      }
    }

    final typedSections = [
      for (final section in sections)
        GanttSectionAst(
          name: section.name,
          tasks: List.unmodifiable([for (final task in section.tasks) result[task.id]!]),
        ),
    ];
    return GanttAst(
      dateFormat: dateFormat,
      axisFormat: axisFormat,
      tickInterval: tickInterval,
      inclusiveEndDates: inclusiveEndDates,
      topAxis: topAxis,
      weekday: weekday,
      weekendStart: weekendStart,
      excludes: List.unmodifiable(excludes),
      includes: List.unmodifiable(includes),
      todayMarker: todayMarker,
      sections: List.unmodifiable(typedSections),
      title: metadata.title,
      accessibilityTitle: metadata.accessibilityTitle,
      accessibilityDescription: metadata.accessibilityDescription,
    );
  }

  GanttTaskAst? _tryResolve(_RawTask raw, GanttTaskAst? previous, Map<String, GanttTaskAst> resolved) {
    final start = switch (raw.startData) {
      null => previous?.end,
      final value => _resolveStart(value, resolved, raw.offset),
    };
    if (start == null) return null;
    final endResult = _resolveEnd(start, raw.endData, resolved, raw.offset);
    if (endResult == null) return null;
    var end = endResult.end;
    DateTime? renderEnd;
    if (!endResult.manual && excludes.isNotEmpty) {
      final adjusted = _adjustExcludedDates(start.add(const Duration(days: 1)), end);
      end = adjusted.end;
      renderEnd = adjusted.renderEnd;
    }
    return GanttTaskAst(
      id: raw.id,
      label: raw.label,
      section: raw.section,
      start: start,
      end: end,
      renderEnd: renderEnd,
      status: raw.status,
      critical: raw.critical,
      milestone: raw.milestone,
      vertical: raw.vertical,
    );
  }

  DateTime? _resolveStart(String value, Map<String, GanttTaskAst> resolved, int offset) {
    final after = _after.firstMatch(value.trim());
    if (after != null) {
      final dependencies = after.group(1)!.split(RegExp(r'\s+'));
      final tasks = dependencies.map((id) => resolved[id]).whereType<GanttTaskAst>().toList();
      if (tasks.length != dependencies.length) return null;
      return tasks.map((task) => task.end).reduce((left, right) => left.isAfter(right) ? left : right);
    }
    return _parseDate(value, dateFormat, source, offset);
  }

  _EndResult? _resolveEnd(DateTime start, String value, Map<String, GanttTaskAst> resolved, int offset) {
    final until = _until.firstMatch(value.trim());
    if (until != null) {
      final dependencies = until.group(1)!.split(RegExp(r'\s+'));
      final tasks = dependencies.map((id) => resolved[id]).whereType<GanttTaskAst>().toList();
      if (tasks.length != dependencies.length) return null;
      final end = tasks.map((task) => task.start).reduce((left, right) => left.isBefore(right) ? left : right);
      return _EndResult(end, false);
    }
    final explicit = _tryParseDate(value, dateFormat);
    if (explicit != null) {
      return _EndResult(inclusiveEndDates ? explicit.add(const Duration(days: 1)) : explicit, true);
    }
    final duration = _duration.firstMatch(value.trim());
    if (duration == null) throwParseError(source, 'Invalid Gantt duration or end date: $value', offset);
    return _EndResult(_addDuration(start, double.parse(duration.group(1)!), duration.group(2)!), false);
  }

  ({DateTime end, DateTime? renderEnd}) _adjustExcludedDates(DateTime cursor, DateTime originalEnd) {
    var end = originalEnd;
    DateTime? renderEnd;
    var invalid = false;
    for (var iterations = 0; !cursor.isAfter(end); iterations++) {
      if (iterations >= 10000) {
        throwParseError(source, 'Failed to find a valid date excluded by Gantt excludes', 0);
      }
      if (!invalid) renderEnd = end;
      invalid = _isExcluded(cursor);
      if (invalid) end = end.add(const Duration(days: 1));
      cursor = cursor.add(const Duration(days: 1));
    }
    return (end: end, renderEnd: renderEnd);
  }

  bool _isExcluded(DateTime date) {
    final formatted = _formatDayJs(date, dateFormat);
    final iso = _isoDate(date);
    if (includes.contains(formatted.toLowerCase()) || includes.contains(iso)) return false;
    if (excludes.contains('weekends')) {
      final first = weekendStart == GanttWeekendStart.friday ? DateTime.friday : DateTime.saturday;
      final second = first == DateTime.saturday ? DateTime.sunday : DateTime.saturday;
      if (date.weekday == first || date.weekday == second) return true;
    }
    final weekdayName = GanttWeekday.values[date.weekday - 1].name;
    return excludes.contains(weekdayName) || excludes.contains(formatted.toLowerCase()) || excludes.contains(iso);
  }
}

final class _RawSection {
  _RawSection(this.name);
  final String name;
  final tasks = <_RawTask>[];
}

final class _RawTask {
  const _RawTask({
    required this.id,
    required this.label,
    required this.section,
    required this.startData,
    required this.endData,
    required this.status,
    required this.critical,
    required this.milestone,
    required this.vertical,
    required this.offset,
  });
  final String id;
  final String label;
  final String section;
  final String? startData;
  final String endData;
  final GanttTaskStatus status;
  final bool critical;
  final bool milestone;
  final bool vertical;
  final int offset;
}

final class _Interaction {
  const _Interaction(this.ids, this.href, this.callback, this.offset);
  final List<String> ids;
  final String? href;
  final GanttCallbackAst? callback;
  final int offset;
}

final class _EndResult {
  const _EndResult(this.end, this.manual);
  final DateTime end;
  final bool manual;
}

GanttTaskAst _copyTask(GanttTaskAst task, {String? link, GanttCallbackAst? callback}) => GanttTaskAst(
  id: task.id,
  label: task.label,
  section: task.section,
  start: task.start,
  end: task.end,
  renderEnd: task.renderEnd,
  status: task.status,
  critical: task.critical,
  milestone: task.milestone,
  vertical: task.vertical,
  link: link ?? task.link,
  callback: callback ?? task.callback,
);

List<String> _splitCallbackArguments(String source) {
  if (source.trim().isEmpty) return const [];
  final result = <String>[];
  final buffer = StringBuffer();
  var quoted = false;
  for (final rune in source.runes) {
    final char = String.fromCharCode(rune);
    if (char == '"') quoted = !quoted;
    if (char == ',' && !quoted) {
      result.add(_unquoteArgument(buffer.toString()));
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  result.add(_unquoteArgument(buffer.toString()));
  return result;
}

String _unquoteArgument(String value) {
  final trimmed = value.trim();
  return trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"')
      ? trimmed.substring(1, trimmed.length - 1)
      : trimmed;
}

DateTime _parseDate(String value, String format, String source, int offset) {
  final parsed = _tryParseDate(value, format);
  if (parsed == null) throwParseError(source, 'Invalid Gantt date: $value', offset);
  return parsed;
}

DateTime? _tryParseDate(String value, String format) {
  final trimmed = value.trim();
  final trimmedFormat = format.trim();
  if (trimmedFormat == 'x' || trimmedFormat == 'X') {
    final number = int.tryParse(trimmed);
    if (number == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(trimmedFormat == 'X' ? number * 1000 : number);
  }
  final pattern = trimmedFormat.isEmpty ? 'YYYY-MM-DD' : trimmedFormat;
  const tokens = ['YYYY', 'SSS', 'YY', 'MM', 'DD', 'HH', 'mm', 'ss', 'M', 'D', 'H', 'm', 's'];
  final fields = <String>[];
  final expression = StringBuffer('^');
  for (var index = 0; index < pattern.length;) {
    final token = tokens.where((token) => pattern.startsWith(token, index)).firstOrNull;
    if (token == null) {
      expression.write(RegExp.escape(pattern[index]));
      index++;
    } else {
      fields.add(token);
      expression.write(
        token == 'YYYY' || token == 'SSS'
            ? r'(\d{'
                  '${token.length}'
                  r'})'
            : r'(\d{1,2})',
      );
      index += token.length;
    }
  }
  expression.write(r'$');
  final match = RegExp(expression.toString()).firstMatch(trimmed);
  if (match == null) return null;
  var year = 1970;
  var month = 1;
  var day = 1;
  var hour = 0;
  var minute = 0;
  var second = 0;
  var millisecond = 0;
  for (var index = 0; index < fields.length; index++) {
    final number = int.parse(match.group(index + 1)!);
    switch (fields[index]) {
      case 'YYYY':
        year = number;
      case 'YY':
        year = 2000 + number;
      case 'MM' || 'M':
        month = number;
      case 'DD' || 'D':
        day = number;
      case 'HH' || 'H':
        hour = number;
      case 'mm' || 'm':
        minute = number;
      case 'ss' || 's':
        second = number;
      case 'SSS':
        millisecond = number;
    }
  }
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

DateTime _addDuration(DateTime start, double value, String unit) => switch (unit) {
  'ms' => start.add(Duration(microseconds: (value * Duration.microsecondsPerMillisecond).round())),
  's' => start.add(Duration(microseconds: (value * Duration.microsecondsPerSecond).round())),
  'm' => start.add(Duration(microseconds: (value * Duration.microsecondsPerMinute).round())),
  'h' => start.add(Duration(microseconds: (value * Duration.microsecondsPerHour).round())),
  'd' => start.add(Duration(microseconds: (value * Duration.microsecondsPerDay).round())),
  'w' => start.add(Duration(microseconds: (value * Duration.microsecondsPerDay * 7).round())),
  'M' => _addCalendarMonths(start, value),
  'y' => _addCalendarMonths(start, value * 12),
  _ => start,
};

DateTime _addCalendarMonths(DateTime start, double months) {
  final whole = months.truncate();
  final totalMonths = start.year * 12 + start.month - 1 + whole;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final day = start.day.clamp(1, DateTime(year, month + 1, 0).day);
  final result = DateTime(
    year,
    month,
    day,
    start.hour,
    start.minute,
    start.second,
    start.millisecond,
    start.microsecond,
  );
  final fraction = months - whole;
  return fraction == 0
      ? result
      : result.add(Duration(microseconds: (fraction * 30 * Duration.microsecondsPerDay).round()));
}

String _formatDayJs(DateTime date, String format) {
  final pattern = format.trim().isEmpty ? 'YYYY-MM-DD' : format.trim();
  final replacements = <String, String>{
    'YYYY': date.year.toString().padLeft(4, '0'),
    'YY': (date.year % 100).toString().padLeft(2, '0'),
    'MM': date.month.toString().padLeft(2, '0'),
    'M': date.month.toString(),
    'DD': date.day.toString().padLeft(2, '0'),
    'D': date.day.toString(),
    'HH': date.hour.toString().padLeft(2, '0'),
    'H': date.hour.toString(),
    'mm': date.minute.toString().padLeft(2, '0'),
    'm': date.minute.toString(),
    'ss': date.second.toString().padLeft(2, '0'),
    's': date.second.toString(),
    'SSS': date.millisecond.toString().padLeft(3, '0'),
  };
  return pattern.replaceAllMapped(
    RegExp(r'YYYY|SSS|YY|MM|DD|HH|mm|ss|M|D|H|m|s'),
    (match) => replacements[match.group(0)]!,
  );
}

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
