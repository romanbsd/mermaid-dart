part of '../layout.dart';

const _timelineOuterTop = 50.0;
const _timelineBlockWidth = 190.0;
const _timelineSectionWidthPerPeriod = 200.0;
const _timelineBlockHeight = 67.8;
const _timelineEventHeight = 50.0;
const _timelineEventGap = 10.0;
const _timelineSectionTaskGap = 50.0;
const _timelineTaskAxisGap = 50.0;
const _timelineAxisEventGap = 82.2;
const _timelineTail = 63.4;
const _timelineAxisStart = 50.0;
const _timelineAxisEndPadding = 240.0;
const _timelineAxisWidth = 4.0;
// Mermaid's vertical renderer uses independently sized left task and right
// event columns; it is not a rotation of the classic horizontal renderer.
const _timelineVerticalNodeWidth = 200.0;
const _timelineVerticalEventWidth = 300.0;
const _timelineVerticalNodePadding = 5.0;
const _timelineVerticalNodeHeight = 32.8;
const _timelineVerticalEventSpacing = 10.0;
const _timelineVerticalSectionTaskGap = 20.0;
const _timelineVerticalTaskAxisGap = 20.0;
const _timelineVerticalTaskGap = 30.0;
const _timelineVerticalEventAxisGap = 50.0;
const _timelineVerticalOuterTop = 50.0;
const _timelineVerticalOuterLeft = 50.0;
const _timelineVerticalTitleSize = 32.0;
const _timelineVerticalLabelBaselineOffset = 2.1;
// Mermaid's default `cScaleInv0` and `cScaleInv1`, used by the first two
// timeline section baselines after the renderer's section-index offset.
const _timelineInverseScale = [Color(255, 255, 185), Color(171, 171, 255)];

({SolidFill fill, SceneStroke stroke, Color text}) _timelineStyle(MermaidTheme theme, int index) {
  final colorIndex = index % theme.categoricalColors.length;
  final lineColor = colorIndex < _timelineInverseScale.length
      ? _timelineInverseScale[colorIndex]
      : theme.categoricalPeerColors[colorIndex];
  return (
    fill: SolidFill(theme.categoricalColors[colorIndex]),
    stroke: SceneStroke(color: lineColor, width: 3),
    text: theme.categoricalLabelColors[colorIndex],
  );
}

_LayoutResult _layoutTimeline(TimelineAst ast, _LayoutContext context) {
  if (ast.direction == TimelineDirection.topDown) {
    return _layoutTimelineVertical(ast, context);
  }
  final config = context.options.optionsFor(const TimelineRenderOptions());
  final theme = context.options.theme;
  final sections = ast.sections.isEmpty ? const [TimelineSectionAst(name: '')] : ast.sections;
  final maxEvents = ast.periods.fold<int>(0, (value, period) => math.max(value, period.events.length));

  final sectionTop = _timelineOuterTop;
  final taskTop = sectionTop + _timelineBlockHeight + _timelineSectionTaskGap;
  final axisY = taskTop + _timelineBlockHeight + _timelineTaskAxisGap;
  final eventTop = axisY + _timelineAxisEventGap;
  final verticalEnd =
      eventTop +
      math.max(maxEvents, 1) * (_timelineEventHeight + _timelineEventGap) -
      _timelineEventGap +
      _timelineTail;
  final elements = <SceneElement>[];
  var sectionX = config.leftMargin - _timelineAxisStart;

  for (var sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
    final section = sections[sectionIndex];
    final periodCount = math.max(section.periods.length, 1);
    final sectionWidth = periodCount * _timelineSectionWidthPerPeriod - 10;
    final style = _timelineStyle(theme, sectionIndex);
    if (section.name.isNotEmpty) {
      _addTimelineNode(
        context,
        elements,
        bounds: Bounds(left: sectionX, top: sectionTop, width: sectionWidth, height: _timelineBlockHeight),
        label: section.name,
        fill: style.fill,
        stroke: style.stroke,
        cssClass: 'timeline-section',
        textColor: style.text,
      );
    }

    for (var periodIndex = 0; periodIndex < section.periods.length; periodIndex++) {
      final period = section.periods[periodIndex];
      final left = sectionX + periodIndex * _timelineSectionWidthPerPeriod;
      final centerX = left + _timelineBlockWidth / 2;
      _addTimelineNode(
        context,
        elements,
        bounds: Bounds(left: left, top: taskTop, width: _timelineBlockWidth, height: _timelineBlockHeight),
        label: period.label,
        fill: style.fill,
        stroke: style.stroke,
        cssClass: 'timeline-period',
        textColor: style.text,
      );
      elements.add(
        SceneLine(
          id: context.id('timeline-guide'),
          start: Point(centerX, taskTop + _timelineBlockHeight),
          end: Point(centerX, verticalEnd),
          stroke: const SceneStroke(color: Color(0, 0, 0), width: 2, dashes: [5, 5]),
          cssClasses: const ['timeline-guide'],
        ),
      );

      for (var eventIndex = 0; eventIndex < period.events.length; eventIndex++) {
        _addTimelineNode(
          context,
          elements,
          bounds: Bounds(
            left: left,
            top: eventTop + eventIndex * (_timelineEventHeight + _timelineEventGap),
            width: _timelineBlockWidth,
            height: _timelineEventHeight,
          ),
          label: period.events[eventIndex],
          fill: style.fill,
          stroke: style.stroke,
          cssClass: 'timeline-event',
          textColor: style.text,
        );
      }
    }
    sectionX += periodCount * _timelineSectionWidthPerPeriod;
  }

  final axisEnd = sectionX + _timelineAxisEndPadding;
  elements.add(
    SceneLine(
      id: context.id('timeline-axis'),
      start: Point(_timelineAxisStart, axisY),
      end: Point(axisEnd, axisY),
      stroke: const SceneStroke(color: Color(0, 0, 0), width: _timelineAxisWidth),
      cssClasses: const ['timeline-axis'],
    ),
  );
  final lrWidth = axisEnd + 50;
  final lrHeight = verticalEnd + 50;
  return _LayoutResult(lrWidth, lrHeight, elements);
}

_LayoutResult _layoutTimelineVertical(TimelineAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const TimelineRenderOptions());
  final theme = context.options.theme;
  final sections = ast.sections.isEmpty ? const [TimelineSectionAst(name: '')] : ast.sections;
  final hasSections = sections.any((section) => section.name.isNotEmpty);
  final taskWidth = _timelineVerticalNodeWidth + 2 * _timelineVerticalNodePadding;
  final eventWidth = _timelineVerticalEventWidth + 2 * _timelineVerticalNodePadding;
  final leftWidth = taskWidth + _timelineVerticalTaskAxisGap;
  final rightWidth = eventWidth + _timelineVerticalEventAxisGap;
  final sectionWidth = leftWidth + rightWidth;
  final sectionX = _timelineVerticalOuterLeft + config.leftMargin;
  final axisX = sectionX + leftWidth;
  final eventX = axisX + _timelineVerticalEventAxisGap;
  final timelineX = hasSections ? axisX : sectionX + leftWidth;
  final maxEventCount = ast.periods.fold<int>(0, (count, period) => math.max(count, period.events.length));
  final maxEventStackHeight = maxEventCount == 0
      ? 0.0
      : maxEventCount * _timelineVerticalNodeHeight + (maxEventCount - 1) * _timelineVerticalEventSpacing;
  final taskSpacing = math.max(_timelineVerticalNodeHeight, maxEventStackHeight) + _timelineVerticalTaskGap;
  final elements = <SceneElement>[];
  var masterY = _timelineVerticalOuterTop;
  var maxNodeBottom = masterY;

  void addPeriod(TimelinePeriodAst period, int colorIndex, double y) {
    final style = _timelineStyle(theme, colorIndex);
    _addTimelineNode(
      context,
      elements,
      bounds: Bounds(
        left: timelineX - _timelineVerticalTaskAxisGap - taskWidth,
        top: y,
        width: taskWidth,
        height: _timelineVerticalNodeHeight,
      ),
      label: period.label,
      fill: style.fill,
      stroke: style.stroke,
      cssClass: 'timeline-period',
      textColor: style.text,
      centerLabel: true,
    );
    for (final (eventIndex, event) in period.events.indexed) {
      final eventY = y + eventIndex * (_timelineVerticalNodeHeight + _timelineVerticalEventSpacing);
      _addTimelineNode(
        context,
        elements,
        bounds: Bounds(
          left: timelineX + _timelineVerticalEventAxisGap,
          top: eventY,
          width: eventWidth,
          height: _timelineVerticalNodeHeight,
        ),
        label: event,
        fill: style.fill,
        stroke: style.stroke,
        cssClass: 'timeline-event',
        textColor: style.text,
        centerLabel: true,
      );
      final lineY = eventY + _timelineVerticalNodeHeight / 2;
      elements.add(
        SceneLine(
          id: context.id('timeline-guide'),
          start: Point(timelineX, lineY),
          end: Point(eventX, lineY),
          stroke: const SceneStroke(color: Color(0, 0, 0), width: 2, dashes: [5, 5]),
          cssClasses: const ['timeline-guide'],
        ),
      );
      maxNodeBottom = math.max(maxNodeBottom, eventY + _timelineVerticalNodeHeight);
    }
    maxNodeBottom = math.max(maxNodeBottom, y + _timelineVerticalNodeHeight);
  }

  for (final (sectionIndex, section) in sections.indexed) {
    final style = _timelineStyle(theme, sectionIndex);
    if (hasSections && section.name.isNotEmpty) {
      _addTimelineNode(
        context,
        elements,
        bounds: Bounds(
          left: timelineX - leftWidth,
          top: masterY,
          width: sectionWidth,
          height: _timelineVerticalNodeHeight,
        ),
        label: section.name,
        fill: style.fill,
        stroke: style.stroke,
        cssClass: 'timeline-section',
        textColor: style.text,
        centerLabel: true,
      );
      maxNodeBottom = math.max(maxNodeBottom, masterY + _timelineVerticalNodeHeight);
    }
    final taskStartY = hasSections ? masterY + _timelineVerticalNodeHeight + _timelineVerticalSectionTaskGap : masterY;
    for (final (periodIndex, period) in section.periods.indexed) {
      addPeriod(period, sectionIndex, taskStartY + periodIndex * taskSpacing);
    }
    if (hasSections) {
      final taskCount = section.periods.length;
      masterY +=
          _timelineVerticalNodeHeight +
          _timelineVerticalSectionTaskGap +
          taskSpacing * math.max(taskCount, 1) -
          (taskCount > 0 ? 2 * _timelineVerticalTaskGap : 0);
    }
  }

  final axisStartY = _timelineVerticalOuterTop - context.options.theme.fontSize * 2;
  final axisEndY = maxNodeBottom + context.options.theme.fontSize * 0.5 + 20;
  elements.add(
    SceneLine(
      id: context.id('timeline-axis'),
      start: Point(timelineX, axisStartY),
      end: Point(timelineX, axisEndY),
      stroke: const SceneStroke(color: Color(0, 0, 0), width: _timelineAxisWidth),
      cssClasses: const ['timeline-axis'],
    ),
  );

  var contentLeft = math.min(timelineX - leftWidth, timelineX);
  var contentTop = axisStartY;
  if (ast.title case final title?) {
    final titleX = sectionWidth / 2 - config.leftMargin;
    elements.add(
      _text(
        context,
        title,
        titleX,
        20,
        baseline: TextBaseline.alphabetic,
        role: SemanticRole.title,
        style: SceneTextStyle(
          fontFamily: theme.fontFamily,
          fontSize: _timelineVerticalTitleSize,
          weight: FontWeight.bold,
          color: theme.primaryText,
        ),
      ),
    );
    contentLeft = math.min(contentLeft, titleX);
    // Browser text metrics place Mermaid's 4ex title roughly eleven pixels
    // above the SVG origin at the default 16px font size.
    contentTop = math.min(contentTop, -11);
  }
  final contentRight = math.max(timelineX + _timelineVerticalEventAxisGap + eventWidth, timelineX);
  final bounds = Bounds(
    left: contentLeft,
    top: contentTop,
    width: contentRight - contentLeft,
    height: axisEndY - contentTop,
  );
  return _LayoutResult(bounds.width, bounds.height, elements, bounds: bounds, viewportPadding: config.padding);
}

void _addTimelineNode(
  _LayoutContext context,
  List<SceneElement> elements, {
  required Bounds bounds,
  required String label,
  required SceneFill fill,
  required SceneStroke stroke,
  required String cssClass,
  required Color textColor,
  bool centerLabel = false,
}) {
  elements.add(
    ScenePath(id: context.id(cssClass), commands: _timelineRoundedTopPath(bounds), fill: fill, cssClasses: [cssClass]),
  );
  elements.add(
    SceneLine(
      id: context.id('$cssClass-line'),
      start: Point(bounds.left, bounds.bottom),
      end: Point(bounds.right, bounds.bottom),
      stroke: stroke,
      cssClasses: ['$cssClass-line'],
    ),
  );
  elements.add(
    _text(
      context,
      label,
      bounds.left + bounds.width / 2,
      centerLabel
          ? bounds.top + bounds.height / 2 + _timelineVerticalLabelBaselineOffset
          : bounds.top + 10 + context.options.theme.fontSize,
      anchor: TextAnchor.middle,
      baseline: TextBaseline.middle,
      style: SceneTextStyle(
        fontFamily: context.options.theme.fontFamily,
        fontSize: context.options.theme.fontSize,
        color: textColor,
      ),
      cssClasses: ['$cssClass-label'],
    ),
  );
}

List<PathCommand> _timelineRoundedTopPath(Bounds bounds) {
  const radius = 5.0;
  final right = bounds.right;
  final bottom = bounds.bottom;
  return [
    MoveTo(Point(bounds.left, bottom - radius)),
    LineTo(Point(bounds.left, bounds.top + radius)),
    QuadraticTo(Point(bounds.left, bounds.top), Point(bounds.left + radius, bounds.top)),
    LineTo(Point(right - radius, bounds.top)),
    QuadraticTo(Point(right, bounds.top), Point(right, bounds.top + radius)),
    LineTo(Point(right, bottom)),
    LineTo(Point(bounds.left, bottom)),
    const ClosePath(),
  ];
}
