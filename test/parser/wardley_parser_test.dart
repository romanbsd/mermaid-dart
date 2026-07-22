import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('wardley parser', () {
    test('parses components, links, metadata, and enum-backed decorators', () {
      final ast =
          parse(DiagramType.wardley, '''wardley-beta
title Coordinate Handling
accTitle: Accessible map
component "Mobile App" [0.2, 0.4] label [-30, 20] (build) (inertia)
component real-time API [30.0, 50.0] (buy)
"Mobile App" +<> real-time API; constraint
''')
              as WardleyAst;

      expect(ast.title, 'Coordinate Handling');
      expect(ast.accessibilityTitle, 'Accessible map');
      expect(ast.components, const [
        WardleyComponentAst(
          name: 'Mobile App',
          position: WardleyPositionAst(x: 40, y: 20),
          label: WardleyLabelAst(offsetX: -30, offsetY: 20),
          inertia: true,
          strategy: WardleyStrategy.build,
        ),
        WardleyComponentAst(
          name: 'real-time API',
          position: WardleyPositionAst(x: 50, y: 30),
          strategy: WardleyStrategy.buy,
        ),
      ]);
      expect(ast.links, const [
        WardleyLinkAst(
          from: 'Mobile App',
          to: 'real-time API',
          style: WardleyLinkStyle.solid,
          flow: WardleyLinkFlow.bidirectional,
          label: 'constraint',
        ),
      ]);
    });

    test('parses size and evolution stages with boundaries and dual labels', () {
      final ast =
          parse(DiagramType.wardley, '''wardley-beta
size [1200, 900]
evolution Genesis@0.3 / Concept -> Custom@0.6 / Emerging -> Product -> Commodity@1.0
''')
              as WardleyAst;

      expect(ast.size, const WardleySizeAst(width: 1200, height: 900));
      expect(ast.evolutionStages, const [
        WardleyEvolutionStageAst(name: 'Genesis', secondName: 'Concept', boundary: 0.3),
        WardleyEvolutionStageAst(name: 'Custom', secondName: 'Emerging', boundary: 0.6),
        WardleyEvolutionStageAst(name: 'Product'),
        WardleyEvolutionStageAst(name: 'Commodity', boundary: 1.0),
      ]);
    });

    test('parses pipelines with normalized evolution and label offsets', () {
      final ast =
          parse(DiagramType.wardley, '''wardley-beta
component Data Store [0.5, 0.5]
pipeline Data Store {
  component real-time queue [0.3] label [-40, 20]
  component batch-loader [70.0]
}
''')
              as WardleyAst;

      expect(ast.pipelines, const [
        WardleyPipelineAst(
          parent: 'Data Store',
          components: [
            WardleyPipelineComponentAst(
              name: 'real-time queue',
              evolution: 30,
              label: WardleyLabelAst(offsetX: -40, offsetY: 20),
            ),
            WardleyPipelineComponentAst(name: 'batch-loader', evolution: 70),
          ],
        ),
      ]);
    });

    test('parses remaining positioned statements and trends', () {
      final ast =
          parse(DiagramType.wardley, '''wardley-beta
anchor on-call engineer [0.9, 0.95]
component Kettle [0.35, 0.43]
evolve Kettle 0.62
note "Critical decision" [0.25, 0.45]
annotations [0.10, 0.90]
annotation 1,[0.60, 0.65] "Critical component"
accelerator "Cloud Native" [0.20, 0.85]
deaccelerator "Legacy Data" [0.40, 0.35]
''')
              as WardleyAst;

      expect(ast.anchors, const [
        WardleyAnchorAst(name: 'on-call engineer', position: WardleyPositionAst(x: 95, y: 90)),
      ]);
      expect(ast.evolves, const [WardleyEvolveAst(component: 'Kettle', target: 62)]);
      expect(ast.notes, const [WardleyNoteAst(text: 'Critical decision', position: WardleyPositionAst(x: 45, y: 25))]);
      expect(ast.annotationsBox, const WardleyPositionAst(x: 90, y: 10));
      expect(ast.annotations, const [
        WardleyAnnotationAst(number: 1, position: WardleyPositionAst(x: 65, y: 60), text: 'Critical component'),
      ]);
      expect(ast.markers, const [
        WardleyAcceleratorAst(name: 'Cloud Native', position: WardleyPositionAst(x: 85, y: 20)),
        WardleyDeacceleratorAst(name: 'Legacy Data', position: WardleyPositionAst(x: 35, y: 40)),
      ]);
    });

    test('normalizes link styles, flow arrows, and label precedence', () {
      final ast =
          parse(DiagramType.wardley, '''wardley-beta
A -.-> B; dashed
B +'supply'<> C; ignored
C +< D
D --> E
''')
              as WardleyAst;

      expect(ast.links, const [
        WardleyLinkAst(from: 'A', to: 'B', style: WardleyLinkStyle.dashed, label: 'dashed'),
        WardleyLinkAst(
          from: 'B',
          to: 'C',
          style: WardleyLinkStyle.solid,
          flow: WardleyLinkFlow.bidirectional,
          label: 'supply',
        ),
        WardleyLinkAst(from: 'C', to: 'D', style: WardleyLinkStyle.solid, flow: WardleyLinkFlow.backward),
        WardleyLinkAst(from: 'D', to: 'E', style: WardleyLinkStyle.solid),
      ]);
    });

    test('preserves upstream no-space and hyphenated-name link behavior', () {
      final ast =
          parse(DiagramType.wardley, '''wardley-beta
component foo--bar [0.3, 0.4]
component baz- [0.6, 0.6]
foo--bar->baz-
''')
              as WardleyAst;

      expect(ast.components.map((component) => component.name), ['foo--bar', 'baz-']);
      expect(ast.links.single.from, 'foo--bar');
      expect(ast.links.single.to, 'baz-');
    });

    test('allows integer annotation coordinates but requires decimal entity coordinates', () {
      final ast =
          parse(DiagramType.wardley, '''wardley-beta
annotations [1, 0]
annotation 1,[1, 0] "Integer coordinates"
''')
              as WardleyAst;

      expect(ast.annotationsBox, const WardleyPositionAst(x: 0, y: 100));
      expect(ast.annotations.single.position, const WardleyPositionAst(x: 0, y: 100));
      expect(
        () => parse(DiagramType.wardley, 'wardley-beta\ncomponent A [1, 1]'),
        throwsA(isA<MermaidParseException>()),
      );
    });

    test('rejects malformed statements and coordinates outside the supported range', () {
      for (final source in [
        'wardley-beta\ncomponent A [0.5]',
        'wardley-beta\ncomponent A [101.0, 0.5]',
        'wardley-beta\npipeline Missing {\n}',
        'wardley-beta\ncomponent A [0.5, 0.5] (lease)',
      ]) {
        expect(() => parse(DiagramType.wardley, source), throwsA(isA<MermaidParseException>()));
      }
    });
  });
}
