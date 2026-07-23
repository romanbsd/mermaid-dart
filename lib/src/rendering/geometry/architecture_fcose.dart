import 'dart:collection';
import 'dart:math' as math;

import 'package:fcose/fcose.dart';

import '../../parser/ast.dart';
import '../options.dart';
import '../scene.dart';

/// Mermaid architecture uses half an icon as the boundary distance for edges
/// that cross compound parents.
const _crossParentIdealLengthFactor = 0.5;

/// Mermaid's weak elasticity for edges that cross compound parents.
const _crossParentElasticity = 0.001;

/// Cytoscape's grid layout leaves this gap between adjacent node boxes.
const _initialGridGap = 10.0;

typedef _SpatialMap = Map<String, ({int x, int y})>;
typedef _GroupAlignments = Map<String, Map<String, ArchitectureAlignmentDirection>>;

/// Positions architecture nodes with Mermaid's fCoSE policies.
Map<String, Point> layoutArchitectureWithFcose(ArchitectureAst ast, ArchitectureRenderOptions options) {
  final graph = FcoseGraph(
    nodes: [
      for (final group in ast.groups) FcoseNode(id: group.id, parentId: group.parent, position: Offset.zero),
      for (final service in ast.services)
        FcoseNode(
          id: service.id,
          width: options.iconSize,
          height: options.iconSize,
          parentId: service.parent,
          position: Offset.zero,
        ),
      for (final junction in ast.junctions)
        FcoseNode(
          id: junction.id,
          width: options.iconSize,
          height: options.iconSize,
          parentId: junction.parent,
          position: Offset.zero,
        ),
    ],
    edges: [
      for (final (index, edge) in ast.edges.indexed)
        FcoseEdge(id: 'architecture-edge-$index', source: edge.leftId, target: edge.rightId),
    ],
  );
  final (:configuredGraph, :layoutOptions) = _ArchitectureFcoseLayout(options)._configure(graph, ast);
  final result = _runTwice(configuredGraph, layoutOptions);
  return {
    for (final service in ast.services)
      service.id: Point(result.positionOf(service.id).x, result.positionOf(service.id).y),
    for (final junction in ast.junctions)
      junction.id: Point(result.positionOf(junction.id).x, result.positionOf(junction.id).y),
  };
}

FcoseResult _runTwice(FcoseGraph graph, FcoseOptions options) {
  final first = FcoseLayout(options: options).run(graph);
  final secondPassGraph = FcoseGraph(
    nodes: [
      for (final node in graph.nodes)
        FcoseNode(
          id: node.id,
          width: node.width,
          height: node.height,
          parentId: node.parentId,
          position: first.positionOf(node.id),
          labelWidth: node.labelWidth,
          labelHeight: node.labelHeight,
          labelHorizontalPosition: node.labelHorizontalPosition,
          labelVerticalPosition: node.labelVerticalPosition,
          nodeRepulsion: node.nodeRepulsion,
        ),
    ],
    edges: graph.edges,
  );
  return FcoseLayout(options: options).run(secondPassGraph);
}

final class _ArchitectureFcoseLayout {
  const _ArchitectureFcoseLayout(this.renderOptions);

  final ArchitectureRenderOptions renderOptions;

  double get _sameParentIdealLength => renderOptions.idealEdgeLengthMultiplier * renderOptions.iconSize;

  double get _crossParentIdealLength => _crossParentIdealLengthFactor * renderOptions.iconSize;

  FcoseOptions _options({
    AlignmentConstraint alignment = const AlignmentConstraint(),
    List<RelativePlacementConstraint> relativePlacements = const [],
  }) => FcoseOptions(
    quality: LayoutQuality.proof,
    randomize: renderOptions.randomize,
    seed: renderOptions.seed,
    maxIterations: renderOptions.numIter,
    nodeSeparation: math.max(renderOptions.nodeSeparation, double.minPositive),
    idealEdgeLength: _sameParentIdealLength,
    edgeElasticity: renderOptions.edgeElasticity,
    compoundPadding: renderOptions.padding,
    alignment: alignment,
    relativePlacements: relativePlacements,
  );

  FcoseGraph _configureGraph(FcoseGraph graph) {
    final nodes = graph.nodeById;
    return FcoseGraph(
      nodes: graph.nodes,
      edges: graph.edges.map((edge) {
        final sameParent = nodes[edge.source]!.parentId == nodes[edge.target]!.parentId;
        return FcoseEdge(
          id: edge.id,
          source: edge.source,
          target: edge.target,
          idealLength: edge.idealLength ?? (sameParent ? _sameParentIdealLength : _crossParentIdealLength),
          elasticity: edge.elasticity ?? (sameParent ? renderOptions.edgeElasticity : _crossParentElasticity),
        );
      }),
    );
  }

  ({FcoseGraph configuredGraph, FcoseOptions layoutOptions}) _configure(FcoseGraph graph, ArchitectureAst ast) {
    final (:spatialMaps, :groupAlignments) = _buildArchitectureData(graph, ast.edges);
    return (
      configuredGraph: _configureGraph(_withAlignmentGrid(graph, ast.alignments)),
      layoutOptions: _options(
        alignment: _alignmentConstraints(graph, spatialMaps, groupAlignments, ast.alignments),
        relativePlacements: _relativeConstraints(spatialMaps, ast.alignments),
      ),
    );
  }

  FcoseGraph _withAlignmentGrid(FcoseGraph graph, List<ArchitectureAlignmentAst> alignments) {
    if (renderOptions.randomize || alignments.isEmpty) return graph;
    final leaves = graph.leafNodes;
    final columns = math.sqrt(leaves.length).ceil();
    final step = renderOptions.iconSize + _initialGridGap;
    final origin = step / 2;
    final positions = {
      for (final (index, node) in leaves.indexed)
        node.id: Offset(origin + (index % columns) * step, origin + (index ~/ columns) * step),
    };
    return FcoseGraph(
      nodes: [
        for (final node in graph.nodes)
          FcoseNode(
            id: node.id,
            width: node.width,
            height: node.height,
            parentId: node.parentId,
            position: positions[node.id] ?? node.position,
            labelWidth: node.labelWidth,
            labelHeight: node.labelHeight,
            labelHorizontalPosition: node.labelHorizontalPosition,
            labelVerticalPosition: node.labelVerticalPosition,
            nodeRepulsion: node.nodeRepulsion,
          ),
      ],
      edges: graph.edges,
    );
  }

  ({List<_SpatialMap> spatialMaps, _GroupAlignments groupAlignments}) _buildArchitectureData(
    FcoseGraph graph,
    List<ArchitectureEdgeAst> edges,
  ) {
    final leaves = graph.leafNodes.map((node) => node.id).toList();
    final adjacency = {for (final id in leaves) id: <_DirectionPair, String>{}};
    final groupAlignments = <String, Map<String, ArchitectureAlignmentDirection>>{};
    for (final edge in edges) {
      if (!adjacency.containsKey(edge.leftId) || !adjacency.containsKey(edge.rightId)) {
        throw ArgumentError.value(edge, 'edges', 'endpoints must be leaf nodes');
      }
      final forward = _DirectionPair(edge.leftDirection, edge.rightDirection);
      final reverse = _DirectionPair(edge.rightDirection, edge.leftDirection);
      if (!forward.isValid) {
        throw ArgumentError.value(edge, 'edges', 'matching port directions cannot form an edge');
      }
      adjacency[edge.leftId]![forward] = edge.rightId;
      adjacency[edge.rightId]![reverse] = edge.leftId;

      final sourceGroup = graph.nodeById[edge.leftId]!.parentId;
      final targetGroup = graph.nodeById[edge.rightId]!.parentId;
      final alignment = forward.alignment;
      if (sourceGroup != null && targetGroup != null && sourceGroup != targetGroup && alignment != null) {
        (groupAlignments[sourceGroup] ??= {})[targetGroup] = alignment;
        (groupAlignments[targetGroup] ??= {})[sourceGroup] = alignment;
      }
    }
    if (leaves.isEmpty) {
      return (spatialMaps: const [], groupAlignments: const {});
    }

    final visited = <String>{leaves.first};
    final notVisited = leaves.skip(1).toSet();
    _SpatialMap breadthFirst(String start) {
      final result = <String, ({int x, int y})>{start: (x: 0, y: 0)};
      final queue = Queue<String>()..add(start);
      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        visited.add(current);
        notVisited.remove(current);
        final position = result[current]!;
        for (final MapEntry(key: pair, value: neighbor) in adjacency[current]!.entries) {
          if (visited.contains(neighbor)) continue;
          result[neighbor] = pair.shift(position);
          queue.add(neighbor);
        }
      }
      return result;
    }

    final spatialMaps = <_SpatialMap>[breadthFirst(leaves.first)];
    while (notVisited.isNotEmpty) {
      spatialMaps.add(breadthFirst(notVisited.first));
    }
    return (spatialMaps: spatialMaps, groupAlignments: groupAlignments);
  }

  AlignmentConstraint _alignmentConstraints(
    FcoseGraph graph,
    List<_SpatialMap> spatialMaps,
    _GroupAlignments groupAlignments,
    List<ArchitectureAlignmentAst> alignments,
  ) {
    final horizontal = <List<String>>[];
    final vertical = <List<String>>[];
    for (final spatialMap in spatialMaps) {
      final horizontalByCoordinate = <int, Map<String, List<String>>>{};
      final verticalByCoordinate = <int, Map<String, List<String>>>{};
      for (final MapEntry(key: id, value: position) in spatialMap.entries) {
        final group = graph.nodeById[id]?.parentId ?? _defaultGroup;
        ((horizontalByCoordinate[position.y] ??= {})[group] ??= []).add(id);
        ((verticalByCoordinate[position.x] ??= {})[group] ??= []).add(id);
      }
      horizontal.addAll(
        _flattenAlignments(horizontalByCoordinate, ArchitectureAlignmentDirection.row, groupAlignments),
      );
      vertical.addAll(_flattenAlignments(verticalByCoordinate, ArchitectureAlignmentDirection.column, groupAlignments));
    }

    final declaredMembers = alignments.expand((alignment) => alignment.members).toSet();
    horizontal.removeWhere((group) => group.any(declaredMembers.contains));
    vertical.removeWhere((group) => group.any(declaredMembers.contains));
    for (final alignment in alignments.where((alignment) => alignment.members.length > 1)) {
      (alignment.direction == ArchitectureAlignmentDirection.row ? horizontal : vertical).add(
        List.of(alignment.members),
      );
    }
    return AlignmentConstraint(horizontal: horizontal, vertical: vertical);
  }

  List<List<String>> _flattenAlignments(
    Map<int, Map<String, List<String>>> byCoordinate,
    ArchitectureAlignmentDirection direction,
    _GroupAlignments groupAlignments,
  ) {
    // Mermaid accumulates these in a plain JavaScript object. Preserve both
    // replacement/insertion semantics and Object.values() key ordering.
    final flattened = <String, List<String>>{};
    for (final MapEntry(key: coordinate, value: groups) in byCoordinate.entries) {
      final coordinateKey = '$coordinate';
      final entries = groups.entries.toList();
      if (entries.length == 1) {
        flattened[coordinateKey] = List.of(entries.single.value);
        continue;
      }
      var count = 0;
      for (var first = 0; first < entries.length - 1; first++) {
        for (var second = first + 1; second < entries.length; second++) {
          final a = entries[first];
          final b = entries[second];
          final compatible =
              a.key == _defaultGroup || b.key == _defaultGroup || groupAlignments[a.key]?[b.key] == direction;
          if (compatible) {
            flattened[coordinateKey] = [...?flattened[coordinateKey], ...a.value, ...b.value];
          } else {
            flattened['$coordinate-$count'] = List.of(a.value);
            count++;
            flattened['$coordinate-$count'] = List.of(b.value);
            count++;
          }
        }
      }
    }

    final arrayIndexes = <({int index, List<String> value})>[];
    final otherValues = <List<String>>[];
    for (final MapEntry(key: key, value: value) in flattened.entries) {
      final index = int.tryParse(key);
      if (index != null && index >= 0 && index <= _maximumJavaScriptArrayIndex && '$index' == key) {
        arrayIndexes.add((index: index, value: value));
      } else {
        otherValues.add(value);
      }
    }
    arrayIndexes.sort((first, second) => first.index.compareTo(second.index));
    return [...arrayIndexes.map((entry) => entry.value), ...otherValues].where((group) => group.length > 1).toList();
  }

  List<RelativePlacementConstraint> _relativeConstraints(
    List<_SpatialMap> spatialMaps,
    List<ArchitectureAlignmentAst> alignments,
  ) {
    final result = <RelativePlacementConstraint>[];
    final declaredPairs = <(String, String)>{};
    final gap = _sameParentIdealLength;
    for (final alignment in alignments) {
      for (var index = 0; index < alignment.members.length - 1; index++) {
        final first = alignment.members[index];
        final second = alignment.members[index + 1];
        declaredPairs
          ..add((first, second))
          ..add((second, first));
        result.add(
          alignment.direction == ArchitectureAlignmentDirection.row
              ? RelativePlacementConstraint.horizontal(first, second, gap: gap)
              : RelativePlacementConstraint.vertical(first, second, gap: gap),
        );
      }
    }

    const shifts = [(-1, 0), (1, 0), (0, 1), (0, -1)];
    for (final spatialMap in spatialMaps) {
      final inverse = {for (final MapEntry(key: id, value: position) in spatialMap.entries) position: id};
      final queue = Queue<({int x, int y})>()..add((x: 0, y: 0));
      final visited = <({int x, int y})>{};
      while (queue.isNotEmpty) {
        final current = queue.removeFirst();
        visited.add(current);
        final currentId = inverse[current];
        if (currentId == null) continue;
        for (final (dx, dy) in shifts) {
          final next = (x: current.x + dx, y: current.y + dy);
          final nextId = inverse[next];
          if (nextId == null || visited.contains(next)) continue;
          queue.add(next);
          if (declaredPairs.contains((currentId, nextId))) continue;
          result.add(switch ((dx, dy)) {
            (-1, 0) => RelativePlacementConstraint.horizontal(nextId, currentId, gap: gap),
            (1, 0) => RelativePlacementConstraint.horizontal(currentId, nextId, gap: gap),
            (0, 1) => RelativePlacementConstraint.vertical(nextId, currentId, gap: gap),
            (0, -1) => RelativePlacementConstraint.vertical(currentId, nextId, gap: gap),
            _ => throw StateError('unknown spatial-map direction'),
          });
        }
      }
    }
    return result;
  }
}

const _defaultGroup = 'default';

/// Largest key ordered as an array index by JavaScript's Object.values().
const _maximumJavaScriptArrayIndex = 0xfffffffe;

final class _DirectionPair {
  const _DirectionPair(this.source, this.target);

  final ArchitectureDirection source;
  final ArchitectureDirection target;

  bool get isValid => source != target;
  bool get _sourceIsHorizontal => !source.isVertical;
  bool get _targetIsHorizontal => !target.isVertical;

  ArchitectureAlignmentDirection? get alignment {
    if (_sourceIsHorizontal != _targetIsHorizontal) return null;
    return _sourceIsHorizontal ? ArchitectureAlignmentDirection.row : ArchitectureAlignmentDirection.column;
  }

  ({int x, int y}) shift(({int x, int y}) position) {
    if (_sourceIsHorizontal) {
      final x = position.x + source.axisSign;
      if (_targetIsHorizontal) return (x: x, y: position.y);
      return (x: x, y: position.y - target.axisSign);
    }
    // Mermaid's architecture grid has positive y upward, opposite to the
    // renderer's screen-coordinate direction convention.
    final y = position.y - source.axisSign;
    if (!_targetIsHorizontal) return (x: position.x, y: y);
    return (x: position.x - target.axisSign, y: y);
  }

  @override
  bool operator ==(Object other) => other is _DirectionPair && source == other.source && target == other.target;

  @override
  int get hashCode => Object.hash(source, target);
}
