part of 'ast.dart';

/// A parsed Mermaid mindmap.
final class MindmapAst extends DiagramAst {
  /// Creates a mindmap rooted at [root].
  const MindmapAst({required this.root, super.title, super.accessibilityTitle, super.accessibilityDescription});

  @override
  DiagramType get type => DiagramType.mindmap;

  /// The single root node.
  final MindmapNodeAst root;

  @override
  List<Object?> get diagramFields => [root];
}

/// One node in an indentation-defined mindmap hierarchy.
final class MindmapNodeAst with _AstValueEquality {
  /// Creates a mindmap node.
  const MindmapNodeAst({
    required this.id,
    required this.label,
    this.shape = MindmapNodeShape.noBorder,
    this.children = const [],
    this.icon,
    this.cssClasses = const [],
  });

  /// Mermaid node identifier.
  final String id;

  /// Visible node label.
  final String label;

  /// Node outline shape.
  final MindmapNodeShape shape;

  /// Child nodes in source order.
  final List<MindmapNodeAst> children;

  /// Optional icon reference from `::icon(...)`.
  final String? icon;

  /// CSS classes from `:::class` decorations.
  final List<String> cssClasses;

  @override
  List<Object?> get equalityFields => [id, label, shape, children, icon, cssClasses];
}

/// Mermaid mindmap node shapes.
enum MindmapNodeShape { noBorder, roundedRectangle, rectangle, circle, cloud, bang, hexagon }
