import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('packet parser', () {
    test('accepts packet and packet-beta headers', () {
      for (final source in ['packet', ' packet ', '\npacket-beta\n']) {
        expect((parse('packet', source) as PacketAst).blocks, isEmpty);
      }
    });

    test('parses ranges, individual bits, and relative-width blocks', () {
      final ast =
          parse('packet', '''packet-beta
0-7: "Source"
8: "Flag"
+16: "Payload"
''')
              as PacketAst;

      expect(ast.blocks, [
        const PacketBlockAst(start: 0, end: 7, label: 'Source'),
        const PacketBlockAst(start: 8, label: 'Flag'),
        const PacketBlockAst(bits: 16, label: 'Payload'),
      ]);
    });

    test('parses common metadata and escaped labels', () {
      final ast =
          parse('packet', r'''packet title Header layout
accTitle: Packet
0-3: "A\"B"
''')
              as PacketAst;

      expect(ast.title, 'Header layout');
      expect(ast.accessibilityTitle, 'Packet');
      expect(ast.blocks.single.label, 'A"B');
    });

    test('rejects malformed ranges', () {
      expect(() => parse('packet', 'packet\n7-: "Broken"'), throwsA(isA<MermaidParseException>()));
    });
  });
}
