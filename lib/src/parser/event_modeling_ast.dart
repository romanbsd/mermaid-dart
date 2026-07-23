part of 'ast.dart';

/// Defines the supported event model entity type values.
enum EventModelEntityType {
  /// Selects the read model variant.
  readModel,

  /// Selects the ui variant.
  ui,

  /// Selects the command variant.
  command,

  /// Selects the event variant.
  event,

  /// Selects the processor variant.
  processor,
}

/// Defines the supported event model data type values.
enum EventModelDataType {
  /// Selects the json variant.
  json,

  /// Selects the java script object variant.
  javaScriptObject,

  /// Selects the figma variant.
  figma,

  /// Selects the salt variant.
  salt,

  /// Selects the uri variant.
  uri,

  /// Selects the markdown variant.
  markdown,

  /// Selects the html variant.
  html,

  /// Selects the text variant.
  text,
}

/// Typed abstract syntax tree node for event modeling syntax.
final class EventModelingAst extends DiagramAst {
  /// Creates a typed [EventModelingAst].
  const EventModelingAst({
    this.modelEntities = const [],
    this.frames = const [],
    this.dataEntities = const [],
    this.notes = const [],
    this.scenarios = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.eventModeling;

  /// The model entities.
  final List<EventModelEntityAst> modelEntities;

  /// The frames.
  final List<EventModelFrameAst> frames;

  /// The data entities.
  final List<EventModelDataEntityAst> dataEntities;

  /// The notes.
  final List<EventModelNoteAst> notes;

  /// The scenarios.
  final List<EventModelScenarioAst> scenarios;

  @override
  List<Object?> get diagramFields => [modelEntities, frames, dataEntities, notes, scenarios];
}

/// Typed abstract syntax tree node for event model entity syntax.
final class EventModelEntityAst with _AstValueEquality {
  /// Creates a typed [EventModelEntityAst].
  const EventModelEntityAst({required this.name});

  /// The name.
  final String name;

  @override
  List<Object?> get equalityFields => [name];
}

/// Typed abstract syntax tree node for event model frame syntax.
sealed class EventModelFrameAst with _AstValueEquality {
  const EventModelFrameAst({
    required this.name,
    required this.entityType,
    required this.entityIdentifier,
    this.sourceFrames = const [],
    this.dataReference,
    this.dataType,
    this.dataInlineValue,
  });

  /// The name.
  final String name;

  /// The entity type.
  final EventModelEntityType entityType;

  /// The entity identifier.
  final String entityIdentifier;

  /// The source frames.
  final List<String> sourceFrames;

  /// The data reference.
  final String? dataReference;

  /// The data type.
  final EventModelDataType? dataType;

  /// The data inline value.
  final String? dataInlineValue;

  @override
  List<Object?> get equalityFields => [
    name,
    entityType,
    entityIdentifier,
    sourceFrames,
    dataReference,
    dataType,
    dataInlineValue,
  ];
}

/// Typed abstract syntax tree node for event model time frame syntax.
final class EventModelTimeFrameAst extends EventModelFrameAst {
  /// Creates a typed [EventModelTimeFrameAst].
  const EventModelTimeFrameAst({
    required super.name,
    required super.entityType,
    required super.entityIdentifier,
    super.sourceFrames,
    super.dataReference,
    super.dataType,
    super.dataInlineValue,
  });
}

/// Typed abstract syntax tree node for event model reset frame syntax.
final class EventModelResetFrameAst extends EventModelFrameAst {
  /// Creates a typed [EventModelResetFrameAst].
  const EventModelResetFrameAst({
    required super.name,
    required super.entityType,
    required super.entityIdentifier,
    super.sourceFrames,
    super.dataReference,
    super.dataType,
    super.dataInlineValue,
  });
}

/// Typed abstract syntax tree node for event model data entity syntax.
final class EventModelDataEntityAst with _AstValueEquality {
  /// Creates a typed [EventModelDataEntityAst].
  const EventModelDataEntityAst({required this.name, this.dataType, required this.value});

  /// The name.
  final String name;

  /// The data type.
  final EventModelDataType? dataType;

  /// The value.
  final String value;

  @override
  List<Object?> get equalityFields => [name, dataType, value];
}

/// Typed abstract syntax tree node for event model note syntax.
final class EventModelNoteAst with _AstValueEquality {
  /// Creates a typed [EventModelNoteAst].
  const EventModelNoteAst({required this.sourceFrame, this.dataType, required this.value});

  /// The source frame.
  final String sourceFrame;

  /// The data type.
  final EventModelDataType? dataType;

  /// The value.
  final String value;

  @override
  List<Object?> get equalityFields => [sourceFrame, dataType, value];
}

/// Typed abstract syntax tree node for event model statement syntax.
final class EventModelStatementAst with _AstValueEquality {
  /// Creates a typed [EventModelStatementAst].
  const EventModelStatementAst({required this.entityType, required this.entityIdentifier});

  /// The entity type.
  final EventModelEntityType entityType;

  /// The entity identifier.
  final String entityIdentifier;

  @override
  List<Object?> get equalityFields => [entityType, entityIdentifier];
}

/// Typed abstract syntax tree node for event model scenario syntax.
final class EventModelScenarioAst with _AstValueEquality {
  /// Creates a typed [EventModelScenarioAst].
  const EventModelScenarioAst({
    required this.sourceFrame,
    required this.given,
    this.when = const [],
    required this.then,
  });

  /// The source frame.
  final String sourceFrame;

  /// The given.
  final List<EventModelStatementAst> given;

  /// The when.
  final List<EventModelStatementAst> when;

  /// The then.
  final List<EventModelStatementAst> then;

  @override
  List<Object?> get equalityFields => [sourceFrame, given, when, then];
}
