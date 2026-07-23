part of 'ast.dart';

enum WardleyStrategy { build, buy, outsource, market }

enum WardleyLinkFlow { forward, backward, bidirectional }

enum WardleyLinkStyle { solid, dashed }

final class WardleyAst extends DiagramAst {
  const WardleyAst({
    this.size,
    this.evolutionStages = const [],
    this.anchors = const [],
    this.components = const [],
    this.links = const [],
    this.evolves = const [],
    this.pipelines = const [],
    this.notes = const [],
    this.annotationsBox,
    this.annotations = const [],
    this.markers = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.wardley;

  final WardleySizeAst? size;
  final List<WardleyEvolutionStageAst> evolutionStages;
  final List<WardleyAnchorAst> anchors;
  final List<WardleyComponentAst> components;
  final List<WardleyLinkAst> links;
  final List<WardleyEvolveAst> evolves;
  final List<WardleyPipelineAst> pipelines;
  final List<WardleyNoteAst> notes;
  final WardleyPositionAst? annotationsBox;
  final List<WardleyAnnotationAst> annotations;
  final List<WardleyMarkerAst> markers;

  @override
  List<Object?> get diagramFields => [
    size,
    evolutionStages,
    anchors,
    components,
    links,
    evolves,
    pipelines,
    notes,
    annotationsBox,
    annotations,
    markers,
  ];
}

final class WardleySizeAst with _AstValueEquality {
  const WardleySizeAst({required this.width, required this.height});
  final int width;
  final int height;

  @override
  List<Object?> get equalityFields => [width, height];
}

final class WardleyPositionAst with _AstValueEquality {
  const WardleyPositionAst({required this.x, required this.y});
  final num x;
  final num y;

  @override
  List<Object?> get equalityFields => [x, y];
}

final class WardleyLabelAst with _AstValueEquality {
  const WardleyLabelAst({required this.offsetX, required this.offsetY});
  final int offsetX;
  final int offsetY;

  @override
  List<Object?> get equalityFields => [offsetX, offsetY];
}

final class WardleyEvolutionStageAst with _AstValueEquality {
  const WardleyEvolutionStageAst({required this.name, this.secondName, this.boundary});
  final String name;
  final String? secondName;
  final num? boundary;

  @override
  List<Object?> get equalityFields => [name, secondName, boundary];
}

final class WardleyAnchorAst with _AstValueEquality {
  const WardleyAnchorAst({required this.name, required this.position});
  final String name;
  final WardleyPositionAst position;

  @override
  List<Object?> get equalityFields => [name, position];
}

final class WardleyComponentAst with _AstValueEquality {
  const WardleyComponentAst({
    required this.name,
    required this.position,
    this.label,
    this.inertia = false,
    this.strategy,
  });

  final String name;
  final WardleyPositionAst position;
  final WardleyLabelAst? label;
  final bool inertia;
  final WardleyStrategy? strategy;

  @override
  List<Object?> get equalityFields => [name, position, label, inertia, strategy];
}

final class WardleyLinkAst with _AstValueEquality {
  const WardleyLinkAst({required this.from, required this.to, required this.style, this.flow, this.label});

  final String from;
  final String to;
  final WardleyLinkStyle style;
  final WardleyLinkFlow? flow;
  final String? label;

  @override
  List<Object?> get equalityFields => [from, to, style, flow, label];
}

final class WardleyEvolveAst with _AstValueEquality {
  const WardleyEvolveAst({required this.component, required this.target});
  final String component;
  final num target;

  @override
  List<Object?> get equalityFields => [component, target];
}

final class WardleyPipelineAst with _AstValueEquality {
  const WardleyPipelineAst({required this.parent, this.components = const []});
  final String parent;
  final List<WardleyPipelineComponentAst> components;

  @override
  List<Object?> get equalityFields => [parent, components];
}

final class WardleyPipelineComponentAst with _AstValueEquality {
  const WardleyPipelineComponentAst({required this.name, required this.evolution, this.label});
  final String name;
  final num evolution;
  final WardleyLabelAst? label;

  @override
  List<Object?> get equalityFields => [name, evolution, label];
}

final class WardleyNoteAst with _AstValueEquality {
  const WardleyNoteAst({required this.text, required this.position});
  final String text;
  final WardleyPositionAst position;

  @override
  List<Object?> get equalityFields => [text, position];
}

final class WardleyAnnotationAst with _AstValueEquality {
  const WardleyAnnotationAst({required this.number, required this.position, required this.text});
  final int number;
  final WardleyPositionAst position;
  final String text;

  @override
  List<Object?> get equalityFields => [number, position, text];
}

sealed class WardleyMarkerAst with _AstValueEquality {
  const WardleyMarkerAst({required this.name, required this.position});
  final String name;
  final WardleyPositionAst position;

  @override
  List<Object?> get equalityFields => [name, position];
}

final class WardleyAcceleratorAst extends WardleyMarkerAst {
  const WardleyAcceleratorAst({required super.name, required super.position});
}

final class WardleyDeacceleratorAst extends WardleyMarkerAst {
  const WardleyDeacceleratorAst({required super.name, required super.position});
}
