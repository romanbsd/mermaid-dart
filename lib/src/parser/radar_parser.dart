import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common_syntax.dart';

final Parser<String> _identifier =
    (pattern('A-Za-z0-9_') & (pattern('A-Za-z0-9_') | (char('-').plus() & pattern('A-Za-z0-9_'))).star()).flatten();
final Parser<String> _number =
    ((char('0') | (pattern('1-9') & digit().star())) & (char('.') & digit().plus()).optional()).flatten();

final class _Label {
  const _Label(this.value);
  final String value;
}

final Parser<_Label> _label = (char('[') & quotedStringParser.flatten() & char(']')).map(
  (values) => _Label(decodeQuotedString(values[1] as String)),
);

final Parser<RadarAxisAst> _axis = (_identifier & _label.optional()).map((values) {
  return RadarAxisAst(name: values[0] as String, label: (values[1] as _Label?)?.value);
});

final Parser<RadarEntryAst> _numberEntry = _number.map((value) => RadarEntryAst(value: num.parse(value)));
final Parser<RadarEntryAst> _detailedEntry =
    (_identifier & horizontalSpaceParser & char(':').optional() & horizontalSpaceParser & _number).map((values) {
      return RadarEntryAst(axis: values[0] as String, value: num.parse(values.last as String));
    });

Parser<Object?> _entryList(Parser<RadarEntryAst> entry) =>
    whitespaceParser & entry & (whitespaceParser & char(',') & whitespaceParser & entry).star() & whitespaceParser;

final Parser<Object?> _entries = _entryList(_numberEntry) | _entryList(_detailedEntry);

final Parser<RadarCurveAst> _curve =
    (_identifier & _label.optional() & horizontalSpaceParser & char('{') & _entries & char('}')).map((value) {
      return RadarCurveAst(
        name: value[0] as String,
        label: flattenParserValues<_Label>(value).firstOrNull?.value,
        entries: List.unmodifiable(flattenParserValues<RadarEntryAst>(value)),
      );
    });

final Parser<RadarOptionAst> _showLegendOption =
    (string('showLegend') & pattern(' \t').plus() & (string('true') | string('false'))).map((value) {
      return RadarShowLegendOptionAst(value.last == 'true');
    });

Parser<RadarOptionAst> _numericOption(String name, RadarOptionAst Function(num value) create) =>
    (string(name) & pattern(' \t').plus() & _number).map((value) => create(num.parse(value.last as String)));

final Parser<RadarOptionAst> _graticuleOption =
    (string('graticule') & pattern(' \t').plus() & (string('circle') | string('polygon'))).map((value) {
      return RadarGraticuleOptionAst(RadarGraticule.values.byName(value.last as String));
    });

final Parser<RadarOptionAst> _option =
    (_showLegendOption |
            _numericOption('ticks', RadarTicksOptionAst.new) |
            _numericOption('max', RadarMaxOptionAst.new) |
            _numericOption('min', RadarMinOptionAst.new) |
            _graticuleOption)
        .cast<RadarOptionAst>();

Parser<Object?> _commaSeparated(Parser<Object?> item) =>
    item & (horizontalSpaceParser & char(',') & horizontalSpaceParser & item).star();

final Parser<Object?> _axisStatement = string('axis') & pattern(' \t').plus() & _commaSeparated(_axis);
final Parser<Object?> _curveStatement = string('curve') & pattern(' \t').plus() & _commaSeparated(_curve);
final Parser<Object?> _optionStatement = _commaSeparated(_option);

final Parser<Object?> _radarGrammar =
    (whitespaceParser &
            string('radar-beta') &
            horizontalSpaceParser &
            char(':').optional() &
            (whitespaceParser & (commonMetadataParser | _axisStatement | _curveStatement | _optionStatement)).star() &
            whitespaceParser)
        .end();

RadarAst parseRadar(String source) {
  final value = parseGrammar(_radarGrammar, source);
  final metadata = commonMetadataFromParserValues(value);
  return RadarAst(
    axes: List.unmodifiable(flattenParserValues<RadarAxisAst>(value)),
    curves: List.unmodifiable(flattenParserValues<RadarCurveAst>(value)),
    options: List.unmodifiable(flattenParserValues<RadarOptionAst>(value)),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}
