import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

import 'support/svg_golden.dart';

const _requestLifecycleSource = '''
---
title: Request lifecycle
---
flowchart LR
accTitle: Request lifecycle flowchart
accDescr: A request passes through authorization and application services
Client([Client]) -->|request| Gateway{Authorized?}
subgraph services [Services]
  direction TB
  Gateway --> API[API]
  API ==> Database[(Database)]
end
Gateway -. denied .-> Error((Denied))
classDef success fill:#d5f5e3,stroke:#1e8449,color:#145a32
class API,Database success
''';

void main() {
  group('flowchart rendering', () {
    test('lays out nodes, edges, labels, and arrowheads as a geometry-complete scene', () {
      final scene = layoutDiagram(
        parse(DiagramType.flowchart, 'flowchart LR\nA[Start] -->|next| B{Ready?}\nB --> C((Done))\n'),
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final nodes = elements.where((element) => element.role == SemanticRole.node).toList();
      final edges = elements.where((element) => element.role == SemanticRole.edge).toList();
      final labels = elements.whereType<SceneText>().map((element) => element.text);

      expect(scene.diagramType, DiagramType.flowchart);
      expect(nodes, hasLength(3));
      expect(edges, hasLength(greaterThanOrEqualTo(4)));
      expect(labels, containsAll(['Start', 'Ready?', 'Done', 'next']));
      expect(scene.bounds.width, greaterThan(scene.bounds.height));
    });

    test('honors top-down direction and typed spacing options', () {
      final scene = layoutDiagram(
        parse(DiagramType.flowchart, 'graph TD\nA --> B --> C\n'),
        options: const RenderOptions(padding: 0, flowchart: FlowchartRenderOptions(nodeSpacing: 80, rankSpacing: 120)),
      );
      final nodeBounds = _flatten(scene.elements)
          .whereType<SceneRect>()
          .where((element) => element.role == SemanticRole.node)
          .map((element) => element.bounds)
          .toList();

      expect(nodeBounds, hasLength(3));
      expect(nodeBounds[1].top - nodeBounds[0].top, greaterThanOrEqualTo(120));
      expect(nodeBounds[2].top - nodeBounds[1].top, greaterThanOrEqualTo(120));
    });

    test('uses the subgraph direction and matches the request lifecycle golden', () {
      final scene = layoutDiagram(
        parse(DiagramType.flowchart, _requestLifecycleSource),
        options: const RenderOptions(padding: 0),
      );
      final labels = {
        for (final text in _flatten(scene.elements).whereType<SceneText>())
          if (text.cssClasses.contains('flowchart-node-label')) text.text: text.position,
      };

      expect(labels['Authorized?']?.x, closeTo(labels['API']!.x, .001));
      expect(labels['API']?.x, closeTo(labels['Database']!.x, .001));
      expect(labels['Authorized?']!.y, lessThan(labels['API']!.y));
      expect(labels['API']!.y, lessThan(labels['Database']!.y));
      expect(
        _flatten(scene.elements).where((element) => element.cssClasses.contains('flowchart-subgraph')),
        hasLength(1),
      );
      final title = _flatten(
        scene.elements,
      ).whereType<SceneText>().singleWhere((element) => element.cssClasses.contains('flowchart-title'));
      final edges = _flatten(
        scene.elements,
      ).whereType<ScenePath>().where((element) => element.cssClasses.contains('flowchart-edge'));

      expect(scene.bounds.top, -50);
      expect(title.position.y, -25);
      expect(title.baseline, TextBaseline.alphabetic);
      expect(title.style.fontSize, 18);
      expect(edges.where((edge) => edge.commands.any((command) => command is CubicTo)), isNotEmpty);
      expectSvgGolden('flowchart_request_lifecycle', renderSvg(scene));
    });
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element is SceneGroup) yield* _flatten(element.children);
  }
}
