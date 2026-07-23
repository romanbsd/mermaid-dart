import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('lays out section bands, tasks, milestones, markers, axes, and links', () {
    final ast =
        parse(DiagramType.gantt, '''
gantt
title Delivery
dateFormat YYYY-MM-DD
axisFormat %m-%d
tickInterval 1day
topAxis
todayMarker off
section Build
Implement :done, impl, 2025-01-01, 2d
Ship :crit, milestone, ship, after impl, 0d
Deadline :vert, deadline, 2025-01-02, 1d
click impl href "https://example.test/impl"
''')
            as GanttAst;

    final scene = layoutDiagram(
      ast,
      options: const RenderOptions(padding: 0, gantt: GanttRenderOptions(useWidth: 600, useMaxWidth: false)),
    );
    final elements = _flatten(scene.elements);

    expect(scene.diagramType, DiagramType.gantt);
    expect(scene.viewport.width, 600);
    expect(elements.whereType<SceneRect>().map((rect) => rect.role), contains(SemanticRole.group));
    expect(elements.whereType<SceneRect>().map((rect) => rect.role), contains(SemanticRole.node));
    expect(elements.whereType<SceneRect>().where((rect) => rect.cssClasses.contains('milestone')), hasLength(1));
    expect(elements.whereType<SceneRect>().where((rect) => rect.cssClasses.contains('vert')), hasLength(1));
    expect(
      elements.whereType<SceneText>().singleWhere((text) => text.text == 'Implement').link,
      'https://example.test/impl',
    );

    final svg = renderSvg(scene, options: const SvgRenderOptions(rootId: 'gantt'));
    expect(svg, contains('class="task done'));
    expect(svg, contains('class="milestone'));
    expect(svg, contains('href="https://example.test/impl"'));
    expect(svg, contains('class="grid'));
  });

  test('compact mode reuses rows only for non-overlapping tasks in a section', () {
    final ast =
        parse(DiagramType.gantt, '''
gantt
dateFormat YYYY-MM-DD
section Work
A :a, 2025-01-01, 2d
B :b, 2025-01-03, 2d
C :c, 2025-01-02, 2d
''')
            as GanttAst;
    final scene = layoutDiagram(
      ast,
      options: const RenderOptions(gantt: GanttRenderOptions(displayMode: GanttDisplayMode.compact)),
    );
    final taskRects = _flatten(
      scene.elements,
    ).whereType<SceneRect>().where((rect) => rect.role == SemanticRole.node).toList();

    final byLabel = {for (final rect in taskRects) rect.label: rect};
    expect(byLabel['A']!.bounds.top, byLabel['B']!.bounds.top);
    expect(byLabel['C']!.bounds.top, isNot(byLabel['A']!.bounds.top));
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element case SceneGroup(:final children)) yield* _flatten(children);
  }
}
