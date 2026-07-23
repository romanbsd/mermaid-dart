import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Mermaid architecture icons', () {
    const resolver = ArchitectureIconResolver();

    test('provides every bundled Mermaid.js architecture icon', () {
      for (final reference in ['cloud', 'internet', 'server', 'database', 'disk']) {
        final geometry = resolver.resolve(reference);

        expect(geometry, isNotNull, reason: reference);
        expect(geometry!.bounds, const Bounds(left: 0, top: 0, width: 80, height: 80));
        expect(geometry.styledPaths, isNotEmpty);
        expect(geometry.styledPaths.first.fill, const SolidFill(Color(8, 126, 191)));
      }
    });

    test('layout resolves bundled icons before using a placeholder', () {
      final scene = layoutDiagram(
        parse(DiagramType.architecture, '''
architecture-beta
group cloud(cloud)[Cloud]
service gateway(internet)[Gateway] in cloud
service api(server)[API] in cloud
service db(database)[Database] in cloud
'''),
      );
      final icons = _flatten(scene.elements).whereType<SceneIcon>().toList();

      expect(icons, hasLength(4));
      expect(
        icons,
        everyElement(
          isA<SceneIcon>().having(
            (icon) => icon.geometry.styledPaths.first.fill,
            'blue Mermaid background',
            const SolidFill(Color(8, 126, 191)),
          ),
        ),
      );

      final svg = renderSvg(scene);
      expect(svg, contains('fill="#087ebf"'));
      expect(svg, contains('stroke="#ffffff"'));
    });
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element case SceneGroup(:final children)) yield* _flatten(children);
  }
}
