import 'dart:io';

import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('mindmap lays out shaped nodes, curved branches, labels, and icons', () {
    final scene = layoutDiagram(
      parse(DiagramType.mindmap, '''
mindmap
  root((Product))
    research[Research]
      interviews(Interviews)
    launch{{Launch}}
    ::icon(rocket)
'''),
      options: const RenderOptions(padding: 0),
      iconResolver: const PlaceholderIconResolver(),
    );
    final elements = _flatten(scene.elements).toList();

    expect(scene.diagramType, DiagramType.mindmap);
    expect(elements.where((element) => element.cssClasses.contains('mindmap-node')), hasLength(4));
    expect(elements.where((element) => element.cssClasses.contains('mindmap-edge')), hasLength(3));
    expect(elements.where((element) => element.cssClasses.contains('mindmap-icon')), hasLength(1));
    expect(
      elements.whereType<SceneText>().map((element) => element.text),
      containsAll(['Product', 'Research', 'Interviews', 'Launch']),
    );
    final edges = elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('mindmap-edge'));
    expect(edges.map((edge) => edge.stroke?.width), containsAll([11, 5]));
    expect(edges.map((edge) => edge.stroke?.color), isNot(contains(const Color(51, 51, 51))));
    expect(scene.bounds.width, greaterThan(0));
    expect(scene.bounds.height, greaterThan(0));
  });

  test('mindmap preserves Mermaid node geometry and branch styling', () {
    final scene = layoutDiagram(
      parse(DiagramType.mindmap, '''
mindmap
  root((Product))
    research[Research]
      interviews(Interviews)
      prototype(Prototype)
    launch{{Launch}}
      rollout)Rollout(
'''),
      options: const RenderOptions(padding: 0),
      textMeasurer: const _MindmapGoldenTextMeasurer(),
    );
    final elements = _flatten(scene.elements).toList();

    final root = elements.whereType<SceneCircle>().single;
    expect(root.radius, closeTo(37.453, 0.001));

    final rectangle = elements.whereType<SceneRect>().singleWhere(
      (element) => element.cssClasses.contains('mindmap-rectangle'),
    );
    expect(rectangle.bounds.width, closeTo(103.891, 0.001));
    expect(rectangle.bounds.height, 44);

    final rounded = elements
        .whereType<SceneRect>()
        .where((element) => element.cssClasses.contains('mindmap-roundedRectangle'))
        .toList();
    expect(rounded, hasLength(2));
    expect(rounded.map((element) => element.radiusX), everyElement(5));
    expect(rounded.map((element) => element.radiusY), everyElement(5));
    expect(rounded.map((element) => element.bounds.width), containsAll([104, closeTo(99.781, 0.001)]));
    expect(rounded.map((element) => element.bounds.height), everyElement(54));

    final hexagon = elements.whereType<ScenePolygon>().single;
    final hexagonWidth = hexagon.points.map((point) => point.x).reduce((a, b) => a < b ? a : b);
    final hexagonRight = hexagon.points.map((point) => point.x).reduce((a, b) => a > b ? a : b);
    expect(hexagonRight - hexagonWidth, closeTo(92.656, 0.001));

    final edges = elements
        .whereType<ScenePath>()
        .where((element) => element.cssClasses.contains('mindmap-edge'))
        .toList();
    expect(edges.map((edge) => edge.stroke?.width), containsAll([11, 5]));
    expect(edges.map((edge) => edge.fill), everyElement(const SolidFill(Color(255, 255, 255, 0))));
    expect(edges.map((edge) => edge.stroke?.color).toSet(), hasLength(2));
  });

  test('tracks the rich Mermaid.js force-layout golden', () {
    final golden = File('test/rendering/goldens/mindmap_product_mermaid.svg').readAsStringSync();

    expect(golden, contains('aria-roledescription="mindmap"'));
    expect(golden, contains('class="mindmapDiagram"'));
    for (final label in ['Product', 'Research', 'Interviews', 'Prototype', 'Launch', 'Rollout']) {
      expect(golden, contains(label), reason: 'missing $label');
    }
    expect(RegExp(r'id="my-svg-edge_').allMatches(golden), hasLength(5));
  });
}

final class _MindmapGoldenTextMeasurer implements TextMeasurer {
  const _MindmapGoldenTextMeasurer();

  static const _sizes = {
    'Product': Size(54.906, 24),
    'Research': Size(63.891, 24),
    'Interviews': Size(74, 24),
    'Prototype': Size(69.781, 24),
    'Launch': Size(50.656, 24),
    'Rollout': Size(50.359, 24),
  };

  @override
  Size measure(String text, SceneTextStyle style) => _sizes[text]!;
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element is SceneGroup) yield* _flatten(element.children);
  }
}
