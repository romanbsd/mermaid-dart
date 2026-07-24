import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('class diagram parser', () {
    test('parses classes, members, annotations, and cardinality relations', () {
      final ast =
          parse(DiagramType.classDiagram, '''
classDiagram
title Domain model
direction LR
class Animal {
  <<abstract>>
  +String name
  +move(distance) bool
}
class Duck["Mallard"] {
  +swim()
}
Animal "1" <|-- "*" Duck : implements
note for Duck "Can fly"
''')
              as ClassDiagramAst;

      expect(ast.title, 'Domain model');
      expect(ast.direction, GraphDirection.leftRight);
      expect(ast.classes, hasLength(2));
      expect(
        ast.classes.first,
        const ClassAst(
          id: 'Animal',
          label: 'Animal',
          annotations: ['abstract'],
          members: [
            ClassMemberAst(text: '+String name', kind: ClassMemberKind.attribute),
            ClassMemberAst(text: '+move(distance) bool', kind: ClassMemberKind.method),
          ],
        ),
      );
      expect(ast.classes.last.label, 'Mallard');
      expect(
        ast.relations.single,
        const ClassRelationAst(
          from: 'Animal',
          to: 'Duck',
          fromCardinality: '1',
          toCardinality: '*',
          startMarker: ClassRelationMarker.extension,
          label: 'implements',
        ),
      );
      expect(ast.notes.single, const ClassNoteAst(text: 'Can fly', classId: 'Duck'));
    });

    test('parses namespaces, inline members, class definitions, and assignments', () {
      final ast =
          parse(DiagramType.classDiagram, '''
classDiagram-v2
namespace billing {
  class Invoice
  class LineItem
}
Invoice : +total() Decimal
Invoice *-- LineItem
classDef aggregate fill:#eef,stroke:#446
class Invoice aggregate
''')
              as ClassDiagramAst;

      expect(
        ast.namespaces.single,
        const ClassNamespaceAst(id: 'billing', label: 'billing', classIds: ['Invoice', 'LineItem']),
      );
      expect(ast.classes.first.members.single.kind, ClassMemberKind.method);
      expect(ast.classes.first.cssClasses, ['aggregate']);
      expect(ast.classDefinitions['aggregate'], {'fill': '#eef', 'stroke': '#446'});
      expect(ast.relations.single.startMarker, ClassRelationMarker.composition);
    });

    test('parses inline stereotypes with full and empty class bodies', () {
      final ast =
          parse(DiagramType.classDiagram, '''
classDiagram
class Shape <<interface>> {
  draw()
}
class Empty <<enumeration>> {}
''')
              as ClassDiagramAst;

      expect(ast.classes.first.annotations, ['interface']);
      expect(ast.classes.first.members.single.kind, ClassMemberKind.method);
      expect(ast.classes.last.annotations, ['enumeration']);
      expect(ast.classes.last.members, isEmpty);
    });

    test('parses namespaces, annotations, and generic member matrix', () {
      final ast =
          parse(DiagramType.classDiagram, '''
classDiagram
namespace domain {
  class Repository~T~ {
    <<interface>>
    +List~T~ items
    +findById(id) T
  }
  class Status {
    <<enumeration>>
    ACTIVE
    INACTIVE
  }
}
class Service {
  <<service>>
  #Map~String,Repository~T~~ repositories
  +save~T~(value T) bool
}
''')
              as ClassDiagramAst;

      expect(ast.namespaces.single.classIds, ['Repository~T~', 'Status']);
      expect(ast.classes.map((entry) => entry.annotations.single), ['interface', 'enumeration', 'service']);
      expect(ast.classes.first.members.map((member) => member.text), ['+List~T~ items', '+findById(id) T']);
      expect(ast.classes.last.members.map((member) => member.kind), [
        ClassMemberKind.attribute,
        ClassMemberKind.method,
      ]);
    });

    test('parses every relation marker, line, and cardinality variant', () {
      final ast =
          parse(DiagramType.classDiagram, '''
classDiagram
A "1" <|-- "*" B : inheritance
A "0..1" *-- "1..*" C : composition
A o-- D : aggregation
A --> E : association
A ..> F : dependency
A ()-- G : lollipop
H --|> A : reverse inheritance
I --* A : reverse composition
J --o A : reverse aggregation
K --() A : reverse lollipop
''')
              as ClassDiagramAst;

      expect(ast.relations, hasLength(10));
      expect(ast.relations.take(6).map((relation) => relation.startMarker), [
        ClassRelationMarker.extension,
        ClassRelationMarker.composition,
        ClassRelationMarker.aggregation,
        ClassRelationMarker.none,
        ClassRelationMarker.none,
        ClassRelationMarker.lollipop,
      ]);
      expect(ast.relations[4].endMarker, ClassRelationMarker.dependency);
      expect(ast.relations[4].line, ClassRelationLine.dotted);
      expect(ast.relations.skip(6).map((relation) => relation.endMarker), [
        ClassRelationMarker.extension,
        ClassRelationMarker.composition,
        ClassRelationMarker.aggregation,
        ClassRelationMarker.lollipop,
      ]);
      expect(ast.relations.first.fromCardinality, '1');
      expect(ast.relations.first.toCardinality, '*');
      expect(ast.relations[1].fromCardinality, '0..1');
      expect(ast.relations[1].toCardinality, '1..*');
    });

    test('reports an unterminated class body at its declaration', () {
      expect(
        () => parse(DiagramType.classDiagram, 'classDiagram\nclass Broken {\n  +name\n'),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.line, 'line', 2)
              .having((error) => error.column, 'column', 1),
        ),
      );
    });
  });
}
