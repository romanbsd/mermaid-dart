import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('timeline rendering', () {
    test('lays out sections, periods, events, and a timeline axis', () {
      final scene = layoutDiagram(
        parse(DiagramType.timeline, '''
timeline
  section Foundation
    Research : Interviews : Prototype
  section Launch
    Release : General availability
'''),
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();

      expect(scene.diagramType, DiagramType.timeline);
      expect(elements.where((element) => element.cssClasses.contains('timeline-section')), hasLength(2));
      expect(elements.where((element) => element.cssClasses.contains('timeline-period')), hasLength(2));
      expect(elements.where((element) => element.cssClasses.contains('timeline-event')), hasLength(3));
      expect(elements.where((element) => element.cssClasses.contains('timeline-axis')), hasLength(1));
      expect(
        elements.whereType<SceneText>().map((element) => element.text),
        containsAll(['Foundation', 'Research', 'Interviews', 'Prototype', 'Launch', 'Release']),
      );
    });

    test('TD direction uses Mermaid vertical columns and event connectors', () {
      const body = 'section One\nA : Event\nsection Two\nB : Event\n';
      final lr = layoutDiagram(
        parse(DiagramType.timeline, 'timeline LR\n$body'),
        options: const RenderOptions(padding: 0),
      );
      final td = layoutDiagram(
        parse(DiagramType.timeline, 'timeline TD\n$body'),
        options: const RenderOptions(padding: 0),
      );

      expect(lr.bounds.width, greaterThan(lr.bounds.height));
      final elements = _flatten(td.elements).toList();
      final axis = elements.whereType<SceneLine>().singleWhere(
        (element) => element.cssClasses.contains('timeline-axis'),
      );
      expect(axis.start.x, axis.end.x);
      expect(axis.start.y, lessThan(axis.end.y));
      final guides = elements.whereType<SceneLine>().where((element) => element.cssClasses.contains('timeline-guide'));
      expect(guides, hasLength(2));
      expect(guides.every((guide) => guide.start.y == guide.end.y), isTrue);
      final event = elements.firstWhere((element) => element.cssClasses.contains('timeline-event'));
      final eventBounds = sceneElementGeometryBounds(event)!;
      expect(eventBounds.width, 310);
      expect(eventBounds.height, closeTo(32.8, 0.001));
    });
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element is SceneGroup) yield* _flatten(element.children);
  }
}
