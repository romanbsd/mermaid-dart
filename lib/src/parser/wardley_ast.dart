part of 'ast.dart';

/// Defines the supported wardley strategy values.
enum WardleyStrategy {
  /// Selects the build variant.
  build,

  /// Selects the buy variant.
  buy,

  /// Selects the outsource variant.
  outsource,

  /// Selects the market variant.
  market,
}

/// Defines the supported wardley link flow values.
enum WardleyLinkFlow {
  /// Selects the forward variant.
  forward,

  /// Selects the backward variant.
  backward,

  /// Selects the bidirectional variant.
  bidirectional,
}

/// Defines the supported wardley link style values.
enum WardleyLinkStyle {
  /// Selects the solid variant.
  solid,

  /// Selects the dashed variant.
  dashed,
}

/// Typed abstract syntax tree node for wardley syntax.
final class WardleyAst extends DiagramAst {
  /// Creates a typed [WardleyAst].
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

  /// The size.
  final WardleySizeAst? size;

  /// The evolution stages.
  final List<WardleyEvolutionStageAst> evolutionStages;

  /// The anchors.
  final List<WardleyAnchorAst> anchors;

  /// The components.
  final List<WardleyComponentAst> components;

  /// The links.
  final List<WardleyLinkAst> links;

  /// The evolves.
  final List<WardleyEvolveAst> evolves;

  /// The pipelines.
  final List<WardleyPipelineAst> pipelines;

  /// The notes.
  final List<WardleyNoteAst> notes;

  /// The annotations box.
  final WardleyPositionAst? annotationsBox;

  /// The annotations.
  final List<WardleyAnnotationAst> annotations;

  /// The markers.
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

/// Typed abstract syntax tree node for wardley size syntax.
final class WardleySizeAst with _AstValueEquality {
  /// Creates a typed [WardleySizeAst].
  const WardleySizeAst({required this.width, required this.height});

  /// The width.
  final int width;

  /// The height.
  final int height;

  @override
  List<Object?> get equalityFields => [width, height];
}

/// Typed abstract syntax tree node for wardley position syntax.
final class WardleyPositionAst with _AstValueEquality {
  /// Creates a typed [WardleyPositionAst].
  const WardleyPositionAst({required this.x, required this.y});

  /// The x.
  final num x;

  /// The y.
  final num y;

  @override
  List<Object?> get equalityFields => [x, y];
}

/// Typed abstract syntax tree node for wardley label syntax.
final class WardleyLabelAst with _AstValueEquality {
  /// Creates a typed [WardleyLabelAst].
  const WardleyLabelAst({required this.offsetX, required this.offsetY});

  /// The offset x.
  final int offsetX;

  /// The offset y.
  final int offsetY;

  @override
  List<Object?> get equalityFields => [offsetX, offsetY];
}

/// Typed abstract syntax tree node for wardley evolution stage syntax.
final class WardleyEvolutionStageAst with _AstValueEquality {
  /// Creates a typed [WardleyEvolutionStageAst].
  const WardleyEvolutionStageAst({required this.name, this.secondName, this.boundary});

  /// The name.
  final String name;

  /// The second name.
  final String? secondName;

  /// The boundary.
  final num? boundary;

  @override
  List<Object?> get equalityFields => [name, secondName, boundary];
}

/// Typed abstract syntax tree node for wardley anchor syntax.
final class WardleyAnchorAst with _AstValueEquality {
  /// Creates a typed [WardleyAnchorAst].
  const WardleyAnchorAst({required this.name, required this.position});

  /// The name.
  final String name;

  /// The position.
  final WardleyPositionAst position;

  @override
  List<Object?> get equalityFields => [name, position];
}

/// Typed abstract syntax tree node for wardley component syntax.
final class WardleyComponentAst with _AstValueEquality {
  /// Creates a typed [WardleyComponentAst].
  const WardleyComponentAst({
    required this.name,
    required this.position,
    this.label,
    this.inertia = false,
    this.strategy,
  });

  /// The name.
  final String name;

  /// The position.
  final WardleyPositionAst position;

  /// The label.
  final WardleyLabelAst? label;

  /// The inertia.
  final bool inertia;

  /// The strategy.
  final WardleyStrategy? strategy;

  @override
  List<Object?> get equalityFields => [name, position, label, inertia, strategy];
}

/// Typed abstract syntax tree node for wardley link syntax.
final class WardleyLinkAst with _AstValueEquality {
  /// Creates a typed [WardleyLinkAst].
  const WardleyLinkAst({required this.from, required this.to, required this.style, this.flow, this.label});

  /// The from.
  final String from;

  /// The to.
  final String to;

  /// The style.
  final WardleyLinkStyle style;

  /// The flow.
  final WardleyLinkFlow? flow;

  /// The label.
  final String? label;

  @override
  List<Object?> get equalityFields => [from, to, style, flow, label];
}

/// Typed abstract syntax tree node for wardley evolve syntax.
final class WardleyEvolveAst with _AstValueEquality {
  /// Creates a typed [WardleyEvolveAst].
  const WardleyEvolveAst({required this.component, required this.target});

  /// The component.
  final String component;

  /// The target.
  final num target;

  @override
  List<Object?> get equalityFields => [component, target];
}

/// Typed abstract syntax tree node for wardley pipeline syntax.
final class WardleyPipelineAst with _AstValueEquality {
  /// Creates a typed [WardleyPipelineAst].
  const WardleyPipelineAst({required this.parent, this.components = const []});

  /// The parent.
  final String parent;

  /// The components.
  final List<WardleyPipelineComponentAst> components;

  @override
  List<Object?> get equalityFields => [parent, components];
}

/// Typed abstract syntax tree node for wardley pipeline component syntax.
final class WardleyPipelineComponentAst with _AstValueEquality {
  /// Creates a typed [WardleyPipelineComponentAst].
  const WardleyPipelineComponentAst({required this.name, required this.evolution, this.label});

  /// The name.
  final String name;

  /// The evolution.
  final num evolution;

  /// The label.
  final WardleyLabelAst? label;

  @override
  List<Object?> get equalityFields => [name, evolution, label];
}

/// Typed abstract syntax tree node for wardley note syntax.
final class WardleyNoteAst with _AstValueEquality {
  /// Creates a typed [WardleyNoteAst].
  const WardleyNoteAst({required this.text, required this.position});

  /// The text.
  final String text;

  /// The position.
  final WardleyPositionAst position;

  @override
  List<Object?> get equalityFields => [text, position];
}

/// Typed abstract syntax tree node for wardley annotation syntax.
final class WardleyAnnotationAst with _AstValueEquality {
  /// Creates a typed [WardleyAnnotationAst].
  const WardleyAnnotationAst({required this.number, required this.position, required this.text});

  /// The number.
  final int number;

  /// The position.
  final WardleyPositionAst position;

  /// The text.
  final String text;

  @override
  List<Object?> get equalityFields => [number, position, text];
}

/// Typed abstract syntax tree node for wardley marker syntax.
sealed class WardleyMarkerAst with _AstValueEquality {
  const WardleyMarkerAst({required this.name, required this.position});

  /// The name.
  final String name;

  /// The position.
  final WardleyPositionAst position;

  @override
  List<Object?> get equalityFields => [name, position];
}

/// Typed abstract syntax tree node for wardley accelerator syntax.
final class WardleyAcceleratorAst extends WardleyMarkerAst {
  /// Creates a typed [WardleyAcceleratorAst].
  const WardleyAcceleratorAst({required super.name, required super.position});
}

/// Typed abstract syntax tree node for wardley deaccelerator syntax.
final class WardleyDeacceleratorAst extends WardleyMarkerAst {
  /// Creates a typed [WardleyDeacceleratorAst].
  const WardleyDeacceleratorAst({required super.name, required super.position});
}
