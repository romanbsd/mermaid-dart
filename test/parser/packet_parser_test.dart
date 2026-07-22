import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('packet parser', () {
    test('accepts packet and packet-beta headers', () {
      for (final source in ['packet', ' packet ', '\npacket-beta\n']) {
        expect((parse(DiagramType.packet, source) as PacketAst).blocks, isEmpty);
      }
    });

    test('parses ranges, individual bits, and relative-width blocks', () {
      final ast =
          parse(DiagramType.packet, '''packet-beta
0-7: "Source"
8: "Flag"
+16: "Payload"
''')
              as PacketAst;

      expect(ast.blocks, [
        const PacketRangeBlockAst(start: 0, end: 7, label: 'Source'),
        const PacketSingleBitBlockAst(bit: 8, label: 'Flag'),
        const PacketRelativeWidthBlockAst(bits: 16, label: 'Payload'),
      ]);
    });

    test('parses common metadata and escaped labels', () {
      final ast =
          parse(DiagramType.packet, r'''packet title Header layout
accTitle: Packet
0-3: "A\"B"
''')
              as PacketAst;

      expect(ast.title, 'Header layout');
      expect(ast.accessibilityTitle, 'Packet');
      expect(ast.blocks.single.label, 'A"B');
    });

    test('rejects malformed ranges', () {
      expect(() => parse(DiagramType.packet, 'packet\n7-: "Broken"'), throwsA(isA<MermaidParseException>()));
    });
  });
}
