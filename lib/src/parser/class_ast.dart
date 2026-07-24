part of 'ast.dart';

/// A parsed Mermaid class diagram.
final class ClassDiagramAst extends DiagramAst {
  /// Creates a class-diagram AST.
  const ClassDiagramAst({
    this.direction = GraphDirection.topDown,
    this.classes = const [],
    this.relations = const [],
    this.namespaces = const [],
    this.notes = const [],
    this.classDefinitions = const {},
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.classDiagram;

  /// Global graph direction.
  final GraphDirection direction;

  /// Classes in first-declaration order.
  final List<ClassAst> classes;

  /// Relations in source order.
  final List<ClassRelationAst> relations;

  /// Explicit namespaces in source order.
  final List<ClassNamespaceAst> namespaces;

  /// Diagram and class notes in source order.
  final List<ClassNoteAst> notes;

  /// CSS-like style properties keyed by class definition name.
  final Map<String, Map<String, String>> classDefinitions;

  @override
  List<Object?> get diagramFields => [direction, classes, relations, namespaces, notes, classDefinitions];
}

/// A class declaration and its visible compartments.
final class ClassAst with _AstValueEquality {
  /// Creates a class node.
  const ClassAst({
    required this.id,
    required this.label,
    this.annotations = const [],
    this.members = const [],
    this.cssClasses = const [],
    this.styles = const {},
    this.namespaceId,
  });

  /// Stable Mermaid identifier.
  final String id;

  /// Visible class label.
  final String label;

  /// Stereotypes such as `interface` and `abstract`.
  final List<String> annotations;

  /// Attributes and methods in declaration order.
  final List<ClassMemberAst> members;

  /// CSS classes assigned to this node.
  final List<String> cssClasses;

  /// Inline style properties.
  final Map<String, String> styles;

  /// Optional enclosing namespace.
  final String? namespaceId;

  @override
  List<Object?> get equalityFields => [id, label, annotations, members, cssClasses, styles, namespaceId];
}

/// Closed set of class-compartment member kinds.
enum ClassMemberKind { attribute, method }

/// One class attribute or method.
final class ClassMemberAst with _AstValueEquality {
  /// Creates a class member.
  const ClassMemberAst({required this.text, required this.kind});

  /// Mermaid member text, including visibility and classifier suffixes.
  final String text;

  /// The compartment this member belongs to.
  final ClassMemberKind kind;

  @override
  List<Object?> get equalityFields => [text, kind];
}

/// Endpoint decoration used by a class relationship.
enum ClassRelationMarker { none, aggregation, extension, composition, dependency, lollipop }

/// Stroke pattern used by a class relationship.
enum ClassRelationLine { solid, dotted }

/// One relationship between two classes.
final class ClassRelationAst with _AstValueEquality {
  /// Creates a class relationship.
  const ClassRelationAst({
    required this.from,
    required this.to,
    this.fromCardinality,
    this.toCardinality,
    this.startMarker = ClassRelationMarker.none,
    this.endMarker = ClassRelationMarker.none,
    this.line = ClassRelationLine.solid,
    this.label,
  });

  /// Source class identifier.
  final String from;

  /// Destination class identifier.
  final String to;

  /// Cardinality next to [from].
  final String? fromCardinality;

  /// Cardinality next to [to].
  final String? toCardinality;

  /// Decoration at the source endpoint.
  final ClassRelationMarker startMarker;

  /// Decoration at the destination endpoint.
  final ClassRelationMarker endMarker;

  /// Relationship stroke pattern.
  final ClassRelationLine line;

  /// Optional center label.
  final String? label;

  @override
  List<Object?> get equalityFields => [from, to, fromCardinality, toCardinality, startMarker, endMarker, line, label];
}

/// One explicit class namespace.
final class ClassNamespaceAst with _AstValueEquality {
  /// Creates a namespace.
  const ClassNamespaceAst({required this.id, required this.label, this.classIds = const []});

  /// Stable namespace identifier.
  final String id;

  /// Visible namespace label.
  final String label;

  /// Directly contained class identifiers.
  final List<String> classIds;

  @override
  List<Object?> get equalityFields => [id, label, classIds];
}

/// A free-standing or class-attached note.
final class ClassNoteAst with _AstValueEquality {
  /// Creates a class note.
  const ClassNoteAst({required this.text, this.classId});

  /// Visible note text.
  final String text;

  /// Optional attached class.
  final String? classId;

  @override
  List<Object?> get equalityFields => [text, classId];
}
