import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('info parser', () {
    test('accepts Mermaid whitespace variants', () {
      for (final source in ['info', '\n    info', 'info\n    ', '\n    info\n    ']) {
        expect(parse(DiagramType.info, source), const InfoAst());
      }
    });

    test('accepts optional showInfo', () {
      for (final source in ['info showInfo', 'info\nshowInfo', '\n info\n showInfo\n']) {
        expect(parse(DiagramType.info, source), const InfoAst());
      }
    });

    test('parses common title and accessibility fields', () {
      expect(
        parse(DiagramType.info, '''
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
          DiagramType.info,
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
        parse(DiagramType.info, '''
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
        () => parse(DiagramType.info, 'info\nunexpected'),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.line, 'line', 2)
              .having((error) => error.column, 'column', 1),
        ),
      );
    });

    test('does not accept Mermaid keywords as prefixes', () {
      for (final source in ['information', 'info showInformation', 'info titleBad']) {
        expect(() => parse(DiagramType.info, source), throwsA(isA<MermaidParseException>()));
      }
    });
  });

  test('converts diagram types only at string boundaries', () {
    expect(DiagramType.fromWireName('eventmodeling'), DiagramType.eventModeling);
    expect(DiagramType.gitGraph.wireName, 'gitGraph');
    expect(DiagramType.tryFromWireName('flowchart'), DiagramType.flowchart);
    expect(parseByName('flowchart', 'flowchart LR'), isA<FlowchartAst>());
    expect(DiagramType.tryFromWireName('sequence'), DiagramType.sequence);
    expect(DiagramType.tryFromWireName('sequenceDiagram'), isNull);
    expect(DiagramType.tryFromWireName('mindmap'), DiagramType.mindmap);
    expect(DiagramType.tryFromWireName('timeline'), DiagramType.timeline);
  });
}
