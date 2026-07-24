import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('class diagrams render compartments, notes, edges, and endpoint markers', () {
    final scene = layoutDiagram(
      parse(DiagramType.classDiagram, '''
classDiagram
class Animal {
  <<abstract>>
  +String name
  +move()
}
class Duck
Animal <|-- Duck : extends
note for Animal "Base type"
'''),
      options: const RenderOptions(padding: 0),
    );
    final elements = _flatten(scene.elements).toList();

    expect(scene.diagramType, DiagramType.classDiagram);
    expect(elements.where((element) => element.cssClasses.contains('class-node')), hasLength(2));
    expect(elements.where((element) => element.cssClasses.contains('class-compartment-divider')), hasLength(2));
    expect(elements.where((element) => element.cssClasses.contains('class-relation')), hasLength(1));
    expect(elements.where((element) => element.cssClasses.contains('class-extension-marker')), hasLength(1));
    expect(elements.where((element) => element.cssClasses.contains('class-note')), hasLength(1));
    expect(elements.where((element) => element.cssClasses.contains('class-relation-label-background')), hasLength(1));
    expect(
      elements.whereType<SceneText>().map((element) => element.text),
      containsAll(['Animal', '«abstract»', '+String name', '+move()', 'extends', 'Base type']),
    );
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element is SceneGroup) yield* _flatten(element.children);
  }
}
