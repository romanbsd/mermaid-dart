import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

import 'support/svg_golden.dart';

void main() {
  test('class domain model matches its rendering golden', () {
    final scene = layoutDiagram(
      parse(DiagramType.classDiagram, '''
classDiagram
direction LR
class Animal {
  +String name
  +move()
}
class Duck {
  +swim()
}
Animal "1" <|-- "*" Duck : extends
note for Duck "Can fly and swim"
'''),
      options: const RenderOptions(padding: 0),
    );

    expectSvgGolden('class_domain_model', renderSvg(scene));
  });

  test('state checkout matches its rendering golden', () {
    final scene = layoutDiagram(
      parse(DiagramType.stateDiagram, '''
stateDiagram-v2
[*] --> Idle
Idle --> Processing : submit
state Processing {
  [*] --> Validating
  Validating --> Complete
}
Processing --> Done : success
Processing --> Failed : error
Done --> [*]
note right of Failed : Retry is available
'''),
      options: const RenderOptions(padding: 0),
    );

    expectSvgGolden('state_checkout', renderSvg(scene));
  });

  test('ER commerce matches its rendering golden', () {
    final scene = layoutDiagram(
      parse(DiagramType.entityRelationship, '''
erDiagram
CUSTOMER {
  int id PK
  string name
}
ORDER {
  int id PK
  int customer_id FK
}
CUSTOMER ||--o{ ORDER : places
'''),
      options: const RenderOptions(padding: 0),
    );

    expectSvgGolden('er_commerce', renderSvg(scene));
  });
}
