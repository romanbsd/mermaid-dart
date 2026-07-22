import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('info parser', () {
    test('accepts Mermaid whitespace variants', () {
      for (final source in ['info', '\n    info', 'info\n    ', '\n    info\n    ']) {
        expect(parse('info', source), const InfoAst());
      }
    });

    test('accepts optional showInfo', () {
      for (final source in ['info showInfo', 'info\nshowInfo', '\n info\n showInfo\n']) {
        expect(parse('info', source), const InfoAst());
      }
    });

    test('parses common title and accessibility fields', () {
      expect(
        parse('info', '''
info showInfo
title  Mermaid   parser
accTitle: Parser status
accDescr {
  Pure Dart parser
  with diagnostics
}
'''),
        const InfoAst(
          title: 'Mermaid parser',
          accessibilityTitle: 'Parser status',
          accessibilityDescription: 'Pure Dart parser\nwith diagnostics',
        ),
      );
    });

    test('accepts indented metadata and metadata on the header line', () {
      expect(
        parse(
          'info',
          'info title First title\n'
              '    title Final title\n'
              '    accTitle: Accessible\n'
              '    accDescr: Description',
        ),
        const InfoAst(title: 'Final title', accessibilityTitle: 'Accessible', accessibilityDescription: 'Description'),
      );
    });

    test('ignores directives, frontmatter, and comments like Mermaid', () {
      expect(
        parse('info', '''
---
title: frontmatter is handled outside the grammar
---
%% a comment
%%{init: {"theme": "dark"}}%%
info
title Visible title %% trailing comment
'''),
        const InfoAst(title: 'Visible title'),
      );
    });

    test('reports syntax errors with a source location', () {
      expect(
        () => parse('info', 'info\nunexpected'),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.line, 'line', 2)
              .having((error) => error.column, 'column', 1),
        ),
      );
    });

    test('does not accept Mermaid keywords as prefixes', () {
      for (final source in ['information', 'info showInformation', 'info titleBad']) {
        expect(() => parse('info', source), throwsA(isA<MermaidParseException>()));
      }
    });
  });

  test('rejects unsupported diagram types', () {
    expect(
      () => parse('flowchart', 'flowchart LR'),
      throwsA(isA<UnsupportedDiagramTypeException>().having((error) => error.diagramType, 'diagramType', 'flowchart')),
    );
  });
}
