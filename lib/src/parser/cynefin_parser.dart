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
  final items = <CynefinItemAst>[];
  void collect(Object? part) {
    switch (part) {
      case CynefinItemAst():
        items.add(part);
      case Iterable<Object?>():
        part.forEach(collect);
    }
  }

  collect(value);
  return CynefinDomainAst(domain: value[0] as CynefinDomain, items: List.unmodifiable(items));
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
          final domains = <CynefinDomain>[];
          String? label;
          void collect(Object? part) {
            switch (part) {
              case CynefinDomain():
                domains.add(part);
              case _TransitionLabel():
                label = part.value;
              case Iterable<Object?>():
                part.forEach(collect);
            }
          }

          collect(value);
          return CynefinTransitionAst(from: domains[0], to: domains[1], label: label);
        });

final Parser<Object?> _cynefinGrammar =
    (whitespaceParser &
            string('cynefin-beta') &
            char(':').optional() &
            (whitespaceParser & (commonMetadataParser | _transition | _domainBlock)).star() &
            whitespaceParser)
        .end();

CynefinAst parseCynefin(String source) {
  final visibleSource = hideIgnoredSyntax(source);
  final result = _cynefinGrammar.parse(visibleSource);
  if (result is Failure) throwParseFailure(source, result);

  final domains = <CynefinDomainAst>[];
  final transitions = <CynefinTransitionAst>[];
  void collect(Object? value) {
    switch (value) {
      case CynefinDomainAst():
        domains.add(value);
      case CynefinTransitionAst():
        transitions.add(value);
      case Iterable<Object?>():
        value.forEach(collect);
    }
  }

  collect(result.value);
  final colonHeader = RegExp(r'^[\t \r\n]*cynefin-beta:').hasMatch(visibleSource);
  final metadata = readCommonMetadata(hideHeader(visibleSource, colonHeader ? 'cynefin-beta:' : 'cynefin-beta'));
  return CynefinAst(
    domains: List.unmodifiable(domains),
    transitions: List.unmodifiable(transitions),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}
