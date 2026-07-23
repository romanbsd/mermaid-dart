import 'package:collection/collection.dart';

import '../../parser/ast.dart';
import '../options.dart';
import '../scene.dart';

const _eventModelLaneBandSize = 100;
const _eventModelNamespaceSegmentCount = 2;

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
  SceneTextStyle textStyle, {
  EventModelingTheme theme = const EventModelingTheme(),
}) {
  final lanesByIndex = <int, EventModelLane>{};
  final boxes = <EventModelBox>[];
  final relations = <EventModelRelation>[];
  final latestBoxByFrameName = <String, EventModelBox>{};
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
        y: 0,
        height: options.swimlaneMinHeight,
        maxHeight: options.swimlaneMinHeight,
      ),
    );
    final text = _frameText(frame, ast.dataEntities);
    final measured = measurer.measure(text, textStyle);
    final width = _eventModelBoxDimension(
      measured.width,
      minimum: options.boxMinWidth,
      maximum: options.boxMaxWidth,
      padding: options.boxPadding,
    );
    final height = _eventModelBoxDimension(
      measured.height,
      minimum: options.boxMinHeight,
      maximum: options.boxMaxHeight,
      padding: options.boxPadding,
    );
    final previousBox = boxes.lastOrNull;
    final x = switch (previousBox) {
      null => options.contentStartX,
      _ when identical(previousLane, lane) && lane.right > 0 => lane.right + options.boxPadding,
      final box => box.bounds.right + options.boxPadding * 2 - options.boxOverlap,
    };
    final visual = _visualFor(frame.entityType, theme);
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
    latestBoxByFrameName[frame.name] = box;
    lane.right = box.bounds.right;
    lane.maxHeight = lane.maxHeight > height ? lane.maxHeight : height;
    lane.height =
        (options.swimlaneMinHeight > lane.maxHeight ? options.swimlaneMinHeight : lane.maxHeight) +
        options.swimlanePadding * 2;
    maxRight = maxRight > box.bounds.right + options.boxPadding ? maxRight : box.bounds.right + options.boxPadding;

    if (frame is! EventModelResetFrameAst && !(frameIndex == 0 && frame.sourceFrames.isEmpty)) {
      if (frame.sourceFrames.isNotEmpty) {
        for (final sourceName in frame.sourceFrames) {
          final source = latestBoxByFrameName[sourceName];
          if (source != null) relations.add(EventModelRelation(source: source, target: box));
        }
      } else {
        final source = boxes.reversed.skip(1).where((candidate) => candidate.lane.index != lane.index).firstOrNull;
        if (source != null) relations.add(EventModelRelation(source: source, target: box));
      }
    }
    previousLane = lane;
  }

  final lanes = lanesByIndex.values.toList()..sort((left, right) => left.index.compareTo(right.index));
  for (var i = 1; i < lanes.length; i++) {
    lanes[i].y = lanes[i - 1].y + lanes[i - 1].height + options.swimlaneGap;
  }
  final height = lanes.isEmpty ? 0.0 : lanes.last.y + lanes.last.height;
  return EventModelLayout(lanes: lanes, boxes: boxes, relations: relations, maxRight: maxRight, height: height);
}

({int index, String label, String? namespace}) _laneIdentity(EventModelFrameAst frame, Map<int, EventModelLane> lanes) {
  final namespace = _entityNamespace(frame.entityIdentifier);
  final (:lower, :label, :prefix) = frame.entityType._lane;
  final upper = lower + _eventModelLaneBandSize;
  if (namespace == null) return (index: lower, label: label, namespace: null);
  final occupied = lanes.keys.where((index) => index > lower && index < upper);
  final index = occupied.fold(lower, (maximum, value) => value > maximum ? value : maximum) + 1;
  return (index: index, label: '$prefix$namespace', namespace: namespace);
}

String? _entityNamespace(String identifier) {
  final parts = identifier.split('.');
  return parts.length == _eventModelNamespaceSegmentCount ? parts.first : null;
}

String _entityName(String identifier) {
  final parts = identifier.split('.');
  return parts.length == _eventModelNamespaceSegmentCount ? parts.last : identifier;
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

(Color, Color) _visualFor(EventModelEntityType type, EventModelingTheme theme) => switch (type) {
  EventModelEntityType.ui => (theme.uiFill, theme.uiStroke),
  EventModelEntityType.processor => (theme.processorFill, theme.processorStroke),
  EventModelEntityType.readModel => (theme.readModelFill, theme.readModelStroke),
  EventModelEntityType.command => (theme.commandFill, theme.commandStroke),
  EventModelEntityType.event => (theme.eventFill, theme.eventStroke),
};

double _eventModelBoxDimension(
  double measured, {
  required double minimum,
  required double maximum,
  required double padding,
}) => (measured + padding * 2).clamp(minimum, maximum) + padding * 2;

extension on EventModelEntityType {
  ({int lower, String label, String prefix}) get _lane => switch (this) {
    EventModelEntityType.ui || EventModelEntityType.processor => (lower: 0, label: 'UI/Automation', prefix: 'UI/A: '),
    EventModelEntityType.readModel ||
    EventModelEntityType.command => (lower: _eventModelLaneBandSize, label: 'Command/Read Model', prefix: 'C/RM: '),
    EventModelEntityType.event => (lower: _eventModelLaneBandSize * 2, label: 'Events', prefix: 'Stream: '),
  };
}
