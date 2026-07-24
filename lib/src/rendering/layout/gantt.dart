part of '../layout.dart';

const _ganttDefaultWidth = 1200.0;
const _ganttAxisBottomOffset = 50.0;
const _ganttAxisFontSize = 10.0;
// Mermaid's bottom D3 axis applies `dy="1em"` after positioning a tick label.
const _ganttBottomAxisLabelDy = _ganttAxisFontSize;
const _ganttTaskRadius = 3.0;
const _ganttTaskStrokeWidth = 2.0;
const _ganttMilestoneScale = 0.8;
const _ganttVerticalWidthFactor = 0.08;
const _ganttVerticalLabelOffset = 60.0;

_LayoutResult _layoutGantt(GanttAst ast, _LayoutContext context) {
  final options = context.options.optionsFor(const GanttRenderOptions());
  final width = options.useWidth ?? _ganttDefaultWidth;
  final tasks = ast.tasks;
  if (tasks.isEmpty) {
    return _LayoutResult(width, options.topPadding * 2, [
      ?_ganttTitle(ast, context, options, width),
    ], bounds: Bounds(left: 0, top: 0, width: width, height: options.topPadding * 2));
  }

  final nonVertical = tasks.where((task) => !task.vertical).toList();
  final rows = _ganttRows(ast, options, nonVertical);
  final rowCount = rows.values.fold<int>(0, (count, row) => math.max(count, row + 1));
  final height = 2 * options.topPadding + rowCount * (options.barHeight + options.barGap);
  final minTime = tasks.map((task) => task.start).reduce((left, right) => left.isBefore(right) ? left : right);
  final maxTime = tasks.map((task) => task.end).reduce((left, right) => left.isAfter(right) ? left : right);
  final scale = _GanttTimeScale(
    minTime,
    maxTime.isAfter(minTime) ? maxTime : minTime.add(const Duration(days: 1)),
    width - options.leftPadding - options.rightPadding,
  );
  final elements = <SceneElement>[
    ..._ganttExcludedRanges(ast, context, options, scale, height),
    ..._ganttAxes(ast, context, options, scale, width, height),
    ..._ganttSectionBands(ast, context, options, rows, width),
    ..._ganttTasks(ast, context, options, scale, rows, width, nonVertical.length),
    ..._ganttSectionLabels(ast, context, options, rows),
    ..._ganttToday(ast, context, options, scale, height),
    ?_ganttTitle(ast, context, options, width),
  ];
  return _LayoutResult(
    width,
    height,
    elements,
    bounds: Bounds(left: 0, top: 0, width: width, height: height),
  );
}

/// The diagram title, drawn the same way whether or not the chart has tasks.
SceneElement? _ganttTitle(GanttAst ast, _LayoutContext context, GanttRenderOptions options, double width) {
  if (ast.title case final title?) {
    return _ganttText(
      context,
      title,
      width / 2,
      options.titleTopMargin,
      fontSize: 18,
      color: options.titleColor,
      anchor: TextAnchor.middle,
      baseline: TextBaseline.alphabetic,
      role: SemanticRole.title,
      classes: const ['titleText'],
    );
  }
  return null;
}

Map<String, int> _ganttRows(GanttAst ast, GanttRenderOptions options, List<GanttTaskAst> tasks) {
  if (options.displayMode == GanttDisplayMode.normal) {
    return {for (final (index, task) in tasks.indexed) task.id: index};
  }
  final rows = <String, int>{};
  var sectionOffset = 0;
  for (final section in ast.sections) {
    final sectionTasks = section.tasks.where((task) => !task.vertical).toList()
      ..sort((left, right) {
        final start = left.start.compareTo(right.start);
        return start != 0 ? start : tasks.indexOf(left).compareTo(tasks.indexOf(right));
      });
    final laneEnds = <DateTime>[];
    for (final task in sectionTasks) {
      var lane = laneEnds.indexWhere((end) => !task.start.isBefore(end));
      if (lane < 0) {
        lane = laneEnds.length;
        laneEnds.add(task.end);
      } else {
        laneEnds[lane] = task.end;
      }
      rows[task.id] = sectionOffset + lane;
    }
    sectionOffset += laneEnds.length;
  }
  return rows;
}

Iterable<SceneElement> _ganttSectionBands(
  GanttAst ast,
  _LayoutContext context,
  GanttRenderOptions options,
  Map<String, int> rows,
  double width,
) sync* {
  final gap = options.barHeight + options.barGap;
  final firstByRow = <int, GanttTaskAst>{};
  for (final task in ast.tasks.where((task) => !task.vertical)) {
    firstByRow.putIfAbsent(rows[task.id]!, () => task);
  }
  final sectionIndexes = {for (final (index, section) in ast.sections.indexed) section.name: index};
  for (final entry in firstByRow.entries) {
    final style = (sectionIndexes[entry.value.section] ?? 0) % _ganttStyleCount(options);
    yield SceneRect(
      id: context.id('section'),
      bounds: Bounds(
        left: 0,
        top: entry.key * gap + options.topPadding - 2,
        width: width - options.rightPadding / 2,
        height: gap,
      ),
      fill: SolidFill(_ganttSectionColor(options, style)),
      role: SemanticRole.group,
      cssClasses: ['section', 'section$style'],
      label: entry.value.section,
    );
  }
}

Iterable<SceneElement> _ganttTasks(
  GanttAst ast,
  _LayoutContext context,
  GanttRenderOptions options,
  _GanttTimeScale scale,
  Map<String, int> rows,
  double width,
  int nonVerticalCount,
) sync* {
  final tasks = [...ast.tasks]..sort((left, right) => left.start.compareTo(right.start));
  final gap = options.barHeight + options.barGap;
  final sectionIndexes = {for (final (index, section) in ast.sections.indexed) section.name: index};

  for (final task in tasks) {
    final sectionStyle = (sectionIndexes[task.section] ?? 0) % _ganttStyleCount(options);
    final startX = scale(task.start);
    final logicalEndX = scale(task.end);
    final renderEndX = scale(task.renderEnd ?? task.end);
    final row = rows[task.id] ?? -1;
    final taskClasses = _ganttTaskClasses(task, sectionStyle);
    final (:fill, :stroke) = _ganttTaskPaint(task, options);

    if (task.vertical) {
      final markerX = startX + options.leftPadding;
      yield SceneRect(
        id: task.id,
        bounds: Bounds(
          left: markerX,
          top: options.gridLineStartPadding,
          width: options.barHeight * _ganttVerticalWidthFactor,
          height: nonVerticalCount * gap + options.barHeight * 2,
        ),
        radiusX: _ganttTaskRadius,
        radiusY: _ganttTaskRadius,
        fill: SolidFill(options.taskBackground),
        stroke: SceneStroke(color: options.verticalLineColor, width: _ganttTaskStrokeWidth),
        role: SemanticRole.annotation,
        cssClasses: taskClasses,
        label: task.label,
      );
      yield _ganttText(
        context,
        task.label,
        markerX,
        options.gridLineStartPadding + nonVerticalCount * gap + _ganttVerticalLabelOffset,
        fontSize: 15,
        color: options.verticalLineColor,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.alphabetic,
        link: task.link,
        classes: [..._ganttTaskTextClasses(task, sectionStyle, outside: false), 'vertText'],
      );
      continue;
    }

    var taskLeft = startX + options.leftPadding;
    var taskWidth = renderEndX - startX;
    if (task.milestone) {
      taskLeft = startX + options.leftPadding + 0.5 * (logicalEndX - startX) - 0.5 * options.barHeight;
      taskWidth = options.barHeight;
    }
    final taskTop = row * gap + options.topPadding;
    final rect = SceneRect(
      id: task.id,
      bounds: Bounds(left: taskLeft, top: taskTop, width: taskWidth, height: options.barHeight),
      radiusX: _ganttTaskRadius,
      radiusY: _ganttTaskRadius,
      fill: SolidFill(fill),
      stroke: SceneStroke(color: stroke, width: _ganttTaskStrokeWidth),
      role: SemanticRole.node,
      cssClasses: taskClasses,
      label: task.label,
    );
    if (task.milestone) {
      final center = Point(taskLeft + options.barHeight / 2, taskTop + options.barHeight / 2);
      yield SceneGroup(
        id: context.id('milestone'),
        transforms: [
          Translate(center.x, center.y),
          const Rotate(45),
          const Scale(_ganttMilestoneScale),
          Translate(-center.x, -center.y),
        ],
        children: [rect],
        role: SemanticRole.node,
        cssClasses: const ['milestone-group'],
      );
    } else {
      yield rect;
    }

    final textStyle = SceneTextStyle(
      fontFamily: context.options.theme.fontFamily,
      fontSize: options.fontSize,
      color: task.link == null ? options.taskText : options.clickableTaskText,
    );
    final measured = context.measurer.measure(task.label, textStyle);
    final labelStartX = task.milestone ? startX + 0.5 * (logicalEndX - startX) - 0.5 * options.barHeight : startX;
    final labelEndX = task.milestone ? labelStartX + options.barHeight : renderEndX;
    final visibleWidth = labelEndX - labelStartX;
    final outside = measured.width > visibleWidth;
    final positionOutsideLeft = outside && labelEndX + measured.width + 1.5 * options.leftPadding > width;
    final classEndX = task.milestone ? startX + options.barHeight : renderEndX;
    final outsideLeft = outside && classEndX + measured.width + 1.5 * options.leftPadding > width;
    final x = outside
        ? positionOutsideLeft
              ? labelStartX + options.leftPadding - 5
              : labelEndX + options.leftPadding + 5
        : labelStartX + options.leftPadding + visibleWidth / 2;
    final color = task.link != null
        ? options.clickableTaskText
        : outside
        ? options.taskTextOutside
        : _ganttInsideTextColor(task, options);
    yield _ganttText(
      context,
      task.label,
      x,
      row * gap + options.barHeight / 2 + (options.fontSize / 2 - 2) + options.topPadding,
      fontSize: options.fontSize,
      color: color,
      anchor: outside ? (outsideLeft ? TextAnchor.end : TextAnchor.start) : TextAnchor.middle,
      baseline: TextBaseline.alphabetic,
      link: task.link,
      fontStyle: task.milestone ? FontStyle.italic : FontStyle.normal,
      classes: _ganttTaskTextClasses(task, sectionStyle, outside: outside, outsideLeft: outsideLeft),
    );
  }
}

Iterable<SceneElement> _ganttSectionLabels(
  GanttAst ast,
  _LayoutContext context,
  GanttRenderOptions options,
  Map<String, int> rows,
) sync* {
  final gap = options.barHeight + options.barGap;
  final sectionIndexes = {for (final (index, section) in ast.sections.indexed) section.name: index};
  for (final section in ast.sections) {
    final sectionRows = section.tasks.where((task) => !task.vertical).map((task) => rows[task.id]!).toSet().toList()
      ..sort();
    if (sectionRows.isEmpty) continue;
    final y = (sectionRows.first + sectionRows.last + 1) * gap / 2 + options.topPadding;
    final lines = section.name.split(RegExp(r'<br\s*/?>|</br\s*>', caseSensitive: false));
    for (final (index, line) in lines.indexed) {
      yield _ganttText(
        context,
        line,
        10,
        y + (index - (lines.length - 1) / 2) * options.sectionFontSize,
        fontSize: options.sectionFontSize,
        color: options.titleColor,
        baseline: TextBaseline.alphabetic,
        classes: ['sectionTitle', 'sectionTitle${sectionIndexes[section.name]! % _ganttStyleCount(options)}'],
      );
    }
  }
}

Iterable<SceneElement> _ganttAxes(
  GanttAst ast,
  _LayoutContext context,
  GanttRenderOptions options,
  _GanttTimeScale scale,
  double width,
  double height,
) sync* {
  final interval = ast.tickInterval ?? options.tickInterval ?? const GanttTickInterval(1, GanttTickUnit.day);
  final ticks = _ganttTicks(scale.start, scale.end, interval, ast.weekday);
  final format = ast.axisFormat ?? (ast.dateFormat == 'D' ? '%d' : options.axisFormat);
  final axisYValues = <double>[height - _ganttAxisBottomOffset];
  if (ast.topAxis || options.topAxis) axisYValues.add(options.topPadding);
  for (final axisY in axisYValues) {
    final top = axisY == options.topPadding;
    final gridEnd = top
        ? axisY + height - options.topPadding - options.gridLineStartPadding
        : axisY - height + options.topPadding + options.gridLineStartPadding;
    yield ScenePath(
      id: context.id('axis'),
      commands: [
        MoveTo(Point(options.leftPadding + 0.5, gridEnd)),
        LineTo(Point(options.leftPadding + 0.5, axisY + 0.5)),
        LineTo(Point(width - options.rightPadding + 0.5, axisY + 0.5)),
        LineTo(Point(width - options.rightPadding + 0.5, gridEnd)),
      ],
      fill: const NoFill(),
      stroke: const SceneStroke(color: Color(0, 0, 0), width: 0),
      role: SemanticRole.annotation,
      cssClasses: const ['grid', 'domain'],
    );
    for (final tick in ticks) {
      final x = options.leftPadding + scale(tick) + 0.5;
      yield SceneLine(
        id: context.id('tick'),
        start: Point(x, axisY),
        end: Point(x, gridEnd),
        stroke: const SceneStroke(color: Color(0, 0, 0, 204)),
        role: SemanticRole.annotation,
        cssClasses: const ['grid', 'tick'],
      );
      yield _ganttText(
        context,
        _formatD3Date(tick, format),
        x,
        axisY + (top ? -3 : 3 + _ganttBottomAxisLabelDy),
        fontSize: _ganttAxisFontSize,
        color: const Color(51, 51, 51, 204),
        anchor: TextAnchor.middle,
        baseline: TextBaseline.alphabetic,
        classes: const ['grid', 'tick-label'],
      );
    }
  }
}

Iterable<SceneElement> _ganttExcludedRanges(
  GanttAst ast,
  _LayoutContext context,
  GanttRenderOptions options,
  _GanttTimeScale scale,
  double height,
) sync* {
  if (ast.excludes.isEmpty && ast.includes.isEmpty) return;
  DateTime? rangeStart;
  DateTime? rangeEnd;
  var day = DateTime(scale.start.year, scale.start.month, scale.start.day);
  final finalDay = DateTime(scale.end.year, scale.end.month, scale.end.day);
  final ranges = <(DateTime, DateTime)>[];
  while (!day.isAfter(finalDay)) {
    if (_ganttDateExcluded(ast, day)) {
      rangeStart ??= day;
      rangeEnd = day;
    } else if (rangeStart != null) {
      ranges.add((rangeStart, rangeEnd!));
      rangeStart = null;
    }
    day = day.add(const Duration(days: 1));
  }
  if (rangeStart != null) ranges.add((rangeStart, rangeEnd!));
  for (final (start, end) in ranges) {
    yield SceneRect(
      id: context.id('exclude'),
      bounds: Bounds(
        left: options.leftPadding + scale(start),
        top: options.gridLineStartPadding,
        width: scale(end.add(const Duration(days: 1))) - scale(start),
        height: height - options.topPadding - options.gridLineStartPadding,
      ),
      fill: SolidFill(options.excludeBackground),
      role: SemanticRole.background,
      cssClasses: const ['exclude-range'],
    );
  }
}

Iterable<SceneElement> _ganttToday(
  GanttAst ast,
  _LayoutContext context,
  GanttRenderOptions options,
  _GanttTimeScale scale,
  double height,
) sync* {
  if (ast.todayMarker is GanttTodayMarkerOff) return;
  final x = options.leftPadding + scale(DateTime.now());
  yield SceneLine(
    id: context.id('today'),
    start: Point(x, options.titleTopMargin),
    end: Point(x, height - options.titleTopMargin),
    stroke: SceneStroke(color: options.todayLineColor, width: 2),
    role: SemanticRole.annotation,
    cssClasses: const ['today'],
  );
}

SceneText _ganttText(
  _LayoutContext context,
  String value,
  double x,
  double y, {
  required double fontSize,
  required Color color,
  TextAnchor anchor = TextAnchor.start,
  TextBaseline baseline = TextBaseline.central,
  SemanticRole role = SemanticRole.label,
  String? link,
  FontStyle fontStyle = FontStyle.normal,
  List<String> classes = const [],
}) => _text(
  context,
  value,
  x,
  y,
  anchor: anchor,
  baseline: baseline,
  role: role,
  style: SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: fontSize,
    style: fontStyle,
    color: color,
  ),
  link: link,
  cssClasses: classes,
);

({Color fill, Color stroke}) _ganttTaskPaint(GanttTaskAst task, GanttRenderOptions options) {
  if (task.status == GanttTaskStatus.active) {
    return (
      fill: options.activeTaskBackground,
      stroke: task.critical ? options.criticalTaskBorder : options.activeTaskBorder,
    );
  }
  if (task.status == GanttTaskStatus.done) {
    return (
      fill: options.doneTaskBackground,
      stroke: task.critical ? options.criticalTaskBorder : options.doneTaskBorder,
    );
  }
  return task.critical
      ? (fill: options.criticalTaskBackground, stroke: options.criticalTaskBorder)
      : (fill: options.taskBackground, stroke: options.taskBorder);
}

Color _ganttInsideTextColor(GanttTaskAst task, GanttRenderOptions options) =>
    task.status == GanttTaskStatus.planned && !task.critical ? options.taskText : options.taskTextOutside;

List<String> _ganttTaskClasses(GanttTaskAst task, int sectionStyle) {
  final state = switch ((task.status, task.critical)) {
    (GanttTaskStatus.active, true) => 'activeCrit',
    (GanttTaskStatus.active, false) => 'active',
    (GanttTaskStatus.done, true) => 'doneCrit',
    (GanttTaskStatus.done, false) => 'done',
    (GanttTaskStatus.planned, true) => 'crit',
    (GanttTaskStatus.planned, false) => 'task',
  };
  return ['task', if (task.milestone) 'milestone', if (task.vertical) 'vert', '$state$sectionStyle'];
}

List<String> _ganttTaskTextClasses(
  GanttTaskAst task,
  int sectionStyle, {
  required bool outside,
  bool outsideLeft = false,
}) => [
  outside ? (outsideLeft ? 'taskTextOutsideLeft' : 'taskTextOutsideRight') : 'taskText',
  outside ? 'taskTextOutside$sectionStyle' : 'taskText$sectionStyle',
  if (task.status == GanttTaskStatus.active) 'activeText$sectionStyle',
  if (task.status == GanttTaskStatus.done) 'doneText$sectionStyle',
  if (task.critical) 'critText$sectionStyle',
  if (task.milestone) 'milestoneText',
  if (task.vertical) 'vertText',
  if (task.link != null) 'clickable',
];

Color _ganttSectionColor(GanttRenderOptions options, int style) => switch (style) {
  1 || 3 => options.alternateSectionBackground,
  2 => options.sectionBackground2,
  _ => options.sectionBackground,
};

bool _ganttDateExcluded(GanttAst ast, DateTime date) => ganttDateExcluded(
  date,
  dateFormat: ast.dateFormat,
  excludes: ast.excludes,
  includes: ast.includes,
  weekendStart: ast.weekendStart,
);

int _ganttStyleCount(GanttRenderOptions options) => options.numberSectionStyles > 0 ? options.numberSectionStyles : 1;

List<DateTime> _ganttTicks(DateTime start, DateTime end, GanttTickInterval interval, GanttWeekday weekday) {
  var tick = _floorGanttTick(start, interval.unit, weekday);
  while (tick.isBefore(start)) {
    tick = _addGanttTick(tick, interval);
  }
  final result = <DateTime>[];
  for (var count = 0; !tick.isAfter(end) && count < 10000; count++) {
    result.add(tick);
    tick = _addGanttTick(tick, interval);
  }
  return result;
}

DateTime _floorGanttTick(DateTime value, GanttTickUnit unit, GanttWeekday weekday) => switch (unit) {
  GanttTickUnit.millisecond => value,
  GanttTickUnit.second => DateTime(value.year, value.month, value.day, value.hour, value.minute, value.second),
  GanttTickUnit.minute => DateTime(value.year, value.month, value.day, value.hour, value.minute),
  GanttTickUnit.hour => DateTime(value.year, value.month, value.day, value.hour),
  GanttTickUnit.day => DateTime(value.year, value.month, value.day),
  GanttTickUnit.week => DateTime(
    value.year,
    value.month,
    value.day,
  ).subtract(Duration(days: (value.weekday - (weekday.index + 1)) % DateTime.daysPerWeek)),
  GanttTickUnit.month => DateTime(value.year, value.month),
};

DateTime _addGanttTick(DateTime value, GanttTickInterval interval) => switch (interval.unit) {
  GanttTickUnit.millisecond => value.add(Duration(milliseconds: interval.count)),
  GanttTickUnit.second => value.add(Duration(seconds: interval.count)),
  GanttTickUnit.minute => value.add(Duration(minutes: interval.count)),
  GanttTickUnit.hour => value.add(Duration(hours: interval.count)),
  GanttTickUnit.day => value.add(Duration(days: interval.count)),
  GanttTickUnit.week => value.add(Duration(days: 7 * interval.count)),
  GanttTickUnit.month => DateTime(value.year, value.month + interval.count, value.day),
};

String _formatD3Date(DateTime value, String format) {
  const shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const longMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  const shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const longWeekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final values = <String, String>{
    '%Y': value.year.toString().padLeft(4, '0'),
    '%y': (value.year % 100).toString().padLeft(2, '0'),
    '%m': value.month.toString().padLeft(2, '0'),
    '%d': value.day.toString().padLeft(2, '0'),
    '%H': value.hour.toString().padLeft(2, '0'),
    '%M': value.minute.toString().padLeft(2, '0'),
    '%S': value.second.toString().padLeft(2, '0'),
    '%L': value.millisecond.toString().padLeft(3, '0'),
    '%b': shortMonths[value.month - 1],
    '%B': longMonths[value.month - 1],
    '%a': shortWeekdays[value.weekday - 1],
    '%A': longWeekdays[value.weekday - 1],
  };
  return format.replaceAllMapped(RegExp(r'%[YymdHMSLbBaA]'), (match) => values[match.group(0)]!);
}

final class _GanttTimeScale {
  const _GanttTimeScale(this.start, this.end, this.width);
  final DateTime start;
  final DateTime end;
  final double width;

  double call(DateTime value) {
    final span = end.millisecondsSinceEpoch - start.millisecondsSinceEpoch;
    return (value.millisecondsSinceEpoch - start.millisecondsSinceEpoch) / span * width;
  }
}
