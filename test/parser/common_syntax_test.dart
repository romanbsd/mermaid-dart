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
}
