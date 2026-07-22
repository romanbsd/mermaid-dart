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
  final visibleSource = hideIgnoredSyntax(source);
  final result = _packetGrammar.parse(visibleSource);
  if (result is Failure) throwParseFailure(source, result);

  final blocks = <PacketBlockAst>[];
  void collect(Object? value) {
    switch (value) {
      case PacketBlockAst():
        blocks.add(value);
      case Iterable<Object?>():
        value.forEach(collect);
    }
  }

  collect(result.value);
  final beta = RegExp(r'^[\t \r\n]*packet-beta\b').hasMatch(visibleSource);
  final metadata = readCommonMetadata(hideHeader(visibleSource, beta ? 'packet-beta' : 'packet'));
  return PacketAst(
    blocks: List.unmodifiable(blocks),
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

  return PacketBlockAst(
    start: int.tryParse(prefix.group(1) ?? ''),
    end: int.tryParse(prefix.group(2) ?? ''),
    bits: int.tryParse(prefix.group(3) ?? ''),
    label: decodeQuotedString(labelLexeme.group(0)!),
  );
}
