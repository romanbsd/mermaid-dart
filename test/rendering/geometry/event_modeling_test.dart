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
  });
}
