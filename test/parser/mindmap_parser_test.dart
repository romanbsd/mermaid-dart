import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('mindmap parser', () {
    test('parses an indented hierarchy with ids, shapes, icons, and classes', () {
      final ast =
          parse(DiagramType.mindmap, '''
mindmap
  root((Product))
    research[Research]
      interviews(Interviews)
    launch{{Launch}}
    ::icon(rocket)
    :::urgent featured
''')
              as MindmapAst;

      expect(ast.root.id, 'root');
      expect(ast.root.label, 'Product');
      expect(ast.root.shape, MindmapNodeShape.circle);
      expect(ast.root.children, hasLength(2));
      expect(ast.root.children.first.id, 'research');
      expect(ast.root.children.first.shape, MindmapNodeShape.rectangle);
      expect(ast.root.children.first.children.single.label, 'Interviews');
      expect(ast.root.children.last.shape, MindmapNodeShape.hexagon);
      expect(ast.root.children.last.icon, 'rocket');
      expect(ast.root.children.last.cssClasses, ['urgent', 'featured']);
    });

    test('parses every upstream node shape and quoted delimiters', () {
      final ast =
          parse(DiagramType.mindmap, '''
mindmap
  root["String containing []"]
    rounded(Rounded)
    cloud)Cloud(
    bang))Bang((
    circle((Circle))
    hex{{Hex}}
''')
              as MindmapAst;

      expect(ast.root.label, 'String containing []');
      expect(ast.root.children.map((node) => node.shape), [
        MindmapNodeShape.roundedRectangle,
        MindmapNodeShape.cloud,
        MindmapNodeShape.bang,
        MindmapNodeShape.circle,
        MindmapNodeShape.hexagon,
      ]);
    });

    test('preserves metadata and rejects a second root with a source location', () {
      final ast =
          parse(DiagramType.mindmap, '''
mindmap
title Product map
accTitle: Product decisions
  root
''')
              as MindmapAst;
      expect(ast.title, 'Product map');
      expect(ast.accessibilityTitle, 'Product decisions');

      expect(
        () => parse(DiagramType.mindmap, 'mindmap\n  root\n  second\n'),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.line, 'line', 3)
              .having((error) => error.message, 'message', contains('only one root')),
        ),
      );
    });

    test('accepts a case-insensitive diagram header', () {
      final ast = parse(DiagramType.mindmap, 'MINDMAP\n  root\n') as MindmapAst;

      expect(ast.root.label, 'root');
    });
  });
}
