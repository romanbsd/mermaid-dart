import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('parses band axes, plots, labels, orientation, and metadata', () {
    final ast =
        parse(DiagramType.xyChart, '''
xychart horizontal
  accTitle: Quarterly revenue
  accDescr: Revenue by quarter
  title "Sales"
  x-axis "Quarter" [Q1, "Q 2", Q3]
  y-axis "Revenue" 0 --> 100
  bar "Actual" [20, 45, 70]
  line "Forecast" [25 "Low", 50, 80 "High"]
''')
            as XyChartAst;

    expect(ast.orientation, XyChartOrientation.horizontal);
    expect(ast.title, 'Sales');
    expect(ast.accessibilityTitle, 'Quarterly revenue');
    expect(ast.accessibilityDescription, 'Revenue by quarter');
    expect(ast.xAxis, const XyChartBandAxisAst(title: 'Quarter', categories: ['Q1', 'Q 2', 'Q3']));
    expect(ast.yAxis, const XyChartLinearAxisAst(title: 'Revenue', min: 0, max: 100));
    expect(ast.plots, [
      const XyChartPlotAst(type: XyChartPlotType.bar, title: 'Actual', points: [20, 45, 70]),
      const XyChartPlotAst(
        type: XyChartPlotType.line,
        title: 'Forecast',
        points: [25, 50, 80],
        pointLabels: ['Low', '', 'High'],
      ),
    ]);
  });

  test('infers linear axes and y range from plot data', () {
    final ast = parse(DiagramType.xyChart, 'xychart-beta\nline [-2, 3, 8]') as XyChartAst;

    expect(ast.xAxis, const XyChartLinearAxisAst(min: 1, max: 3));
    expect(ast.yAxis, const XyChartLinearAxisAst(min: -2, max: 8));
  });

  test('rejects malformed and empty plot data', () {
    expect(() => parse(DiagramType.xyChart, 'xychart\nbar []'), throwsA(isA<MermaidParseException>()));
    expect(() => parse(DiagramType.xyChart, 'xychart\nline [1,,2]'), throwsA(isA<MermaidParseException>()));
  });
}
