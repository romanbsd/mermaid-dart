import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common_syntax.dart';

final Parser<Object?> _integer = (char('0') | (pattern('1-9') & digit().star())).flatten();
final Parser<Object?> _range =
    _integer & (horizontalSpaceParser & char('-') & horizontalSpaceParser & _integer).optional();
final Parser<Object?> _relativeWidth = char('+') & _integer;
final Parser<PacketBlockAst> _block =
    (horizontalSpaceParser &
            (_range | _relativeWidth) &
            horizontalSpaceParser &
            char(':') &
            horizontalSpaceParser &
            quotedStringParser &
            horizontalSpaceParser &
            lineEndParser)
        .flatten()
        .map(_blockFromLexeme);

final Parser<Object?> _packetGrammar =
    (whitespaceParser &
            (string('packet-beta') | string('packet')) &
            (whitespaceParser & (commonMetadataParser | _block)).star() &
            whitespaceParser)
        .end();

/// Parses the Mermaid `packet` grammar.
PacketAst parsePacket(String source) {
  final value = parseGrammar(_packetGrammar, source);
  final metadata = commonMetadataFromParserValues(value);
  return PacketAst(
    blocks: List.unmodifiable(flattenParserValues<PacketBlockAst>(value)),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}

PacketBlockAst _blockFromLexeme(String lexeme) {
  final prefix = RegExp(
    r'^[\t ]*(?:(0|[1-9][0-9]*)(?:[\t ]*-[\t ]*(0|[1-9][0-9]*))?|\+[\t ]*(0|[1-9][0-9]*))[\t ]*:[\t ]*',
  ).firstMatch(lexeme)!;
  final labelLexeme = RegExp(r'''["'](?:\\.|[^"'\\])*["']''').matchAsPrefix(lexeme, prefix.end)!;

  final label = decodeQuotedString(labelLexeme.group(0)!);
  if (int.tryParse(prefix.group(3) ?? '') case final bits?) {
    return PacketRelativeWidthBlockAst(bits: bits, label: label);
  }
  final start = int.parse(prefix.group(1)!);
  if (int.tryParse(prefix.group(2) ?? '') case final end?) {
    return PacketRangeBlockAst(start: start, end: end, label: label);
  }
  return PacketSingleBitBlockAst(bit: start, label: label);
}
