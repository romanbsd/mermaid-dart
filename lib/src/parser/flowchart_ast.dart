part of 'ast.dart';

/// Flow direction declared by a Mermaid flowchart.
enum FlowchartDirection {
  topDown,
  bottomTop,
  leftRight,
  rightLeft;

  /// Whether this direction lies on the vertical axis.
  bool get isVertical => this == topDown || this == bottomTop;

  /// Whether this direction lies on the horizontal axis.
  bool get isHorizontal => !isVertical;

  /// Whether layout proceeds from top or left toward bottom or right.
  bool get isForward => this == topDown || this == leftRight;

  /// Whether layout proceeds from bottom or right toward top or left.
  bool get isReversed => !isForward;
}

/// Closed set of classic Mermaid flowchart node shapes.
enum FlowchartNodeShape {
  rectangle,
  rounded,
  stadium,
  subroutine,
  cylinder,
  circle,
  doubleCircle,
  asymmetric,
  diamond,
  hexagon,
  parallelogram,
  parallelogramAlt,
  trapezoid,
  trapezoidAlt,
}

/// Stroke pattern used by a flowchart edge.
enum FlowchartEdgeStroke { normal, thick, dotted }

/// Marker drawn at either endpoint of a flowchart edge.
enum FlowchartEdgeMarker { none, arrow, circle, cross }

/// A parsed Mermaid flowchart.
final class FlowchartAst extends DiagramAst {
  /// Creates a typed flowchart AST.
  const FlowchartAst({
    this.direction = FlowchartDirection.topDown,
    this.nodes = const [],
    this.edges = const [],
    this.subgraphs = const [],
    this.classDefinitions = const {},
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.flowchart;

  /// Global graph direction.
  final FlowchartDirection direction;

  /// Nodes in first-declaration order.
  final List<FlowchartNodeAst> nodes;

  /// Edges in source order.
  final List<FlowchartEdgeAst> edges;

  /// Subgraphs in source order.
  final List<FlowchartSubgraphAst> subgraphs;

  /// CSS-like class properties keyed by class name.
  final Map<String, Map<String, String>> classDefinitions;

  @override
  List<Object?> get diagramFields => [direction, nodes, edges, subgraphs, classDefinitions];
}

/// One flowchart node.
final class FlowchartNodeAst with _AstValueEquality {
  /// Creates a typed flowchart node.
  const FlowchartNodeAst({
    required this.id,
    required this.label,
    this.shape = FlowchartNodeShape.rectangle,
    this.cssClasses = const [],
    this.styles = const {},
  });

  /// Stable Mermaid node identifier.
  final String id;

  /// Visible node label.
  final String label;

  /// Node geometry.
  final FlowchartNodeShape shape;

  /// Classes assigned through `class`, `:::`, or `classDef`.
  final List<String> cssClasses;

  /// Inline properties from a `style` statement.
  final Map<String, String> styles;

  @override
  List<Object?> get equalityFields => [id, label, shape, cssClasses, styles];
}

/// One directed or open flowchart edge.
final class FlowchartEdgeAst with _AstValueEquality {
  /// Creates a typed flowchart edge.
  const FlowchartEdgeAst({
    required this.from,
    required this.to,
    this.id,
    this.label,
    this.stroke = FlowchartEdgeStroke.normal,
    this.startMarker = FlowchartEdgeMarker.none,
    this.endMarker = FlowchartEdgeMarker.arrow,
    this.length = 1,
    this.styles = const {},
  });

  /// Source node identifier.
  final String from;

  /// Destination node identifier.
  final String to;

  /// Optional edge identifier declared with `id@`.
  final String? id;

  /// Optional edge label.
  final String? label;

  /// Edge stroke pattern.
  final FlowchartEdgeStroke stroke;

  /// Marker at the source endpoint.
  final FlowchartEdgeMarker startMarker;

  /// Marker at the destination endpoint.
  final FlowchartEdgeMarker endMarker;

  /// Mermaid's minimum-rank edge length.
  final int length;

  /// Inline properties assigned with Mermaid's `linkStyle` statement.
  final Map<String, String> styles;

  @override
  List<Object?> get equalityFields => [from, to, id, label, stroke, startMarker, endMarker, length, styles];
}

/// A flowchart subgraph and its directly declared nodes.
final class FlowchartSubgraphAst with _AstValueEquality {
  /// Creates a typed subgraph.
  const FlowchartSubgraphAst({required this.id, required this.title, this.direction, this.nodeIds = const []});

  /// Stable subgraph identifier.
  final String id;

  /// Visible subgraph title.
  final String title;

  /// Optional local direction.
  final FlowchartDirection? direction;

  /// Directly declared member node identifiers.
  final List<String> nodeIds;

  @override
  List<Object?> get equalityFields => [id, title, direction, nodeIds];
}
