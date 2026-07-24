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

    test('parses no-space arrows without consuming them as node ids', () {
      final ast =
          parse(DiagramType.flowchart, '''
flowchart LR
A-->B
B-.->C
C---D
''')
              as FlowchartAst;

      expect(ast.nodes.map((node) => node.id), ['A', 'B', 'C', 'D']);
      expect(ast.edges, const [
        FlowchartEdgeAst(from: 'A', to: 'B'),
        FlowchartEdgeAst(from: 'B', to: 'C', stroke: FlowchartEdgeStroke.dotted),
        FlowchartEdgeAst(from: 'C', to: 'D', endMarker: FlowchartEdgeMarker.none),
      ]);
    });

    test('parses inline classes on bare nodes while retaining punctuation in ids', () {
      final ast =
          parse(DiagramType.flowchart, '''
flowchart LR
source-node.v1:port --> target-node:::hot,selected
''')
              as FlowchartAst;

      expect(ast.nodes.first.id, 'source-node.v1:port');
      expect(
        ast.nodes.last,
        const FlowchartNodeAst(id: 'target-node', label: 'target-node', cssClasses: ['hot', 'selected']),
      );
    });

    test('expands ampersand node groups on both sides of an edge', () {
      final ast = parse(DiagramType.flowchart, 'flowchart LR\nA & B --> C & D\n') as FlowchartAst;

      expect(ast.nodes.map((node) => node.id), ['A', 'B', 'C', 'D']);
      expect(ast.edges, const [
        FlowchartEdgeAst(from: 'A', to: 'C'),
        FlowchartEdgeAst(from: 'A', to: 'D'),
        FlowchartEdgeAst(from: 'B', to: 'C'),
        FlowchartEdgeAst(from: 'B', to: 'D'),
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

    test('ports the upstream shape, chain, link-style, and markdown matrix', () {
      const shapes = {
        'A[Rectangle]': FlowchartNodeShape.rectangle,
        'A(Rounded)': FlowchartNodeShape.rounded,
        'A([Stadium])': FlowchartNodeShape.stadium,
        'A[[Subroutine]]': FlowchartNodeShape.subroutine,
        'A[(Database)]': FlowchartNodeShape.cylinder,
        'A((Circle))': FlowchartNodeShape.circle,
        'A(((Double)))': FlowchartNodeShape.doubleCircle,
        'A>Asymmetric]': FlowchartNodeShape.asymmetric,
        'A{Diamond}': FlowchartNodeShape.diamond,
        'A{{Hexagon}}': FlowchartNodeShape.hexagon,
        'A[/Lean right/]': FlowchartNodeShape.parallelogram,
        r'A[\Lean left\]': FlowchartNodeShape.parallelogramAlt,
        r'A[/Trapezoid\]': FlowchartNodeShape.trapezoid,
        r'A[\Trapezoid alt/]': FlowchartNodeShape.trapezoidAlt,
      };
      for (final MapEntry(key: source, value: shape) in shapes.entries) {
        late final FlowchartAst ast;
        try {
          ast = parse(DiagramType.flowchart, 'flowchart LR\n$source\n') as FlowchartAst;
        } on MermaidParseException catch (error) {
          fail('$source: $error');
        }
        expect(ast.nodes.single.shape, shape, reason: source);
      }

      final ast =
          parse(DiagramType.flowchart, '''
flowchart LR
A["`Markdown label`"] --> B --> C
linkStyle default stroke-width:2px
linkStyle 0,1 stroke:#ff0000
''')
              as FlowchartAst;

      expect(ast.nodes.first.label, 'Markdown label');
      expect(ast.edges, hasLength(2));
      expect(ast.edges.first.styles, {'stroke-width': '2px', 'stroke': '#ff0000'});
      expect(ast.edges.last.styles, {'stroke-width': '2px', 'stroke': '#ff0000'});
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
