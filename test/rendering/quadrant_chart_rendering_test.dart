import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('lays out Mermaid quadrant geometry, labels, borders, and styled points', () {
    final scene = layoutDiagram(
      parse(DiagramType.quadrantChart, '''
quadrantChart
  title Campaigns
  accTitle: Campaign quadrant
  x-axis Low Reach --> High Reach
  y-axis Low Engagement --> High Engagement
  quadrant-1 Expand
  quadrant-2 Promote
  quadrant-3 Re-evaluate
  quadrant-4 Improve
  Campaign A: [0.75, 0.80] radius: 12, color: #ff3300, stroke-color: #10f0f0, stroke-width: 5px
'''),
      options: const RenderOptions(padding: 0),
    );
    final svg = renderSvg(scene);

    expect(scene.diagramType, DiagramType.quadrantChart);
    expect(scene.widthPolicy, SceneWidthPolicy.fitContainer);
    expect(scene.accessibilityTitle, 'Campaign quadrant');
    expect(svg, contains('viewBox="0 0 500 500"'));
    expect(svg, contains('class="quadrant quadrant-1"'));
    expect(svg, contains('class="quadrant-point"'));
    expect(svg, contains('cx="379"'));
    expect(svg, contains('cy="129.8"'));
    expect(svg, contains('r="12"'));
    expect(svg, contains('fill="#ff3300"'));
    expect(svg, contains('stroke="#10f0f0"'));
    expect(svg, contains('stroke-width="5"'));
    expect(svg, contains('Campaign A'));
    expect(svg, contains('High Engagement'));
  });

  test('centers quadrant and axis labels when no points are present', () {
    final svg = renderDiagramSvg(DiagramType.quadrantChart, '''
quadrantChart
  x-axis Low --> High
  y-axis Bottom --> Top
  quadrant-1 Do
''', options: const RenderOptions(padding: 0));

    expect(svg, contains('class="quadrant-label"'));
    expect(svg, contains('Do'));
    expect(svg, contains('Low'));
    expect(svg, contains('Top'));
  });
}
