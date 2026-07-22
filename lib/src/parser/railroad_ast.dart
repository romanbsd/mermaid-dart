part of 'ast.dart';

/// Renderer-ready syntax tree shared by all railroad grammar frontends.
final class RailroadAst extends DiagramAst {
  const RailroadAst({this.rules = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  final List<RailroadRuleAst> rules;

  @override
  List<Object?> get diagramFields => [rules];
}

final class RailroadRuleAst with _AstValueEquality {
  const RailroadRuleAst({required this.name, required this.definition});

  final String name;
  final RailroadNodeAst definition;

  @override
  List<Object?> get equalityFields => [name, definition];
}

/// A node understood by the single railroad rendering pipeline.
sealed class RailroadNodeAst with _AstValueEquality {
  const RailroadNodeAst();
}

final class RailroadTerminalAst extends RailroadNodeAst {
  const RailroadTerminalAst(this.value);
  final String value;

  @override
  List<Object?> get equalityFields => [value];
}

final class RailroadNonTerminalAst extends RailroadNodeAst {
  const RailroadNonTerminalAst(this.name);
  final String name;

  @override
  List<Object?> get equalityFields => [name];
}

final class RailroadSequenceAst extends RailroadNodeAst {
  const RailroadSequenceAst(this.elements);
  final List<RailroadNodeAst> elements;

  @override
  List<Object?> get equalityFields => [elements];
}

final class RailroadChoiceAst extends RailroadNodeAst {
  const RailroadChoiceAst(this.alternatives);
  final List<RailroadNodeAst> alternatives;

  @override
  List<Object?> get equalityFields => [alternatives];
}

final class RailroadOptionalAst extends RailroadNodeAst {
  const RailroadOptionalAst(this.element);
  final RailroadNodeAst element;

  @override
  List<Object?> get equalityFields => [element];
}

final class RailroadRepetitionAst extends RailroadNodeAst {
  const RailroadRepetitionAst(this.element, {required this.min, required this.max});

  final RailroadNodeAst element;
  final int min;
  final num max;

  @override
  List<Object?> get equalityFields => [element, min, max];
}

final class RailroadSpecialAst extends RailroadNodeAst {
  const RailroadSpecialAst(this.text);
  final String text;

  @override
  List<Object?> get equalityFields => [text];
}
