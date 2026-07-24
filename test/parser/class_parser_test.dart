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
