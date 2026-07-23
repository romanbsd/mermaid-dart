import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('sequence rendering', () {
    test('lays out participants, lifelines, messages, notes, blocks, and activations', () {
      final scene = layoutDiagram(
        parse(DiagramType.sequence, '''
sequenceDiagram
participant Client
participant API
Client->>+API: Request
alt accepted
  API-->>Client: Response
else rejected
  API--xClient: Error
end
Note right of API: Handles requests
deactivate API
'''),
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final labels = elements.whereType<SceneText>().map((element) => element.text);

      expect(scene.diagramType, DiagramType.sequence);
      expect(elements.where((element) => element.cssClasses.contains('sequence-participant')), hasLength(4));
      expect(elements.where((element) => element.cssClasses.contains('sequence-lifeline')), hasLength(2));
      expect(elements.where((element) => element.cssClasses.contains('sequence-message-line')), hasLength(3));
      expect(elements.where((element) => element.cssClasses.contains('sequence-activation')), hasLength(1));
      expect(elements.where((element) => element.cssClasses.contains('sequence-block')), hasLength(4));
      expect(elements.where((element) => element.cssClasses.contains('sequence-block-label-box')), hasLength(1));
      expect(elements.where((element) => element.cssClasses.contains('sequence-note')), hasLength(1));
      expect(
        labels,
        containsAll(['Client', 'API', 'Request', '[accepted]', 'Response', '[rejected]', 'Error', 'Handles requests']),
      );
      expect(scene.bounds.height, greaterThan(scene.bounds.width / 2));
    });

    test('honors typed actor spacing and mirror options', () {
      final source = 'sequenceDiagram\nparticipant A\nparticipant B\nA->>B: hello\n';
      final mirrored = layoutDiagram(
        parse(DiagramType.sequence, source),
        options: const RenderOptions(padding: 0, sequence: SequenceRenderOptions(actorMargin: 120)),
      );
      final unmirrored = layoutDiagram(
        parse(DiagramType.sequence, source),
        options: const RenderOptions(padding: 0, sequence: SequenceRenderOptions(actorMargin: 20, mirrorActors: false)),
      );

      expect(
        _flatten(mirrored.elements).where((element) => element.cssClasses.contains('sequence-participant')),
        hasLength(4),
      );
      expect(
        _flatten(unmirrored.elements).where((element) => element.cssClasses.contains('sequence-participant')),
        hasLength(2),
      );
      expect(mirrored.bounds.width, greaterThan(unmirrored.bounds.width));
    });
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element is SceneGroup) yield* _flatten(element.children);
  }
}
