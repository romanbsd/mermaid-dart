import 'package:mermaid_dart/src/parser/common_syntax.dart';
import 'package:mermaid_dart/src/parser/errors.dart';
import 'package:test/test.dart';

void main() {
  group('diagram source preparation', () {
    test('shares header and metadata masking without changing offsets', () {
      const source = '%% before\r\ntreemap-beta\r\ntitle Revenue\r\n"Root"';

      final prepared = prepareDiagramSource(source, headers: const ['treemap', 'treemap-beta']);

      expect(prepared.metadata.title, 'Revenue');
      expect(prepared.syntax.length, source.length);
      expect(prepared.syntax.indexOf('"Root"'), source.indexOf('"Root"'));
      expect(sourceLines(prepared.syntax).last, isA<SourceLine>());
      expect(sourceLines(prepared.syntax).last.offset, source.indexOf('"Root"'));
    });

    test('reads only the top-level title from YAML frontmatter', () {
      const source = '''
---
title: "Packet Diagram"
config:
  title: Nested config value
---
packet
0: "Flag"
''';

      final prepared = prepareDiagramSource(source, headers: const ['packet']);

      expect(prepared.metadata.title, 'Packet Diagram');
      expect(prepared.syntax.length, source.length);
      expect(prepared.syntax.indexOf('0: "Flag"'), source.indexOf('0: "Flag"'));
    });

    test('reports a missing header at the first visible token', () {
      const source = '\n  wrong';

      expect(
        () => prepareDiagramSource(source, headers: const ['railroad-beta']),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.offset, 'offset', source.indexOf('wrong'))
              .having((error) => error.message, 'message', 'Expected railroad-beta'),
        ),
      );
    });
  });

  group('quote-aware scanning', () {
    test('splits on separators outside quotes, keeping empty and untrimmed segments', () {
      expect(splitOutsideQuotes('a, "b, c" , d', ','), ['a', ' "b, c" ', ' d']);
      expect(splitOutsideQuotes(',,', ','), ['', '', '']);
      expect(splitOutsideQuotes('plain', ','), ['plain']);
    });

    test('honours multi-character separators without overlapping matches', () {
      expect(splitOutsideQuotes('a->b->c', '->'), ['a', 'b', 'c']);
      expect(splitOutsideQuotes('a-->b', '->'), ['a-', 'b']);
      expect(splitOutsideQuotes('a"x->y"->b', '->'), ['a"x->y"', 'b']);
    });

    test('treats a backslash inside quotes as an escape only when escapes are enabled', () {
      expect(splitOutsideQuotes(r'"a\"b",c', ','), [r'"a\"b"', 'c']);
      // Without escapes the second quote closes the run, so the comma sits inside the next one.
      expect(splitOutsideQuotes(r'"a\"b",c', ',', escapes: false), [r'"a\"b",c']);
    });

    test('restricts quoting to the requested characters', () {
      expect(splitOutsideQuotes("'a,b',c", ','), ["'a,b'", 'c']);
      expect(splitOutsideQuotes("'a,b',c", ',', quotes: '"'), ["'a", "b'", 'c']);
    });

    test('reports the first and last unquoted offsets, or -1 when there is none', () {
      expect(indexOutsideQuotes('a@"b@c"@d', '@'), 1);
      expect(lastIndexOutsideQuotes('a@"b@c"@d', '@'), 7);
      expect(indexOutsideQuotes('"a@b"', '@'), -1);
      expect(lastIndexOutsideQuotes('"a@b"', '@'), -1);
    });
  });

  group('ignored common syntax', () {
    test('only hides frontmatter at the start of the document', () {
      const bodyBlock = 'info\n---\nbody\n---\n';

      expect(hideIgnoredSyntax(bodyBlock), bodyBlock);
    });

    test('continues to hide leading frontmatter after blank lines', () {
      const source = '\n---\ntitle: Frontmatter\n---\ninfo\n';
      final hidden = hideIgnoredSyntax(source);

      expect(hidden.length, source.length);
      expect(hidden, '\n   \n                  \n   \ninfo\n');
    });
  });
}
