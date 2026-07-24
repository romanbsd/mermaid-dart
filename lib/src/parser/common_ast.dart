part of 'ast.dart';

/// Cardinal layout direction shared by graph-shaped Mermaid diagrams.
enum GraphDirection {
  topDown,
  bottomTop,
  leftRight,
  rightLeft;

  /// Whether ranks progress on the vertical axis.
  bool get isVertical => this == topDown || this == bottomTop;

  /// Whether ranks progress on the horizontal axis.
  bool get isHorizontal => !isVertical;

  /// Whether ranks use their natural top-to-bottom or left-to-right order.
  bool get isForward => this == topDown || this == leftRight;
}

/// Base type for immutable syntax trees produced by Mermaid parsers.
///
/// Common title and accessibility metadata is normalized here so renderers can
/// consume it uniformly across every diagram family.
sealed class DiagramAst with _AstValueEquality {
  const DiagramAst({this.title, this.accessibilityTitle, this.accessibilityDescription});

  /// The grammar and renderer family represented by this tree.
  DiagramType get type;

  /// The optional diagram title from frontmatter or diagram syntax.
  final String? title;

  /// The optional concise title intended for assistive technology.
  final String? accessibilityTitle;

  /// The optional detailed description intended for assistive technology.
  final String? accessibilityDescription;

  /// Diagram-specific fields used by structural equality.
  List<Object?> get diagramFields;

  @override
  List<Object?> get equalityFields => [...diagramFields, title, accessibilityTitle, accessibilityDescription];
}
