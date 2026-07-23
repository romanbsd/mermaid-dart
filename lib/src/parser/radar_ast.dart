part of 'ast.dart';

/// Syntax tree for a `radar` diagram.
final class RadarAst extends DiagramAst {
  /// Creates a typed [RadarAst].
  const RadarAst({
    this.axes = const [],
    this.curves = const [],
    this.options = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.radar;

  /// The axes.
  final List<RadarAxisAst> axes;

  /// The curves.
  final List<RadarCurveAst> curves;

  /// The options.
  final List<RadarOptionAst> options;

  @override
  List<Object?> get diagramFields => [axes, curves, options];
}

/// Typed abstract syntax tree node for radar axis syntax.
final class RadarAxisAst with _AstValueEquality {
  /// Creates a typed [RadarAxisAst].
  const RadarAxisAst({required this.name, this.label});

  /// The name.
  final String name;

  /// The label.
  final String? label;

  @override
  List<Object?> get equalityFields => [name, label];
}

/// Typed abstract syntax tree node for radar curve syntax.
final class RadarCurveAst with _AstValueEquality {
  /// Creates a typed [RadarCurveAst].
  const RadarCurveAst({required this.name, this.label, required this.entries});

  /// The name.
  final String name;

  /// The label.
  final String? label;

  /// The entries.
  final List<RadarEntryAst> entries;

  @override
  List<Object?> get equalityFields => [name, label, entries];
}

/// Typed abstract syntax tree node for radar entry syntax.
final class RadarEntryAst with _AstValueEquality {
  /// Creates a typed [RadarEntryAst].
  const RadarEntryAst({this.axis, required this.value});

  /// The axis.
  final String? axis;

  /// The value.
  final num value;

  @override
  List<Object?> get equalityFields => [axis, value];
}

/// Typed abstract syntax tree node for radar option syntax.
sealed class RadarOptionAst with _AstValueEquality {
  const RadarOptionAst();
}

/// Typed abstract syntax tree node for radar show legend option syntax.
final class RadarShowLegendOptionAst extends RadarOptionAst {
  /// Creates a typed [RadarShowLegendOptionAst].
  const RadarShowLegendOptionAst(this.value);

  /// The value.
  final bool value;

  @override
  List<Object?> get equalityFields => [value];
}

/// Typed abstract syntax tree node for radar ticks option syntax.
final class RadarTicksOptionAst extends RadarOptionAst {
  /// Creates a typed [RadarTicksOptionAst].
  const RadarTicksOptionAst(this.value);

  /// The value.
  final num value;

  @override
  List<Object?> get equalityFields => [value];
}

/// Typed abstract syntax tree node for radar max option syntax.
final class RadarMaxOptionAst extends RadarOptionAst {
  /// Creates a typed [RadarMaxOptionAst].
  const RadarMaxOptionAst(this.value);

  /// The value.
  final num value;

  @override
  List<Object?> get equalityFields => [value];
}

/// Typed abstract syntax tree node for radar min option syntax.
final class RadarMinOptionAst extends RadarOptionAst {
  /// Creates a typed [RadarMinOptionAst].
  const RadarMinOptionAst(this.value);

  /// The value.
  final num value;

  @override
  List<Object?> get equalityFields => [value];
}

/// Typed abstract syntax tree node for radar graticule option syntax.
final class RadarGraticuleOptionAst extends RadarOptionAst {
  /// Creates a typed [RadarGraticuleOptionAst].
  const RadarGraticuleOptionAst(this.value);

  /// The value.
  final RadarGraticule value;

  @override
  List<Object?> get equalityFields => [value];
}

/// Defines the supported radar graticule values.
enum RadarGraticule {
  /// Selects the circle variant.
  circle,

  /// Selects the polygon variant.
  polygon,
}
