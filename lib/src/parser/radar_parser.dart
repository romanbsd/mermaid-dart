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
      final entries = <RadarEntryAst>[];
      String? name;
      String? label;
      void collect(Object? item) {
        switch (item) {
          case RadarEntryAst():
            entries.add(item);
          case _Label():
            label = item.value;
          case String() when name == null:
            name = item;
          case Iterable<Object?>():
            item.forEach(collect);
        }
      }

      collect(value);
      return RadarCurveAst(name: name!, label: label, entries: List.unmodifiable(entries));
    });

final Parser<RadarOptionAst> _option =
    ((string('showLegend') & pattern(' \t').plus() & (string('true') | string('false'))) |
            ((string('ticks') | string('max') | string('min')) & pattern(' \t').plus() & _number) |
            (string('graticule') & pattern(' \t').plus() & (string('circle') | string('polygon'))))
        .map((value) {
          final parts = value as List;
          final name = RadarOptionName.values.byName(parts.first as String);
          final raw = parts.last as String;
          final converted = switch (name) {
            RadarOptionName.showLegend => raw == 'true',
            RadarOptionName.graticule => RadarGraticule.values.byName(raw),
            _ => num.parse(raw),
          };
          return RadarOptionAst(name: name, value: converted);
        });

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
  final visibleSource = hideIgnoredSyntax(source);
  final result = _radarGrammar.parse(visibleSource);
  if (result is Failure) throwParseFailure(source, result);

  final axes = <RadarAxisAst>[];
  final curves = <RadarCurveAst>[];
  final options = <RadarOptionAst>[];
  void collect(Object? value) {
    switch (value) {
      case RadarAxisAst():
        axes.add(value);
      case RadarCurveAst():
        curves.add(value);
      case RadarOptionAst():
        options.add(value);
      case Iterable<Object?>():
        value.forEach(collect);
    }
  }

  collect(result.value);
  final metadata = readCommonMetadata(hideHeader(visibleSource, 'radar-beta'));
  return RadarAst(
    axes: List.unmodifiable(axes),
    curves: List.unmodifiable(curves),
    options: List.unmodifiable(options),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}
