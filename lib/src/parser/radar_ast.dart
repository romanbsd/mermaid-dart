part of 'ast.dart';

/// Syntax tree for a `radar` diagram.
final class RadarAst extends DiagramAst {
  const RadarAst({
    this.axes = const [],
    this.curves = const [],
    this.options = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  final List<RadarAxisAst> axes;
  final List<RadarCurveAst> curves;
  final List<RadarOptionAst> options;

  @override
  List<Object?> get diagramFields => [axes, curves, options];
}

final class RadarAxisAst with _AstValueEquality {
  const RadarAxisAst({required this.name, this.label});

  final String name;
  final String? label;

  @override
  List<Object?> get equalityFields => [name, label];
}

final class RadarCurveAst with _AstValueEquality {
  const RadarCurveAst({required this.name, this.label, required this.entries});

  final String name;
  final String? label;
  final List<RadarEntryAst> entries;

  @override
  List<Object?> get equalityFields => [name, label, entries];
}

final class RadarEntryAst with _AstValueEquality {
  const RadarEntryAst({this.axis, required this.value});

  final String? axis;
  final num value;

  @override
  List<Object?> get equalityFields => [axis, value];
}

sealed class RadarOptionAst with _AstValueEquality {
  const RadarOptionAst();
}

final class RadarShowLegendOptionAst extends RadarOptionAst {
  const RadarShowLegendOptionAst(this.value);

  final bool value;

  @override
  List<Object?> get equalityFields => [value];
}

final class RadarTicksOptionAst extends RadarOptionAst {
  const RadarTicksOptionAst(this.value);

  final num value;

  @override
  List<Object?> get equalityFields => [value];
}

final class RadarMaxOptionAst extends RadarOptionAst {
  const RadarMaxOptionAst(this.value);

  final num value;

  @override
  List<Object?> get equalityFields => [value];
}

final class RadarMinOptionAst extends RadarOptionAst {
  const RadarMinOptionAst(this.value);

  final num value;

  @override
  List<Object?> get equalityFields => [value];
}

final class RadarGraticuleOptionAst extends RadarOptionAst {
  const RadarGraticuleOptionAst(this.value);

  final RadarGraticule value;

  @override
  List<Object?> get equalityFields => [value];
}

enum RadarGraticule { circle, polygon }
