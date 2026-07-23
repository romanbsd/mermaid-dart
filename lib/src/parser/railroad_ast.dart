part of 'ast.dart';

/// Renderer-ready syntax tree shared by all railroad grammar frontends.
enum RailroadSyntax {
  /// Selects the classic variant.
  classic(DiagramType.railroad),

  /// Selects the ebnf variant.
  ebnf(DiagramType.railroadEbnf),

  /// Selects the abnf variant.
  abnf(DiagramType.railroadAbnf),

  /// Selects the peg variant.
  peg(DiagramType.railroadPeg);

  const RailroadSyntax(this.diagramType);

  /// The diagram type.
  final DiagramType diagramType;
}

/// Typed abstract syntax tree node for railroad syntax.
final class RailroadAst extends DiagramAst {
  /// Creates a typed [RailroadAst].
  const RailroadAst({
    this.syntax = RailroadSyntax.classic,
    this.rules = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  /// The syntax.
  final RailroadSyntax syntax;

  /// The rules.
  final List<RailroadRuleAst> rules;

  @override
  DiagramType get type => syntax.diagramType;

  @override
  List<Object?> get diagramFields => [syntax, rules];
}

/// Typed abstract syntax tree node for railroad rule syntax.
final class RailroadRuleAst with _AstValueEquality {
  /// Creates a typed [RailroadRuleAst].
  const RailroadRuleAst({required this.name, required this.definition});

  /// The name.
  final String name;

  /// The definition.
  final RailroadNodeAst definition;

  @override
  List<Object?> get equalityFields => [name, definition];
}

/// A node understood by the single railroad rendering pipeline.
sealed class RailroadNodeAst with _AstValueEquality {
  const RailroadNodeAst();
}

/// Typed abstract syntax tree node for railroad terminal syntax.
final class RailroadTerminalAst extends RailroadNodeAst {
  /// Creates a typed [RailroadTerminalAst].
  const RailroadTerminalAst(this.value);

  /// The value.
  final String value;

  @override
  List<Object?> get equalityFields => [value];
}

/// Typed abstract syntax tree node for railroad non terminal syntax.
final class RailroadNonTerminalAst extends RailroadNodeAst {
  /// Creates a typed [RailroadNonTerminalAst].
  const RailroadNonTerminalAst(this.name);

  /// The name.
  final String name;

  @override
  List<Object?> get equalityFields => [name];
}

/// Typed abstract syntax tree node for railroad sequence syntax.
final class RailroadSequenceAst extends RailroadNodeAst {
  /// Creates a typed [RailroadSequenceAst].
  const RailroadSequenceAst(this.elements);

  /// The elements.
  final List<RailroadNodeAst> elements;

  @override
  List<Object?> get equalityFields => [elements];
}

/// Typed abstract syntax tree node for railroad choice syntax.
final class RailroadChoiceAst extends RailroadNodeAst {
  /// Creates a typed [RailroadChoiceAst].
  const RailroadChoiceAst(this.alternatives);

  /// The alternatives.
  final List<RailroadNodeAst> alternatives;

  @override
  List<Object?> get equalityFields => [alternatives];
}

/// Typed abstract syntax tree node for railroad optional syntax.
final class RailroadOptionalAst extends RailroadNodeAst {
  /// Creates a typed [RailroadOptionalAst].
  const RailroadOptionalAst(this.element);

  /// The element.
  final RailroadNodeAst element;

  @override
  List<Object?> get equalityFields => [element];
}

/// Typed abstract syntax tree node for railroad repetition syntax.
final class RailroadRepetitionAst extends RailroadNodeAst {
  /// Creates a typed [RailroadRepetitionAst].
  const RailroadRepetitionAst(this.element, {required this.min, required this.max});

  /// The element.
  final RailroadNodeAst element;

  /// The min.
  final int min;

  /// The max.
  final num max;

  @override
  List<Object?> get equalityFields => [element, min, max];
}

/// Typed abstract syntax tree node for railroad special syntax.
final class RailroadSpecialAst extends RailroadNodeAst {
  /// Creates a typed [RailroadSpecialAst].
  const RailroadSpecialAst(this.text);

  /// The text.
  final String text;

  @override
  List<Object?> get equalityFields => [text];
}
