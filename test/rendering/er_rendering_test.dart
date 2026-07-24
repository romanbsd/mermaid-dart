import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('ER diagrams render entity tables, attributes, relationships, and cardinalities', () {
    final scene = layoutDiagram(
      parse(DiagramType.entityRelationship, '''
erDiagram
CUSTOMER {
  string id PK
}
ORDER {
  int id PK
  int customer_id FK
}
CUSTOMER ||--o{ ORDER : places
'''),
      options: const RenderOptions(padding: 0),
    );
    final elements = _flatten(scene.elements).toList();

    expect(scene.diagramType, DiagramType.entityRelationship);
    expect(elements.where((element) => element.cssClasses.contains('er-entity')), hasLength(2));
    expect(elements.where((element) => element.cssClasses.contains('er-attribute-divider')), hasLength(2));
    expect(elements.where((element) => element.cssClasses.contains('er-attribute-row')), hasLength(3));
    expect(elements.where((element) => element.cssClasses.contains('er-relationship')), hasLength(1));
    expect(elements.where((element) => element.cssClasses.contains('er-relationship-label-background')), hasLength(1));
    expect(elements.where((element) => element.cssClasses.contains('er-cardinality')), isNotEmpty);
    expect(
      elements.whereType<SceneText>().map((element) => element.text),
      containsAll(['CUSTOMER', 'ORDER', 'string', 'id', 'PK', 'customer_id', 'FK', 'places']),
    );
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element is SceneGroup) yield* _flatten(element.children);
  }
}
