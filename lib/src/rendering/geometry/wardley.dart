import 'dart:math' as math;

import '../../parser/ast.dart';
import '../scene.dart';

/// Wardley map coordinates are percentages on both axes.
const wardleyCoordinateMaximum = 100.0;

enum WardleyNodeKind { anchor, component, pipelineComponent }

final class WardleyModel {
  const WardleyModel({required this.nodes, required this.links, required this.trends, required this.pipelines});

  final List<WardleyNodeModel> nodes;
  final List<WardleyLinkModel> links;
  final List<WardleyTrendModel> trends;
  final List<WardleyPipelineModel> pipelines;
}

final class WardleyNodeModel {
  const WardleyNodeModel({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.kind,
    this.labelOffsetX,
    this.labelOffsetY,
    this.inertia = false,
    this.strategy,
    this.isPipelineParent = false,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final WardleyNodeKind kind;
  final double? labelOffsetX;
  final double? labelOffsetY;
  final bool inertia;
  final WardleyStrategy? strategy;
  final bool isPipelineParent;

  WardleyNodeModel asPipelineParent() => WardleyNodeModel(
    id: id,
    label: label,
    x: x,
    y: y,
    kind: kind,
    labelOffsetX: labelOffsetX,
    labelOffsetY: labelOffsetY,
    inertia: inertia,
    strategy: strategy,
    isPipelineParent: true,
  );
}

final class WardleyLinkModel {
  const WardleyLinkModel({required this.sourceId, required this.targetId, required this.style, this.flow, this.label});

  final String sourceId;
  final String targetId;
  final WardleyLinkStyle style;
  final WardleyLinkFlow? flow;
  final String? label;
}

final class WardleyTrendModel {
  const WardleyTrendModel({required this.nodeId, required this.targetX, required this.targetY});

  final String nodeId;
  final double targetX;
  final double targetY;
}

final class WardleyPipelineModel {
  const WardleyPipelineModel({required this.parentId, required this.componentIds});

  final String parentId;
  final List<String> componentIds;
}

/// Projects Wardley percentage coordinates into a padded scene viewport.
Point projectWardleyPoint({
  required double x,
  required double y,
  required double width,
  required double height,
  required double padding,
}) {
  final chartWidth = width - padding * 2;
  final chartHeight = height - padding * 2;
  return Point(
    padding + x.clamp(0, wardleyCoordinateMaximum) / wardleyCoordinateMaximum * chartWidth,
    height - padding - y.clamp(0, wardleyCoordinateMaximum) / wardleyCoordinateMaximum * chartHeight,
  );
}

/// Returns the three vertices used by Mermaid's market strategy symbol.
({Point top, Point left, Point right}) wardleyMarketTriangle({
  required Point center,
  required double radius,
  required double angle,
}) => (
  top: Point(center.x, center.y - radius),
  left: Point(center.x - radius * math.cos(angle), center.y + radius * math.sin(angle)),
  right: Point(center.x + radius * math.cos(angle), center.y + radius * math.sin(angle)),
);

/// Builds Mermaid's typed accelerator or deaccelerator marker path.
List<PathCommand> wardleyMarkerCommands(
  Point origin, {
  required bool right,
  required double width,
  required double height,
  required double headWidth,
  required double notchDepth,
}) {
  final tailX = origin.x + (right ? 0 : width);
  final neckX = origin.x + (right ? width - headWidth : headWidth);
  final tipX = origin.x + (right ? width : 0);
  final top = origin.y - height / 2;
  final bottom = origin.y + height / 2;
  return [
    MoveTo(Point(tailX, top)),
    LineTo(Point(neckX, top)),
    LineTo(Point(neckX, top - notchDepth)),
    LineTo(Point(tipX, origin.y)),
    LineTo(Point(neckX, bottom + notchDepth)),
    LineTo(Point(neckX, bottom)),
    LineTo(Point(tailX, bottom)),
    const ClosePath(),
  ];
}

WardleyModel buildWardleyModel(WardleyAst ast) {
  final nodes = <WardleyNodeModel>[
    for (final anchor in ast.anchors)
      WardleyNodeModel(
        id: anchor.name,
        label: anchor.name,
        x: anchor.position.x.toDouble(),
        y: anchor.position.y.toDouble(),
        kind: WardleyNodeKind.anchor,
      ),
    for (final component in ast.components)
      WardleyNodeModel(
        id: component.name,
        label: component.name,
        x: component.position.x.toDouble(),
        y: component.position.y.toDouble(),
        kind: WardleyNodeKind.component,
        labelOffsetX: component.label?.offsetX.toDouble(),
        labelOffsetY: component.label?.offsetY.toDouble(),
        inertia: component.inertia,
        strategy: component.strategy,
      ),
  ];
  final pipelines = <WardleyPipelineModel>[];
  final nodeIndexesById = <String, int>{};
  for (final (index, node) in nodes.indexed) {
    nodeIndexesById.putIfAbsent(node.id, () => index);
  }
  for (final pipeline in ast.pipelines) {
    final parentIndex = nodeIndexesById[pipeline.parent];
    if (parentIndex == null) continue;
    final parent = nodes[parentIndex];
    nodes[parentIndex] = parent.asPipelineParent();
    final componentIds = <String>[];
    for (final component in pipeline.components) {
      final id = '${pipeline.parent}_${component.name}';
      componentIds.add(id);
      nodeIndexesById.putIfAbsent(id, () => nodes.length);
      nodes.add(
        WardleyNodeModel(
          id: id,
          label: component.name,
          x: component.evolution.toDouble(),
          y: parent.y,
          kind: WardleyNodeKind.pipelineComponent,
          labelOffsetX: component.label?.offsetX.toDouble(),
          labelOffsetY: component.label?.offsetY.toDouble(),
        ),
      );
    }
    pipelines.add(WardleyPipelineModel(parentId: parent.id, componentIds: componentIds));
  }

  final nodesById = <String, WardleyNodeModel>{};
  final nodeIdsByLabel = <String, String>{};
  for (final node in nodes) {
    nodesById.putIfAbsent(node.id, () => node);
    nodeIdsByLabel.putIfAbsent(node.label, () => node.id);
  }
  String resolve(String name) => nodesById[name]?.id ?? nodeIdsByLabel[name] ?? name;
  final links = [
    for (final link in ast.links)
      WardleyLinkModel(
        sourceId: resolve(link.from),
        targetId: resolve(link.to),
        style: link.style,
        flow: link.flow,
        label: link.label,
      ),
  ];
  final trends = <WardleyTrendModel>[];
  for (final evolve in ast.evolves) {
    final node = nodesById[resolve(evolve.component)];
    if (node != null) {
      trends.add(WardleyTrendModel(nodeId: node.id, targetX: evolve.target.toDouble(), targetY: node.y));
    }
  }
  return WardleyModel(nodes: nodes, links: links, trends: trends, pipelines: pipelines);
}
