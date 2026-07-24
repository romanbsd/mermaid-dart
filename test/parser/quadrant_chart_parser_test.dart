import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('parses labels, metadata, points, classes, and direct styles', () {
    final ast =
        parse(DiagramType.quadrantChart, '''
quadrantChart
  title Reach and engagement
  accTitle: Campaign chart
  accDescr: Campaign reach by engagement
  x-axis Low Reach --> High Reach
  y-axis Low Engagement --> High Engagement
  quadrant-1 Expand
  quadrant-2 Promote
  quadrant-3 Re-evaluate
  quadrant-4 Improve
  Campaign A: [0.3, 0.6]
  Campaign B:::important: [0.8, 0.2] radius: 12, color: #ff3300
  classDef important color: #109060, radius: 10, stroke-color: #310085, stroke-width: 4px
''')
            as QuadrantChartAst;

    expect(ast.title, 'Reach and engagement');
    expect(ast.accessibilityTitle, 'Campaign chart');
    expect(ast.accessibilityDescription, 'Campaign reach by engagement');
    expect(ast.xAxis, const QuadrantAxisAst(start: 'Low Reach', end: 'High Reach'));
    expect(ast.yAxis, const QuadrantAxisAst(start: 'Low Engagement', end: 'High Engagement'));
    expect(ast.quadrants, {
      Quadrant.topRight: 'Expand',
      Quadrant.topLeft: 'Promote',
      Quadrant.bottomLeft: 'Re-evaluate',
      Quadrant.bottomRight: 'Improve',
    });
    expect(ast.points, [
      const QuadrantPointAst(label: 'Campaign A', x: .3, y: .6),
      const QuadrantPointAst(
        label: 'Campaign B',
        x: .8,
        y: .2,
        className: 'important',
        style: QuadrantPointStyleAst(radius: 12, color: '#ff3300'),
      ),
    ]);
    expect(ast.classDefinitions, {
      'important': const QuadrantPointStyleAst(radius: 10, color: '#109060', strokeColor: '#310085', strokeWidth: 4),
    });
  });

  test('accepts quoted labels, comments, and boundary coordinates', () {
    final ast =
        parse(DiagramType.quadrantChart, '''
quadrantChart
  x-axis "Not urgent" --> "Urgent now" %% comment
  y-axis "Low value"
  "Important ❤": [0, 1]
''')
            as QuadrantChartAst;

    expect(ast.xAxis, const QuadrantAxisAst(start: 'Not urgent', end: 'Urgent now'));
    expect(ast.yAxis, const QuadrantAxisAst(start: 'Low value'));
    expect(ast.points.single, const QuadrantPointAst(label: 'Important ❤', x: 0, y: 1));
  });

  test('rejects out-of-range points and unsupported styles', () {
    expect(
      () => parse(DiagramType.quadrantChart, 'quadrantChart\nPoint: [1.1, 0.2]'),
      throwsA(isA<MermaidParseException>()),
    );
    expect(
      () => parse(DiagramType.quadrantChart, 'quadrantChart\nPoint: [0.1, 0.2] opacity: 0.5'),
      throwsA(isA<MermaidParseException>()),
    );
    expect(
      () => parse(DiagramType.quadrantChart, 'quadrantChart\nPoint: [0.1, 0.2] stroke-width: 3'),
      throwsA(isA<MermaidParseException>()),
    );
  });
}
