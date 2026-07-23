import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

import 'support/svg_golden.dart';

final class _ExactTextMeasurer implements TextMeasurer {
  const _ExactTextMeasurer();

  @override
  Size measure(String text, SceneTextStyle style) {
    final lines = text.split('\n');
    final width = lines.map((line) => line.runes.length).fold(0, (a, b) => a > b ? a : b) * 10.0;
    return Size(width, lines.length * 20.0);
  }
}

void main() {
  test('places release-plan dates like Mermaid.js', () {
    final ast =
        parse(DiagramType.gantt, '''
gantt
title Release plan
dateFormat YYYY-MM-DD
axisFormat %b %d
tickInterval 1day
todayMarker off
section Design
Research :done, crit, research, 2025-01-01, 2d
Review :active, review, after research, 1d
section Delivery
Implementation :implementation, after review, 3d
Release :milestone, release, after implementation, 0d
Deadline :vert, deadline, 2025-01-06, 1d
''')
            as GanttAst;
    final scene = layoutDiagram(
      ast,
      textMeasurer: const _ExactTextMeasurer(),
      options: const RenderOptions(padding: 0, gantt: GanttRenderOptions(useWidth: 1200, useMaxWidth: false)),
    );
    final dateLabels = _flatten(
      scene.elements,
    ).whereType<SceneText>().where((element) => element.cssClasses.contains('tick-label')).toList();

    expect(dateLabels.map((label) => label.text), const [
      'Jan 01',
      'Jan 02',
      'Jan 03',
      'Jan 04',
      'Jan 05',
      'Jan 06',
      'Jan 07',
    ]);
    expect(dateLabels.map((label) => label.position.y), everyElement(159));
    expectSvgGolden('gantt_release_plan', renderSvg(scene));
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element case SceneGroup(:final children)) yield* _flatten(children);
  }
}
