import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

final class _MermaidXyTextMeasurer implements TextMeasurer {
  const _MermaidXyTextMeasurer();

  @override
  Size measure(String text, SceneTextStyle style) {
    if (text == 'Sales') return const Size(45, 23);
    if (text == 'Quarter' || text == 'Revenue') return const Size(50, 19);
    if (const {'Q1', 'Q2', 'Q3', 'Q4'}.contains(text)) return const Size(17, 16);
    if (RegExp(r'^\d+$').hasMatch(text)) {
      return Size(text.length == 3 ? 22.031 : 15, 16);
    }
    return const DeterministicTextMeasurer().measure(text, style);
  }
}

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

  test('matches Mermaid 11.16 vertical component geometry and paint', () {
    final svg = renderDiagramSvg(
      DiagramType.xyChart,
      '''
xychart
  title "Sales"
  x-axis "Quarter" [Q1, Q2, Q3, Q4]
  y-axis "Revenue" 0 --> 100
  bar "Actual" [20, 45, 70, 85]
  line "Forecast" [25 "Low", 50, 75, 95 "High"]
''',
      options: const RenderOptions(padding: 0),
      textMeasurer: const _MermaidXyTextMeasurer(),
    );

    expect(svg, contains('fill="#ffffff"'));
    expect(svg, contains('x="70.681"'));
    expect(svg, contains('y="354.2"'));
    expect(svg, contains('width="100.7"'));
    expect(svg, contains('height="83.8"'));
    expect(svg, contains('fill="#ececff"'));
    expect(svg, contains('stroke="#8493a6"'));
    expect(svg, contains('translate(121.031 325.25)'));
    expect(svg, contains('translate(5 240.5) rotate(270)'));
    expect(svg, isNot(contains('<line')));
    expect(svg, isNot(contains('<polyline')));
    expect(svg, isNot(contains('<circle')));
    expect(RegExp('<path\\b').allMatches(svg), hasLength(18));
  });
}
