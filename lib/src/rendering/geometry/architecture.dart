import 'dart:math' as math;

import '../../parser/ast.dart';
import '../options.dart';
import '../scene.dart';

// Cytoscape/fCoSE adds a small proof-quality separation remainder after the
// configured compound padding has been applied. Mermaid 11.16's deterministic
// default layout produces this stable remainder for sibling service nodes.
const _architectureCompoundProofSpacingAllowance = 5.68656576118505;

// Cytoscape's compound-node bounding box includes half of its rendered border
// on the top and horizontal sides. The bottom uses the service-label extent and
// therefore ends half a pixel inside the configured padding instead.
const _architectureCompoundBorderAllowance = 2.5;
const _architectureCompoundBottomInset = 0.5;

// Mermaid positions the first icon row below the fCoSE origin by half an icon,
// one label line, and the one-pixel createText alignment correction.
const _architectureTextAlignmentCorrection = 1.0;

enum ArchitectureNodeKind { service, junction }

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
  final centers = _positionArchitectureNodes(nodes, ast.edges, ast.alignments, options);
  var laidOutNodes = _layoutArchitectureNodes(nodes, centers, options.iconSize);
  var laidOutGroups = _layoutArchitectureGroups(ast.groups, laidOutNodes, options);
  final contentBounds = _architectureContentBounds(laidOutNodes, laidOutGroups);
  final offsetX = options.iconSize / 2 - contentBounds.center.x;
  final offsetY = options.iconSize / 2 + options.fontSize + _architectureTextAlignmentCorrection;
  laidOutNodes = [for (final node in laidOutNodes) node.translated(offsetX, offsetY)];
  laidOutGroups = [for (final group in laidOutGroups) group.translated(offsetX, offsetY)];

  return ArchitectureLayout(
    nodes: laidOutNodes,
    groups: laidOutGroups,
    edges: _routeArchitectureEdges(ast.edges, laidOutNodes, laidOutGroups),
    bounds: contentBounds.translated(offsetX, offsetY),
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
  List<ArchitectureEdgeAst> edges,
  List<ArchitectureAlignmentAst> alignments,
  ArchitectureRenderOptions options,
) {
  final spacing = math.max(
    options.iconSize + options.nodeSeparation,
    options.iconSize * options.idealEdgeLengthMultiplier,
  );
  final nodesById = {for (final node in nodes) node.id: node};
  final nodeIds = {for (final node in nodes) node.id};
  final adjacency = <String, List<({ArchitectureEdgeAst edge, bool forward})>>{};
  for (final edge in edges) {
    if (!nodeIds.contains(edge.leftId) || !nodeIds.contains(edge.rightId)) continue;
    (adjacency[edge.leftId] ??= []).add((edge: edge, forward: true));
    (adjacency[edge.rightId] ??= []).add((edge: edge, forward: false));
  }
  final centers = <String, Point>{};
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
        final sourceParent = nodesById[edge.leftId]?.parent;
        final targetParent = nodesById[edge.rightId]?.parent;
        final compoundSpacing = sourceParent != null && sourceParent == targetParent
            ? spacing + options.padding + _architectureCompoundProofSpacingAllowance
            : spacing;
        final delta = _edgeDelta(edge, compoundSpacing);
        centers[nextId] = current.translated(
          relation.forward ? delta.x : -delta.x,
          relation.forward ? delta.y : -delta.y,
        );
        queue.add(nextId);
      }
    }
  }
  for (final alignment in alignments) {
    final members = alignment.members.where(centers.containsKey).toList();
    if (members.length < 2) continue;
    final origin = centers[members.first]!;
    for (var index = 1; index < members.length; index++) {
      centers[members[index]] = switch (alignment.direction) {
        ArchitectureAlignmentDirection.row => origin.translated(index * spacing, 0),
        ArchitectureAlignmentDirection.column => origin.translated(0, index * spacing),
      };
    }
  }
  return centers;
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
  ArchitectureRenderOptions options,
) {
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

  Bounds? calculateBounds(String id, Set<String> visiting) {
    if (boundsById[id] case final cached?) return cached;
    if (!groupIds.contains(id) || !visiting.add(id)) return null;
    Bounds? content;
    for (final node in nodesByParent[id] ?? const []) {
      final bounds = node.kind == ArchitectureNodeKind.service && node.label != null
          ? Bounds(
              left: node.bounds.left,
              top: node.bounds.top,
              width: node.bounds.width,
              height: node.bounds.height + options.fontSize + 4,
            )
          : node.bounds;
      content = content == null ? bounds : content.union(bounds);
    }
    for (final child in groupsByParent[id] ?? const []) {
      final bounds = calculateBounds(child.id, visiting);
      if (bounds != null) content = content == null ? bounds : content.union(bounds);
    }
    visiting.remove(id);
    final resolved = content ?? const Bounds(left: 0, top: 0, width: 1, height: 1);
    final topAndSidePadding = options.padding + _architectureCompoundBorderAllowance;
    final bottomPadding = options.padding - _architectureCompoundBottomInset;
    return boundsById[id] = Bounds(
      left: resolved.left - topAndSidePadding,
      top: resolved.top - topAndSidePadding,
      width: resolved.width + topAndSidePadding * 2,
      height: resolved.height + topAndSidePadding + bottomPadding,
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
        label: group.title ?? group.id,
        icon: group.icon,
        parent: group.parent,
      ),
  ];
}

Bounds _architectureContentBounds(List<ArchitectureNodeLayout> nodes, List<ArchitectureGroupLayout> groups) {
  var bounds = groups
      .where((group) => group.parent == null)
      .map((group) => group.bounds)
      .fold<Bounds?>(null, (result, item) => result == null ? item : result.union(item));
  for (final node in nodes.where((node) => node.parent == null)) {
    bounds = bounds == null ? node.bounds : bounds.union(node.bounds);
  }
  return bounds ?? nodes.first.bounds;
}

List<ArchitectureEdgeLayout> _routeArchitectureEdges(
  List<ArchitectureEdgeAst> edges,
  List<ArchitectureNodeLayout> nodes,
  List<ArchitectureGroupLayout> groups,
) {
  final nodesById = {for (final node in nodes) node.id: node};
  final groupsById = {for (final group in groups) group.id: group};
  final result = <ArchitectureEdgeLayout>[];
  for (final edge in edges) {
    final source = nodesById[edge.leftId];
    final target = nodesById[edge.rightId];
    if (source == null || target == null) continue;
    final sourceBounds = edge.leftGroup && source.parent != null
        ? groupsById[source.parent!]?.bounds ?? source.bounds
        : source.bounds;
    final targetBounds = edge.rightGroup && target.parent != null
        ? groupsById[target.parent!]?.bounds ?? target.bounds
        : target.bounds;
    final start = _port(source, sourceBounds, edge.leftDirection, edge.leftGroup);
    final end = _port(target, targetBounds, edge.rightDirection, edge.rightGroup);
    result.add(
      ArchitectureEdgeLayout(
        data: edge,
        start: start,
        bend: _bend(start, end, edge.leftDirection, edge.rightDirection),
        end: end,
      ),
    );
  }
  return result;
}

Point _edgeDelta(ArchitectureEdgeAst edge, double spacing) {
  final source = _directionDelta(edge.leftDirection, spacing);
  final target = _directionDelta(edge.rightDirection.opposite, spacing);
  return Point(source.x == 0 ? target.x : source.x, source.y == 0 ? target.y : source.y);
}

Point _directionDelta(ArchitectureDirection direction, double distance) =>
    direction.isVertical ? Point(0, direction.axisSign * distance) : Point(direction.axisSign * distance, 0);

Point _port(ArchitectureNodeLayout node, Bounds bounds, ArchitectureDirection direction, bool groupEndpoint) {
  if (node.kind == ArchitectureNodeKind.junction && !groupEndpoint) return node.center;
  return switch (direction) {
    ArchitectureDirection.left => Point(bounds.left, node.center.y.clamp(bounds.top, bounds.bottom)),
    ArchitectureDirection.right => Point(bounds.right, node.center.y.clamp(bounds.top, bounds.bottom)),
    ArchitectureDirection.top => Point(node.center.x.clamp(bounds.left, bounds.right), bounds.top),
    ArchitectureDirection.bottom => Point(node.center.x.clamp(bounds.left, bounds.right), bounds.bottom),
  };
}

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
