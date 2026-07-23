part of 'ast.dart';

/// Defines the supported cynefin domain values.
enum CynefinDomain {
  /// Selects the complex variant.
  complex,

  /// Selects the complicated variant.
  complicated,

  /// Selects the clear variant.
  clear,

  /// Selects the chaotic variant.
  chaotic,

  /// Selects the confusion variant.
  confusion,
}

/// Typed abstract syntax tree node for cynefin syntax.
final class CynefinAst extends DiagramAst {
  /// Creates a typed [CynefinAst].
  const CynefinAst({
    this.domains = const [],
    this.transitions = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.cynefin;

  /// The domains.
  final List<CynefinDomainAst> domains;

  /// The transitions.
  final List<CynefinTransitionAst> transitions;

  @override
  List<Object?> get diagramFields => [domains, transitions];
}

/// Typed abstract syntax tree node for cynefin domain syntax.
final class CynefinDomainAst with _AstValueEquality {
  /// Creates a typed [CynefinDomainAst].
  const CynefinDomainAst({required this.domain, this.items = const []});

  /// The domain.
  final CynefinDomain domain;

  /// The items.
  final List<CynefinItemAst> items;

  @override
  List<Object?> get equalityFields => [domain, items];
}

/// Typed abstract syntax tree node for cynefin item syntax.
final class CynefinItemAst with _AstValueEquality {
  /// Creates a typed [CynefinItemAst].
  const CynefinItemAst({required this.label});

  /// The label.
  final String label;

  @override
  List<Object?> get equalityFields => [label];
}

/// Typed abstract syntax tree node for cynefin transition syntax.
final class CynefinTransitionAst with _AstValueEquality {
  /// Creates a typed [CynefinTransitionAst].
  const CynefinTransitionAst({required this.from, required this.to, this.label});

  /// The from.
  final CynefinDomain from;

  /// The to.
  final CynefinDomain to;

  /// The label.
  final String? label;

  @override
  List<Object?> get equalityFields => [from, to, label];
}
