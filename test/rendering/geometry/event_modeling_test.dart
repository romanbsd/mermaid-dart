import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart/src/rendering/geometry/event_modeling.dart';
import 'package:test/test.dart';

final class _ExactTextMeasurer implements TextMeasurer {
  const _ExactTextMeasurer();

  @override
  Size measure(String text, SceneTextStyle style) {
    final lines = text.split('\n');
    return Size(
      lines.map((line) => line.runes.length).fold(0, (left, right) => left > right ? left : right) * 10,
      lines.length * 20,
    );
  }
}

void main() {
  const measurer = _ExactTextMeasurer();
  const style = SceneTextStyle(weight: FontWeight.bold);

  group('layoutEventModel', () {
    test('allocates namespaced frames to distinct lanes like Mermaid', () {
      final layout = layoutEventModel(
        const EventModelingAst(
          frames: [
            EventModelTimeFrameAst(name: 'first', entityType: EventModelEntityType.ui, entityIdentifier: 'Sales.A'),
            EventModelTimeFrameAst(name: 'second', entityType: EventModelEntityType.ui, entityIdentifier: 'Sales.B'),
          ],
        ),
        const EventModelingRenderOptions(),
        measurer,
        style,
      );

      expect(layout.lanes, hasLength(2));
      expect(layout.lanes.map((lane) => lane.label), ['UI/A: Sales', 'UI/A: Sales']);
      expect(layout.lanes.map((lane) => lane.y), [0, 140]);
      expect(layout.boxes.map((box) => box.bounds.left), [250, 280]);
      expect(layout.boxes.map((box) => box.bounds.width), [100, 100]);
      expect(layout.relations, hasLength(1));
      expect(layout.relations.single.source, same(layout.boxes.first));
      expect(layout.relations.single.target, same(layout.boxes.last));
      expect(layout.maxRight, 390);
    });

    test('reset frames are positioned without creating relations', () {
      final layout = layoutEventModel(
        const EventModelingAst(
          frames: [
            EventModelTimeFrameAst(
              name: 'created',
              entityType: EventModelEntityType.event,
              entityIdentifier: 'Created',
            ),
            EventModelResetFrameAst(
              name: 'reset',
              entityType: EventModelEntityType.command,
              entityIdentifier: 'Reset',
              sourceFrames: ['created'],
            ),
          ],
        ),
        const EventModelingRenderOptions(),
        measurer,
        style,
      );

      expect(layout.boxes, hasLength(2));
      expect(layout.relations, isEmpty);
    });

    test('resolves data references into backend-neutral multiline text', () {
      final layout = layoutEventModel(
        const EventModelingAst(
          dataEntities: [EventModelDataEntityAst(name: 'payload', value: '{ "id": 7 }')],
          frames: [
            EventModelTimeFrameAst(
              name: 'created',
              entityType: EventModelEntityType.event,
              entityIdentifier: 'Order.Created',
              dataReference: 'payload',
            ),
          ],
        ),
        const EventModelingRenderOptions(),
        measurer,
        style,
      );

      expect(layout.boxes.single.text, 'Created\n\n"id": 7');
      expect(layout.boxes.single.lane.label, 'Stream: Order');
    });

    test('reflows downstream lanes after a later frame grows an earlier lane', () {
      final layout = layoutEventModel(
        const EventModelingAst(
          frames: [
            EventModelTimeFrameAst(name: 'screen', entityType: EventModelEntityType.ui, entityIdentifier: 'Screen'),
            EventModelTimeFrameAst(name: 'event', entityType: EventModelEntityType.event, entityIdentifier: 'Event'),
            EventModelTimeFrameAst(
              name: 'details',
              entityType: EventModelEntityType.ui,
              entityIdentifier: 'Details',
              dataInlineValue: 'one\ntwo\nthree',
            ),
          ],
        ),
        const EventModelingRenderOptions(
          boxMinHeight: 10,
          boxMaxHeight: 200,
          boxPadding: 5,
          swimlaneMinHeight: 50,
          swimlanePadding: 10,
          swimlaneGap: 10,
        ),
        measurer,
        style,
      );

      expect(layout.lanes.map((lane) => lane.height), [140, 70]);
      expect(layout.lanes.map((lane) => lane.y), [0, 150]);
      expect(layout.height, 220);
    });

    test('explicit sources resolve to the latest duplicate frame name', () {
      final layout = layoutEventModel(
        const EventModelingAst(
          frames: [
            EventModelTimeFrameAst(name: 'shared', entityType: EventModelEntityType.ui, entityIdentifier: 'Screen'),
            EventModelTimeFrameAst(name: 'shared', entityType: EventModelEntityType.event, entityIdentifier: 'Created'),
            EventModelTimeFrameAst(
              name: 'target',
              entityType: EventModelEntityType.command,
              entityIdentifier: 'Handle',
              sourceFrames: ['shared'],
            ),
          ],
        ),
        const EventModelingRenderOptions(),
        measurer,
        style,
      );

      expect(layout.relations.last.source, same(layout.boxes[1]));
      expect(layout.relations.last.target, same(layout.boxes[2]));
    });
  });
}
