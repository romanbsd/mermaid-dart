import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

final class _KanbanTextMeasurer implements TextMeasurer {
  const _KanbanTextMeasurer();

  @override
  Size measure(String text, SceneTextStyle style) => Size(text.length * 8, 18);
}

void main() {
  test('lays out columns, cards, metadata, icons, and priority markers', () {
    final ast =
        parse(DiagramType.kanban, '''
kanban
  todo[To do]
    parser[Implement parser]@{ ticket: M-1, assigned: Roman, priority: high, icon: code }
  done[Done]
    release[Release]
''')
            as KanbanAst;
    final scene = layoutDiagram(
      ast,
      textMeasurer: const _KanbanTextMeasurer(),
      options: const RenderOptions(
        padding: 0,
        kanban: KanbanRenderOptions(ticketBaseUrl: 'https://issues.example/#TICKET#'),
      ),
    );
    final elements = _flatten(scene.elements).toList();

    expect(scene.diagramType, DiagramType.kanban);
    expect(
      elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('kanban-section')),
      hasLength(2),
    );
    expect(
      elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('kanban-card')),
      hasLength(2),
    );
    expect(
      elements.whereType<SceneText>().map((element) => element.text),
      containsAll(['To do', 'Implement parser', 'M-1', 'Roman', 'Done', 'Release']),
    );
    expect(
      elements.whereType<SceneLine>().where((element) => element.cssClasses.contains('kanban-priority-high')),
      hasLength(1),
    );
    expect(elements.whereType<SceneIcon>(), hasLength(1));

    final svg = renderSvg(scene);
    expect(svg, contains('class="kanban-section'));
    expect(svg, contains('class="kanban-card'));
    expect(svg, contains('Implement parser'));
    expect(svg, contains('href="https://issues.example/M-1"'));
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element is SceneGroup) yield* _flatten(element.children);
  }
}
