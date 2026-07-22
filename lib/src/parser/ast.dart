/// Base type for syntax trees produced by Mermaid parsers.
sealed class DiagramAst with _AstValueEquality {
  const DiagramAst({this.title, this.accessibilityTitle, this.accessibilityDescription});

  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;

  List<Object?> get diagramFields;

  @override
  List<Object?> get equalityFields => [...diagramFields, title, accessibilityTitle, accessibilityDescription];
}

mixin _AstValueEquality {
  List<Object?> get equalityFields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is _AstValueEquality &&
          _deepListEquals(equalityFields, other.equalityFields);

  @override
  int get hashCode => Object.hash(runtimeType, _deepHash(equalityFields));
}

bool _deepListEquals(List<Object?> left, List<Object?> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    final leftValue = left[index];
    final rightValue = right[index];
    if (leftValue is List && rightValue is List) {
      if (!_deepListEquals(leftValue, rightValue)) return false;
    } else if (leftValue != rightValue) {
      return false;
    }
  }
  return true;
}

int _deepHash(Object? value) => switch (value) {
  List() => Object.hashAll(value.map(_deepHash)),
  _ => value.hashCode,
};

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

/// Syntax tree for a `treemap` diagram.
final class TreemapAst extends DiagramAst {
  const TreemapAst({this.rows = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  final List<TreemapRowAst> rows;

  @override
  List<Object?> get diagramFields => [rows];
}

sealed class TreemapRowAst with _AstValueEquality {
  const TreemapRowAst();
}

final class TreemapNodeRowAst extends TreemapRowAst {
  const TreemapNodeRowAst({required this.indent, required this.item});

  final int indent;
  final TreemapItemAst item;

  @override
  List<Object?> get equalityFields => [indent, item];
}

final class TreemapClassDefAst extends TreemapRowAst {
  const TreemapClassDefAst({required this.name, this.style});

  final String name;
  final String? style;

  @override
  List<Object?> get equalityFields => [name, style];
}

sealed class TreemapItemAst with _AstValueEquality {
  const TreemapItemAst({required this.name, this.classSelector});

  final String name;
  final String? classSelector;
}

final class TreemapSectionAst extends TreemapItemAst {
  const TreemapSectionAst({required super.name, super.classSelector});

  @override
  List<Object?> get equalityFields => [name, classSelector];
}

final class TreemapLeafAst extends TreemapItemAst {
  const TreemapLeafAst({required super.name, required this.value, super.classSelector});

  final num value;

  @override
  List<Object?> get equalityFields => [name, value, classSelector];
}

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

/// Syntax tree for an `info` diagram.
final class InfoAst extends DiagramAst {
  const InfoAst({super.title, super.accessibilityTitle, super.accessibilityDescription});

  @override
  List<Object?> get diagramFields => const [];

  @override
  String toString() =>
      'InfoAst(title: $title, accessibilityTitle: $accessibilityTitle, '
      'accessibilityDescription: $accessibilityDescription)';
}

/// Syntax tree for a `pie` diagram.
final class PieAst extends DiagramAst {
  const PieAst({
    this.showData = false,
    this.sections = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  final bool showData;
  final List<PieSectionAst> sections;

  @override
  List<Object?> get diagramFields => [showData, sections];
}

/// A labeled numeric section in a [PieAst].
final class PieSectionAst with _AstValueEquality {
  const PieSectionAst({required this.label, required this.value});

  final String label;
  final num value;

  @override
  List<Object?> get equalityFields => [label, value];

  @override
  String toString() => 'PieSectionAst(label: $label, value: $value)';
}

/// Syntax tree for a `packet` diagram.
final class PacketAst extends DiagramAst {
  const PacketAst({this.blocks = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  final List<PacketBlockAst> blocks;

  @override
  List<Object?> get diagramFields => [blocks];
}

/// A bit range or relative-width block in a [PacketAst].
final class PacketBlockAst with _AstValueEquality {
  const PacketBlockAst({this.start, this.end, this.bits, required this.label});

  final int? start;
  final int? end;
  final int? bits;
  final String label;

  @override
  List<Object?> get equalityFields => [start, end, bits, label];

  @override
  String toString() => 'PacketBlockAst(start: $start, end: $end, bits: $bits, label: $label)';
}

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

final class RadarOptionAst with _AstValueEquality {
  const RadarOptionAst({required this.name, required this.value});

  final RadarOptionName name;
  final Object value;

  @override
  List<Object?> get equalityFields => [name, value];
}

enum RadarOptionName { showLegend, ticks, max, min, graticule }

enum RadarGraticule { circle, polygon }

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

enum GitGraphDirection { leftToRight, topToBottom, bottomToTop }

enum GitGraphCommitType { normal, reverse, highlight }

final class GitGraphAst extends DiagramAst {
  const GitGraphAst({
    this.direction,
    this.statements = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  final GitGraphDirection? direction;
  final List<GitGraphStatementAst> statements;

  @override
  List<Object?> get diagramFields => [direction, statements];
}

sealed class GitGraphStatementAst with _AstValueEquality {
  const GitGraphStatementAst();
}

final class GitGraphCommitAst extends GitGraphStatementAst {
  const GitGraphCommitAst({this.id, this.message, this.tags = const [], this.type});

  final String? id;
  final String? message;
  final List<String> tags;
  final GitGraphCommitType? type;

  @override
  List<Object?> get equalityFields => [id, message, tags, type];
}

final class GitGraphBranchAst extends GitGraphStatementAst {
  const GitGraphBranchAst({required this.name, this.order});

  final String name;
  final int? order;

  @override
  List<Object?> get equalityFields => [name, order];
}

final class GitGraphMergeAst extends GitGraphStatementAst {
  const GitGraphMergeAst({required this.branch, this.id, this.tags = const [], this.type});

  final String branch;
  final String? id;
  final List<String> tags;
  final GitGraphCommitType? type;

  @override
  List<Object?> get equalityFields => [branch, id, tags, type];
}

final class GitGraphCheckoutAst extends GitGraphStatementAst {
  const GitGraphCheckoutAst({required this.branch});

  final String branch;

  @override
  List<Object?> get equalityFields => [branch];
}

final class GitGraphCherryPickAst extends GitGraphStatementAst {
  const GitGraphCherryPickAst({this.id, this.parent, this.tags = const []});

  final String? id;
  final String? parent;
  final List<String> tags;

  @override
  List<Object?> get equalityFields => [id, parent, tags];
}

enum ArchitectureDirection { left, right, top, bottom }

enum ArchitectureAlignmentDirection { row, column }

final class ArchitectureAst extends DiagramAst {
  const ArchitectureAst({
    this.groups = const [],
    this.services = const [],
    this.junctions = const [],
    this.edges = const [],
    this.alignments = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  final List<ArchitectureGroupAst> groups;
  final List<ArchitectureServiceAst> services;
  final List<ArchitectureJunctionAst> junctions;
  final List<ArchitectureEdgeAst> edges;
  final List<ArchitectureAlignmentAst> alignments;

  @override
  List<Object?> get diagramFields => [groups, services, junctions, edges, alignments];
}

final class ArchitectureGroupAst with _AstValueEquality {
  const ArchitectureGroupAst({required this.id, this.icon, this.title, this.parent});

  final String id;
  final String? icon;
  final String? title;
  final String? parent;

  @override
  List<Object?> get equalityFields => [id, icon, title, parent];
}

final class ArchitectureServiceAst with _AstValueEquality {
  const ArchitectureServiceAst({required this.id, this.icon, this.iconText, this.title, this.parent});

  final String id;
  final String? icon;
  final String? iconText;
  final String? title;
  final String? parent;

  @override
  List<Object?> get equalityFields => [id, icon, iconText, title, parent];
}

final class ArchitectureJunctionAst with _AstValueEquality {
  const ArchitectureJunctionAst({required this.id, this.parent});

  final String id;
  final String? parent;

  @override
  List<Object?> get equalityFields => [id, parent];
}

final class ArchitectureEdgeAst with _AstValueEquality {
  const ArchitectureEdgeAst({
    required this.leftId,
    required this.leftDirection,
    this.leftArrow = false,
    this.leftGroup = false,
    required this.rightId,
    required this.rightDirection,
    this.rightArrow = false,
    this.rightGroup = false,
    this.title,
  });

  final String leftId;
  final ArchitectureDirection leftDirection;
  final bool leftArrow;
  final bool leftGroup;
  final String rightId;
  final ArchitectureDirection rightDirection;
  final bool rightArrow;
  final bool rightGroup;
  final String? title;

  @override
  List<Object?> get equalityFields => [
    leftId,
    leftDirection,
    leftArrow,
    leftGroup,
    rightId,
    rightDirection,
    rightArrow,
    rightGroup,
    title,
  ];
}

final class ArchitectureAlignmentAst with _AstValueEquality {
  const ArchitectureAlignmentAst({required this.direction, required this.members});

  final ArchitectureAlignmentDirection direction;
  final List<String> members;

  @override
  List<Object?> get equalityFields => [direction, members];
}

final class TreeViewAst extends DiagramAst {
  const TreeViewAst({this.nodes = const [], super.title, super.accessibilityTitle, super.accessibilityDescription});

  final List<TreeViewNodeAst> nodes;

  @override
  List<Object?> get diagramFields => [nodes];
}

final class TreeViewNodeAst with _AstValueEquality {
  const TreeViewNodeAst({required this.name, this.indent, this.cssClass, this.icon, this.description});

  final String name;
  final int? indent;
  final String? cssClass;
  final String? icon;
  final String? description;

  @override
  List<Object?> get equalityFields => [name, indent, cssClass, icon, description];
}

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
