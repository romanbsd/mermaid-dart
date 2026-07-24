import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('ER diagram parser', () {
    test('parses entities, aliases, attributes, keys, comments, and relationships', () {
      final ast =
          parse(DiagramType.entityRelationship, '''
erDiagram
title Commerce
direction LR
CUSTOMER {
  string id PK "customer id"
  string email UK
}
ORDER["Purchase"] {
  int id PK
  int customer_id FK
}
CUSTOMER ||--o{ ORDER : places
''')
              as ErDiagramAst;

      expect(ast.title, 'Commerce');
      expect(ast.direction, GraphDirection.leftRight);
      expect(ast.entities, hasLength(2));
      expect(
        ast.entities.first.attributes.first,
        const ErAttributeAst(type: 'string', name: 'id', keys: {ErAttributeKey.primary}, comment: 'customer id'),
      );
      expect(ast.entities.last.label, 'Purchase');
      expect(
        ast.relationships.single,
        const ErRelationshipAst(
          from: 'CUSTOMER',
          to: 'ORDER',
          fromCardinality: ErCardinality.exactlyOne,
          toCardinality: ErCardinality.zeroOrMore,
          identifying: true,
          label: 'places',
        ),
      );
    });

    test('supports textual cardinalities, quoted names, and CSS classes', () {
      final ast =
          parse(DiagramType.entityRelationship, '''
erDiagram
"Person Account" one optionally to zero or more "Login Event" : records
classDef secure fill:#efe,stroke:#282
class "Person Account","Login Event" secure
''')
              as ErDiagramAst;

      expect(ast.relationships.single.identifying, isFalse);
      expect(ast.relationships.single.fromCardinality, ErCardinality.exactlyOne);
      expect(ast.relationships.single.toCardinality, ErCardinality.zeroOrMore);
      expect(ast.entities.every((entity) => entity.cssClasses.contains('secure')), isTrue);
      expect(ast.classDefinitions['secure'], {'fill': '#efe', 'stroke': '#282'});
    });

    test('accepts an upstream attribute block closed after its last attribute', () {
      final ast =
          parse(DiagramType.entityRelationship, '''
erDiagram
BUILDING {
  public.geometry(point,4326) location}
''')
              as ErDiagramAst;

      expect(
        ast.entities.single.attributes.single,
        const ErAttributeAst(type: 'public.geometry(point,4326)', name: 'location'),
      );
    });

    test('parses every symbolic relationship cardinality combination', () {
      const tokens = {
        '||': ErCardinality.exactlyOne,
        '|o': ErCardinality.zeroOrOne,
        '|{': ErCardinality.oneOrMore,
        'o{': ErCardinality.zeroOrMore,
        'u': ErCardinality.parent,
      };
      const mirroredTokens = {
        '||': ErCardinality.exactlyOne,
        'o|': ErCardinality.zeroOrOne,
        '}|': ErCardinality.oneOrMore,
        '}o': ErCardinality.zeroOrMore,
        'u': ErCardinality.parent,
      };
      final lines = <String>[];
      for (final left in tokens.keys) {
        for (final right in mirroredTokens.keys) {
          lines.add('LEFT_${lines.length} $left--$right RIGHT_${lines.length} : relates');
        }
      }
      final ast = parse(DiagramType.entityRelationship, 'erDiagram\n${lines.join('\n')}') as ErDiagramAst;

      expect(ast.relationships, hasLength(tokens.length * mirroredTokens.length));
      var index = 0;
      for (final left in tokens.entries) {
        for (final right in mirroredTokens.entries) {
          final relationship = ast.relationships[index++];
          expect(relationship.fromCardinality, left.value);
          expect(relationship.toCardinality, right.value);
          expect(relationship.identifying, isTrue);
        }
      }
    });

    test('parses aliases and every attribute key variant', () {
      final ast =
          parse(DiagramType.entityRelationship, '''
erDiagram
ACCOUNT["Customer Account"] {
  uuid id PK "primary identifier"
  string email UK
  uuid owner_id FK
  string region PK, FK, UK "compound key member"
  decimal(10,2) balance
}
ACCOUNT ||..o{ "AUDIT EVENT" : records
''')
              as ErDiagramAst;

      expect(ast.entities.first.label, 'Customer Account');
      expect(ast.entities.first.attributes.map((attribute) => attribute.keys), [
        {ErAttributeKey.primary},
        {ErAttributeKey.unique},
        {ErAttributeKey.foreign},
        {ErAttributeKey.primary, ErAttributeKey.foreign, ErAttributeKey.unique},
        <ErAttributeKey>{},
      ]);
      expect(ast.entities.first.attributes.first.comment, 'primary identifier');
      expect(ast.relationships.single.identifying, isFalse);
      expect(ast.entities.last.id, 'AUDIT EVENT');
    });

    test('reports malformed attributes with a source location', () {
      expect(
        () => parse(DiagramType.entityRelationship, 'erDiagram\nUSER {\n  string\n}\n'),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.line, 'line', 3)
              .having((error) => error.column, 'column', 3),
        ),
      );
    });
  });
}
