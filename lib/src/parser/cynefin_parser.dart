import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common_syntax.dart';

final Parser<CynefinDomain> _domain =
    (string('complex') | string('complicated') | string('clear') | string('chaotic') | string('confusion')).map(
      (value) => CynefinDomain.values.byName(value as String),
    );

final Parser<CynefinItemAst> _item = quotedStringParser.flatten().map(
  (value) => CynefinItemAst(label: decodeQuotedString(value)),
);

final Parser<CynefinDomainAst> _domainBlock = (_domain & (whitespaceParser & _item).star()).map((value) {
  return CynefinDomainAst(
    domain: value[0] as CynefinDomain,
    items: List.unmodifiable(flattenParserValues<CynefinItemAst>(value)),
  );
});

final class _TransitionLabel {
  const _TransitionLabel(this.value);
  final String value;
}

final Parser<CynefinTransitionAst> _transition =
    (_domain &
            horizontalSpaceParser &
            string('-->') &
            horizontalSpaceParser &
            _domain &
            (horizontalSpaceParser &
                    char(':') &
                    horizontalSpaceParser &
                    quotedStringParser.flatten().map((value) => _TransitionLabel(decodeQuotedString(value))))
                .optional() &
            horizontalSpaceParser &
            lineEndParser)
        .map((value) {
          final domains = flattenParserValues<CynefinDomain>(value);
          return CynefinTransitionAst(
            from: domains[0],
            to: domains[1],
            label: flattenParserValues<_TransitionLabel>(value).firstOrNull?.value,
          );
        });

final Parser<Object?> _cynefinGrammar =
    (whitespaceParser &
            string('cynefin-beta') &
            char(':').optional() &
            (whitespaceParser & (commonMetadataParser | _transition | _domainBlock)).star() &
            whitespaceParser)
        .end();

CynefinAst parseCynefin(String source) {
  final value = parseGrammar(_cynefinGrammar, source);
  final metadata = commonMetadataFromParserValues(value);
  return CynefinAst(
    domains: List.unmodifiable(flattenParserValues<CynefinDomainAst>(value)),
    transitions: List.unmodifiable(flattenParserValues<CynefinTransitionAst>(value)),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}
