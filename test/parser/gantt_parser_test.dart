import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('gantt parser', () {
    test('accepts the case-insensitive header and common metadata', () {
      final ast =
          parse(DiagramType.gantt, '''
GANTT
title Delivery plan
accTitle: Accessible plan
accDescr {
  First line
  second line
}
''')
              as GanttAst;

      expect(ast.title, 'Delivery plan');
      expect(ast.accessibilityTitle, 'Accessible plan');
      expect(ast.accessibilityDescription, 'First line\nsecond line');
      expect(ast.sections, isEmpty);
    });

    test('ports upstream configuration and merges include/exclude tokens', () {
      final ast =
          parse(DiagramType.gantt, '''
gantt
dateFormat YYYY-MM-DD
axisFormat %d/%m
tickInterval 2week
inclusiveEndDates
topAxis
weekday monday
weekend friday
excludes weekends, 2025-02-10
excludes monday 2025-02-11
includes 2025-02-10
todayMarker off
''')
              as GanttAst;

      expect(ast.dateFormat, 'YYYY-MM-DD');
      expect(ast.axisFormat, '%d/%m');
      expect(ast.tickInterval, const GanttTickInterval(2, GanttTickUnit.week));
      expect(ast.inclusiveEndDates, isTrue);
      expect(ast.topAxis, isTrue);
      expect(ast.weekday, GanttWeekday.monday);
      expect(ast.weekendStart, GanttWeekendStart.friday);
      expect(ast.excludes, const [
        GanttWeekendsFilter(),
        GanttDateLiteralFilter('2025-02-10'),
        GanttWeekdayFilter(GanttWeekday.monday),
        GanttDateLiteralFilter('2025-02-11'),
      ]);
      expect(ast.includes, const [GanttDateLiteralFilter('2025-02-10')]);
      expect(ast.todayMarker, const GanttTodayMarkerOff());
    });

    test('resolves dates, durations, dependencies, tags, sections, and links', () {
      final ast =
          parse(DiagramType.gantt, '''
gantt
dateFormat YYYY-MM-DD
section Design
Research :done, crit, research, 2025-01-01, 2d
Review :active, review, after research, 1d
section Delivery
Release :milestone, release, after review, 0d
Window :window, 2024-12-30, until research
Marker :vert, marker, 2025-01-02, 1d
click review href "https://example.test/review"
''')
              as GanttAst;

      expect(ast.sections.map((section) => section.name), ['Design', 'Delivery']);
      expect(ast.tasks, hasLength(5));
      expect(ast.tasks.map((task) => (task.id, task.start, task.end)), [
        ('research', DateTime(2025), DateTime(2025, 1, 3)),
        ('review', DateTime(2025, 1, 3), DateTime(2025, 1, 4)),
        ('release', DateTime(2025, 1, 4), DateTime(2025, 1, 4)),
        ('window', DateTime(2024, 12, 30), DateTime(2025)),
        ('marker', DateTime(2025, 1, 2), DateTime(2025, 1, 3)),
      ]);
      expect(ast.tasks.first.status, GanttTaskStatus.done);
      expect(ast.tasks.first.critical, isTrue);
      expect(ast.tasks[1].status, GanttTaskStatus.active);
      expect(ast.tasks[1].link, 'https://example.test/review');
      expect(ast.tasks[2].milestone, isTrue);
      expect(ast.tasks.last.vertical, isTrue);
    });

    test('uses the previous task end and generated ids for one-field tasks', () {
      final ast =
          parse(DiagramType.gantt, '''
gantt
dateFormat YYYY-MM-DD
section Work
First :2025-01-01, 2d
Second :3d
''')
              as GanttAst;

      expect(ast.tasks[0].id, 'task1');
      expect(ast.tasks[1].id, 'task2');
      expect(ast.tasks[1].start, DateTime(2025, 1, 3));
      expect(ast.tasks[1].end, DateTime(2025, 1, 6));
    });

    test('adjusts durations around excluded weekends and explicit includes', () {
      final ast =
          parse(DiagramType.gantt, '''
gantt
dateFormat YYYY-MM-DD
excludes weekends
includes 2025-01-04
section Work
Task :task, 2025-01-03, 3d
''')
              as GanttAst;

      expect(ast.tasks.single.end, DateTime(2025, 1, 7));
      expect(ast.tasks.single.renderEnd, DateTime(2025, 1, 7));
    });

    test('resolves every duration unit, with M as months and m as minutes', () {
      final ast =
          parse(DiagramType.gantt, '''
gantt
dateFormat YYYY-MM-DDTHH:mm
section Work
Millis :ms, 2025-01-01T00:00, 500ms
Seconds :s, 2025-01-01T00:00, 30s
Minutes :m, 2025-01-01T00:00, 15m
Hours :h, 2025-01-01T00:00, 6h
Days :d, 2025-01-01T00:00, 2d
Weeks :w, 2025-01-01T00:00, 1w
Months :mo, 2025-01-01T00:00, 3M
Years :y, 2025-01-01T00:00, 1y
Fractional :fm, 2025-01-01T00:00, 1.5M
''')
              as GanttAst;

      final ends = {for (final task in ast.tasks) task.id: task.end};
      expect(ends['ms'], DateTime(2025, 1, 1, 0, 0, 0, 500));
      expect(ends['s'], DateTime(2025, 1, 1, 0, 0, 30));
      expect(ends['m'], DateTime(2025, 1, 1, 0, 15));
      expect(ends['h'], DateTime(2025, 1, 1, 6));
      expect(ends['d'], DateTime(2025, 1, 3));
      expect(ends['w'], DateTime(2025, 1, 8));
      expect(ends['mo'], DateTime(2025, 4));
      expect(ends['y'], DateTime(2026));
      // A fractional month is a flat 30-day remainder, as upstream Mermaid does.
      expect(ends['fm'], DateTime(2025, 2, 16));
    });

    test('reports invalid dates, tick intervals, and unresolved dependencies', () {
      expect(() => parse(DiagramType.gantt, 'gantt\ntickInterval day'), throwsA(isA<MermaidParseException>()));
      expect(
        () => parse(DiagramType.gantt, 'gantt\ndateFormat YYYY-MM-DD\nTask :id, 2025-99-01, 1d'),
        throwsA(isA<MermaidParseException>()),
      );
      expect(
        () => parse(DiagramType.gantt, 'gantt\ndateFormat YYYY-MM-DD\nTask :id, after missing, 1d'),
        throwsA(isA<MermaidParseException>()),
      );
    });
  });
}
