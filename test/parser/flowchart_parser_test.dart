import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('flowchart parser', () {
    test('exposes reusable direction predicates', () {
      expect(FlowchartDirection.topDown.isVertical, isTrue);
      expect(FlowchartDirection.bottomTop.isVertical, isTrue);
      expect(FlowchartDirection.leftRight.isHorizontal, isTrue);
      expect(FlowchartDirection.rightLeft.isHorizontal, isTrue);
      expect(FlowchartDirection.topDown.isForward, isTrue);
      expect(FlowchartDirection.leftRight.isForward, isTrue);
      expect(FlowchartDirection.bottomTop.isReversed, isTrue);
      expect(FlowchartDirection.rightLeft.isReversed, isTrue);
    });

    test('parses metadata, direction, shaped nodes, labeled edges, and chains', () {
      final ast =
          parse(DiagramType.flowchart, '''
flowchart LR
title Decisions
accTitle: Accessible decisions
accDescr: A decision flow
A[Hard] -->|choose| B(Round) --> C{Decision}
''')
              as FlowchartAst;

      expect(ast.direction, FlowchartDirection.leftRight);
      expect(ast.title, 'Decisions');
      expect(ast.accessibilityTitle, 'Accessible decisions');
      expect(ast.accessibilityDescription, 'A decision flow');
      expect(ast.nodes, [
        const FlowchartNodeAst(id: 'A', label: 'Hard'),
        const FlowchartNodeAst(id: 'B', label: 'Round', shape: FlowchartNodeShape.rounded),
        const FlowchartNodeAst(id: 'C', label: 'Decision', shape: FlowchartNodeShape.diamond),
      ]);
      expect(ast.edges, [
        const FlowchartEdgeAst(from: 'A', to: 'B', label: 'choose'),
        const FlowchartEdgeAst(from: 'B', to: 'C'),
      ]);
    });

    test('supports graph aliases and Mermaid edge variants', () {
      final ast =
          parse(DiagramType.flowchart, '''
graph TD
A --- B
B -. dotted .-> C
C == thick ==> D
D o--o E
E x--x F
F <--> G
''')
              as FlowchartAst;

      expect(ast.direction, FlowchartDirection.topDown);
      expect(ast.edges, [
        const FlowchartEdgeAst(from: 'A', to: 'B', endMarker: FlowchartEdgeMarker.none),
        const FlowchartEdgeAst(from: 'B', to: 'C', label: 'dotted', stroke: FlowchartEdgeStroke.dotted),
        const FlowchartEdgeAst(from: 'C', to: 'D', label: 'thick', stroke: FlowchartEdgeStroke.thick),
        const FlowchartEdgeAst(
          from: 'D',
          to: 'E',
          startMarker: FlowchartEdgeMarker.circle,
          endMarker: FlowchartEdgeMarker.circle,
        ),
        const FlowchartEdgeAst(
          from: 'E',
          to: 'F',
          startMarker: FlowchartEdgeMarker.cross,
          endMarker: FlowchartEdgeMarker.cross,
        ),
        const FlowchartEdgeAst(from: 'F', to: 'G', startMarker: FlowchartEdgeMarker.arrow),
      ]);
    });

    test('parses subgraphs, local direction, classes, and class definitions', () {
      final ast =
          parse(DiagramType.flowchart, '''
flowchart TB
subgraph api [API tier]
  direction LR
  A[Gateway] --> B[(Database)]
end
classDef hot fill:#f96,stroke:#333
class A,B hot
''')
              as FlowchartAst;

      expect(ast.subgraphs, [
        const FlowchartSubgraphAst(
          id: 'api',
          title: 'API tier',
          direction: FlowchartDirection.leftRight,
          nodeIds: ['A', 'B'],
        ),
      ]);
      expect(ast.nodes.first.cssClasses, ['hot']);
      expect(ast.nodes.last.cssClasses, ['hot']);
      expect(ast.classDefinitions, {
        'hot': {'fill': '#f96', 'stroke': '#333'},
      });
      expect(ast.nodes.last.shape, FlowchartNodeShape.cylinder);
    });

    test('includes previously declared nodes referenced inside a subgraph', () {
      final ast =
          parse(DiagramType.flowchart, '''
flowchart LR
Gateway{Authorized?}
subgraph services [Services]
  direction TB
  Gateway --> API[API]
  API ==> Database[(Database)]
end
''')
              as FlowchartAst;

      expect(ast.subgraphs.single.nodeIds, ['Gateway', 'API', 'Database']);
    });

    test('reports an unterminated node with a source location', () {
      expect(
        () => parse(DiagramType.flowchart, 'flowchart TD\nA[broken --> B\n'),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.line, 'line', 2)
              .having((error) => error.column, 'column', 2),
        ),
      );
    });
  });
}
