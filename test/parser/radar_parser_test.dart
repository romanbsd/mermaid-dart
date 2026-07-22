import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('radar parser', () {
    test('accepts all header variants', () {
      for (final source in ['radar-beta', ' radar-beta: ', '\nradar-beta :\n']) {
        expect((parse(DiagramType.radar, source) as RadarAst).axes, isEmpty);
      }
    });

    test('parses axes and optional labels', () {
      final ast = parse(DiagramType.radar, 'radar-beta\naxis speed["Speed"], quality, cost["Cost"]') as RadarAst;

      expect(ast.axes, [
        const RadarAxisAst(name: 'speed', label: 'Speed'),
        const RadarAxisAst(name: 'quality'),
        const RadarAxisAst(name: 'cost', label: 'Cost'),
      ]);
    });

    test('parses positional and detailed curve entries', () {
      final ast =
          parse(DiagramType.radar, '''radar-beta
axis speed, quality
curve current["Current"] { 3, 4 }, target { speed: 5, quality 6 }
''')
              as RadarAst;

      expect(ast.curves, [
        const RadarCurveAst(
          name: 'current',
          label: 'Current',
          entries: [RadarEntryAst(value: 3), RadarEntryAst(value: 4)],
        ),
        const RadarCurveAst(
          name: 'target',
          entries: [
            RadarEntryAst(axis: 'speed', value: 5),
            RadarEntryAst(axis: 'quality', value: 6),
          ],
        ),
      ]);
    });

    test('parses all option value types and common metadata', () {
      final ast =
          parse(DiagramType.radar, '''radar-beta:
title Comparison
accTitle: Radar chart
showLegend true, ticks 5, min 0, max 10.5, graticule polygon
''')
              as RadarAst;

      expect(ast.title, 'Comparison');
      expect(ast.accessibilityTitle, 'Radar chart');
      expect(ast.options, [
        const RadarOptionAst(name: RadarOptionName.showLegend, value: true),
        const RadarOptionAst(name: RadarOptionName.ticks, value: 5),
        const RadarOptionAst(name: RadarOptionName.min, value: 0),
        const RadarOptionAst(name: RadarOptionName.max, value: 10.5),
        const RadarOptionAst(name: RadarOptionName.graticule, value: RadarGraticule.polygon),
      ]);
    });

    test('rejects mixed positional and detailed entries', () {
      expect(
        () => parse(DiagramType.radar, 'radar-beta\naxis a\ncurve c { 1, a: 2 }'),
        throwsA(isA<MermaidParseException>()),
      );
    });
  });
}
