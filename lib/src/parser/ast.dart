/// Base type for syntax trees produced by Mermaid parsers.
sealed class DiagramAst {
  const DiagramAst();
}

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
    this.title,
    this.accessibilityTitle,
    this.accessibilityDescription,
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
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

mixin _WardleyValueEquality {
  List<Object?> get equalityFields;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is _WardleyValueEquality &&
          _listEquals(equalityFields, other.equalityFields);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(equalityFields));
}

final class WardleySizeAst with _WardleyValueEquality {
  const WardleySizeAst({required this.width, required this.height});
  final int width;
  final int height;

  @override
  List<Object?> get equalityFields => [width, height];
}

final class WardleyPositionAst with _WardleyValueEquality {
  const WardleyPositionAst({required this.x, required this.y});
  final num x;
  final num y;

  @override
  List<Object?> get equalityFields => [x, y];
}

final class WardleyLabelAst with _WardleyValueEquality {
  const WardleyLabelAst({required this.offsetX, required this.offsetY});
  final int offsetX;
  final int offsetY;

  @override
  List<Object?> get equalityFields => [offsetX, offsetY];
}

final class WardleyEvolutionStageAst with _WardleyValueEquality {
  const WardleyEvolutionStageAst({required this.name, this.secondName, this.boundary});
  final String name;
  final String? secondName;
  final num? boundary;

  @override
  List<Object?> get equalityFields => [name, secondName, boundary];
}

final class WardleyAnchorAst with _WardleyValueEquality {
  const WardleyAnchorAst({required this.name, required this.position});
  final String name;
  final WardleyPositionAst position;

  @override
  List<Object?> get equalityFields => [name, position];
}

final class WardleyComponentAst with _WardleyValueEquality {
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

final class WardleyLinkAst with _WardleyValueEquality {
  const WardleyLinkAst({required this.from, required this.to, required this.style, this.flow, this.label});

  final String from;
  final String to;
  final WardleyLinkStyle style;
  final WardleyLinkFlow? flow;
  final String? label;

  @override
  List<Object?> get equalityFields => [from, to, style, flow, label];
}

final class WardleyEvolveAst with _WardleyValueEquality {
  const WardleyEvolveAst({required this.component, required this.target});
  final String component;
  final num target;

  @override
  List<Object?> get equalityFields => [component, target];
}

final class WardleyPipelineAst {
  const WardleyPipelineAst({required this.parent, this.components = const []});
  final String parent;
  final List<WardleyPipelineComponentAst> components;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WardleyPipelineAst && parent == other.parent && _listEquals(components, other.components);

  @override
  int get hashCode => Object.hash(parent, Object.hashAll(components));
}

final class WardleyPipelineComponentAst with _WardleyValueEquality {
  const WardleyPipelineComponentAst({required this.name, required this.evolution, this.label});
  final String name;
  final num evolution;
  final WardleyLabelAst? label;

  @override
  List<Object?> get equalityFields => [name, evolution, label];
}

final class WardleyNoteAst with _WardleyValueEquality {
  const WardleyNoteAst({required this.text, required this.position});
  final String text;
  final WardleyPositionAst position;

  @override
  List<Object?> get equalityFields => [text, position];
}

final class WardleyAnnotationAst with _WardleyValueEquality {
  const WardleyAnnotationAst({required this.number, required this.position, required this.text});
  final int number;
  final WardleyPositionAst position;
  final String text;

  @override
  List<Object?> get equalityFields => [number, position, text];
}

sealed class WardleyMarkerAst with _WardleyValueEquality {
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
  const TreemapAst({this.rows = const [], this.title, this.accessibilityTitle, this.accessibilityDescription});

  final List<TreemapRowAst> rows;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreemapAst &&
          _listEquals(rows, other.rows) &&
          title == other.title &&
          accessibilityTitle == other.accessibilityTitle &&
          accessibilityDescription == other.accessibilityDescription;

  @override
  int get hashCode => Object.hash(Object.hashAll(rows), title, accessibilityTitle, accessibilityDescription);
}

sealed class TreemapRowAst {
  const TreemapRowAst();
}

final class TreemapNodeRowAst extends TreemapRowAst {
  const TreemapNodeRowAst({required this.indent, required this.item});

  final int indent;
  final TreemapItemAst item;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TreemapNodeRowAst && indent == other.indent && item == other.item;

  @override
  int get hashCode => Object.hash(indent, item);
}

final class TreemapClassDefAst extends TreemapRowAst {
  const TreemapClassDefAst({required this.name, this.style});

  final String name;
  final String? style;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TreemapClassDefAst && name == other.name && style == other.style;

  @override
  int get hashCode => Object.hash(name, style);
}

sealed class TreemapItemAst {
  const TreemapItemAst({required this.name, this.classSelector});

  final String name;
  final String? classSelector;
}

final class TreemapSectionAst extends TreemapItemAst {
  const TreemapSectionAst({required super.name, super.classSelector});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreemapSectionAst && name == other.name && classSelector == other.classSelector;

  @override
  int get hashCode => Object.hash(runtimeType, name, classSelector);
}

final class TreemapLeafAst extends TreemapItemAst {
  const TreemapLeafAst({required super.name, required this.value, super.classSelector});

  final num value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreemapLeafAst && name == other.name && value == other.value && classSelector == other.classSelector;

  @override
  int get hashCode => Object.hash(runtimeType, name, value, classSelector);
}

/// Renderer-ready syntax tree shared by all railroad grammar frontends.
final class RailroadAst extends DiagramAst {
  const RailroadAst({this.rules = const [], this.title, this.accessibilityTitle, this.accessibilityDescription});

  final List<RailroadRuleAst> rules;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RailroadAst &&
          _listEquals(rules, other.rules) &&
          title == other.title &&
          accessibilityTitle == other.accessibilityTitle &&
          accessibilityDescription == other.accessibilityDescription;

  @override
  int get hashCode => Object.hash(Object.hashAll(rules), title, accessibilityTitle, accessibilityDescription);
}

final class RailroadRuleAst {
  const RailroadRuleAst({required this.name, required this.definition});

  final String name;
  final RailroadNodeAst definition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RailroadRuleAst && name == other.name && definition == other.definition;

  @override
  int get hashCode => Object.hash(name, definition);
}

/// A node understood by the single railroad rendering pipeline.
sealed class RailroadNodeAst {
  const RailroadNodeAst();
}

final class RailroadTerminalAst extends RailroadNodeAst {
  const RailroadTerminalAst(this.value);
  final String value;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RailroadTerminalAst && value == other.value;

  @override
  int get hashCode => Object.hash(runtimeType, value);
}

final class RailroadNonTerminalAst extends RailroadNodeAst {
  const RailroadNonTerminalAst(this.name);
  final String name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RailroadNonTerminalAst && name == other.name;

  @override
  int get hashCode => Object.hash(runtimeType, name);
}

final class RailroadSequenceAst extends RailroadNodeAst {
  const RailroadSequenceAst(this.elements);
  final List<RailroadNodeAst> elements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RailroadSequenceAst && _listEquals(elements, other.elements);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(elements));
}

final class RailroadChoiceAst extends RailroadNodeAst {
  const RailroadChoiceAst(this.alternatives);
  final List<RailroadNodeAst> alternatives;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RailroadChoiceAst && _listEquals(alternatives, other.alternatives);

  @override
  int get hashCode => Object.hash(runtimeType, Object.hashAll(alternatives));
}

final class RailroadOptionalAst extends RailroadNodeAst {
  const RailroadOptionalAst(this.element);
  final RailroadNodeAst element;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RailroadOptionalAst && element == other.element;

  @override
  int get hashCode => Object.hash(runtimeType, element);
}

final class RailroadRepetitionAst extends RailroadNodeAst {
  const RailroadRepetitionAst(this.element, {required this.min, required this.max});

  final RailroadNodeAst element;
  final int min;
  final num max;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RailroadRepetitionAst && element == other.element && min == other.min && max == other.max;

  @override
  int get hashCode => Object.hash(runtimeType, element, min, max);
}

final class RailroadSpecialAst extends RailroadNodeAst {
  const RailroadSpecialAst(this.text);
  final String text;

  @override
  bool operator ==(Object other) => identical(this, other) || other is RailroadSpecialAst && text == other.text;

  @override
  int get hashCode => Object.hash(runtimeType, text);
}

/// Syntax tree for an `info` diagram.
final class InfoAst extends DiagramAst {
  const InfoAst({this.title, this.accessibilityTitle, this.accessibilityDescription});

  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InfoAst &&
          title == other.title &&
          accessibilityTitle == other.accessibilityTitle &&
          accessibilityDescription == other.accessibilityDescription;

  @override
  int get hashCode => Object.hash(title, accessibilityTitle, accessibilityDescription);

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
    this.title,
    this.accessibilityTitle,
    this.accessibilityDescription,
  });

  final bool showData;
  final List<PieSectionAst> sections;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

/// A labeled numeric section in a [PieAst].
final class PieSectionAst {
  const PieSectionAst({required this.label, required this.value});

  final String label;
  final num value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PieSectionAst && label == other.label && value == other.value;

  @override
  int get hashCode => Object.hash(label, value);

  @override
  String toString() => 'PieSectionAst(label: $label, value: $value)';
}

/// Syntax tree for a `packet` diagram.
final class PacketAst extends DiagramAst {
  const PacketAst({this.blocks = const [], this.title, this.accessibilityTitle, this.accessibilityDescription});

  final List<PacketBlockAst> blocks;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

/// A bit range or relative-width block in a [PacketAst].
final class PacketBlockAst {
  const PacketBlockAst({this.start, this.end, this.bits, required this.label});

  final int? start;
  final int? end;
  final int? bits;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PacketBlockAst && start == other.start && end == other.end && bits == other.bits && label == other.label;

  @override
  int get hashCode => Object.hash(start, end, bits, label);

  @override
  String toString() => 'PacketBlockAst(start: $start, end: $end, bits: $bits, label: $label)';
}

/// Syntax tree for a `radar` diagram.
final class RadarAst extends DiagramAst {
  const RadarAst({
    this.axes = const [],
    this.curves = const [],
    this.options = const [],
    this.title,
    this.accessibilityTitle,
    this.accessibilityDescription,
  });

  final List<RadarAxisAst> axes;
  final List<RadarCurveAst> curves;
  final List<RadarOptionAst> options;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

final class RadarAxisAst {
  const RadarAxisAst({required this.name, this.label});

  final String name;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RadarAxisAst && name == other.name && label == other.label;

  @override
  int get hashCode => Object.hash(name, label);
}

final class RadarCurveAst {
  const RadarCurveAst({required this.name, this.label, required this.entries});

  final String name;
  final String? label;
  final List<RadarEntryAst> entries;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadarCurveAst && name == other.name && label == other.label && _listEquals(entries, other.entries);

  @override
  int get hashCode => Object.hash(name, label, Object.hashAll(entries));
}

final class RadarEntryAst {
  const RadarEntryAst({this.axis, required this.value});

  final String? axis;
  final num value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RadarEntryAst && axis == other.axis && value == other.value;

  @override
  int get hashCode => Object.hash(axis, value);
}

final class RadarOptionAst {
  const RadarOptionAst({required this.name, required this.value});

  final RadarOptionName name;
  final Object value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RadarOptionAst && name == other.name && value == other.value;

  @override
  int get hashCode => Object.hash(name, value);
}

enum RadarOptionName { showLegend, ticks, max, min, graticule }

enum RadarGraticule { circle, polygon }

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

enum CynefinDomain { complex, complicated, clear, chaotic, confusion }

final class CynefinAst extends DiagramAst {
  const CynefinAst({
    this.domains = const [],
    this.transitions = const [],
    this.title,
    this.accessibilityTitle,
    this.accessibilityDescription,
  });

  final List<CynefinDomainAst> domains;
  final List<CynefinTransitionAst> transitions;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

final class CynefinDomainAst {
  const CynefinDomainAst({required this.domain, this.items = const []});

  final CynefinDomain domain;
  final List<CynefinItemAst> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CynefinDomainAst && domain == other.domain && _listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(domain, Object.hashAll(items));
}

final class CynefinItemAst {
  const CynefinItemAst({required this.label});

  final String label;

  @override
  bool operator ==(Object other) => identical(this, other) || other is CynefinItemAst && label == other.label;

  @override
  int get hashCode => label.hashCode;
}

final class CynefinTransitionAst {
  const CynefinTransitionAst({required this.from, required this.to, this.label});

  final CynefinDomain from;
  final CynefinDomain to;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CynefinTransitionAst && from == other.from && to == other.to && label == other.label;

  @override
  int get hashCode => Object.hash(from, to, label);
}

enum GitGraphDirection { leftToRight, topToBottom, bottomToTop }

enum GitGraphCommitType { normal, reverse, highlight }

final class GitGraphAst extends DiagramAst {
  const GitGraphAst({
    this.direction,
    this.statements = const [],
    this.title,
    this.accessibilityTitle,
    this.accessibilityDescription,
  });

  final GitGraphDirection? direction;
  final List<GitGraphStatementAst> statements;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

sealed class GitGraphStatementAst {
  const GitGraphStatementAst();
}

final class GitGraphCommitAst extends GitGraphStatementAst {
  const GitGraphCommitAst({this.id, this.message, this.tags = const [], this.type});

  final String? id;
  final String? message;
  final List<String> tags;
  final GitGraphCommitType? type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitGraphCommitAst &&
          id == other.id &&
          message == other.message &&
          _listEquals(tags, other.tags) &&
          type == other.type;

  @override
  int get hashCode => Object.hash(id, message, Object.hashAll(tags), type);
}

final class GitGraphBranchAst extends GitGraphStatementAst {
  const GitGraphBranchAst({required this.name, this.order});

  final String name;
  final int? order;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GitGraphBranchAst && name == other.name && order == other.order;

  @override
  int get hashCode => Object.hash(name, order);
}

final class GitGraphMergeAst extends GitGraphStatementAst {
  const GitGraphMergeAst({required this.branch, this.id, this.tags = const [], this.type});

  final String branch;
  final String? id;
  final List<String> tags;
  final GitGraphCommitType? type;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitGraphMergeAst &&
          branch == other.branch &&
          id == other.id &&
          _listEquals(tags, other.tags) &&
          type == other.type;

  @override
  int get hashCode => Object.hash(branch, id, Object.hashAll(tags), type);
}

final class GitGraphCheckoutAst extends GitGraphStatementAst {
  const GitGraphCheckoutAst({required this.branch});

  final String branch;

  @override
  bool operator ==(Object other) => identical(this, other) || other is GitGraphCheckoutAst && branch == other.branch;

  @override
  int get hashCode => branch.hashCode;
}

final class GitGraphCherryPickAst extends GitGraphStatementAst {
  const GitGraphCherryPickAst({this.id, this.parent, this.tags = const []});

  final String? id;
  final String? parent;
  final List<String> tags;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitGraphCherryPickAst && id == other.id && parent == other.parent && _listEquals(tags, other.tags);

  @override
  int get hashCode => Object.hash(id, parent, Object.hashAll(tags));
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
    this.title,
    this.accessibilityTitle,
    this.accessibilityDescription,
  });

  final List<ArchitectureGroupAst> groups;
  final List<ArchitectureServiceAst> services;
  final List<ArchitectureJunctionAst> junctions;
  final List<ArchitectureEdgeAst> edges;
  final List<ArchitectureAlignmentAst> alignments;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

final class ArchitectureGroupAst {
  const ArchitectureGroupAst({required this.id, this.icon, this.title, this.parent});

  final String id;
  final String? icon;
  final String? title;
  final String? parent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchitectureGroupAst &&
          id == other.id &&
          icon == other.icon &&
          title == other.title &&
          parent == other.parent;

  @override
  int get hashCode => Object.hash(id, icon, title, parent);
}

final class ArchitectureServiceAst {
  const ArchitectureServiceAst({required this.id, this.icon, this.iconText, this.title, this.parent});

  final String id;
  final String? icon;
  final String? iconText;
  final String? title;
  final String? parent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchitectureServiceAst &&
          id == other.id &&
          icon == other.icon &&
          iconText == other.iconText &&
          title == other.title &&
          parent == other.parent;

  @override
  int get hashCode => Object.hash(id, icon, iconText, title, parent);
}

final class ArchitectureJunctionAst {
  const ArchitectureJunctionAst({required this.id, this.parent});

  final String id;
  final String? parent;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ArchitectureJunctionAst && id == other.id && parent == other.parent;

  @override
  int get hashCode => Object.hash(id, parent);
}

final class ArchitectureEdgeAst {
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchitectureEdgeAst &&
          leftId == other.leftId &&
          leftDirection == other.leftDirection &&
          leftArrow == other.leftArrow &&
          leftGroup == other.leftGroup &&
          rightId == other.rightId &&
          rightDirection == other.rightDirection &&
          rightArrow == other.rightArrow &&
          rightGroup == other.rightGroup &&
          title == other.title;

  @override
  int get hashCode =>
      Object.hash(leftId, leftDirection, leftArrow, leftGroup, rightId, rightDirection, rightArrow, rightGroup, title);
}

final class ArchitectureAlignmentAst {
  const ArchitectureAlignmentAst({required this.direction, required this.members});

  final ArchitectureAlignmentDirection direction;
  final List<String> members;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArchitectureAlignmentAst && direction == other.direction && _listEquals(members, other.members);

  @override
  int get hashCode => Object.hash(direction, Object.hashAll(members));
}

final class TreeViewAst extends DiagramAst {
  const TreeViewAst({this.nodes = const [], this.title, this.accessibilityTitle, this.accessibilityDescription});

  final List<TreeViewNodeAst> nodes;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

final class TreeViewNodeAst {
  const TreeViewNodeAst({required this.name, this.indent, this.cssClass, this.icon, this.description});

  final String name;
  final int? indent;
  final String? cssClass;
  final String? icon;
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreeViewNodeAst &&
          name == other.name &&
          indent == other.indent &&
          cssClass == other.cssClass &&
          icon == other.icon &&
          description == other.description;

  @override
  int get hashCode => Object.hash(name, indent, cssClass, icon, description);
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
    this.title,
    this.accessibilityTitle,
    this.accessibilityDescription,
  });

  final List<EventModelEntityAst> modelEntities;
  final List<EventModelFrameAst> frames;
  final List<EventModelDataEntityAst> dataEntities;
  final List<EventModelNoteAst> notes;
  final List<EventModelScenarioAst> scenarios;
  final String? title;
  final String? accessibilityTitle;
  final String? accessibilityDescription;
}

final class EventModelEntityAst {
  const EventModelEntityAst({required this.name});
  final String name;

  @override
  bool operator ==(Object other) => identical(this, other) || other is EventModelEntityAst && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

sealed class EventModelFrameAst {
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is EventModelFrameAst &&
          name == other.name &&
          entityType == other.entityType &&
          entityIdentifier == other.entityIdentifier &&
          _listEquals(sourceFrames, other.sourceFrames) &&
          dataReference == other.dataReference &&
          dataType == other.dataType &&
          dataInlineValue == other.dataInlineValue;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    entityType,
    entityIdentifier,
    Object.hashAll(sourceFrames),
    dataReference,
    dataType,
    dataInlineValue,
  );
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

final class EventModelDataEntityAst {
  const EventModelDataEntityAst({required this.name, this.dataType, required this.value});

  final String name;
  final EventModelDataType? dataType;
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelDataEntityAst && name == other.name && dataType == other.dataType && value == other.value;

  @override
  int get hashCode => Object.hash(name, dataType, value);
}

final class EventModelNoteAst {
  const EventModelNoteAst({required this.sourceFrame, this.dataType, required this.value});

  final String sourceFrame;
  final EventModelDataType? dataType;
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelNoteAst &&
          sourceFrame == other.sourceFrame &&
          dataType == other.dataType &&
          value == other.value;

  @override
  int get hashCode => Object.hash(sourceFrame, dataType, value);
}

final class EventModelStatementAst {
  const EventModelStatementAst({required this.entityType, required this.entityIdentifier});

  final EventModelEntityType entityType;
  final String entityIdentifier;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelStatementAst && entityType == other.entityType && entityIdentifier == other.entityIdentifier;

  @override
  int get hashCode => Object.hash(entityType, entityIdentifier);
}

final class EventModelScenarioAst {
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
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModelScenarioAst &&
          sourceFrame == other.sourceFrame &&
          _listEquals(given, other.given) &&
          _listEquals(when, other.when) &&
          _listEquals(then, other.then);

  @override
  int get hashCode => Object.hash(sourceFrame, Object.hashAll(given), Object.hashAll(when), Object.hashAll(then));
}
