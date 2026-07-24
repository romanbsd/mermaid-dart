part of 'ast.dart';

/// A parsed Mermaid entity-relationship diagram.
final class ErDiagramAst extends DiagramAst {
  /// Creates an ER-diagram AST.
  const ErDiagramAst({
    this.direction = GraphDirection.topDown,
    this.entities = const [],
    this.relationships = const [],
    this.classDefinitions = const {},
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.entityRelationship;

  /// Global graph direction.
  final GraphDirection direction;

  /// Entities in first-declaration order.
  final List<ErEntityAst> entities;

  /// Relationships in source order.
  final List<ErRelationshipAst> relationships;

  /// CSS-like style properties keyed by class definition name.
  final Map<String, Map<String, String>> classDefinitions;

  @override
  List<Object?> get diagramFields => [direction, entities, relationships, classDefinitions];
}

/// One ER entity and its attributes.
final class ErEntityAst with _AstValueEquality {
  /// Creates an ER entity.
  const ErEntityAst({
    required this.id,
    required this.label,
    this.attributes = const [],
    this.cssClasses = const [],
    this.styles = const {},
  });

  /// Stable entity identifier.
  final String id;

  /// Visible entity label.
  final String label;

  /// Attributes in source order.
  final List<ErAttributeAst> attributes;

  /// CSS classes assigned to this entity.
  final List<String> cssClasses;

  /// Inline style properties.
  final Map<String, String> styles;

  @override
  List<Object?> get equalityFields => [id, label, attributes, cssClasses, styles];
}

/// Closed set of ER attribute key markers.
enum ErAttributeKey { primary, foreign, unique }

/// One entity attribute.
final class ErAttributeAst with _AstValueEquality {
  /// Creates an ER attribute.
  const ErAttributeAst({required this.type, required this.name, this.keys = const {}, this.comment});

  /// Attribute data type.
  final String type;

  /// Attribute name.
  final String name;

  /// Key constraints.
  final Set<ErAttributeKey> keys;

  /// Optional quoted comment.
  final String? comment;

  @override
  List<Object?> get equalityFields => [type, name, keys, comment];
}

/// Cardinality at one endpoint of an ER relationship.
enum ErCardinality { zeroOrOne, exactlyOne, zeroOrMore, oneOrMore, parent }

/// One relationship between two ER entities.
final class ErRelationshipAst with _AstValueEquality {
  /// Creates an ER relationship.
  const ErRelationshipAst({
    required this.from,
    required this.to,
    required this.fromCardinality,
    required this.toCardinality,
    required this.identifying,
    required this.label,
  });

  /// Source entity identifier.
  final String from;

  /// Destination entity identifier.
  final String to;

  /// Cardinality at [from].
  final ErCardinality fromCardinality;

  /// Cardinality at [to].
  final ErCardinality toCardinality;

  /// Whether the relationship uses a solid identifying line.
  final bool identifying;

  /// Relationship role label.
  final String label;

  @override
  List<Object?> get equalityFields => [from, to, fromCardinality, toCardinality, identifying, label];
}
