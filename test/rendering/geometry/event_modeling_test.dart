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
    test('reuses namespaced lanes and advances boxes horizontally', () {
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

      expect(layout.lanes, hasLength(1));
      expect(layout.lanes.single.label, 'UI/A: Sales');
      expect(layout.boxes.map((box) => box.bounds.left), [250, 360]);
      expect(layout.boxes.map((box) => box.bounds.width), [100, 100]);
      expect(layout.relations, isEmpty);
      expect(layout.maxRight, 470);
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
