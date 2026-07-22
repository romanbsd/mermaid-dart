import 'dart:math' as math;

import '../../parser/ast.dart';
import '../options.dart';
import '../scene.dart';

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
    center: Point(center.x + x, center.y + y),
    bounds: Bounds(left: bounds.left + x, top: bounds.top + y, width: bounds.width, height: bounds.height),
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

  ArchitectureGroupLayout translated(double x, double y) => ArchitectureGroupLayout(
    id: id,
    bounds: Bounds(left: bounds.left + x, top: bounds.top + y, width: bounds.width, height: bounds.height),
    label: label,
    icon: icon,
    parent: parent,
  );
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
  final nodes = <_NodeSeed>[
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
  if (nodes.isEmpty) {
    return const ArchitectureLayout(
      nodes: [],
      groups: [],
      edges: [],
      bounds: Bounds(left: 0, top: 0, width: 1, height: 1),
    );
  }

  final nodeIds = {for (final node in nodes) node.id};
  final adjacency = <String, List<({ArchitectureEdgeAst edge, bool forward})>>{};
  for (final edge in ast.edges) {
    if (!nodeIds.contains(edge.leftId) || !nodeIds.contains(edge.rightId)) continue;
    (adjacency[edge.leftId] ??= []).add((edge: edge, forward: true));
    (adjacency[edge.rightId] ??= []).add((edge: edge, forward: false));
  }
  final centers = <String, Point>{};
  final spacing = math.max(
    options.iconSize + options.nodeSeparation,
    options.iconSize * options.idealEdgeLengthMultiplier,
  );
  var component = 0;
  for (final root in nodes) {
    if (centers.containsKey(root.id)) continue;
    centers[root.id] = Point(0, component * spacing * 1.5);
    component++;
    final queue = <String>[root.id];
    for (var cursor = 0; cursor < queue.length; cursor++) {
      final currentId = queue[cursor];
      final current = centers[currentId]!;
      for (final relation in adjacency[currentId] ?? const []) {
        final edge = relation.edge;
        final nextId = relation.forward ? edge.rightId : edge.leftId;
        if (centers.containsKey(nextId)) continue;
        final delta = _edgeDelta(edge, spacing);
        centers[nextId] = relation.forward
            ? Point(current.x + delta.x, current.y + delta.y)
            : Point(current.x - delta.x, current.y - delta.y);
        queue.add(nextId);
      }
    }
  }

  for (final alignment in ast.alignments) {
    final members = alignment.members.where(centers.containsKey).toList();
    if (members.length < 2) continue;
    final origin = centers[members.first]!;
    for (var index = 1; index < members.length; index++) {
      final id = members[index];
      centers[id] = switch (alignment.direction) {
        ArchitectureAlignmentDirection.row => Point(origin.x + index * spacing, origin.y),
        ArchitectureAlignmentDirection.column => Point(origin.x, origin.y + index * spacing),
      };
    }
  }

  var laidOutNodes = <ArchitectureNodeLayout>[
    for (final node in nodes)
      ArchitectureNodeLayout(
        id: node.id,
        kind: node.kind,
        center: centers[node.id]!,
        bounds: Bounds(
          left: centers[node.id]!.x - options.iconSize / 2,
          top: centers[node.id]!.y - options.iconSize / 2,
          width: options.iconSize,
          height: options.iconSize,
        ),
        label: node.label,
        icon: node.icon,
        iconText: node.iconText,
        parent: node.parent,
      ),
  ];
  final groupAsts = {for (final group in ast.groups) group.id: group};
  final groupBounds = <String, Bounds>{};
  final nodesByParent = <String, List<ArchitectureNodeLayout>>{};
  for (final node in laidOutNodes) {
    if (node.parent case final parent?) (nodesByParent[parent] ??= []).add(node);
  }
  final groupsByParent = <String, List<ArchitectureGroupAst>>{};
  for (final group in ast.groups) {
    if (group.parent case final parent?) (groupsByParent[parent] ??= []).add(group);
  }

  Bounds? calculateGroup(String id, Set<String> visiting) {
    if (groupBounds[id] case final cached?) return cached;
    final group = groupAsts[id];
    if (group == null || !visiting.add(id)) return null;
    Bounds? content;
    for (final node in nodesByParent[id] ?? const []) {
      final visual = node.kind == ArchitectureNodeKind.service && node.label != null
          ? Bounds(
              left: node.bounds.left,
              top: node.bounds.top,
              width: node.bounds.width,
              height: node.bounds.height + options.fontSize + 4,
            )
          : node.bounds;
      content = content == null ? visual : content.union(visual);
    }
    for (final child in groupsByParent[id] ?? const []) {
      final bounds = calculateGroup(child.id, visiting);
      if (bounds != null) content = content == null ? bounds : content.union(bounds);
    }
    visiting.remove(id);
    content ??= const Bounds(left: 0, top: 0, width: 1, height: 1);
    final bounds = Bounds(
      left: content.left - options.padding,
      top: content.top - options.padding,
      width: content.width + options.padding * 2,
      height: content.height + options.padding * 2,
    );
    groupBounds[id] = bounds;
    return bounds;
  }

  for (final group in ast.groups) {
    calculateGroup(group.id, <String>{});
  }
  var laidOutGroups = <ArchitectureGroupLayout>[
    for (final group in ast.groups)
      ArchitectureGroupLayout(
        id: group.id,
        bounds: groupBounds[group.id] ?? const Bounds(left: 0, top: 0, width: 1, height: 1),
        label: group.title ?? group.id,
        icon: group.icon,
        parent: group.parent,
      ),
  ];

  Bounds contentBounds =
      laidOutGroups
          .where((group) => group.parent == null)
          .fold<Bounds?>(null, (bounds, group) => bounds == null ? group.bounds : bounds.union(group.bounds)) ??
      laidOutNodes.first.bounds;
  for (final node in laidOutNodes.where((node) => node.parent == null)) {
    contentBounds = contentBounds.union(node.bounds);
  }
  final offsetX = -contentBounds.left;
  final offsetY = -contentBounds.top;
  laidOutNodes = [for (final node in laidOutNodes) node.translated(offsetX, offsetY)];
  laidOutGroups = [for (final group in laidOutGroups) group.translated(offsetX, offsetY)];
  final translatedNodes = {for (final node in laidOutNodes) node.id: node};
  final translatedGroups = {for (final group in laidOutGroups) group.id: group};

  final edges = <ArchitectureEdgeLayout>[];
  for (final edge in ast.edges) {
    final source = translatedNodes[edge.leftId];
    final target = translatedNodes[edge.rightId];
    if (source == null || target == null) continue;
    final sourceBounds = edge.leftGroup && source.parent != null
        ? translatedGroups[source.parent!]?.bounds ?? source.bounds
        : source.bounds;
    final targetBounds = edge.rightGroup && target.parent != null
        ? translatedGroups[target.parent!]?.bounds ?? target.bounds
        : target.bounds;
    final start = _port(source, sourceBounds, edge.leftDirection, edge.leftGroup);
    final end = _port(target, targetBounds, edge.rightDirection, edge.rightGroup);
    final bend = _bend(start, end, edge.leftDirection, edge.rightDirection);
    edges.add(ArchitectureEdgeLayout(data: edge, start: start, bend: bend, end: end));
  }

  return ArchitectureLayout(
    nodes: laidOutNodes,
    groups: laidOutGroups,
    edges: edges,
    bounds: Bounds(left: 0, top: 0, width: contentBounds.width, height: contentBounds.height),
  );
}

Point _edgeDelta(ArchitectureEdgeAst edge, double spacing) {
  double x = 0;
  double y = 0;
  switch (edge.leftDirection) {
    case ArchitectureDirection.left:
      x = -spacing;
    case ArchitectureDirection.right:
      x = spacing;
    case ArchitectureDirection.top:
      y = -spacing;
    case ArchitectureDirection.bottom:
      y = spacing;
  }
  switch (edge.rightDirection) {
    case ArchitectureDirection.left:
      x = x == 0 ? spacing : x;
    case ArchitectureDirection.right:
      x = x == 0 ? -spacing : x;
    case ArchitectureDirection.top:
      y = y == 0 ? spacing : y;
    case ArchitectureDirection.bottom:
      y = y == 0 ? -spacing : y;
  }
  return Point(x, y);
}

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
