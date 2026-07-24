import 'ast.dart';
import 'common_syntax.dart';

/// Parses a Mermaid timeline.
TimelineAst parseTimeline(String source) {
  final header = RegExp(
    r'^[\t \r\n]*timeline(?:[ \t]+(LR|TD))?(?=\s|$)',
    caseSensitive: false,
  ).firstMatch(hideIgnoredSyntax(source));
  if (header == null) {
    throwParseError(source, 'Expected timeline', firstNonWhitespaceOffset(source));
  }
  final direction = header.group(1)?.toUpperCase() == 'TD' ? TimelineDirection.topDown : TimelineDirection.leftRight;
  final normalizedSource = source.replaceRange(header.start, header.end, header.group(0)!.toLowerCase());
  final prepared = prepareDiagramSource(
    normalizedSource,
    headers: [if (header.group(1) case final value?) 'timeline ${value.toLowerCase()}', 'timeline'],
  );
  final sections = <_MutableTimelineSection>[];
  _MutableTimelineSection? current;
  _MutableTimelinePeriod? lastPeriod;

  for (final line in sourceLines(prepared.syntax)) {
    final text = line.text.trim();
    if (text.isEmpty) continue;
    if (RegExp(r'^section(?:\s|$)', caseSensitive: false).hasMatch(text)) {
      final name = text.substring('section'.length).trim();
      if (name.isEmpty) throwParseError(source, 'Expected a section name', line.offset);
      current = _MutableTimelineSection(name);
      sections.add(current);
      lastPeriod = null;
      continue;
    }
    if (text.startsWith(':')) {
      if (lastPeriod == null) {
        throwParseError(source, 'A timeline event must follow a period', line.offset);
      }
      lastPeriod.events.addAll(_timelineFields(text.substring(1)));
      continue;
    }

    if (current == null) {
      current = _MutableTimelineSection('');
      sections.add(current);
    }
    final fields = _timelineFields(text);
    if (fields.isEmpty || fields.first.isEmpty) {
      throwParseError(source, 'Expected a timeline period', line.offset);
    }
    lastPeriod = _MutableTimelinePeriod(fields.first)..events.addAll(fields.skip(1));
    current.periods.add(lastPeriod);
  }

  return TimelineAst(
    direction: direction,
    sections: [for (final section in sections) section.freeze()],
    title: prepared.metadata.title,
    accessibilityTitle: prepared.metadata.accessibilityTitle,
    accessibilityDescription: prepared.metadata.accessibilityDescription,
  );
}

List<String> _timelineFields(String text) =>
    text.split(RegExp(r':\s+')).map((value) => value.trim()).where((value) => value.isNotEmpty).toList();

final class _MutableTimelineSection {
  _MutableTimelineSection(this.name);

  final String name;
  final periods = <_MutableTimelinePeriod>[];

  TimelineSectionAst freeze() =>
      TimelineSectionAst(name: name, periods: [for (final period in periods) period.freeze()]);
}

final class _MutableTimelinePeriod {
  _MutableTimelinePeriod(this.label);

  final String label;
  final events = <String>[];

  TimelinePeriodAst freeze() => TimelinePeriodAst(label: label, events: List.unmodifiable(events));
}
