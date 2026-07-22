import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common_syntax.dart';

final Parser<Object?> _unsignedInteger = char('0') | (pattern('1-9') & digit().star());
final Parser<Object?> _number = (char('-').optional() & _unsignedInteger & (char('.') & digit().plus()).optional())
    .flatten();

final Parser<PieSectionAst> _section =
    (horizontalSpaceParser &
            quotedStringParser &
            horizontalSpaceParser &
            char(':') &
            horizontalSpaceParser &
            _number &
            horizontalSpaceParser &
            lineEndParser)
        .flatten()
        .map(_sectionFromLexeme);

final class _ShowData {
  const _ShowData();
}

final Parser<Object?> _pieGrammar =
    (whitespaceParser &
            string('pie') &
            whitespaceParser &
            string('showData').map((_) => const _ShowData()).optional() &
            (whitespaceParser & (commonMetadataParser | _section)).star() &
            whitespaceParser)
        .end();

/// Parses the Mermaid `pie` grammar.
PieAst parsePie(String source) {
  final value = parseGrammar(
    _pieGrammar,
    source,
    onFailure: (visibleSource, result) {
      final malformedSection = RegExp(
        r'''[\t \r\n]*["'](?:\\.|[^"'\\])*["'][\t ]*:[\t ]*''',
      ).matchAsPrefix(visibleSource, result.position);
      if (malformedSection != null) {
        throwParseError(source, 'number expected', malformedSection.end);
      }
    },
  );
  final metadata = commonMetadataFromParserValues(value);
  return PieAst(
    showData: flattenParserValues<_ShowData>(value).isNotEmpty,
    sections: List.unmodifiable(flattenParserValues<PieSectionAst>(value)),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}

PieSectionAst _sectionFromLexeme(String lexeme) {
  var index = 0;
  while (index < lexeme.length && (lexeme.codeUnitAt(index) == 9 || lexeme.codeUnitAt(index) == 32)) {
    index++;
  }

  final labelStart = index;
  final quote = lexeme[index++];
  while (index < lexeme.length) {
    final character = lexeme[index++];
    if (character == '\\' && index < lexeme.length) {
      index++;
    } else if (character == quote) {
      break;
    }
  }
  final label = decodeQuotedString(lexeme.substring(labelStart, index));

  final value = RegExp(r':\s*(-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?)').firstMatch(lexeme.substring(index))!;
  return PieSectionAst(label: label.trim(), value: num.parse(value.group(1)!));
}
