import 'package:collection/collection.dart';

import '../../parser/ast.dart';
import '../options.dart';
import '../scene.dart';

final class EventModelLayout {
  const EventModelLayout({
    required this.lanes,
    required this.boxes,
    required this.relations,
    required this.maxRight,
    required this.height,
  });

  final List<EventModelLane> lanes;
  final List<EventModelBox> boxes;
  final List<EventModelRelation> relations;
  final double maxRight;
  final double height;
}

final class EventModelLane {
  EventModelLane({
    required this.index,
    required this.label,
    required this.y,
    required this.height,
    required this.maxHeight,
    this.namespace,
    this.right = 0,
  });

  final int index;
  final String label;
  final String? namespace;
  double y;
  double height;
  double maxHeight;
  double right;
}

final class EventModelBox {
  const EventModelBox({
    required this.frame,
    required this.frameIndex,
    required this.lane,
    required this.bounds,
    required this.fill,
    required this.stroke,
    required this.text,
  });

  final EventModelFrameAst frame;
  final int frameIndex;
  final EventModelLane lane;
  final Bounds bounds;
  final Color fill;
  final Color stroke;
  final String text;
}

final class EventModelRelation {
  const EventModelRelation({required this.source, required this.target});

  final EventModelBox source;
  final EventModelBox target;
}

EventModelLayout layoutEventModel(
  EventModelingAst ast,
  EventModelingRenderOptions options,
  TextMeasurer measurer,
  SceneTextStyle textStyle,
) {
  final lanesByIndex = <int, EventModelLane>{};
  final boxes = <EventModelBox>[];
  final relations = <EventModelRelation>[];
  EventModelLane? previousLane;
  var maxRight = 0.0;

  for (var frameIndex = 0; frameIndex < ast.frames.length; frameIndex++) {
    final frame = ast.frames[frameIndex];
    final laneIdentity = _laneIdentity(frame, lanesByIndex);
    final lane = lanesByIndex.putIfAbsent(
      laneIdentity.index,
      () => EventModelLane(
        index: laneIdentity.index,
        label: laneIdentity.label,
        namespace: laneIdentity.namespace,
        y: laneIdentity.index * options.swimlaneMinHeight + options.swimlaneGap,
        height: options.swimlaneMinHeight,
        maxHeight: options.swimlaneMinHeight,
      ),
    );
    final text = _frameText(frame, ast.dataEntities);
    final measured = measurer.measure(text, textStyle);
    final containsData = text != _entityName(frame.entityIdentifier);
    final measuredWidth = containsData ? measured.width / 3 : measured.width;
    final width =
        (measuredWidth + options.boxPadding * 2).clamp(options.boxMinWidth, options.boxMaxWidth) +
        options.boxPadding * 2;
    final height =
        (measured.height + options.boxPadding * 2).clamp(options.boxMinHeight, options.boxMaxHeight) +
        options.boxPadding * 2;
    final previousBox = boxes.lastOrNull;
    final x = switch ((previousLane, lane.right, previousBox)) {
      (null, _, _) => options.contentStartX,
      (final previous?, final right, _) when identical(previous, lane) && right > 0 => right + options.boxPadding,
      (_, _, null) => options.contentStartX,
      (_, _, final box?) => box.bounds.right + options.boxPadding * 2 - options.boxOverlap,
    };
    final visual = _visualFor(frame.entityType);
    final box = EventModelBox(
      frame: frame,
      frameIndex: frameIndex,
      lane: lane,
      bounds: Bounds(left: x, top: 0, width: width, height: height),
      fill: visual.$1,
      stroke: visual.$2,
      text: text,
    );
    boxes.add(box);
    lane.right = box.bounds.right;
    lane.maxHeight = lane.maxHeight > height ? lane.maxHeight : height;
    lane.height =
        (options.swimlaneMinHeight > lane.maxHeight ? options.swimlaneMinHeight : lane.maxHeight) +
        options.swimlanePadding * 2;
    maxRight = maxRight > box.bounds.right + options.boxPadding ? maxRight : box.bounds.right + options.boxPadding;

    if (frame is! EventModelResetFrameAst && !(frameIndex == 0 && frame.sourceFrames.isEmpty)) {
      if (frame.sourceFrames.isNotEmpty) {
        for (final sourceName in frame.sourceFrames) {
          final source = boxes.where((candidate) => candidate.frame.name == sourceName).lastOrNull;
          if (source != null) relations.add(EventModelRelation(source: source, target: box));
        }
      } else {
        final source = boxes.reversed.skip(1).where((candidate) => candidate.lane.index != lane.index).firstOrNull;
        if (source != null) relations.add(EventModelRelation(source: source, target: box));
      }
    }
    previousLane = lane;

    final sorted = lanesByIndex.values.toList()..sort((left, right) => left.index.compareTo(right.index));
    if (sorted.isNotEmpty) sorted.first.y = 0;
    for (var i = 1; i < sorted.length; i++) {
      sorted[i].y = sorted[i - 1].y + sorted[i - 1].height + options.swimlaneGap;
    }
  }

  final lanes = lanesByIndex.values.toList()..sort((left, right) => left.index.compareTo(right.index));
  final height = lanes.isEmpty ? 0.0 : lanes.last.y + lanes.last.height;
  return EventModelLayout(lanes: lanes, boxes: boxes, relations: relations, maxRight: maxRight, height: height);
}

({int index, String label, String? namespace}) _laneIdentity(EventModelFrameAst frame, Map<int, EventModelLane> lanes) {
  final namespace = _entityNamespace(frame.entityIdentifier);
  if (namespace != null) {
    final existing = lanes.values.where((lane) => lane.namespace == namespace).firstOrNull;
    if (existing != null) return (index: existing.index, label: existing.label, namespace: namespace);
  }
  final (lower, upper, label, prefix) = switch (frame.entityType) {
    EventModelEntityType.ui || EventModelEntityType.processor => (0, 100, 'UI/Automation', 'UI/A: '),
    EventModelEntityType.readModel || EventModelEntityType.command => (100, 200, 'Command/Read Model', 'C/RM: '),
    EventModelEntityType.event => (200, 300, 'Events', 'Stream: '),
  };
  if (namespace == null) return (index: lower, label: label, namespace: null);
  final occupied = lanes.keys.where((index) => index > lower && index < upper);
  final index = occupied.fold(lower, (maximum, value) => value > maximum ? value : maximum) + 1;
  return (index: index, label: '$prefix$namespace', namespace: namespace);
}

String? _entityNamespace(String identifier) {
  final parts = identifier.split('.');
  return parts.length == 2 ? parts.first : null;
}

String _entityName(String identifier) {
  final parts = identifier.split('.');
  return parts.length == 2 ? parts.last : identifier;
}

String _frameText(EventModelFrameAst frame, List<EventModelDataEntityAst> dataEntities) {
  final name = _entityName(frame.entityIdentifier);
  var data = frame.dataInlineValue;
  if (frame.dataReference case final reference?) {
    data = dataEntities.where((entity) => entity.name == reference).firstOrNull?.value;
  }
  if (data == null) return name;
  final open = data.indexOf('{');
  final close = data.lastIndexOf('}');
  final content = (open >= 0 && close > open ? data.substring(open + 1, close) : data).trim();
  return content.isEmpty ? name : '$name\n\n$content';
}

(Color, Color) _visualFor(EventModelEntityType type) => switch (type) {
  EventModelEntityType.ui => (const Color(255, 255, 255), const Color(219, 218, 218)),
  EventModelEntityType.processor => (const Color(237, 179, 246), const Color(184, 140, 191)),
  EventModelEntityType.readModel => (const Color(211, 241, 162), const Color(163, 183, 50)),
  EventModelEntityType.command => (const Color(188, 214, 254), const Color(103, 154, 195)),
  EventModelEntityType.event => (const Color(255, 183, 120), const Color(193, 154, 15)),
};
