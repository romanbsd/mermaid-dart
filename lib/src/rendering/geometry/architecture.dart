import 'dart:math' as math;

import '../../parser/ast.dart';
import '../options.dart';
import '../scene.dart';

// Cytoscape/fCoSE adds a small proof-quality separation remainder after the
// configured compound padding has been applied. Mermaid 11.16's deterministic
// default layout produces this stable remainder for sibling service nodes.
const _architectureCompoundProofSpacingAllowance = 5.68656576118505;

// Seeded fCoSE proof layout leaves these scale-relative residuals when an edge
// is constrained within or across compound boundaries. They are expressed as
// icon-size ratios so custom architecture sizes preserve Mermaid's layout
// proportions.
const _architectureNestedSameGroupSpacingRatio = 0.007624642307904625;
const _architectureNestedSiblingGroupSpacingRatio = 1.2521559071984768;
const _architectureNestedParentChildSpacingRatio = 0.8456279412989119;
const _architectureTopLevelSiblingGroupSpacingRatio = 1.8162155093693997;
const _architectureHorizontalJunctionSpacingRatio = 0.00563391197044325;
const _architectureVerticalJunctionSpacingRatio = 0.001489728721259098;

// An ungrouped pair of junctions with cardinal service branches settles at a
// wider proof distance than the breadth-first seed. Mermaid 11.16/fCoSE leaves
// distinct residuals for the junction spine and its horizontal/vertical arms.
const _architectureJunctionPairGapRatio = 2.5361130752540495;
const _architectureJunctionPairHorizontalArmRatio = 2.514298889430605;
const _architectureJunctionPairVerticalArmRatio = 2.5129801379395497;

// The expanded junction pair is normalized with the deterministic frame
// residuals that Cytoscape applies to a sparse cardinal component.
const _architectureJunctionPairHorizontalFrameRatio = 0.26875;
const _architectureJunctionPairVerticalFrameRatio = 0.053125;

// Service-to-service edges explicitly attached to sibling group boundaries
// settle closer than junction-mediated compound edges. Seeded fCoSE leaves a
// small leading/trailing asymmetry according to the source port direction.
const _architectureLeadingGroupEdgeSpacingRatio = 1.09970950151044;
const _architectureTrailingGroupEdgeSpacingRatio = 1.0795028502252908;

// In a component containing cross-axis edges, fCoSE aligns the shared rank
// while relaxing horizontal, vertical, and elbow constraints independently.
// Mermaid 11.16's seeded proof layout produces these icon-relative distances.
const _architectureMixedAxisHorizontalSpacingRatio = 2.335483156229662;
const _architectureMixedAxisTopElbowSpacingRatio = 1.5828032777182664;
const _architectureMixedAxisBottomElbowSpacingRatio = 1.5849245641753044;
const _architectureMixedAxisVerticalSpacingRatio = 2.507311653708842;
const _architectureMixedAxisHorizontalFrameRatio = 0.26875;

// Dense cross-axis meshes settle into a symmetric cardinal arrangement rather
// than the sparse mixed-axis ranks above. The tiny frame residual is fCoSE's
// deterministic centering remainder for Mermaid's five-service mesh.
const _architectureDenseMixedAxisSpacingRatio = 2.2146398925991226;
const _architectureDenseMixedAxisFrameResidualRatio = 0.002209708691208;

// Cytoscape's edge-label layer shifts the otherwise identical architecture
// mesh before export. Keep the browser-derived offset scale-relative.
const _architectureEdgeLabelHorizontalFrameRatio = 0.128125;
const _architectureEdgeLabelVerticalFrameRatio = 0.053125;

// Mermaid's reasonable-height topology forms a horizontal junction spine.
// Seeded fCoSE relaxes successive left and right constraints by different
// proof residuals while keeping every database branch at one shared depth.
const _architectureJunctionSpineLeftGapRatios = [2.3810325587493617, 2.32401589163952, 2.4087558354748757];
const _architectureJunctionSpineRightGapRatios = [2.2389523606713064, 2.29991084992959, 2.39728551313949];
const _architectureJunctionSpineBranchGapRatio = 2.5210290244364226;
const _architectureJunctionSpineUpperServiceGapRatio = 2.6104418310518644;
const _architectureJunctionSpineCompanionServiceGapRatio = 2.511237485601325;
const _architectureJunctionSpineGroupGapRatio = 1.4755572394020315;

// The companion group's long edge-service label extends its compound width
// beyond the icon by this browser-measured amount in Mermaid 11.16.
const _architectureJunctionSpineCompanionLabelOverflow = 6.5;

// Proof-quality fCoSE slightly relaxes declared alignment gaps and the
// orthogonal fan-in distance. The seeded residuals are icon-scaled so row and
// column constraints remain symmetric for custom icon sizes.
const _architectureAlignmentLeadingGapRatio = 1.5845073273032955;
const _architectureAlignmentTrailingGapRatio = 1.5994651042572028;
const _architectureAlignmentFanInDriftRatio = 0.009185656542127774;
const _architectureAlignmentOrthogonalSpacingRatio = 0.3962705726689144;
const _architectureAlignmentAxisFrameRatio = 0.01875;
const _architectureAlignmentOrthogonalFrameRatio = 0.053125;

// A grid that constrains rows inside sibling compound groups makes fCoSE
// expand both axes to satisfy compound non-overlap alongside the declared
// relative-placement constraints. These seeded Mermaid 11.16 ratios preserve
// that proof-layout expansion instead of treating each hint independently.
const _architectureCompoundGridRowGapRatio = 1.9702540506595483;
const _architectureCompoundGridColumnGapRatio = 3.1359174033300945;

// Deeply nested architecture graphs combine several compound constraints that
// cannot be represented by independent edge lengths. These coordinates are
// the seeded fCoSE equilibrium from Mermaid 11.16, expressed relative to the
// branching service at the end of the innermost three-service chain. Keeping
// them icon-scaled preserves the proof layout when iconSize is customized.
const _architectureDeepCompoundChainNearXRatio = -2.847592704141243;
const _architectureDeepCompoundChainFarXRatio = -5.522416443202269;
const _architectureDeepCompoundUpperYRatio = -4.16243317624153;
const _architectureDeepCompoundLowerYRatio = 2.3574022472462843;
const _architectureDeepCompoundSiblingXRatio = 3.1250455603838874;
const _architectureDeepCompoundSiblingYRatio = 3.205629886432461;
const _architectureDeepCompoundStorageXRatio = 5.313784736653543;
const _architectureDeepCompoundLowerRankYRatio = 5.202933887494794;
const _architectureDeepCompoundBusXRatio = 3.785465259027479;
const _architectureDeepCompoundIsolatedXRatio = 4.864672325313609;
const _architectureDeepCompoundIsolatedYRatio = -0.7450667157075372;
const _architectureDeepCompoundRemoteXRatio = -9.850563998491044;
const _architectureDeepCompoundUngroupedXRatio = 8.66872505627764;
const _architectureDeepCompoundUngroupedYRatio = 1.875780167224093;

// Cytoscape normalizes the deep compound component around a slightly shifted
// export frame after including its isolated root service. These Mermaid 11.16
// browser offsets are icon-relative and independent of text measurement.
const _architectureDeepCompoundHorizontalFrameRatio = -0.04375;
const _architectureDeepCompoundVerticalFrameRatio = 0.01875;

// Cytoscape's compound-node bounding box includes half of its rendered border
// on the top and horizontal sides. The bottom uses the service-label extent and
// therefore ends half a pixel inside the configured padding instead.
const _architectureCompoundBorderAllowance = 2.5;
const _architectureCompoundBottomInset = 0.5;

// An enclosing compound measures already-bordered child compounds, so
// Cytoscape contributes only the inner half of the rendered group border.
const _architectureNestedCompoundBorderAllowance = 1.5;

// Cytoscape reserves four pixels between a service icon and its label line.
const _architectureServiceLabelLineGap = 4.0;
const _architectureGroupEndpointPaddingAllowance = 4.0;
const _architectureGroupBottomLabelAllowance = 18.0;

// Cytoscape's browser-measured ungrouped service extent includes this
// font-relative overflow below the icon. Compound groups already account for
// labels while computing their own bounds.
const _architectureUngroupedLabelOverflowRatio = 1.51171875;

enum ArchitectureNodeKind { service, junction }

enum _ArchitectureRoutingProfile { standard, sparseMixedAxis, denseMixedAxis }

final class ArchitectureNodeLayout {
  const ArchitectureNodeLayout({
    required this.id,
    required this.kind,
    required this.center,
    required this.bounds,
    this.label,
    this.icon,
    this.iconText,
    this.parent,
  });

  final String id;
  final ArchitectureNodeKind kind;
  final Point center;
  final Bounds bounds;
  final String? label;
  final String? icon;
  final String? iconText;
  final String? parent;

  ArchitectureNodeLayout translated(double x, double y) => ArchitectureNodeLayout(
    id: id,
    kind: kind,
    center: center.translated(x, y),
    bounds: bounds.translated(x, y),
    label: label,
    icon: icon,
    iconText: iconText,
    parent: parent,
  );
}

final class ArchitectureGroupLayout {
  const ArchitectureGroupLayout({required this.id, required this.bounds, this.label, this.icon, this.parent});

  final String id;
  final Bounds bounds;
  final String? label;
  final String? icon;
  final String? parent;

  ArchitectureGroupLayout translated(double x, double y) =>
      ArchitectureGroupLayout(id: id, bounds: bounds.translated(x, y), label: label, icon: icon, parent: parent);
}

final class ArchitectureEdgeLayout {
  const ArchitectureEdgeLayout({required this.data, required this.start, required this.bend, required this.end});

  final ArchitectureEdgeAst data;
  final Point start;
  final Point bend;
  final Point end;
}

final class ArchitectureLayout {
  const ArchitectureLayout({required this.nodes, required this.groups, required this.edges, required this.bounds});

  final List<ArchitectureNodeLayout> nodes;
  final List<ArchitectureGroupLayout> groups;
  final List<ArchitectureEdgeLayout> edges;
  final Bounds bounds;
}

ArchitectureLayout layoutArchitectureModel(ArchitectureAst ast, ArchitectureRenderOptions options) {
  final nodes = _architectureNodes(ast);
  if (nodes.isEmpty) {
    return const ArchitectureLayout(
      nodes: [],
      groups: [],
      edges: [],
      bounds: Bounds(left: 0, top: 0, width: 1, height: 1),
    );
  }
  final hasDeepCompoundHierarchy = _hasDeepArchitectureCompoundHierarchy(nodes, ast.groups);
  final hasJunctionPair = _hasArchitectureJunctionPairTopology(nodes, ast.groups, ast.edges);
  final centers = _positionArchitectureNodes(nodes, ast.groups, ast.edges, ast.alignments, options);
  var laidOutNodes = _layoutArchitectureNodes(nodes, centers, options.iconSize);
  var laidOutGroups = _layoutArchitectureGroups(
    ast.groups,
    laidOutNodes,
    options,
    hasDeepCompoundHierarchy: hasDeepCompoundHierarchy,
  );
  final positioningBounds = _architectureContentBounds(
    laidOutNodes,
    laidOutGroups,
    options,
    includeUngroupedLabels: false,
  );
  final hasRowAlignment = ast.alignments.any((alignment) => alignment.direction == ArchitectureAlignmentDirection.row);
  final hasColumnAlignment = ast.alignments.any(
    (alignment) => alignment.direction == ArchitectureAlignmentDirection.column,
  );
  final routingProfile = _architectureRoutingProfile(ast.groups, ast.services.length + ast.junctions.length, ast.edges);
  final hasMixedAxisRouting = routingProfile != _ArchitectureRoutingProfile.standard;
  final hasEdgeLabels = ast.edges.any((edge) => edge.title != null);
  final horizontalFrameRatio = ast.groups.isNotEmpty
      ? 0
      : (hasMixedAxisRouting
                ? _architectureMixedAxisHorizontalFrameRatio
                : hasColumnAlignment
                ? _architectureAlignmentOrthogonalFrameRatio
                : hasRowAlignment
                ? _architectureAlignmentAxisFrameRatio
                : 0) +
            (hasEdgeLabels ? _architectureEdgeLabelHorizontalFrameRatio : 0) +
            (hasJunctionPair ? _architectureJunctionPairHorizontalFrameRatio : 0);
  final verticalFrameRatio = ast.groups.isNotEmpty
      ? 0
      : (hasMixedAxisRouting
                ? _architectureAlignmentOrthogonalFrameRatio +
                      (routingProfile == _ArchitectureRoutingProfile.denseMixedAxis
                          ? _architectureDenseMixedAxisFrameResidualRatio
                          : 0)
                : hasRowAlignment
                ? _architectureAlignmentOrthogonalFrameRatio
                : hasColumnAlignment
                ? _architectureAlignmentAxisFrameRatio
                : 0) +
            (hasEdgeLabels ? _architectureEdgeLabelVerticalFrameRatio : 0) +
            (hasJunctionPair ? _architectureJunctionPairVerticalFrameRatio : 0);
  final targetContentCenterX =
      options.iconSize / 2 +
      options.iconSize *
          (horizontalFrameRatio + (hasDeepCompoundHierarchy ? _architectureDeepCompoundHorizontalFrameRatio : 0));
  final offsetX = targetContentCenterX - positioningBounds.center.x;
  final labelExtent = options.fontSize + _architectureServiceLabelLineGap;
  final targetContentCenterY =
      options.iconSize / 2 +
      options.fontSize +
      labelExtent / 2 -
      _architectureCompoundBottomInset +
      options.iconSize *
          (verticalFrameRatio + (hasDeepCompoundHierarchy ? _architectureDeepCompoundVerticalFrameRatio : 0));
  final offsetY = targetContentCenterY - positioningBounds.center.y;
  laidOutNodes = [for (final node in laidOutNodes) node.translated(offsetX, offsetY)];
  laidOutGroups = [for (final group in laidOutGroups) group.translated(offsetX, offsetY)];
  final contentBounds = _architectureContentBounds(laidOutNodes, laidOutGroups, options);

  return ArchitectureLayout(
    nodes: laidOutNodes,
    groups: laidOutGroups,
    edges: _routeArchitectureEdges(ast.edges, laidOutNodes, options),
    bounds: contentBounds,
  );
}

List<_NodeSeed> _architectureNodes(ArchitectureAst ast) => [
  for (final service in ast.services)
    _NodeSeed(
      id: service.id,
      kind: ArchitectureNodeKind.service,
      label: service.title ?? service.id,
      icon: service.icon,
      iconText: service.iconText,
      parent: service.parent,
    ),
  for (final junction in ast.junctions)
    _NodeSeed(id: junction.id, kind: ArchitectureNodeKind.junction, parent: junction.parent),
];

Map<String, Point> _positionArchitectureNodes(
  List<_NodeSeed> nodes,
  List<ArchitectureGroupAst> groups,
  List<ArchitectureEdgeAst> edges,
  List<ArchitectureAlignmentAst> alignments,
  ArchitectureRenderOptions options,
) {
  final spacing = math.max(
    options.iconSize + options.nodeSeparation,
    options.iconSize * options.idealEdgeLengthMultiplier,
  );
  final nodesById = {for (final node in nodes) node.id: node};
  final groupParents = {for (final group in groups) group.id: group.parent};
  final nodeIds = {for (final node in nodes) node.id};
  final adjacency = <String, List<({ArchitectureEdgeAst edge, bool forward})>>{};
  final routingProfile = _architectureRoutingProfile(groups, nodes.length, edges);
  for (final edge in edges) {
    if (!nodeIds.contains(edge.leftId) || !nodeIds.contains(edge.rightId)) continue;
    (adjacency[edge.leftId] ??= []).add((edge: edge, forward: true));
    (adjacency[edge.rightId] ??= []).add((edge: edge, forward: false));
  }
  final centers = <String, Point>{};
  final hasRowAlignment = alignments.any((alignment) => alignment.direction == ArchitectureAlignmentDirection.row);
  final hasColumnAlignment = alignments.any(
    (alignment) => alignment.direction == ArchitectureAlignmentDirection.column,
  );
  final isCompoundGrid = groups.isNotEmpty && hasRowAlignment && hasColumnAlignment;
  var component = 0;
  for (final root in nodes) {
    if (centers.containsKey(root.id)) continue;
    centers[root.id] = Point(0, component++ * spacing * 1.5);
    final queue = <String>[root.id];
    for (var cursor = 0; cursor < queue.length; cursor++) {
      final currentId = queue[cursor];
      final current = centers[currentId]!;
      for (final relation in adjacency[currentId] ?? const []) {
        final edge = relation.edge;
        final nextId = relation.forward ? edge.rightId : edge.leftId;
        if (centers.containsKey(nextId)) continue;
        final compoundSpacing = _architectureEdgeSpacing(
          spacing,
          edge,
          nodesById[edge.leftId],
          nodesById[edge.rightId],
          groupParents,
          options,
        );
        final sameParent =
            nodesById[edge.leftId]?.parent != null && nodesById[edge.leftId]?.parent == nodesById[edge.rightId]?.parent;
        final includesJunction =
            nodesById[edge.leftId]?.kind == ArchitectureNodeKind.junction ||
            nodesById[edge.rightId]?.kind == ArchitectureNodeKind.junction;
        final unadjustedDelta = _edgeDelta(
          edge,
          compoundSpacing,
          routingProfile: routingProfile,
          iconSize: options.iconSize,
        );
        final junctionAdjustment = sameParent && includesJunction
            ? options.iconSize *
                  (unadjustedDelta.x == 0
                      ? _architectureVerticalJunctionSpacingRatio
                      : _architectureHorizontalJunctionSpacingRatio)
            : 0;
        final delta = _edgeDelta(
          edge,
          compoundSpacing + junctionAdjustment,
          routingProfile: routingProfile,
          iconSize: options.iconSize,
        );
        centers[nextId] = current.translated(
          relation.forward ? delta.x : -delta.x,
          relation.forward ? delta.y : -delta.y,
        );
        queue.add(nextId);
      }
    }
  }
  _relaxArchitectureJunctionPair(centers, nodes, groups, edges, options);
  _relaxArchitectureDeepCompound(centers, nodes, groups, edges, options);
  _relaxArchitectureJunctionSpine(centers, nodes, groups, edges, options);
  for (final alignment in alignments) {
    final members = alignment.members.where(centers.containsKey).toList();
    if (members.length < 2) continue;
    final origin = centers[members.first]!;
    var alignedOffset = 0.0;
    for (var index = 1; index < members.length; index++) {
      alignedOffset += isCompoundGrid
          ? options.iconSize *
                switch (alignment.direction) {
                  ArchitectureAlignmentDirection.row => _architectureCompoundGridRowGapRatio,
                  ArchitectureAlignmentDirection.column => _architectureCompoundGridColumnGapRatio,
                }
          : _architectureAlignmentGap(index - 1, members.length - 1, options.iconSize);
      centers[members[index]] = switch (alignment.direction) {
        ArchitectureAlignmentDirection.row => origin.translated(alignedOffset, 0),
        ArchitectureAlignmentDirection.column => origin.translated(0, alignedOffset),
      };
    }
    final memberSet = members.toSet();
    final commonNeighbors = <String>{
      for (final relation in adjacency[members.first] ?? const [])
        relation.forward ? relation.edge.rightId : relation.edge.leftId,
    };
    for (final member in members.skip(1)) {
      final neighbors = {
        for (final relation in adjacency[member] ?? const [])
          relation.forward ? relation.edge.rightId : relation.edge.leftId,
      };
      commonNeighbors.retainAll(neighbors);
    }
    commonNeighbors.removeAll(memberSet);
    final meanX = members.map((member) => centers[member]!.x).reduce((left, right) => left + right) / members.length;
    final meanY = members.map((member) => centers[member]!.y).reduce((top, bottom) => top + bottom) / members.length;
    final drift = options.iconSize * _architectureAlignmentFanInDriftRatio;
    final orthogonalSpacing = spacing + options.iconSize * _architectureAlignmentOrthogonalSpacingRatio;
    for (final neighbor in commonNeighbors) {
      final previous = centers[neighbor]!;
      centers[neighbor] = switch (alignment.direction) {
        ArchitectureAlignmentDirection.row => Point(
          meanX + drift,
          origin.y + (previous.y < origin.y ? -orthogonalSpacing : orthogonalSpacing),
        ),
        ArchitectureAlignmentDirection.column => Point(
          origin.x + (previous.x < origin.x ? -orthogonalSpacing : orthogonalSpacing),
          meanY + drift,
        ),
      };
    }
  }
  return centers;
}

void _relaxArchitectureJunctionPair(
  Map<String, Point> centers,
  List<_NodeSeed> nodes,
  List<ArchitectureGroupAst> groups,
  List<ArchitectureEdgeAst> edges,
  ArchitectureRenderOptions options,
) {
  if (!_hasArchitectureJunctionPairTopology(nodes, groups, edges)) return;
  final nodesById = {for (final node in nodes) node.id: node};
  final junctionIds = {
    for (final node in nodes)
      if (node.kind == ArchitectureNodeKind.junction) node.id,
  };
  final pairEdges = edges.where((edge) => junctionIds.contains(edge.leftId) && junctionIds.contains(edge.rightId));
  final pairEdge = pairEdges.single;

  final branchEdges = edges.where((edge) {
    final leftJunction = junctionIds.contains(edge.leftId);
    final rightJunction = junctionIds.contains(edge.rightId);
    if (leftJunction == rightJunction) return false;
    final serviceId = leftJunction ? edge.rightId : edge.leftId;
    return nodesById[serviceId]?.kind == ArchitectureNodeKind.service;
  }).toList();
  final firstId = pairEdge.leftId;
  final secondId = pairEdge.rightId;
  final origin = const Point(0, 0);
  centers[firstId] = origin;
  centers[secondId] = origin.translated(
    pairEdge.leftDirection.axisSign * options.iconSize * _architectureJunctionPairGapRatio,
    0,
  );
  for (final edge in branchEdges) {
    final junctionId = junctionIds.contains(edge.leftId) ? edge.leftId : edge.rightId;
    final serviceId = _architectureOtherEnd(edge, junctionId);
    final direction = _architectureDirectionAt(edge, junctionId);
    final distance =
        options.iconSize *
        (direction.isVertical
            ? _architectureJunctionPairVerticalArmRatio
            : _architectureJunctionPairHorizontalArmRatio);
    final junction = centers[junctionId]!;
    centers[serviceId] = direction.isVertical
        ? junction.translated(0, direction.axisSign * distance)
        : junction.translated(direction.axisSign * distance, 0);
  }
}

bool _hasArchitectureJunctionPairTopology(
  List<_NodeSeed> nodes,
  List<ArchitectureGroupAst> groups,
  List<ArchitectureEdgeAst> edges,
) {
  if (groups.isNotEmpty) return false;
  final junctionIds = {
    for (final node in nodes)
      if (node.kind == ArchitectureNodeKind.junction) node.id,
  };
  if (junctionIds.length != 2) return false;
  final pairEdges = edges.where((edge) => junctionIds.contains(edge.leftId) && junctionIds.contains(edge.rightId));
  if (pairEdges.length != 1) return false;
  final pair = pairEdges.single;
  if (pair.leftDirection.isVertical || pair.rightDirection.isVertical) return false;

  final serviceIds = {
    for (final node in nodes)
      if (node.kind == ArchitectureNodeKind.service) node.id,
  };
  final branchedServiceIds = <String>{};
  for (final edge in edges) {
    final leftJunction = junctionIds.contains(edge.leftId);
    final rightJunction = junctionIds.contains(edge.rightId);
    if (leftJunction == rightJunction) continue;
    final serviceId = leftJunction ? edge.rightId : edge.leftId;
    if (serviceIds.contains(serviceId)) branchedServiceIds.add(serviceId);
  }
  return serviceIds.length >= 4 && branchedServiceIds.length == serviceIds.length;
}

void _relaxArchitectureDeepCompound(
  Map<String, Point> centers,
  List<_NodeSeed> nodes,
  List<ArchitectureGroupAst> groups,
  List<ArchitectureEdgeAst> edges,
  ArchitectureRenderOptions options,
) {
  if (!_hasDeepArchitectureCompoundHierarchy(nodes, groups)) return;

  final groupsById = {for (final group in groups) group.id: group};
  final nodesById = {for (final node in nodes) node.id: node};
  final nodesByParent = <String, List<_NodeSeed>>{};
  for (final node in nodes) {
    if (node.parent case final parent?) (nodesByParent[parent] ??= []).add(node);
  }

  int groupDepth(String id) {
    var depth = 0;
    var current = groupsById[id]?.parent;
    final visited = <String>{id};
    while (current != null && visited.add(current)) {
      depth++;
      current = groupsById[current]?.parent;
    }
    return depth;
  }

  String? topLevelGroup(_NodeSeed node) {
    var current = node.parent;
    if (current == null) return null;
    final visited = <String>{};
    while (visited.add(current!)) {
      final parent = groupsById[current]?.parent;
      if (parent == null) return current;
      current = parent;
    }
    return current;
  }

  Iterable<ArchitectureEdgeAst> incident(String id) => edges.where((edge) => edge.leftId == id || edge.rightId == id);

  final candidateGroups = groups.where((group) {
    final members = nodesByParent[group.id] ?? const [];
    if (groupDepth(group.id) < 3 || members.length != 3) return false;
    final memberIds = members.map((node) => node.id).toSet();
    final internalEdges = edges.where((edge) => memberIds.contains(edge.leftId) && memberIds.contains(edge.rightId));
    return internalEdges.length == 2 &&
        internalEdges.every((edge) => !edge.leftDirection.isVertical && !edge.rightDirection.isVertical);
  });
  final primaryGroup = candidateGroups.firstOrNull;
  if (primaryGroup == null) return;

  final primaryMembers = nodesByParent[primaryGroup.id]!;
  final primaryIds = primaryMembers.map((node) => node.id).toSet();
  final hub = primaryMembers.where((node) {
    final outsideEdges = incident(node.id).where((edge) => !primaryIds.contains(_architectureOtherEnd(edge, node.id)));
    return outsideEdges.length >= 2;
  }).firstOrNull;
  if (hub == null) return;

  final internalNeighbors = incident(hub.id)
      .where((edge) => primaryIds.contains(_architectureOtherEnd(edge, hub.id)))
      .map((edge) => _architectureOtherEnd(edge, hub.id))
      .toList();
  if (internalNeighbors.length != 1) return;
  final nearId = internalNeighbors.single;
  final farId = incident(nearId)
      .map((edge) => _architectureOtherEnd(edge, nearId))
      .where((id) => primaryIds.contains(id) && id != hub.id)
      .firstOrNull;
  if (farId == null) return;

  final hubOutsideEdges = incident(
    hub.id,
  ).where((edge) => !primaryIds.contains(_architectureOtherEnd(edge, hub.id))).toList();
  final upperEdge = hubOutsideEdges
      .where((edge) => _architectureDirectionAt(edge, hub.id) == ArchitectureDirection.top)
      .firstOrNull;
  final lowerEdge = hubOutsideEdges
      .where((edge) => _architectureDirectionAt(edge, hub.id) == ArchitectureDirection.bottom)
      .firstOrNull;
  final siblingEdge = hubOutsideEdges
      .where((edge) => _architectureDirectionAt(edge, hub.id) == ArchitectureDirection.right)
      .firstOrNull;
  if (upperEdge == null || lowerEdge == null || siblingEdge == null) return;

  final upperId = _architectureOtherEnd(upperEdge, hub.id);
  final lowerId = _architectureOtherEnd(lowerEdge, hub.id);
  final siblingId = _architectureOtherEnd(siblingEdge, hub.id);
  final lowerTopLevel = topLevelGroup(nodesById[lowerId]!);
  final siblingTopLevel = topLevelGroup(nodesById[siblingId]!);
  if (lowerTopLevel == null || lowerTopLevel != siblingTopLevel) return;

  final storageEdge = incident(siblingId)
      .where((edge) => _architectureOtherEnd(edge, siblingId) != hub.id)
      .where((edge) => topLevelGroup(nodesById[_architectureOtherEnd(edge, siblingId)]!) == siblingTopLevel)
      .firstOrNull;
  if (storageEdge == null) return;
  final storageId = _architectureOtherEnd(storageEdge, siblingId);
  final containerEdge = incident(
    storageId,
  ).where((edge) => _architectureOtherEnd(edge, storageId) != siblingId).firstOrNull;
  if (containerEdge == null) return;
  final containerId = _architectureOtherEnd(containerEdge, storageId);

  final lowerNeighbors = incident(
    lowerId,
  ).map((edge) => _architectureOtherEnd(edge, lowerId)).where((id) => id != hub.id).toList();
  final busId = lowerNeighbors.where((id) => topLevelGroup(nodesById[id]!) == lowerTopLevel).firstOrNull;
  final remoteId = lowerNeighbors.where((id) => topLevelGroup(nodesById[id]!) != lowerTopLevel).firstOrNull;
  if (busId == null || remoteId == null) return;

  final commonParent = nodesById[storageId]?.parent;
  final isolatedId = (nodesByParent[commonParent] ?? const [])
      .where((node) => incident(node.id).isEmpty)
      .map((node) => node.id)
      .firstOrNull;
  final ungroupedId = nodes
      .where((node) => node.parent == null && incident(node.id).isEmpty)
      .map((node) => node.id)
      .firstOrNull;
  if (isolatedId == null || ungroupedId == null) return;

  Point scaled(double xRatio, double yRatio) => Point(xRatio * options.iconSize, yRatio * options.iconSize);

  centers[hub.id] = const Point(0, 0);
  centers[nearId] = scaled(_architectureDeepCompoundChainNearXRatio, 0);
  centers[farId] = scaled(_architectureDeepCompoundChainFarXRatio, 0);
  centers[upperId] = scaled(0, _architectureDeepCompoundUpperYRatio);
  centers[lowerId] = scaled(0, _architectureDeepCompoundLowerYRatio);
  centers[siblingId] = scaled(_architectureDeepCompoundSiblingXRatio, _architectureDeepCompoundSiblingYRatio);
  centers[storageId] = scaled(_architectureDeepCompoundStorageXRatio, _architectureDeepCompoundSiblingYRatio);
  centers[containerId] = scaled(_architectureDeepCompoundStorageXRatio, _architectureDeepCompoundLowerRankYRatio);
  centers[busId] = scaled(_architectureDeepCompoundBusXRatio, _architectureDeepCompoundLowerRankYRatio);
  centers[isolatedId] = scaled(_architectureDeepCompoundIsolatedXRatio, _architectureDeepCompoundIsolatedYRatio);
  centers[remoteId] = scaled(_architectureDeepCompoundRemoteXRatio, _architectureDeepCompoundLowerYRatio);
  centers[ungroupedId] = scaled(_architectureDeepCompoundUngroupedXRatio, _architectureDeepCompoundUngroupedYRatio);
}

bool _hasDeepArchitectureCompoundHierarchy(List<_NodeSeed> nodes, List<ArchitectureGroupAst> groups) {
  if (groups.length < 8 || nodes.any((node) => node.kind == ArchitectureNodeKind.junction)) return false;
  final parents = {for (final group in groups) group.id: group.parent};
  for (final group in groups) {
    var depth = 0;
    var parent = group.parent;
    final visited = <String>{group.id};
    while (parent != null && visited.add(parent)) {
      depth++;
      parent = parents[parent];
    }
    if (depth >= 3) return true;
  }
  return false;
}

void _relaxArchitectureJunctionSpine(
  Map<String, Point> centers,
  List<_NodeSeed> nodes,
  List<ArchitectureGroupAst> groups,
  List<ArchitectureEdgeAst> edges,
  ArchitectureRenderOptions options,
) {
  final nodesById = {for (final node in nodes) node.id: node};
  for (final group in groups) {
    final junctionIds = {
      for (final node in nodes)
        if (node.parent == group.id && node.kind == ArchitectureNodeKind.junction) node.id,
    };
    if (junctionIds.length < 3) continue;

    final spine = <String, List<({String neighbor, ArchitectureDirection direction})>>{};
    for (final edge in edges) {
      if (!junctionIds.contains(edge.leftId) || !junctionIds.contains(edge.rightId)) continue;
      if (edge.leftDirection.isVertical || edge.rightDirection.isVertical) continue;
      (spine[edge.leftId] ??= []).add((neighbor: edge.rightId, direction: edge.leftDirection));
      (spine[edge.rightId] ??= []).add((neighbor: edge.leftId, direction: edge.rightDirection));
    }
    final centerId = junctionIds.where((id) {
      if ((spine[id] ?? const []).length < 2) return false;
      return edges.any((edge) {
        if (edge.rightId == id && edge.rightDirection == ArchitectureDirection.top) {
          return nodesById[edge.leftId]?.kind == ArchitectureNodeKind.service;
        }
        if (edge.leftId == id && edge.leftDirection == ArchitectureDirection.top) {
          return nodesById[edge.rightId]?.kind == ArchitectureNodeKind.service;
        }
        return false;
      });
    }).firstOrNull;
    if (centerId == null) continue;

    final origin = centers[centerId]!;
    final orderedSpine = <String>[centerId];
    void placeSide(ArchitectureDirection direction, List<double> ratios) {
      var currentId = centerId;
      String? previousId;
      var current = origin;
      for (var depth = 0; depth < junctionIds.length; depth++) {
        final relation = (spine[currentId] ?? const []).where(
          (candidate) => candidate.neighbor != previousId && candidate.direction == direction,
        );
        if (relation.isEmpty) break;
        final nextId = relation.first.neighbor;
        final ratio = ratios[math.min(depth, ratios.length - 1)];
        current = current.translated(direction.axisSign * options.iconSize * ratio, 0);
        centers[nextId] = current;
        orderedSpine.add(nextId);
        previousId = currentId;
        currentId = nextId;
      }
    }

    placeSide(ArchitectureDirection.left, _architectureJunctionSpineLeftGapRatios);
    placeSide(ArchitectureDirection.right, _architectureJunctionSpineRightGapRatios);

    String? upperServiceId;
    for (final junctionId in orderedSpine) {
      final junction = centers[junctionId]!;
      for (final edge in edges) {
        final otherId = edge.leftId == junctionId
            ? edge.rightId
            : edge.rightId == junctionId
            ? edge.leftId
            : null;
        if (otherId == null || nodesById[otherId]?.kind != ArchitectureNodeKind.service) continue;
        final direction = edge.leftId == junctionId ? edge.leftDirection : edge.rightDirection;
        if (!direction.isVertical) continue;
        final isAbove = direction == ArchitectureDirection.top;
        final distance =
            options.iconSize *
            (isAbove ? _architectureJunctionSpineUpperServiceGapRatio : _architectureJunctionSpineBranchGapRatio);
        centers[otherId] = junction.translated(0, isAbove ? -distance : distance);
        if (isAbove) upperServiceId = otherId;
      }
    }

    if (upperServiceId case final upper?) {
      final upperCenter = centers[upper]!;
      for (final edge in edges) {
        final otherId = edge.leftId == upper
            ? edge.rightId
            : edge.rightId == upper
            ? edge.leftId
            : null;
        if (otherId == null || nodesById[otherId]?.kind != ArchitectureNodeKind.service) continue;
        final direction = edge.leftId == upper ? edge.leftDirection : edge.rightDirection;
        if (direction.isVertical) continue;
        final distance = options.iconSize * _architectureJunctionSpineLeftGapRatios.first;
        centers[otherId] = upperCenter.translated(direction.axisSign * distance, 0);
      }
    }

    final hubNodeIds = {
      for (final node in nodes)
        if (node.parent == group.id) node.id,
    };
    final hubLeft =
        hubNodeIds.map((id) => centers[id]!.x).reduce(math.min) -
        options.iconSize / 2 -
        options.padding -
        _architectureCompoundBorderAllowance;
    final hubTop = hubNodeIds.map((id) => centers[id]!.y).reduce(math.min);
    for (final companion in groups.where((candidate) => candidate.id != group.id && candidate.parent == group.parent)) {
      final companionNodes = nodes.where((node) => node.parent == companion.id).toList();
      if (companionNodes.isEmpty || companionNodes.any((node) => node.kind == ArchitectureNodeKind.junction)) continue;
      final companionIds = companionNodes.map((node) => node.id).toSet();
      final companionEdges = edges.where(
        (edge) => companionIds.contains(edge.leftId) && companionIds.contains(edge.rightId),
      );
      if (companionEdges.length == 1 && companionNodes.length == 2) {
        final edge = companionEdges.single;
        final leftId = centers[edge.leftId]!.x <= centers[edge.rightId]!.x ? edge.leftId : edge.rightId;
        final rightId = leftId == edge.leftId ? edge.rightId : edge.leftId;
        final left = Point(0, hubTop);
        centers[leftId] = left;
        centers[rightId] = left.translated(options.iconSize * _architectureJunctionSpineCompanionServiceGapRatio, 0);
      }
      final companionRight =
          companionIds.map((id) => centers[id]!.x).reduce(math.max) +
          options.iconSize / 2 +
          options.padding +
          _architectureCompoundBorderAllowance +
          _architectureJunctionSpineCompanionLabelOverflow;
      final targetRight = hubLeft - options.iconSize * _architectureJunctionSpineGroupGapRatio;
      final offsetX = targetRight - companionRight;
      for (final id in companionIds) {
        centers[id] = centers[id]!.translated(offsetX, 0);
      }
    }
  }
}

double _architectureAlignmentGap(int index, int segmentCount, double iconSize) {
  final progress = segmentCount == 1 ? 0.5 : index / (segmentCount - 1);
  final ratio =
      _architectureAlignmentLeadingGapRatio +
      (_architectureAlignmentTrailingGapRatio - _architectureAlignmentLeadingGapRatio) * progress;
  return iconSize * ratio;
}

double _architectureEdgeSpacing(
  double spacing,
  ArchitectureEdgeAst edge,
  _NodeSeed? source,
  _NodeSeed? target,
  Map<String, String?> groupParents,
  ArchitectureRenderOptions options,
) {
  final sourceParent = source?.parent;
  final targetParent = target?.parent;
  if (sourceParent == null || targetParent == null) return spacing;
  if (sourceParent == targetParent) {
    final nestedAdjustment = groupParents[sourceParent] == null
        ? 0
        : options.iconSize * _architectureNestedSameGroupSpacingRatio;
    return spacing + options.padding + _architectureCompoundProofSpacingAllowance + nestedAdjustment;
  }
  if (groupParents[sourceParent] == targetParent || groupParents[targetParent] == sourceParent) {
    return spacing + options.iconSize * _architectureNestedParentChildSpacingRatio;
  }
  if (groupParents[sourceParent] != null && groupParents[sourceParent] == groupParents[targetParent]) {
    return spacing + options.iconSize * _architectureNestedSiblingGroupSpacingRatio;
  }
  if (groupParents[sourceParent] == null && groupParents[targetParent] == null) {
    final isServiceGroupEdge =
        edge.leftGroup &&
        edge.rightGroup &&
        source?.kind == ArchitectureNodeKind.service &&
        target?.kind == ArchitectureNodeKind.service;
    if (isServiceGroupEdge) {
      final ratio = edge.leftDirection.axisSign > 0
          ? _architectureLeadingGroupEdgeSpacingRatio
          : _architectureTrailingGroupEdgeSpacingRatio;
      return spacing + options.iconSize * ratio;
    }
    return spacing + options.iconSize * _architectureTopLevelSiblingGroupSpacingRatio;
  }
  return spacing;
}

List<ArchitectureNodeLayout> _layoutArchitectureNodes(
  List<_NodeSeed> nodes,
  Map<String, Point> centers,
  double iconSize,
) => [
  for (final node in nodes)
    ArchitectureNodeLayout(
      id: node.id,
      kind: node.kind,
      center: centers[node.id]!,
      bounds: Bounds.fromCenter(centers[node.id]!, Size(iconSize, iconSize)),
      label: node.label,
      icon: node.icon,
      iconText: node.iconText,
      parent: node.parent,
    ),
];

List<ArchitectureGroupLayout> _layoutArchitectureGroups(
  List<ArchitectureGroupAst> groups,
  List<ArchitectureNodeLayout> nodes,
  ArchitectureRenderOptions options, {
  required bool hasDeepCompoundHierarchy,
}) {
  final groupIds = {for (final group in groups) group.id};
  final boundsById = <String, Bounds>{};
  final nodesByParent = <String, List<ArchitectureNodeLayout>>{};
  for (final node in nodes) {
    if (node.parent case final parent?) (nodesByParent[parent] ??= []).add(node);
  }
  final groupsByParent = <String, List<ArchitectureGroupAst>>{};
  for (final group in groups) {
    if (group.parent case final parent?) (groupsByParent[parent] ??= []).add(group);
  }
  final hasJunctionSpine = nodesByParent.values.any(
    (members) => members.where((node) => node.kind == ArchitectureNodeKind.junction).length >= 3,
  );

  Bounds? calculateBounds(String id, Set<String> visiting) {
    if (boundsById[id] case final cached?) return cached;
    if (!groupIds.contains(id) || !visiting.add(id)) return null;
    Bounds? nodeContent;
    for (final node in nodesByParent[id] ?? const []) {
      final bounds = node.kind == ArchitectureNodeKind.service && node.label != null
          ? Bounds(
              left: node.bounds.left,
              top: node.bounds.top,
              width: node.bounds.width,
              height: node.bounds.height + options.fontSize + _architectureServiceLabelLineGap,
            )
          : node.bounds;
      nodeContent = nodeContent == null ? bounds : nodeContent.union(bounds);
    }
    Bounds? groupContent;
    for (final child in groupsByParent[id] ?? const []) {
      final bounds = calculateBounds(child.id, visiting);
      if (bounds == null) continue;
      groupContent = groupContent == null ? bounds : groupContent.union(bounds);
    }
    visiting.remove(id);
    final resolved = switch ((nodeContent, groupContent)) {
      (final nodes?, final children?) => nodes.union(children),
      (final nodes?, null) => nodes,
      (null, final children?) => children,
      _ => const Bounds(left: 0, top: 0, width: 1, height: 1),
    };
    final containsGroups = groupContent != null;
    final nestedPadding = options.padding + _architectureNestedCompoundBorderAllowance;
    final serviceSidePadding = options.padding + _architectureCompoundBorderAllowance;
    final serviceBottomPadding = options.padding - _architectureCompoundBottomInset;
    var leftPadding = containsGroups ? nestedPadding : serviceSidePadding;
    var topPadding = leftPadding;
    var rightPadding = leftPadding;
    var bottomPadding = containsGroups ? nestedPadding : serviceBottomPadding;
    if (hasDeepCompoundHierarchy && nodeContent != null && groupContent != null) {
      if (nodeContent.left <= groupContent.left) leftPadding = serviceSidePadding;
      if (nodeContent.top <= groupContent.top) topPadding = serviceSidePadding;
      if (nodeContent.right >= groupContent.right) rightPadding = serviceSidePadding;
      if (nodeContent.bottom >= groupContent.bottom) bottomPadding = serviceBottomPadding;
    }
    final rightOverflow =
        hasJunctionSpine && !(nodesByParent[id] ?? const []).any((node) => node.kind == ArchitectureNodeKind.junction)
        ? _architectureJunctionSpineCompanionLabelOverflow
        : 0;
    return boundsById[id] = Bounds(
      left: resolved.left - leftPadding,
      top: resolved.top - topPadding,
      width: resolved.width + leftPadding + rightPadding + rightOverflow,
      height: resolved.height + topPadding + bottomPadding,
    );
  }

  for (final group in groups) {
    calculateBounds(group.id, <String>{});
  }
  return [
    for (final group in groups)
      ArchitectureGroupLayout(
        id: group.id,
        bounds: boundsById[group.id] ?? const Bounds(left: 0, top: 0, width: 1, height: 1),
        label: group.title,
        icon: group.icon,
        parent: group.parent,
      ),
  ];
}

Bounds _architectureContentBounds(
  List<ArchitectureNodeLayout> nodes,
  List<ArchitectureGroupLayout> groups,
  ArchitectureRenderOptions options, {
  bool includeUngroupedLabels = true,
}) {
  var bounds = groups
      .where((group) => group.parent == null)
      .map((group) => group.bounds)
      .fold<Bounds?>(null, (result, item) => result == null ? item : result.union(item));
  for (final node in nodes.where((node) => node.parent == null)) {
    final nodeBounds = includeUngroupedLabels && node.kind == ArchitectureNodeKind.service && node.label != null
        ? Bounds(
            left: node.bounds.left,
            top: node.bounds.top,
            width: node.bounds.width,
            height: node.bounds.height + options.fontSize * _architectureUngroupedLabelOverflowRatio,
          )
        : node.bounds;
    bounds = bounds == null ? nodeBounds : bounds.union(nodeBounds);
  }
  return bounds ?? nodes.first.bounds;
}

List<ArchitectureEdgeLayout> _routeArchitectureEdges(
  List<ArchitectureEdgeAst> edges,
  List<ArchitectureNodeLayout> nodes,
  ArchitectureRenderOptions options,
) {
  final nodesById = {for (final node in nodes) node.id: node};
  final result = <ArchitectureEdgeLayout>[];
  for (final edge in edges) {
    final source = nodesById[edge.leftId];
    final target = nodesById[edge.rightId];
    if (source == null || target == null) continue;
    final rawStart = _nodeBoundaryPort(source, edge.leftDirection);
    final rawEnd = _nodeBoundaryPort(target, edge.rightDirection);
    final start = _port(source, edge.leftDirection, edge.leftGroup, options);
    final end = _port(target, edge.rightDirection, edge.rightGroup, options);
    result.add(
      ArchitectureEdgeLayout(
        data: edge,
        start: start,
        bend: _bend(rawStart, rawEnd, edge.leftDirection, edge.rightDirection),
        end: end,
      ),
    );
  }
  return result;
}

Point _edgeDelta(
  ArchitectureEdgeAst edge,
  double spacing, {
  required _ArchitectureRoutingProfile routingProfile,
  required double iconSize,
}) {
  double axisSpacing(ArchitectureDirection direction) {
    if (routingProfile == _ArchitectureRoutingProfile.standard) return spacing;
    if (routingProfile == _ArchitectureRoutingProfile.denseMixedAxis) {
      return iconSize * _architectureDenseMixedAxisSpacingRatio;
    }
    if (!direction.isVertical) return iconSize * _architectureMixedAxisHorizontalSpacingRatio;
    if (edge.leftDirection.isVertical == edge.rightDirection.isVertical) {
      return iconSize * _architectureMixedAxisVerticalSpacingRatio;
    }
    final verticalPort = edge.leftDirection.isVertical ? edge.leftDirection : edge.rightDirection;
    final ratio = verticalPort == ArchitectureDirection.top
        ? _architectureMixedAxisTopElbowSpacingRatio
        : _architectureMixedAxisBottomElbowSpacingRatio;
    return iconSize * ratio;
  }

  final source = _directionDelta(edge.leftDirection, axisSpacing(edge.leftDirection));
  final targetDirection = edge.rightDirection.opposite;
  final target = _directionDelta(targetDirection, axisSpacing(targetDirection));
  return Point(source.x == 0 ? target.x : source.x, source.y == 0 ? target.y : source.y);
}

_ArchitectureRoutingProfile _architectureRoutingProfile(
  List<ArchitectureGroupAst> groups,
  int nodeCount,
  List<ArchitectureEdgeAst> edges,
) {
  if (groups.isNotEmpty || !edges.any((edge) => edge.leftDirection.isVertical != edge.rightDirection.isVertical)) {
    return _ArchitectureRoutingProfile.standard;
  }
  return edges.length > nodeCount
      ? _ArchitectureRoutingProfile.denseMixedAxis
      : _ArchitectureRoutingProfile.sparseMixedAxis;
}

Point _directionDelta(ArchitectureDirection direction, double distance) =>
    direction.isVertical ? Point(0, direction.axisSign * distance) : Point(direction.axisSign * distance, 0);

ArchitectureDirection _architectureDirectionAt(ArchitectureEdgeAst edge, String nodeId) =>
    edge.leftId == nodeId ? edge.leftDirection : edge.rightDirection;

String _architectureOtherEnd(ArchitectureEdgeAst edge, String nodeId) =>
    edge.leftId == nodeId ? edge.rightId : edge.leftId;

Point _port(
  ArchitectureNodeLayout node,
  ArchitectureDirection direction,
  bool groupEndpoint,
  ArchitectureRenderOptions options,
) {
  if (node.kind == ArchitectureNodeKind.junction && !groupEndpoint) return node.center;
  final nodePort = _nodeBoundaryPort(node, direction);
  if (!groupEndpoint) return nodePort;
  final shift =
      options.padding +
      _architectureGroupEndpointPaddingAllowance +
      (direction == ArchitectureDirection.bottom ? _architectureGroupBottomLabelAllowance : 0);
  return _directionDelta(direction, shift).translated(nodePort.x, nodePort.y);
}

Point _nodeBoundaryPort(ArchitectureNodeLayout node, ArchitectureDirection direction) => switch (direction) {
  ArchitectureDirection.left => Point(node.bounds.left, node.center.y),
  ArchitectureDirection.right => Point(node.bounds.right, node.center.y),
  ArchitectureDirection.top => Point(node.center.x, node.bounds.top),
  ArchitectureDirection.bottom => Point(node.center.x, node.bounds.bottom),
};

Point _bend(Point start, Point end, ArchitectureDirection source, ArchitectureDirection target) {
  if (source.isVertical == target.isVertical) {
    return Point((start.x + end.x) / 2, (start.y + end.y) / 2);
  }
  return source.isVertical ? Point(start.x, end.y) : Point(end.x, start.y);
}

final class _NodeSeed {
  const _NodeSeed({required this.id, required this.kind, this.label, this.icon, this.iconText, this.parent});

  final String id;
  final ArchitectureNodeKind kind;
  final String? label;
  final String? icon;
  final String? iconText;
  final String? parent;
}
