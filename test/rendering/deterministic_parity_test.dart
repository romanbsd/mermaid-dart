import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

import 'support/svg_golden.dart';

final class _ExactTextMeasurer implements TextMeasurer {
  const _ExactTextMeasurer();

  @override
  Size measure(String text, SceneTextStyle style) {
    final lines = text.split('\n');
    return Size(lines.map((line) => line.runes.length).fold(0, (a, b) => a > b ? a : b) * 10, lines.length * 20);
  }
}

void main() {
  const measurer = _ExactTextMeasurer();

  group('Mermaid deterministic renderer parity', () {
    test('info uses Mermaid version-label geometry', () {
      final scene = layoutDiagram(
        const InfoAst(),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0, info: InfoRenderOptions(version: '11.9.0')),
      );
      final elements = _flatten(scene.elements).toList();
      final label = elements.whereType<SceneText>().single;

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 400, height: 100));
      expect(label.text, 'v11.9.0');
      expect(label.position, const Point(100, 40));
      expect(label.style.fontSize, 32);
      expect(label.cssClasses, contains('version'));
      expect(elements.whereType<SceneRect>(), isEmpty);
      expectSvgGolden('info_version', renderSvg(scene));
    });

    test('tree view aligns descriptions and sizes highlighted rows', () {
      final scene = layoutDiagram(
        const TreeViewAst(
          nodes: [
            TreeViewNodeAst(name: 'root', cssClass: 'highlight'),
            TreeViewNodeAst(name: 'child', indent: 2, description: 'details'),
            TreeViewNodeAst(name: 'peer', indent: 2, description: 'more'),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final descriptions = elements
          .whereType<SceneText>()
          .where((element) => element.cssClasses.contains('treeView-node-description'))
          .toList();
      final highlight = elements.whereType<SceneRect>().singleWhere(
        (element) => element.cssClasses.contains('treeView-highlight-bg'),
      );

      expect(descriptions.map((description) => description.position.x).toSet(), hasLength(1));
      expect(highlight.bounds.width, scene.bounds.width - 2);
      expect(
        elements.whereType<SceneLine>().where((element) => element.cssClasses.contains('treeView-node-line')),
        hasLength(4),
      );
      expect(elements.whereType<SceneCircle>(), isEmpty);
      expectSvgGolden('tree_descriptions', renderSvg(scene));
    });

    test('railroad uses Mermaid baselines, markers, and typed arcs', () {
      final scene = layoutDiagram(
        const RailroadAst(
          rules: [
            RailroadRuleAst(
              name: 'value',
              definition: RailroadChoiceAst([
                RailroadTerminalAst('yes'),
                RailroadOptionalAst(RailroadNonTerminalAst('name')),
              ]),
            ),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();

      expect(elements.whereType<SceneCircle>(), hasLength(2));
      expect(
        elements
            .whereType<SceneText>()
            .singleWhere((element) => element.cssClasses.contains('railroad-rule-name'))
            .text,
        'value =',
      );
      expect(elements.whereType<ScenePath>().expand((path) => path.commands).whereType<ArcTo>(), isNotEmpty);
      expect(
        elements.whereType<SceneGroup>().where((element) => element.cssClasses.contains('railroad-terminal')),
        hasLength(1),
      );
      expectSvgGolden('railroad_choice', renderSvg(scene));
    });

    test('packet splits blocks at row boundaries and shows bit labels', () {
      final scene = layoutDiagram(
        const PacketAst(blocks: [PacketRangeBlockAst(start: 0, end: 40, label: 'payload')]),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final blocks = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('packetBlock'))
          .toList();
      final bitLabels = elements
          .whereType<SceneText>()
          .where((element) => element.cssClasses.contains('packetByte'))
          .map((element) => element.text);

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 1026, height: 79));
      expect(blocks, hasLength(2));
      expect(blocks[0].bounds, const Bounds(left: 1, top: 5, width: 1019, height: 32));
      expect(blocks[1].bounds, const Bounds(left: 1, top: 42, width: 283, height: 32));
      expect(bitLabels, ['0', '31', '32', '40']);
      expectSvgGolden('packet_wrapped', renderSvg(scene));
    });

    test('packet applies typed sizing options and can hide bit labels', () {
      final scene = layoutDiagram(
        const PacketAst(blocks: [PacketRelativeWidthBlockAst(bits: 10, label: 'field')]),
        textMeasurer: measurer,
        options: const RenderOptions(
          padding: 0,
          packet: PacketRenderOptions(
            rowHeight: 20,
            bitWidth: 10,
            bitsPerRow: 8,
            showBits: false,
            paddingX: 2,
            paddingY: 3,
          ),
        ),
      );
      final elements = _flatten(scene.elements).toList();
      final blocks = elements.whereType<SceneRect>().toList();

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 82, height: 49));
      expect(blocks.map((block) => block.bounds.width), [78, 18]);
      expect(elements.whereType<SceneText>().where((element) => element.cssClasses.contains('packetByte')), isEmpty);
    });

    test('packet places its title below the final word like Mermaid', () {
      final scene = layoutDiagram(
        const PacketAst(
          title: 'Header',
          blocks: [PacketRangeBlockAst(start: 0, end: 40, label: 'payload')],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final title = _flatten(
        scene.elements,
      ).whereType<SceneText>().singleWhere((element) => element.cssClasses.contains('packetTitle'));

      expect(scene.bounds.height, 111);
      expect(title.position, const Point(513, 92.5));
    });

    test('pie filters sub-one-percent slices and places percentage labels', () {
      final scene = layoutDiagram(
        const PieAst(
          sections: [
            PieSectionAst(label: 'Large', value: 999),
            PieSectionAst(label: 'Tiny', value: 1),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();

      expect(
        elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('pieCircle')),
        hasLength(1),
      );
      expect(
        elements.whereType<SceneCircle>().where((element) => element.cssClasses.contains('pieOuterCircle')),
        hasLength(1),
      );
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('slice'))
            .map((element) => element.text),
        ['100%'],
      );
      expect(elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('legend')), hasLength(2));
      expectSvgGolden('pie_filtered', renderSvg(scene));
    });

    test('pie supports donut, highlight, and bottom legend options', () {
      final scene = layoutDiagram(
        const PieAst(
          sections: [
            PieSectionAst(label: 'A', value: 3),
            PieSectionAst(label: 'B', value: 1),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(
          padding: 0,
          pie: PieRenderOptions(donutHole: .4, legendPosition: PieLegendPosition.bottom, highlightSlice: 'A'),
        ),
      );
      final elements = _flatten(scene.elements).toList();
      final paths = elements.whereType<ScenePath>().toList();

      expect(scene.bounds.height, 494);
      expect(paths, hasLength(2));
      expect(paths.every((path) => path.commands.whereType<ArcTo>().length == 2), isTrue);
      expect(paths.first.cssClasses, contains('highlighted'));
    });

    test('pie owns its title position inside the chart frame', () {
      final scene = layoutDiagram(
        const PieAst(
          title: 'Share',
          sections: [PieSectionAst(label: 'A', value: 1)],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final title = _flatten(
        scene.elements,
      ).whereType<SceneText>().singleWhere((element) => element.cssClasses.contains('pieTitleText'));

      expect(scene.bounds.height, 450);
      expect(title.position, const Point(225, 25));
    });

    test('radar honors ticks and circular curve interpolation', () {
      final scene = layoutDiagram(
        const RadarAst(
          axes: [
            RadarAxisAst(name: 'a'),
            RadarAxisAst(name: 'b'),
            RadarAxisAst(name: 'c'),
          ],
          curves: [
            RadarCurveAst(
              name: 'first',
              label: 'First',
              entries: [RadarEntryAst(value: 2), RadarEntryAst(value: 4), RadarEntryAst(value: 3)],
            ),
          ],
          options: [RadarTicksOptionAst(3), RadarGraticuleOptionAst(RadarGraticule.circle)],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();

      expect(
        elements.whereType<SceneCircle>().where((element) => element.cssClasses.contains('radarGraticule')),
        hasLength(3),
      );
      final curve = elements.whereType<ScenePath>().singleWhere(
        (element) => element.cssClasses.contains('radarCurve-0'),
      );
      expect(curve.commands.whereType<CubicTo>(), hasLength(3));
      expect(
        elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('radarLegendBox-0')),
        hasLength(1),
      );
      expectSvgGolden('radar_circle', renderSvg(scene));
    });

    test('radar renders polygon graticules and can suppress its legend', () {
      final scene = layoutDiagram(
        const RadarAst(
          axes: [
            RadarAxisAst(name: 'a'),
            RadarAxisAst(name: 'b'),
            RadarAxisAst(name: 'c'),
          ],
          curves: [
            RadarCurveAst(
              name: 'one',
              entries: [RadarEntryAst(value: 1), RadarEntryAst(value: 3), RadarEntryAst(value: 5)],
            ),
          ],
          options: [
            RadarTicksOptionAst(2),
            RadarMinOptionAst(1),
            RadarMaxOptionAst(5),
            RadarShowLegendOptionAst(false),
            RadarGraticuleOptionAst(RadarGraticule.polygon),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();

      expect(
        elements.whereType<ScenePolygon>().where((element) => element.cssClasses.contains('radarGraticule')),
        hasLength(2),
      );
      expect(
        elements.whereType<ScenePolygon>().where((element) => element.cssClasses.contains('radarCurve-0')),
        hasLength(1),
      );
      expect(elements.whereType<ScenePath>(), isEmpty);
      expect(elements.whereType<SceneRect>().where((element) => element.role == SemanticRole.legend), isEmpty);
    });

    test('radar owns its title position in the top margin', () {
      final scene = layoutDiagram(
        const RadarAst(title: 'Capabilities'),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final title = _flatten(
        scene.elements,
      ).whereType<SceneText>().singleWhere((element) => element.cssClasses.contains('radarTitle'));

      expect(scene.bounds.height, 700);
      expect(title.position, const Point(350, 0));
    });
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element case SceneGroup(:final children)) yield* _flatten(children);
  }
}
