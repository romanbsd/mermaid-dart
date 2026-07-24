import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('lays out bars, line, axes, labels, and accessible SVG', () {
    final scene = layoutDiagram(
      parse(DiagramType.xyChart, '''
xychart
  accTitle: Sales chart
  title "Quarterly sales"
  x-axis [Q1, Q2, Q3]
  y-axis 0 --> 100
  bar [20, 50, 80]
  line [30 "start", 60, 90 "end"]
'''),
    );
    final svg = renderSvg(scene);

    expect(scene.diagramType, DiagramType.xyChart);
    expect(svg, contains('Quarterly sales'));
    expect(svg, contains('Sales chart'));
    expect(svg, contains('xychart-bar'));
    expect(svg, contains('xychart-line'));
    expect(svg, contains('start'));
    expect(svg, contains('Q1'));
  });
}
