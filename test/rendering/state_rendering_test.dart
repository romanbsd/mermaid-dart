import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('state diagrams render states, transitions, special states, and notes', () {
    final scene = layoutDiagram(
      parse(DiagramType.stateDiagram, '''
stateDiagram-v2
[*] --> Idle
Idle --> Choice : decide
state Choice <<choice>>
Choice --> Done
Done --> [*]
note right of Idle : Waiting
'''),
      options: const RenderOptions(padding: 0),
    );
    final elements = _flatten(scene.elements).toList();

    expect(scene.diagramType, DiagramType.stateDiagram);
    expect(elements.where((element) => element.cssClasses.contains('state-node')), hasLength(2));
    expect(elements.where((element) => element.cssClasses.contains('state-choice')), hasLength(1));
    expect(elements.where((element) => element.cssClasses.contains('state-start')), hasLength(1));
    expect(elements.where((element) => element.cssClasses.contains('state-end')), hasLength(1));
    expect(elements.where((element) => element.cssClasses.contains('state-transition')), hasLength(5));
    expect(elements.where((element) => element.cssClasses.contains('state-transition-label-background')), hasLength(1));
    expect(elements.where((element) => element.cssClasses.contains('state-note')), hasLength(1));
    expect(
      elements.whereType<SceneText>().map((element) => element.text),
      containsAll(['Idle', 'Choice', 'Done', 'decide', 'Waiting']),
    );
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element is SceneGroup) yield* _flatten(element.children);
  }
}
