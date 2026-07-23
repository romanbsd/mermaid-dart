import 'dart:math' as math;

import 'package:fcose/fcose.dart' as fcose;

import '../../parser/ast.dart';
import '../options.dart';
import '../scene.dart';

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
const _architectureLabelMeasurementStepsPerPixel = 2.0;
const _architectureGroupLabelInset = 4.0;
const _architectureGroupIconScale = 0.75;
const _architectureGroupEndpointPaddingAllowance = 4.0;
const _architectureGroupBottomLabelAllowance = 18.0;

// Mermaid's browser text box is 1.0234375 times the configured architecture
// font size. An ungrouped label starts one font size below the icon and extends
// by half that measured line box around its baseline.
const _architectureServiceLabelLineHeightRatio = 1.0234375;

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

ArchitectureLayout layoutArchitectureModel(
  ArchitectureAst ast,
  ArchitectureRenderOptions options, {
  TextMeasurer textMeasurer = const DeterministicTextMeasurer(),
  String fontFamily = 'Arial, sans-serif',
}) {
  final nodes = _architectureNodes(ast);
  if (nodes.isEmpty) {
    return const ArchitectureLayout(
      nodes: [],
      groups: [],
      edges: [],
      bounds: Bounds(left: 0, top: 0, width: 1, height: 1),
    );
  }
  final textStyle = SceneTextStyle(fontFamily: fontFamily, fontSize: options.fontSize);

  final centers = _layoutArchitectureWithFcose(ast, nodes, options);
  var laidOutNodes = _layoutArchitectureNodes(nodes, centers, options.iconSize);
  var laidOutGroups = _layoutArchitectureGroups(
    ast.groups,
    laidOutNodes,
    options,
    textMeasurer: textMeasurer,
    textStyle: textStyle,
  );

  // fCoSE geometry is translation-invariant. Keep the renderer output stable
  // with one topology-independent origin while the viewBox follows the final,
  // label-aware content bounds.
  final positioningBounds = _architectureContentBounds(
    laidOutNodes,
    laidOutGroups,
    options,
    textMeasurer: textMeasurer,
    textStyle: textStyle,
    includeUngroupedLabels: false,
  );
  final contentBounds = _architectureContentBounds(
    laidOutNodes,
    laidOutGroups,
    options,
    textMeasurer: textMeasurer,
    textStyle: textStyle,
  );
  final offsetX = -positioningBounds.left;
  final offsetY = -positioningBounds.top;
  laidOutNodes = [for (final node in laidOutNodes) node.translated(offsetX, offsetY)];
  laidOutGroups = [for (final group in laidOutGroups) group.translated(offsetX, offsetY)];

  return ArchitectureLayout(
    nodes: laidOutNodes,
    groups: laidOutGroups,
    edges: _routeArchitectureEdges(ast.edges, laidOutNodes, options),
    bounds: contentBounds.translated(offsetX, offsetY),
  );
}

fcose.MermaidArchitectureDirection _fcoseDirection(ArchitectureDirection direction) => switch (direction) {
  ArchitectureDirection.left => fcose.MermaidArchitectureDirection.left,
  ArchitectureDirection.right => fcose.MermaidArchitectureDirection.right,
  ArchitectureDirection.top => fcose.MermaidArchitectureDirection.top,
  ArchitectureDirection.bottom => fcose.MermaidArchitectureDirection.bottom,
};

Map<String, Point> _layoutArchitectureWithFcose(
  ArchitectureAst ast,
  List<_NodeSeed> nodes,
  ArchitectureRenderOptions options,
) {
  final graph = fcose.FcoseGraph(
    nodes: [
      for (final group in ast.groups)
        fcose.FcoseNode(id: group.id, parentId: group.parent, position: fcose.Offset.zero),
      for (final node in nodes)
        fcose.FcoseNode(
          id: node.id,
          width: options.iconSize,
          height: options.iconSize,
          parentId: node.parent,
          position: fcose.Offset.zero,
        ),
    ],
    edges: [
      for (final (index, edge) in ast.edges.indexed)
        fcose.FcoseEdge(id: 'architecture-edge-$index', source: edge.leftId, target: edge.rightId),
    ],
  );
  final result =
      fcose.MermaidFcoseAdapter(
            iconSize: options.iconSize,
            idealEdgeLengthMultiplier: options.idealEdgeLengthMultiplier,
            edgeElasticity: options.edgeElasticity,
            padding: options.padding,
            nodeSeparation: math.max(options.nodeSeparation, double.minPositive),
            numIter: options.numIter,
            randomize: options.randomize,
            seed: options.seed,
          )
          .configureArchitecture(
            graph,
            directionalEdges: [
              for (final edge in ast.edges)
                fcose.MermaidDirectionalEdge(
                  source: edge.leftId,
                  sourceDirection: _fcoseDirection(edge.leftDirection),
                  target: edge.rightId,
                  targetDirection: _fcoseDirection(edge.rightDirection),
                ),
            ],
            layoutHints: [
              for (final alignment in ast.alignments)
                fcose.MermaidAlignmentHint(switch (alignment.direction) {
                  ArchitectureAlignmentDirection.row => fcose.MermaidAlignmentDirection.row,
                  ArchitectureAlignmentDirection.column => fcose.MermaidAlignmentDirection.column,
                }, alignment.members),
            ],
          )
          .runMermaidArchitecture();
  return {for (final node in nodes) node.id: Point(result.positionOf(node.id).x, result.positionOf(node.id).y)};
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
  required TextMeasurer textMeasurer,
  required SceneTextStyle textStyle,
}) {
  final groupsById = {for (final group in groups) group.id: group};
  final boundsById = <String, Bounds>{};
  final nodesByParent = <String, List<ArchitectureNodeLayout>>{};
  for (final node in nodes) {
    if (node.parent case final parent?) (nodesByParent[parent] ??= []).add(node);
  }
  final groupsByParent = <String, List<ArchitectureGroupAst>>{};
  for (final group in groups) {
    if (group.parent case final parent?) (groupsByParent[parent] ??= []).add(group);
  }
  Bounds renderedNodeBounds(ArchitectureNodeLayout node) {
    if (node.kind != ArchitectureNodeKind.service || node.label == null) return node.bounds;
    final measuredLabelWidth =
        (textMeasurer.measure(node.label!, textStyle).width * _architectureLabelMeasurementStepsPerPixel).round() /
        _architectureLabelMeasurementStepsPerPixel;
    final labelOverhang = measuredLabelWidth - node.bounds.width;
    // Cytoscape expands a compound by the complete label overhang when a
    // centered child label becomes the content extremum. Model that expansion
    // symmetrically around the child instead of recognizing a particular graph.
    final contentWidth = labelOverhang > _architectureCompoundBorderAllowance
        ? node.bounds.width + 2 * labelOverhang
        : node.bounds.width;
    return Bounds(
      left: node.center.x - contentWidth / 2,
      top: node.bounds.top,
      width: contentWidth,
      height: node.bounds.height + options.fontSize + _architectureServiceLabelLineGap,
    );
  }

  Bounds? calculateBounds(String id, Set<String> visiting) {
    if (boundsById[id] case final cached?) return cached;
    if (!groupsById.containsKey(id) || !visiting.add(id)) return null;
    Bounds? nodeContent;
    for (final node in nodesByParent[id] ?? const []) {
      final bounds = renderedNodeBounds(node);
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
    if (nodeContent != null && groupContent != null) {
      if (nodeContent.left <= groupContent.left) leftPadding = serviceSidePadding;
      if (nodeContent.top <= groupContent.top) topPadding = serviceSidePadding;
      if (nodeContent.right >= groupContent.right) rightPadding = serviceSidePadding;
      if (nodeContent.bottom >= groupContent.bottom) bottomPadding = serviceBottomPadding;
    }

    final group = groupsById[id]!;
    final labelWidth = group.title == null ? 0.0 : textMeasurer.measure(group.title!, textStyle).width;
    final iconWidth = group.icon == null ? 0.0 : options.padding * _architectureGroupIconScale;
    final minimumHeaderWidth = group.title == null ? 0.0 : 2 * _architectureGroupLabelInset + iconWidth + labelWidth;
    final paddedWidth = math.max(resolved.width + leftPadding + rightPadding, minimumHeaderWidth);
    return boundsById[id] = Bounds(
      left: resolved.left - leftPadding,
      top: resolved.top - topPadding,
      width: paddedWidth,
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
  required TextMeasurer textMeasurer,
  required SceneTextStyle textStyle,
  bool includeUngroupedLabels = true,
}) {
  var bounds = groups
      .where((group) => group.parent == null)
      .map((group) => group.bounds)
      .fold<Bounds?>(null, (result, item) => result == null ? item : result.union(item));
  for (final node in nodes.where((node) => node.parent == null)) {
    final nodeBounds = includeUngroupedLabels && node.kind == ArchitectureNodeKind.service && node.label != null
        ? _architectureUngroupedServiceBounds(node, options, textMeasurer, textStyle)
        : node.bounds;
    bounds = bounds == null ? nodeBounds : bounds.union(nodeBounds);
  }
  return bounds ?? nodes.first.bounds;
}

Bounds _architectureUngroupedServiceBounds(
  ArchitectureNodeLayout node,
  ArchitectureRenderOptions options,
  TextMeasurer textMeasurer,
  SceneTextStyle textStyle,
) {
  final labelWidth = textMeasurer.measure(node.label!, textStyle).width;
  final width = math.max(node.bounds.width, labelWidth);
  return Bounds(
    left: node.center.x - width / 2,
    top: node.bounds.top,
    width: width,
    height: node.bounds.height + options.fontSize + options.fontSize * _architectureServiceLabelLineHeightRatio / 2,
  );
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

Point _directionDelta(ArchitectureDirection direction, double distance) =>
    direction.isVertical ? Point(0, direction.axisSign * distance) : Point(direction.axisSign * distance, 0);

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
