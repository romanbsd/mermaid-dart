import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('pie parser', () {
    test('accepts empty diagrams with optional showData', () {
      for (final source in ['pie', '  pie  ', '\npie\n', 'pie showData']) {
        final ast = parse(DiagramType.pie, source) as PieAst;
        expect(ast.showData, source.contains('showData'));
        expect(ast.sections, isEmpty);
      }
    });

    test('parses integer, decimal, and negative sections in source order', () {
      final ast =
          parse(DiagramType.pie, '''
pie showData
  "GitHub" : 100
  "GitLab": 50.5
  "Other": -2
''')
              as PieAst;

      expect(ast.showData, isTrue);
      expect(ast.sections, [
        const PieSectionAst(label: 'GitHub', value: 100),
        const PieSectionAst(label: 'GitLab', value: 50.5),
        const PieSectionAst(label: 'Other', value: -2),
      ]);
    });

    test('parses both string delimiters and escaped label characters', () {
      final ast =
          parse(DiagramType.pie, r'''pie
"A\"B": 1
'single quoted': 2''')
              as PieAst;

      expect(ast.sections, [
        const PieSectionAst(label: 'A"B', value: 1),
        const PieSectionAst(label: 'single quoted', value: 2),
      ]);
    });

    test('parses common title and accessibility metadata', () {
      final ast =
          parse(DiagramType.pie, '''
pie title Language share
  accTitle: Languages
  accDescr {
    Share by language
    in this repository
  }
  "Dart": 100
''')
              as PieAst;

      expect(ast.title, 'Language share');
      expect(ast.accessibilityTitle, 'Languages');
      expect(ast.accessibilityDescription, 'Share by language\nin this repository');
    });

    test('ignores Mermaid comments and directives', () {
      final ast =
          parse(DiagramType.pie, '''
%%{init: {"theme": "dark"}}%%
pie
%% hidden
"Visible": 1 %% trailing
''')
              as PieAst;

      expect(ast.sections, [const PieSectionAst(label: 'Visible', value: 1)]);
    });

    test('reports malformed section values at their source location', () {
      expect(
        () => parse(DiagramType.pie, 'pie\n"Broken": many'),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.line, 'line', 2)
              .having((error) => error.column, 'column', greaterThan(1)),
        ),
      );
    });
  });
}
