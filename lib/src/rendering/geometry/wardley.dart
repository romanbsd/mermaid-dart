import 'package:collection/collection.dart';

import '../../parser/ast.dart';

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
  for (final pipeline in ast.pipelines) {
    final parentIndex = nodes.indexWhere((node) => node.id == pipeline.parent);
    if (parentIndex < 0) continue;
    final parent = nodes[parentIndex];
    nodes[parentIndex] = parent.asPipelineParent();
    final componentIds = <String>[];
    for (final component in pipeline.components) {
      final id = '${pipeline.parent}_${component.name}';
      componentIds.add(id);
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

  String resolve(String name) =>
      nodes.where((node) => node.id == name).firstOrNull?.id ??
      nodes.where((node) => node.label == name).firstOrNull?.id ??
      name;
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
    final node = nodes.where((node) => node.id == resolve(evolve.component)).firstOrNull;
    if (node != null) {
      trends.add(WardleyTrendModel(nodeId: node.id, targetX: evolve.target.toDouble(), targetY: node.y));
    }
  }
  return WardleyModel(nodes: nodes, links: links, trends: trends, pipelines: pipelines);
}
