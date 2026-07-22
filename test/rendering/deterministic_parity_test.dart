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

    test('treemap squarifies sorted values inside the root section', () {
      final scene = layoutDiagram(
        const TreemapAst(
          title: 'Revenue',
          rows: [
            TreemapNodeRowAst(indent: 0, item: TreemapSectionAst(name: 'Root')),
            TreemapNodeRowAst(indent: 2, item: TreemapLeafAst(name: 'Large', value: 3)),
            TreemapNodeRowAst(indent: 2, item: TreemapLeafAst(name: 'Small', value: 1)),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final leaves = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('treemapLeaf'))
          .toList();

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 960, height: 530));
      expect(leaves, hasLength(2));
      expect(leaves[0].label, 'Large');
      expect(leaves[0].bounds, const Bounds(left: 10, top: 65, width: 703, height: 455));
      expect(leaves[1].bounds, const Bounds(left: 723, top: 65, width: 227, height: 455));
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('treemapValue'))
            .map((element) => element.text),
        ['3', '1'],
      );
      expectSvgGolden('treemap_squarified', renderSvg(scene));
    });

    test('treemap typed options hide values and preserve class selectors', () {
      final scene = layoutDiagram(
        const TreemapAst(
          rows: [
            TreemapNodeRowAst(indent: 0, item: TreemapSectionAst(name: 'Root')),
            TreemapNodeRowAst(
              indent: 2,
              item: TreemapLeafAst(name: 'Only', value: 10, classSelector: 'important'),
            ),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(
          padding: 0,
          treemap: TreemapRenderOptions(width: 400, height: 240, showValues: false),
        ),
      );
      final elements = _flatten(scene.elements).toList();
      final leaf = elements.whereType<SceneGroup>().singleWhere(
        (element) => element.cssClasses.contains('treemapLeafGroup'),
      );

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 400, height: 240));
      expect(leaf.cssClasses, contains('important'));
      expect(elements.whereType<SceneText>().where((element) => element.cssClasses.contains('treemapValue')), isEmpty);
    });

    test('treemap class definitions resolve into backend-neutral styles', () {
      final scene = layoutDiagram(
        const TreemapAst(
          rows: [
            TreemapClassDefAst(name: 'important', style: 'fill:#112233,stroke:#445566,color:#ffffff'),
            TreemapNodeRowAst(indent: 0, item: TreemapSectionAst(name: 'Root')),
            TreemapNodeRowAst(
              indent: 2,
              item: TreemapLeafAst(name: 'Only', value: 10, classSelector: 'important'),
            ),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final leaf = elements.whereType<SceneRect>().singleWhere((element) => element.cssClasses.contains('treemapLeaf'));
      final label = elements.whereType<SceneText>().singleWhere(
        (element) => element.cssClasses.contains('treemapLabel'),
      );

      expect(leaf.fill, const SolidFill(Color(17, 34, 51)));
      expect(leaf.stroke?.color, const Color(68, 85, 102));
      expect(label.style.color, const Color(255, 255, 255));
    });

    test('cynefin renders seeded boundaries, badges, and curved transitions', () {
      final ast = CynefinAst(
        title: 'Decision context',
        domains: const [
          CynefinDomainAst(
            domain: CynefinDomain.complex,
            items: [CynefinItemAst(label: 'Probe')],
          ),
          CynefinDomainAst(
            domain: CynefinDomain.confusion,
            items: [
              CynefinItemAst(label: 'One'),
              CynefinItemAst(label: 'Two'),
              CynefinItemAst(label: 'Three'),
              CynefinItemAst(label: 'Four'),
              CynefinItemAst(label: 'Five'),
            ],
          ),
        ],
        transitions: const [
          CynefinTransitionAst(from: CynefinDomain.complex, to: CynefinDomain.complicated, label: 'Pattern found'),
        ],
      );
      final scene = layoutDiagram(
        ast,
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0, cynefin: CynefinRenderOptions(seed: 42)),
      );
      final elements = _flatten(scene.elements).toList();
      final boundaries = elements.whereType<ScenePath>().where(
        (element) => element.cssClasses.contains('cynefinBoundary'),
      );
      final arrow = elements.whereType<ScenePath>().singleWhere(
        (element) => element.cssClasses.contains('cynefinArrowLine'),
      );
      final title = elements.whereType<SceneText>().singleWhere(
        (element) => element.cssClasses.contains('cynefinTitle'),
      );

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 880, height: 680));
      expect(boundaries, hasLength(2));
      expect(boundaries.every((path) => path.commands.whereType<CubicTo>().length == 7), isTrue);
      expect(
        elements.whereType<ScenePath>().singleWhere((element) => element.cssClasses.contains('cynefinCliff')).commands,
        hasLength(3),
      );
      expect(
        elements
            .whereType<ScenePath>()
            .singleWhere((element) => element.cssClasses.contains('cynefinConfusion'))
            .commands,
        hasLength(4),
      );
      expect(arrow.commands.whereType<QuadraticTo>(), hasLength(1));
      expect(
        elements.whereType<ScenePolygon>().where((element) => element.cssClasses.contains('cynefinArrowHead')),
        hasLength(1),
      );
      expect(
        elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('cynefinItem')),
        hasLength(4),
      );
      expect(
        elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('cynefinItemOverflow')),
        hasLength(1),
      );
      expect(title.position, const Point(440, 20));
      expectSvgGolden('cynefin_seeded', renderSvg(scene));
    });

    test('cynefin typed options support straight compact layouts', () {
      final scene = layoutDiagram(
        const CynefinAst(),
        textMeasurer: measurer,
        options: const RenderOptions(
          padding: 0,
          cynefin: CynefinRenderOptions(
            width: 400,
            height: 300,
            padding: 10,
            boundaryAmplitude: 0,
            showDomainDescriptions: false,
          ),
        ),
      );
      final elements = _flatten(scene.elements).toList();

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 420, height: 320));
      expect(
        elements
            .whereType<ScenePath>()
            .where((element) => element.cssClasses.contains('cynefinBoundary'))
            .expand((path) => path.commands)
            .whereType<CubicTo>()
            .every((command) => command.control1.x == command.control2.x || command.control1.y == command.control2.y),
        isTrue,
      );
      expect(
        elements.whereType<SceneText>().where((element) => element.cssClasses.contains('cynefinSubtitle')),
        isEmpty,
      );
    });

    test('event modeling uses Mermaid swimlanes, frame colors, and relations', () {
      final scene = layoutDiagram(
        const EventModelingAst(
          frames: [
            EventModelTimeFrameAst(
              name: 'screen',
              entityType: EventModelEntityType.ui,
              entityIdentifier: 'Sales.Checkout',
            ),
            EventModelTimeFrameAst(
              name: 'submit',
              entityType: EventModelEntityType.command,
              entityIdentifier: 'SubmitOrder',
              sourceFrames: ['screen'],
            ),
            EventModelTimeFrameAst(
              name: 'placed',
              entityType: EventModelEntityType.event,
              entityIdentifier: 'OrderPlaced',
            ),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final lanes = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('em-swimlane-background'))
          .toList();
      final boxes = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('em-box-rect'))
          .toList();
      final relations = elements
          .whereType<ScenePath>()
          .where((element) => element.cssClasses.contains('em-relation'))
          .toList();

      expect(lanes, hasLength(3));
      expect(lanes.map((lane) => lane.bounds.top), [0, 140, 280]);
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('em-swimlane-label'))
            .map((element) => element.text),
        ['UI/A: Sales', 'Command/Read Model', 'Events'],
      );
      expect(boxes.map((box) => box.bounds), [
        const Bounds(left: 250, top: 15, width: 120, height: 100),
        const Bounds(left: 300, top: 155, width: 150, height: 100),
        const Bounds(left: 380, top: 295, width: 150, height: 100),
      ]);
      expect(boxes.map((box) => box.fill), const [
        SolidFill(Color(255, 255, 255)),
        SolidFill(Color(188, 214, 254)),
        SolidFill(Color(255, 183, 120)),
      ]);
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('em-box-label'))
            .map((element) => element.text),
        ['Checkout', 'SubmitOrder', 'OrderPlaced'],
      );
      expect(relations, hasLength(2));
      expect(relations[0].commands, const [MoveTo(Point(330, 115)), LineTo(Point(350, 155))]);
      expect(relations[1].commands, const [MoveTo(Point(400, 255)), LineTo(Point(430, 295))]);
      expect(
        elements.whereType<ScenePolygon>().where((element) => element.cssClasses.contains('em-arrowhead')),
        hasLength(2),
      );
      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 555, height: 410));
      expectSvgGolden('event_modeling_swimlanes', renderSvg(scene));
    });

    test('event modeling typed options constrain measured frame geometry', () {
      final scene = layoutDiagram(
        const EventModelingAst(
          frames: [
            EventModelTimeFrameAst(
              name: 'one',
              entityType: EventModelEntityType.event,
              entityIdentifier: 'VeryLongEventName',
            ),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(
          padding: 0,
          eventModeling: EventModelingRenderOptions(
            contentStartX: 100,
            boxMinWidth: 60,
            boxMaxWidth: 100,
            boxPadding: 5,
            swimlanePadding: 10,
          ),
        ),
      );
      final elements = _flatten(scene.elements).toList();
      final box = elements.whereType<SceneRect>().singleWhere((element) => element.cssClasses.contains('em-box-rect'));

      expect(box.bounds, const Bounds(left: 100, top: 10, width: 110, height: 90));
      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 225, height: 110));
    });

    test('git graph renders typed commit shapes, parents, tags, and ordered branches', () {
      final ast = GitGraphAst(
        title: 'Release history',
        statements: const [
          GitGraphCommitAst(id: 'ZERO', tags: ['v1'], type: GitGraphCommitType.highlight),
          GitGraphBranchAst(name: 'feature', order: 2),
          GitGraphCommitAst(id: 'A', type: GitGraphCommitType.reverse),
          GitGraphCheckoutAst(branch: 'main'),
          GitGraphCommitAst(id: 'MAIN'),
          GitGraphMergeAst(branch: 'feature', id: 'M', tags: ['release']),
          GitGraphCherryPickAst(id: 'A'),
        ],
      );
      final scene = layoutDiagram(
        ast,
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0, gitGraph: GitGraphRenderOptions(rotateCommitLabel: false)),
      );
      final elements = _flatten(scene.elements).toList();

      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('git-branch-label'))
            .map((element) => element.text),
        ['main', 'feature'],
      );
      expect(
        elements.whereType<SceneLine>().where((element) => element.cssClasses.contains('git-branch-line')),
        hasLength(2),
      );
      expect(
        elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('git-commit-edge')),
        hasLength(6),
      );
      expect(
        elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('git-commit-highlight-outer')),
        hasLength(1),
      );
      expect(
        elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('git-commit-reverse-mark')),
        hasLength(1),
      );
      expect(
        elements.whereType<SceneCircle>().where((element) => element.cssClasses.contains('git-commit-merge-inner')),
        hasLength(1),
      );
      expect(
        elements.whereType<SceneCircle>().where((element) => element.cssClasses.contains('git-commit-cherry-outer')),
        hasLength(1),
      );
      expect(
        elements.whereType<ScenePolygon>().where((element) => element.cssClasses.contains('git-tag-background')),
        hasLength(3),
      );
      expect(
        elements.whereType<SceneText>().singleWhere((element) => element.cssClasses.contains('git-title')).text,
        'Release history',
      );
      expectSvgGolden('git_graph_history', renderSvg(scene));
    });

    test('git graph top-to-bottom and bottom-to-top reverse the history axis', () {
      const statements = [GitGraphCommitAst(id: 'A'), GitGraphBranchAst(name: 'feature'), GitGraphCommitAst(id: 'B')];
      List<Point> centers(GitGraphDirection direction) {
        final scene = layoutDiagram(
          GitGraphAst(direction: direction, statements: statements),
          textMeasurer: measurer,
          options: const RenderOptions(
            padding: 0,
            gitGraph: GitGraphRenderOptions(showBranches: false, showCommitLabel: false),
          ),
        );
        return _flatten(scene.elements)
            .whereType<SceneCircle>()
            .where((element) => element.cssClasses.contains('git-commit-normal'))
            .map((element) => element.center)
            .toList();
      }

      final topToBottom = centers(GitGraphDirection.topToBottom);
      final bottomToTop = centers(GitGraphDirection.bottomToTop);
      expect(topToBottom[0].y, lessThan(topToBottom[1].y));
      expect(bottomToTop[0].y, greaterThan(bottomToTop[1].y));
      expect(topToBottom.map((point) => point.x), bottomToTop.map((point) => point.x));
    });

    test('git graph parallel mode aligns sibling commits on the history axis', () {
      final scene = layoutDiagram(
        const GitGraphAst(
          statements: [
            GitGraphCommitAst(id: 'ROOT'),
            GitGraphBranchAst(name: 'feature'),
            GitGraphCommitAst(id: 'FEATURE'),
            GitGraphCheckoutAst(branch: 'main'),
            GitGraphCommitAst(id: 'MAIN'),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(
          padding: 0,
          gitGraph: GitGraphRenderOptions(showBranches: false, showCommitLabel: false, parallelCommits: true),
        ),
      );
      final commits = _flatten(
        scene.elements,
      ).whereType<SceneCircle>().where((element) => element.cssClasses.contains('git-commit-normal')).toList();

      expect(commits, hasLength(3));
      expect(commits[1].center.x, commits[2].center.x);
      expect(commits[1].center.y, isNot(commits[2].center.y));
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

    test('wardley projects coordinates inside padded axes and renders map semantics', () {
      final scene = layoutDiagram(
        const WardleyAst(
          title: 'Operating model',
          evolutionStages: [
            WardleyEvolutionStageAst(name: 'Genesis', boundary: .4),
            WardleyEvolutionStageAst(name: 'Product', boundary: 1),
          ],
          anchors: [WardleyAnchorAst(name: 'User', position: WardleyPositionAst(x: 10, y: 90))],
          components: [
            WardleyComponentAst(
              name: 'API',
              position: WardleyPositionAst(x: 50, y: 60),
              label: WardleyLabelAst(offsetX: -20, offsetY: 15),
              strategy: WardleyStrategy.build,
              inertia: true,
            ),
            WardleyComponentAst(
              name: 'Database',
              position: WardleyPositionAst(x: 80, y: 30),
              strategy: WardleyStrategy.buy,
            ),
          ],
          links: [
            WardleyLinkAst(
              from: 'API',
              to: 'Database',
              style: WardleyLinkStyle.dashed,
              flow: WardleyLinkFlow.bidirectional,
              label: 'depends',
            ),
          ],
          evolves: [WardleyEvolveAst(component: 'API', target: 90)],
          notes: [WardleyNoteAst(text: 'Watch this', position: WardleyPositionAst(x: 20, y: 80))],
          annotationsBox: WardleyPositionAst(x: 65, y: 85),
          annotations: [WardleyAnnotationAst(number: 1, position: WardleyPositionAst(x: 70, y: 50), text: 'Critical')],
          markers: [
            WardleyAcceleratorAst(name: 'Cloud', position: WardleyPositionAst(x: 15, y: 75)),
            WardleyDeacceleratorAst(name: 'Legacy', position: WardleyPositionAst(x: 60, y: 20)),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(
          padding: 0,
          wardley: WardleyRenderOptions(width: 500, height: 400, padding: 40, nodeRadius: 5, showGrid: true),
        ),
      );
      final elements = _flatten(scene.elements).toList();
      final nodes = elements
          .whereType<SceneCircle>()
          .where((element) => element.cssClasses.contains('wardley-component'))
          .toList();
      final axes = elements
          .whereType<SceneLine>()
          .where((element) => element.cssClasses.contains('wardley-axis'))
          .toList();
      final componentLabels = elements
          .whereType<SceneText>()
          .where((element) => element.cssClasses.contains('wardley-node-label'))
          .toList();

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 500, height: 400));
      expect(axes.map((axis) => (axis.start, axis.end)), [
        (const Point(40, 360), const Point(460, 360)),
        (const Point(40, 40), const Point(40, 360)),
      ]);
      expect(nodes.map((node) => node.center), [const Point(250, 168), const Point(376, 264)]);
      expect(componentLabels.singleWhere((label) => label.text == 'API').position, const Point(230, 183));
      expect(
        elements.whereType<SceneLine>().where((element) => element.cssClasses.contains('wardley-grid-line')),
        hasLength(6),
      );
      expect(
        elements
            .whereType<SceneLine>()
            .singleWhere((element) => element.cssClasses.contains('wardley-stage-boundary'))
            .start
            .x,
        208,
      );
      expect(
        elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('wardley-link')),
        hasLength(1),
      );
      expect(
        elements.whereType<ScenePolygon>().where((element) => element.cssClasses.contains('wardley-link-arrow')),
        hasLength(2),
      );
      expect(
        elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('wardley-trend')),
        hasLength(1),
      );
      expect(
        elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('wardley-marker')),
        hasLength(2),
      );
      expect(
        elements.whereType<SceneText>().singleWhere((element) => element.text == 'Watch this').position,
        const Point(124, 104),
      );
      expect(
        elements.whereType<SceneText>().singleWhere((element) => element.cssClasses.contains('wardley-title')).position,
        const Point(250, 20),
      );
      expectSvgGolden('wardley_semantics', renderSvg(scene));
    });

    test('wardley pipelines position their parent and filter child-to-parent links', () {
      final scene = layoutDiagram(
        const WardleyAst(
          components: [WardleyComponentAst(name: 'Platform', position: WardleyPositionAst(x: 50, y: 50))],
          pipelines: [
            WardleyPipelineAst(
              parent: 'Platform',
              components: [
                WardleyPipelineComponentAst(name: 'Queue', evolution: 30),
                WardleyPipelineComponentAst(name: 'Store', evolution: 70),
              ],
            ),
          ],
          links: [WardleyLinkAst(from: 'Queue', to: 'Platform', style: WardleyLinkStyle.solid)],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final pipelineBox = elements.whereType<SceneRect>().singleWhere(
        (element) => element.cssClasses.contains('wardley-pipeline-box'),
      );
      final parent = elements.whereType<SceneRect>().singleWhere(
        (element) => element.cssClasses.contains('wardley-pipeline-parent'),
      );

      expect(pipelineBox.bounds.left, closeTo(274.2, 1e-9));
      expect(pipelineBox.bounds.top, 288);
      expect(pipelineBox.bounds.width, closeTo(351.6, 1e-9));
      expect(pipelineBox.bounds.height, 24);
      expect(parent.bounds.center.x, 450);
      expect(parent.bounds.center.y, closeTo(286.4, 1e-9));
      expect(
        elements.whereType<SceneLine>().where(
          (element) => element.cssClasses.contains('wardley-pipeline-evolution-link'),
        ),
        hasLength(1),
      );
      expect(elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('wardley-link')), isEmpty);
    });
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element case SceneGroup(:final children)) yield* _flatten(children);
  }
}
