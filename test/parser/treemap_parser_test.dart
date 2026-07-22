import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('treemap parser', () {
    test('accepts both headers and empty diagrams', () {
      for (final header in ['treemap', 'treemap-beta']) {
        expect(parse(DiagramType.treemap, header), const TreemapAst());
      }
    });

    test('parses sections and leaves while preserving indentation', () {
      final ast =
          parse(DiagramType.treemap, '''treemap
"Root"
  "Group":::sectionClass
    "First" , 1,234.5
    'Second' : 200:::leafClass
''')
              as TreemapAst;

      expect(ast.rows, const [
        TreemapNodeRowAst(indent: 0, item: TreemapSectionAst(name: 'Root')),
        TreemapNodeRowAst(
          indent: 2,
          item: TreemapSectionAst(name: 'Group', classSelector: 'sectionClass'),
        ),
        TreemapNodeRowAst(indent: 4, item: TreemapLeafAst(name: 'First', value: 1234.5)),
        TreemapNodeRowAst(
          indent: 4,
          item: TreemapLeafAst(name: 'Second', value: 200, classSelector: 'leafClass'),
        ),
      ]);
    });

    test('parses class definitions as typed rows', () {
      final ast =
          parse(DiagramType.treemap, '''treemap
classDef section fill:blue,stroke:#fff;
classDef plain
"Root":::section
''')
              as TreemapAst;

      expect(ast.rows, const [
        TreemapClassDefAst(name: 'section', style: 'fill:blue,stroke:#fff'),
        TreemapClassDefAst(name: 'plain'),
        TreemapNodeRowAst(
          indent: 0,
          item: TreemapSectionAst(name: 'Root', classSelector: 'section'),
        ),
      ]);
    });

    test('parses metadata and ignores Mermaid comments', () {
      final ast =
          parse(DiagramType.treemap, '''%% before header
treemap-beta
title Revenue map
accTitle: Accessible revenue map
accDescr {
  Revenue grouped by region
}
%% hidden row
"Revenue"
  "Europe": 42
''')
              as TreemapAst;

      expect(ast.title, 'Revenue map');
      expect(ast.accessibilityTitle, 'Accessible revenue map');
      expect(ast.accessibilityDescription, 'Revenue grouped by region');
      expect(ast.rows, hasLength(2));
    });

    test('retains multiple root rows like the upstream parser frontend', () {
      final ast = parse(DiagramType.treemap, 'treemap\n"Root1"\n"Root2"') as TreemapAst;

      expect(ast.rows, hasLength(2));
      expect(ast.rows.whereType<TreemapNodeRowAst>().map((row) => row.indent), everyElement(0));
    });

    test('rejects unquoted nodes, malformed values, and class selectors', () {
      for (final source in ['treemap\nRoot', 'treemap\n"Leaf": value', 'treemap\n"Root":::not-valid']) {
        expect(() => parse(DiagramType.treemap, source), throwsA(isA<MermaidParseException>()));
      }
    });
  });
}
