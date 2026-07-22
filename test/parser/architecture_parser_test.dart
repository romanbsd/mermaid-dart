import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('architecture parser', () {
    test('accepts empty diagrams and common metadata', () {
      final ast =
          parse(DiagramType.architecture, '''
  architecture-beta
  title Platform
  accTitle: Accessible platform
  accDescr {
    First line
    Second line
  }
''')
              as ArchitectureAst;

      expect(ast.groups, isEmpty);
      expect(ast.services, isEmpty);
      expect(ast.title, 'Platform');
      expect(ast.accessibilityTitle, 'Accessible platform');
      expect(ast.accessibilityDescription, 'First line\nSecond line');
    });

    test('reads metadata that starts on the header line', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta title Header title\naccTitle: First label\naccTitle: Architecture\n',
              )
              as ArchitectureAst;

      expect(ast.title, 'Header title');
      expect(ast.accessibilityTitle, 'Architecture');
    });

    test('parses groups, services, and junctions', () {
      final ast =
          parse(DiagramType.architecture, '''architecture-beta
group cloud(logos:aws-cloud)["Cloud 'A'"]
group api(server)[API] in cloud
service db(database)["The \\"Main\\" Database"] in api
service cache "C" [Cache] in api
junction split in api
''')
              as ArchitectureAst;

      expect(ast.groups, [
        const ArchitectureGroupAst(id: 'cloud', icon: 'logos:aws-cloud', title: "Cloud 'A'"),
        const ArchitectureGroupAst(id: 'api', icon: 'server', title: 'API', parent: 'cloud'),
      ]);
      expect(ast.services, [
        const ArchitectureServiceAst(id: 'db', icon: 'database', title: 'The "Main" Database', parent: 'api'),
        const ArchitectureServiceAst(id: 'cache', iconText: 'C', title: 'Cache', parent: 'api'),
      ]);
      expect(ast.junctions, [const ArchitectureJunctionAst(id: 'split', parent: 'api')]);
    });

    test('parses directions, labels, arrows, and group boundaries', () {
      final ast =
          parse(DiagramType.architecture, '''architecture-beta
a:L -- R:b
a{group}:T <-- B:b{group}
a:R -[calls]-> L:b
''')
              as ArchitectureAst;

      expect(ast.edges, [
        const ArchitectureEdgeAst(
          leftId: 'a',
          leftDirection: ArchitectureDirection.left,
          rightId: 'b',
          rightDirection: ArchitectureDirection.right,
        ),
        const ArchitectureEdgeAst(
          leftId: 'a',
          leftDirection: ArchitectureDirection.top,
          leftArrow: true,
          leftGroup: true,
          rightId: 'b',
          rightDirection: ArchitectureDirection.bottom,
          rightGroup: true,
        ),
        const ArchitectureEdgeAst(
          leftId: 'a',
          leftDirection: ArchitectureDirection.right,
          rightId: 'b',
          rightDirection: ArchitectureDirection.left,
          rightArrow: true,
          title: 'calls',
        ),
      ]);
    });

    test('parses enum-backed row and column alignments', () {
      final ast =
          parse(DiagramType.architecture, '''architecture-beta
align row a b c
align column a d
''')
              as ArchitectureAst;

      expect(ast.alignments, [
        const ArchitectureAlignmentAst(direction: ArchitectureAlignmentDirection.row, members: ['a', 'b', 'c']),
        const ArchitectureAlignmentAst(direction: ArchitectureAlignmentDirection.column, members: ['a', 'd']),
      ]);
    });

    test('rejects incomplete alignments and reserved identifiers', () {
      expect(
        () => parse(DiagramType.architecture, 'architecture-beta\nalign row only\n'),
        throwsA(isA<MermaidParseException>()),
      );
      for (final identifier in ['align', 'row', 'column']) {
        expect(
          () => parse(DiagramType.architecture, 'architecture-beta\nservice $identifier(server)[Invalid]\n'),
          throwsA(isA<MermaidParseException>()),
        );
      }
    });
  });
}
