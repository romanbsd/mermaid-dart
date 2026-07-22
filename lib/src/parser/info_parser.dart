import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common_syntax.dart';

final Parser<Object?> _infoGrammar =
    (whitespaceParser &
            string('info') &
            whitespaceParser &
            (string('showInfo') & whitespaceParser).optional() &
            (whitespaceParser & commonMetadataParser).star() &
            whitespaceParser)
        .end();

/// Parses the Mermaid `info` grammar.
InfoAst parseInfo(String source) {
  final visibleSource = hideIgnoredSyntax(source);
  final result = _infoGrammar.parse(visibleSource);
  if (result is Failure) throwParseFailure(source, result);

  final metadata = readCommonMetadata(hideHeader(visibleSource, 'info', modifier: 'showInfo'));
  return InfoAst(
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}
