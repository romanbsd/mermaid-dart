part of 'ast.dart';

enum CynefinDomain { complex, complicated, clear, chaotic, confusion }

final class CynefinAst extends DiagramAst {
  const CynefinAst({
    this.domains = const [],
    this.transitions = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  final List<CynefinDomainAst> domains;
  final List<CynefinTransitionAst> transitions;

  @override
  List<Object?> get diagramFields => [domains, transitions];
}

final class CynefinDomainAst with _AstValueEquality {
  const CynefinDomainAst({required this.domain, this.items = const []});

  final CynefinDomain domain;
  final List<CynefinItemAst> items;

  @override
  List<Object?> get equalityFields => [domain, items];
}

final class CynefinItemAst with _AstValueEquality {
  const CynefinItemAst({required this.label});

  final String label;

  @override
  List<Object?> get equalityFields => [label];
}

final class CynefinTransitionAst with _AstValueEquality {
  const CynefinTransitionAst({required this.from, required this.to, this.label});

  final CynefinDomain from;
  final CynefinDomain to;
  final String? label;

  @override
  List<Object?> get equalityFields => [from, to, label];
}
