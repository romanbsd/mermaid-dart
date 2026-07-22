part of 'ast.dart';

enum EventModelEntityType { readModel, ui, command, event, processor }

enum EventModelDataType { json, javaScriptObject, figma, salt, uri, markdown, html, text }

final class EventModelingAst extends DiagramAst {
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

  final List<EventModelEntityAst> modelEntities;
  final List<EventModelFrameAst> frames;
  final List<EventModelDataEntityAst> dataEntities;
  final List<EventModelNoteAst> notes;
  final List<EventModelScenarioAst> scenarios;

  @override
  List<Object?> get diagramFields => [modelEntities, frames, dataEntities, notes, scenarios];
}

final class EventModelEntityAst with _AstValueEquality {
  const EventModelEntityAst({required this.name});
  final String name;

  @override
  List<Object?> get equalityFields => [name];
}

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

  final String name;
  final EventModelEntityType entityType;
  final String entityIdentifier;
  final List<String> sourceFrames;
  final String? dataReference;
  final EventModelDataType? dataType;
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

final class EventModelTimeFrameAst extends EventModelFrameAst {
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

final class EventModelResetFrameAst extends EventModelFrameAst {
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

final class EventModelDataEntityAst with _AstValueEquality {
  const EventModelDataEntityAst({required this.name, this.dataType, required this.value});

  final String name;
  final EventModelDataType? dataType;
  final String value;

  @override
  List<Object?> get equalityFields => [name, dataType, value];
}

final class EventModelNoteAst with _AstValueEquality {
  const EventModelNoteAst({required this.sourceFrame, this.dataType, required this.value});

  final String sourceFrame;
  final EventModelDataType? dataType;
  final String value;

  @override
  List<Object?> get equalityFields => [sourceFrame, dataType, value];
}

final class EventModelStatementAst with _AstValueEquality {
  const EventModelStatementAst({required this.entityType, required this.entityIdentifier});

  final EventModelEntityType entityType;
  final String entityIdentifier;

  @override
  List<Object?> get equalityFields => [entityType, entityIdentifier];
}

final class EventModelScenarioAst with _AstValueEquality {
  const EventModelScenarioAst({
    required this.sourceFrame,
    required this.given,
    this.when = const [],
    required this.then,
  });

  final String sourceFrame;
  final List<EventModelStatementAst> given;
  final List<EventModelStatementAst> when;
  final List<EventModelStatementAst> then;

  @override
  List<Object?> get equalityFields => [sourceFrame, given, when, then];
}
