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

final class _MappedTextMeasurer implements TextMeasurer {
  const _MappedTextMeasurer(this.sizes);

  final Map<String, Size> sizes;

  @override
  Size measure(String text, SceneTextStyle style) => sizes[text] ?? const _ExactTextMeasurer().measure(text, style);
}

void main() {
  const measurer = _ExactTextMeasurer();

  group('Mermaid deterministic renderer parity', () {
    test('info defaults match the pinned Mermaid renderer', () {
      final scene = layoutDiagram(const InfoAst(), textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final label = _flatten(scene.elements).whereType<SceneText>().single;

      expect(label.text, 'v11.16.0');
      expect(label.baseline, TextBaseline.alphabetic);
      expect(label.style.fontFamily, '"trebuchet ms", verdana, arial, sans-serif');
    });

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
      final labels = elements
          .whereType<SceneText>()
          .where((element) => element.cssClasses.contains('treeView-node-label'))
          .toList();
      final lines = elements
          .whereType<SceneLine>()
          .where((element) => element.cssClasses.contains('treeView-node-line'))
          .toList();

      expect(labels.map((label) => label.text), ['/', 'root', 'child', 'peer']);
      expect(labels.map((label) => label.baseline), everyElement(TextBaseline.middle));
      expect(labels.map((label) => label.style.color), everyElement(TreeViewRenderOptions.defaultLabelColor));
      expect(descriptions.map((description) => description.position.x).toSet(), hasLength(1));
      expect(
        descriptions.map((description) => description.style.color),
        everyElement(TreeViewRenderOptions.defaultDescriptionColor),
      );
      expect(highlight.fill, const SolidFill(TreeViewRenderOptions.defaultHighlightBackground));
      expect(highlight.stroke, const SceneStroke(color: TreeViewRenderOptions.defaultHighlightStroke));
      expect(highlight.bounds.right, scene.bounds.width - 2);
      expect(lines, hasLength(6));
      expect(lines.map((line) => line.stroke?.color), everyElement(TreeViewRenderOptions.defaultLineColor));
      expect(lines.map((line) => line.stroke?.cap), everyElement(StrokeCap.butt));
      expect(lines.map((line) => line.stroke?.join), everyElement(StrokeJoin.miter));
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
      final ruleName = elements.whereType<SceneText>().singleWhere(
        (element) => element.cssClasses.contains('railroad-rule-name'),
      );
      final nodeLabels = elements.whereType<SceneText>().where((element) => element != ruleName);
      expect(ruleName.text, 'value =');
      expect(ruleName.style.fontSize, 16);
      expect(ruleName.style.fontFamily, '"trebuchet ms", verdana, arial, sans-serif');
      expect(ruleName.style.weight, FontWeight.bold);
      expect(ruleName.baseline, TextBaseline.alphabetic);
      expect(nodeLabels.map((label) => label.baseline), everyElement(TextBaseline.middle));
      expect(elements.whereType<ScenePath>().expand((path) => path.commands).whereType<ArcTo>(), isNotEmpty);
      final terminal = elements.whereType<SceneGroup>().singleWhere(
        (element) => element.cssClasses.contains('railroad-terminal'),
      );
      final terminalRect = terminal.children.whereType<SceneRect>().single;
      final terminalLabel = terminal.children.whereType<SceneText>().single;
      expect(terminalRect.fill, SolidFill(const Color(255, 255, 222)));
      expect(terminalRect.stroke?.color, const Color(238, 238, 188));
      expect(terminalLabel.style.color, const Color(0, 0, 33));
      final nonterminal = elements.whereType<SceneGroup>().singleWhere(
        (element) => element.cssClasses.contains('railroad-nonterminal'),
      );
      final nonterminalRect = nonterminal.children.whereType<SceneRect>().single;
      final nonterminalLabel = nonterminal.children.whereType<SceneText>().single;
      expect(nonterminalRect.fill, const SolidFill(Color(236, 236, 255)));
      expect(nonterminalRect.stroke?.color, const Color(199, 199, 241));
      expect(nonterminalLabel.style.color, const Color(19, 19, 0));
      final railStrokes = elements
          .whereType<ScenePath>()
          .where((element) => element.cssClasses.contains('railroad-line'))
          .map((element) => element.stroke);
      expect(railStrokes.map((stroke) => stroke?.cap), everyElement(StrokeCap.butt));
      expect(railStrokes.map((stroke) => stroke?.join), everyElement(StrokeJoin.miter));
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

      expect(scene.bounds, const Bounds(left: 10, top: 5, width: 980, height: 415));
      expect(leaves, hasLength(2));
      expect(leaves[0].label, 'Large');
      expect(leaves[0].bounds, const Bounds(left: 20, top: 100, width: 718, height: 310));
      expect(leaves[1].bounds, const Bounds(left: 748, top: 100, width: 232, height: 310));
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('treemapValue'))
            .map((element) => element.text),
        ['3', '1'],
      );
      expectSvgGolden('treemap_squarified', renderSvg(scene));
    });

    test('treemap matches Mermaid synthetic-root section geometry', () {
      final ast =
          parse(
                DiagramType.treemap,
                'treemap\n'
                '"Products"\n'
                '  "Large": 3\n'
                '  "Small": 1\n',
              )
              as TreemapAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final elements = _flatten(scene.elements).toList();
      final section = elements.whereType<SceneRect>().singleWhere(
        (element) => element.cssClasses.contains('treemapSection'),
      );
      final leaves = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('treemapLeaf'))
          .toList();
      final labels = elements.whereType<SceneText>().toList();

      expect(section.label, 'Products');
      expect(section.bounds, const Bounds(left: 10, top: 35, width: 980, height: 355));
      expect(section.fill, const SolidFill(Color(134, 134, 255, 153)));
      expect(section.stroke?.color, const Color(57, 57, 255, 102));
      expect(leaves.map((leaf) => leaf.bounds), const [
        Bounds(left: 20, top: 70, width: 718, height: 310),
        Bounds(left: 748, top: 70, width: 232, height: 310),
      ]);
      expect(leaves.map((leaf) => leaf.fill), everyElement(const SolidFill(Color(134, 134, 255, 77))));
      expect(leaves.map((leaf) => leaf.stroke?.color), everyElement(const Color(134, 134, 255)));
      expect(labels.map((label) => label.text), ['Products', '4', 'Large', '3', 'Small', '1']);
      expect(labels.map((label) => label.position), const [
        Point(16, 47.5),
        Point(980, 47.5),
        Point(379, 225),
        Point(379, 246),
        Point(864, 225),
        Point(864, 246),
      ]);
      expect(scene.bounds, const Bounds(left: 10, top: 35, width: 980, height: 355));
      expect(scene.viewport, const Bounds(left: 2, top: 27, width: 996, height: 371));
    });

    test('treemap preserves nested section geometry and custom styles', () {
      final ast =
          parse(
                DiagramType.treemap,
                'treemap-beta\n'
                '"Products"\n'
                '  "Electronics"\n'
                '    "Phones": 50\n'
                '    "Computers": 30\n'
                '  "Clothing":::important\n'
                '    "Men": 20\n'
                '    "Women": 20\n'
                'classDef important fill:#ff9966,stroke:#333333,color:#ffffff;\n',
              )
              as TreemapAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final elements = _flatten(scene.elements).toList();
      final sections = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('treemapSection'))
          .toList();
      final leaves = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('treemapLeaf'))
          .toList();
      final clothing = sections.singleWhere((section) => section.label == 'Clothing');

      expect(sections.map((section) => section.bounds), const [
        Bounds(left: 10, top: 35, width: 980, height: 355),
        Bounds(left: 20, top: 70, width: 637, height: 310),
        Bounds(left: 667, top: 70, width: 313, height: 310),
      ]);
      expect(leaves.map((leaf) => leaf.bounds), const [
        Bounds(left: 30, top: 105, width: 382, height: 265),
        Bounds(left: 422, top: 105, width: 225, height: 265),
        Bounds(left: 677, top: 105, width: 293, height: 128),
        Bounds(left: 677, top: 243, width: 293, height: 127),
      ]);
      expect(sections.map((section) => section.fill), const [
        SolidFill(Color(134, 134, 255, 153)),
        SolidFill(Color(255, 255, 120, 153)),
        SolidFill(Color(255, 153, 102, 153)),
      ]);
      expect(clothing.stroke?.color, const Color(51, 51, 51, 102));
      expect(leaves.map((leaf) => leaf.fill), const [
        SolidFill(Color(255, 255, 120, 77)),
        SolidFill(Color(255, 255, 120, 77)),
        SolidFill(Color(215, 255, 134, 77)),
        SolidFill(Color(215, 255, 134, 77)),
      ]);
      expect(elements.whereType<SceneText>().map((element) => (element.text, element.style.color)), const [
        ('Products', Color(255, 255, 255)),
        ('120', Color(255, 255, 255)),
        ('Electronics', Color(0, 0, 0)),
        ('80', Color(0, 0, 0)),
        ('Phones', Color(255, 255, 255)),
        ('50', Color(255, 255, 255)),
        ('Computers', Color(0, 0, 0)),
        ('30', Color(0, 0, 0)),
        ('Clothing', Color(255, 255, 255)),
        ('40', Color(255, 255, 255)),
        ('Men', Color(0, 0, 0)),
        ('20', Color(0, 0, 0)),
        ('Women', Color(0, 0, 0)),
        ('20', Color(0, 0, 0)),
      ]);
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.text == 'Clothing' || element.text == '40')
            .map((element) => element.style.color),
        everyElement(const Color(255, 255, 255)),
      );
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

      expect(scene.bounds, const Bounds(left: 10, top: 35, width: 380, height: 195));
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

      expect(leaf.fill, const SolidFill(Color(17, 34, 51, 77)));
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
      final subtitles = elements.whereType<SceneText>().where(
        (element) => element.cssClasses.contains('cynefinSubtitle'),
      );
      final confusion = elements.whereType<ScenePath>().singleWhere(
        (element) => element.cssClasses.contains('cynefinConfusion'),
      );
      final badges = elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('cynefinItem'));
      final domainLabels = elements.whereType<SceneText>().where(
        (element) => element.cssClasses.contains('cynefinDomainLabel'),
      );

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 880, height: 680));
      expect(boundaries, hasLength(2));
      expect(boundaries.every((path) => path.commands.whereType<CubicTo>().length == 7), isTrue);
      expect(boundaries.map((path) => path.stroke?.dashes), everyElement(const [6, 3]));
      expect(boundaries.map((path) => path.stroke?.cap), everyElement(StrokeCap.butt));
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
      expect(confusion.stroke?.width, 1.5);
      expect(confusion.stroke?.dashes, const [4, 2]);
      expect(
        elements.whereType<ScenePolygon>().where((element) => element.cssClasses.contains('cynefinArrowHead')),
        hasLength(1),
      );
      expect(
        elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('cynefinItem')),
        hasLength(4),
      );
      expect(badges.map((badge) => badge.stroke?.color), everyElement(const Color(51, 51, 51)));
      expect(
        elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('cynefinItemOverflow')),
        hasLength(1),
      );
      expect(title.position, const Point(440, 20));
      expect(domainLabels.map((label) => label.style.color), everyElement(const Color(19, 19, 0)));
      expect(subtitles.map((subtitle) => subtitle.style.fontSize), everyElement(11));
      expect(subtitles.map((subtitle) => subtitle.baseline), everyElement(TextBaseline.middle));
      expectSvgGolden('cynefin_seeded', renderSvg(scene));
    });

    test('cynefin defaults use Mermaid boundary amplitude and stable CLI seed', () {
      final scene = layoutDiagram(const CynefinAst(), textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final boundaries = _flatten(
        scene.elements,
      ).whereType<ScenePath>().where((element) => element.cssClasses.contains('cynefinBoundary')).toList();

      expect((boundaries[0].commands.first as MoveTo).point.x, closeTo(444.8574703261256, 1e-9));
      expect((boundaries[1].commands.first as MoveTo).point.y, closeTo(343.14857986569405, 1e-9));
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

    test('event modeling matches namespaced and reset-frame Mermaid geometry', () {
      final ast =
          parse(
                DiagramType.eventModeling,
                'eventmodeling\n'
                'timeframe 01 command Cart.Update\n'
                'tf 02 evt Cart.Updated ->> 01 `jsobj`{ a: b }\n'
                'resetframe 03 readmodel Cart.Items ->> 02\n',
              )
              as EventModelingAst;
      final scene = layoutDiagram(
        ast,
        textMeasurer: const _MappedTextMeasurer({
          'Update': Size(116, 20),
          'Updated\n\na: b': Size(204.33333333333334, 60),
          'Items': Size(103, 20),
        }),
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
      final relation = elements.whereType<ScenePath>().singleWhere(
        (element) => element.cssClasses.contains('em-relation'),
      );

      expect(lanes.map((lane) => lane.label), ['C/RM: Cart', 'C/RM: Cart', 'Stream: Cart']);
      expect(lanes.map((lane) => lane.bounds.top), [0, 140, 280]);
      expect(lanes.map((lane) => lane.bounds.width), everyElement(closeTo(678.3333333333334, 1e-9)));
      expect(boxes.map((box) => box.bounds), [
        const Bounds(left: 250, top: 15, width: 156, height: 100),
        const Bounds(left: 336, top: 295, width: 244.33333333333334, height: 100),
        const Bounds(left: 510.33333333333337, top: 155, width: 143, height: 100),
      ]);
      expect(relation.commands, const [MoveTo(Point(354, 115)), LineTo(Point(417.44444444444446, 295))]);
      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 678.3333333333334, height: 410));
      expect(scene.viewport, const Bounds(left: -30, top: -30, width: 738.3333333333334, height: 470));
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
      final highlight = elements.whereType<SceneRect>().singleWhere(
        (element) => element.cssClasses.contains('git-commit-highlight-outer'),
      );
      final commits = elements
          .whereType<SceneCircle>()
          .where(
            (element) =>
                element.cssClasses.contains('git-commit-normal') ||
                element.cssClasses.contains('git-commit-merge-outer') ||
                element.cssClasses.contains('git-commit-cherry-outer'),
          )
          .toList();

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
        [highlight.bounds.center, ...commits.map((commit) => commit.center)],
        const [Point(10, -2), Point(60, 48), Point(110, -2), Point(160, -2), Point(210, -2)],
      );
      expect(highlight.fill, const SolidFill(Color(19, 19, 0)));
      expect(
        elements
            .whereType<SceneRect>()
            .singleWhere((element) => element.cssClasses.contains('git-commit-highlight-inner'))
            .fill,
        const SolidFill(Color(236, 236, 255)),
      );
      expect(
        elements
            .whereType<ScenePath>()
            .singleWhere((element) => element.cssClasses.contains('git-commit-reverse-mark'))
            .stroke,
        const SceneStroke(color: Color(236, 236, 255), width: 3),
      );
      expect(
        elements
            .whereType<SceneCircle>()
            .singleWhere((element) => element.cssClasses.contains('git-commit-merge-inner'))
            .fill,
        const SolidFill(Color(236, 236, 255)),
      );
      expect(
        elements
            .whereType<SceneCircle>()
            .singleWhere((element) => element.cssClasses.contains('git-commit-cherry-outer'))
            .fill,
        const SolidFill(Color(51, 51, 51)),
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

    test('git graph matches Mermaid lane, branch-label, edge, and rotated-label geometry', () {
      final scene = layoutDiagram(
        const GitGraphAst(
          statements: [
            GitGraphCommitAst(id: 'A'),
            GitGraphBranchAst(name: 'develop'),
            GitGraphCommitAst(id: 'B'),
          ],
        ),
        textMeasurer: const _MappedTextMeasurer({
          'main': Size(35, 19),
          'develop': Size(56.421875, 19),
          'A': Size(5.90625, 11),
          'B': Size(5.671875, 11),
        }),
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final commits = elements
          .whereType<SceneCircle>()
          .where((element) => element.cssClasses.contains('git-commit-normal'))
          .toList();
      final branches = elements
          .whereType<SceneLine>()
          .where((element) => element.cssClasses.contains('git-branch-line'))
          .toList();
      final labels = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('git-branch-label-background'))
          .toList();
      final branchLabels = elements
          .whereType<SceneText>()
          .where((element) => element.cssClasses.contains('git-branch-label'))
          .toList();
      final commitLabelBackgrounds = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('git-commit-label-background'))
          .toList();
      final commitLabels = elements
          .whereType<SceneText>()
          .where((element) => element.cssClasses.contains('git-commit-label'))
          .toList();
      final edge = elements.whereType<ScenePath>().singleWhere(
        (element) => element.cssClasses.contains('git-commit-edge'),
      );
      final rotated = scene.elements.whereType<SceneGroup>().where(
        (element) => element.cssClasses.contains('git-commit-label-rotated'),
      );

      expect(commits.map((commit) => commit.center), const [Point(10, -2), Point(60, 88)]);
      expect(commits.map((commit) => commit.fill), const [SolidFill(Color(0, 0, 236)), SolidFill(Color(222, 222, 0))]);
      expect(commits.map((commit) => commit.stroke?.width), everyElement(1));
      expect(branches.map((branch) => (branch.start, branch.end)), const [
        (Point(0, -2), Point(100, -2)),
        (Point(0, 88), Point(100, 88)),
      ]);
      expect(
        branches.map((branch) => branch.stroke),
        everyElement(const SceneStroke(color: Color(51, 51, 51), dashes: [2])),
      );
      expect(labels.map((label) => label.bounds), const [
        Bounds(left: -88, top: -13.5, width: 53, height: 23),
        Bounds(left: -109.421875, top: 76.5, width: 74.421875, height: 23),
      ]);
      expect(edge.commands, const [
        MoveTo(Point(10, -2)),
        LineTo(Point(10, 68)),
        ArcTo(radiusX: 20, radiusY: 20, clockwise: false, end: Point(30, 88)),
        LineTo(Point(60, 88)),
      ]);
      expect(edge.stroke?.width, 8);
      expect(edge.stroke?.cap, StrokeCap.round);
      expect(branchLabels.map((label) => label.style.color), const [Color(255, 255, 255), Color(0, 0, 0)]);
      expect(
        commitLabelBackgrounds.map((label) => label.fill),
        everyElement(const SolidFill(Color(255, 255, 222, 128))),
      );
      expect(commitLabels.map((label) => label.style.color), everyElement(const Color(0, 0, 33)));
      expect(rotated, hasLength(2));
      final transforms = rotated.first.transforms;
      expect(transforms, hasLength(2));
      expect((transforms.first as Translate).x, closeTo(-13.544375, 1e-12));
      expect((transforms.first as Translate).y, closeTo(12.008125, 1e-12));
      expect(transforms.last, const Rotate(-45, center: Point(0, -2)));
      expect(scene.viewport.left, -117.421875);
      expect(scene.viewport.top, -21.5);
      expect(scene.viewport.width, 225.421875);
      expect(scene.viewport.height, closeTo(145.929443359375, 1e-5));
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

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 1026, height: 109));
      expect(blocks, hasLength(2));
      expect(blocks[0].bounds, const Bounds(left: 1, top: 15, width: 1019, height: 32));
      expect(blocks[1].bounds, const Bounds(left: 1, top: 62, width: 283, height: 32));
      expect(bitLabels, ['0', '31', '32', '40']);
      expectSvgGolden('packet_wrapped', renderSvg(scene));
    });

    test('packet applies Mermaid bit-label padding and middle baseline', () {
      final scene = layoutDiagram(
        const PacketAst(
          blocks: [
            PacketRangeBlockAst(start: 0, end: 7, label: 'Source'),
            PacketSingleBitBlockAst(bit: 8, label: 'Flag'),
            PacketRelativeWidthBlockAst(bits: 16, label: 'Payload'),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final labels = elements.whereType<SceneText>().where((element) => element.cssClasses.contains('packetLabel'));
      final blocks = elements.whereType<SceneRect>();

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 1026, height: 62));
      expect(blocks.map((block) => block.bounds.top), everyElement(15));
      expect(blocks.map((block) => block.fill), everyElement(const SolidFill(Color(239, 239, 239))));
      expect(blocks.map((block) => block.stroke?.color), everyElement(const Color(0, 0, 0)));
      expect(blocks.map((block) => block.stroke?.cap), everyElement(StrokeCap.butt));
      expect(blocks.map((block) => block.stroke?.join), everyElement(StrokeJoin.miter));
      expect(labels.map((label) => label.style.color), everyElement(const Color(0, 0, 0)));
      expect(labels.map((label) => label.baseline), everyElement(TextBaseline.middle));
      expect(labels.map((label) => label.style.fontSize), everyElement(12));
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('packetByte'))
            .map((element) => element.style.color),
        everyElement(const Color(51, 51, 51)),
      );
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('packetByte'))
            .map((element) => element.style.fontSize),
        everyElement(10),
      );
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

      expect(scene.bounds.height, 141);
      expect(title.position, const Point(513, 117.5));
      expect(title.style.fontSize, 14);
      expect(title.baseline, TextBaseline.middle);
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
      final slices = elements
          .whereType<ScenePath>()
          .where((element) => element.cssClasses.contains('pieCircle'))
          .toList();
      final outerCircle = elements.whereType<SceneCircle>().singleWhere(
        (element) => element.cssClasses.contains('pieOuterCircle'),
      );
      final legendBoxes = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('legend'))
          .toList();
      final legendText = elements
          .whereType<SceneText>()
          .where((element) => element.cssClasses.contains('legendText'))
          .toList();

      expect(slices, hasLength(1));
      expect(slices.single.fill, const SolidFill(Color(236, 236, 255, 179)));
      expect(slices.single.stroke?.color, const Color(0, 0, 0, 179));
      expect(outerCircle.stroke?.color, const Color(0, 0, 0));
      expect(outerCircle.stroke?.cap, StrokeCap.butt);
      expect(outerCircle.stroke?.join, StrokeJoin.miter);
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('slice'))
            .map((element) => (element.text, element.style.fontSize, element.baseline)),
        [('100%', 17, TextBaseline.alphabetic)],
      );
      expect(legendBoxes, hasLength(2));
      expect(legendBoxes.map((box) => box.fill), [
        const SolidFill(Color(236, 236, 255)),
        const SolidFill(Color(255, 255, 222)),
      ]);
      expect(legendBoxes.map((box) => box.stroke?.color), [const Color(236, 236, 255), const Color(255, 255, 222)]);
      expect(legendText.map((label) => label.style.color), everyElement(const Color(0, 0, 0)));
      expect(legendText.map((element) => element.style.fontSize), everyElement(17));
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
      expect(title.style.fontSize, 25);
      expect(title.baseline, TextBaseline.alphabetic);
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

      final graticules = elements
          .whereType<SceneCircle>()
          .where((element) => element.cssClasses.contains('radarGraticule'))
          .toList();
      expect(graticules, hasLength(3));
      expect(graticules.map((ring) => ring.fill), everyElement(const SolidFill(Color(222, 222, 222, 77))));
      expect(graticules.map((ring) => ring.stroke?.color), everyElement(const Color(222, 222, 222)));
      expect(graticules.map((ring) => ring.stroke?.width), everyElement(1));
      final axes = elements.whereType<SceneLine>().where((element) => element.cssClasses.contains('radarAxisLine'));
      expect(axes.map((axis) => axis.stroke?.color), everyElement(const Color(51, 51, 51)));
      expect(axes.map((axis) => axis.stroke?.width), everyElement(2));
      final curve = elements.whereType<ScenePath>().singleWhere(
        (element) => element.cssClasses.contains('radarCurve-0'),
      );
      expect(curve.commands.whereType<CubicTo>(), hasLength(3));
      expect(curve.fill, const SolidFill(Color(134, 134, 255, 128)));
      expect(curve.stroke?.color, const Color(134, 134, 255));
      final legendBox = elements.whereType<SceneRect>().singleWhere(
        (element) => element.cssClasses.contains('radarLegendBox-0'),
      );
      expect(legendBox.fill, const SolidFill(Color(134, 134, 255, 128)));
      expect(legendBox.stroke?.color, const Color(134, 134, 255));
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('radarAxisLabel'))
            .map((element) => element.style.fontSize),
        everyElement(12),
      );
      final legend = elements.whereType<SceneText>().singleWhere(
        (element) => element.cssClasses.contains('radarLegendText'),
      );
      expect(legend.style.fontSize, 12);
      expect(legend.baseline, TextBaseline.hanging);
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
        options: const RenderOptions(padding: 0, radar: RadarRenderOptions(seriesColors: [])),
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
      final stageBoundary = elements.whereType<SceneLine>().singleWhere(
        (element) => element.cssClasses.contains('wardley-stage-boundary'),
      );

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
      expect(stageBoundary.start.x, 208);
      expect(stageBoundary.stroke?.color, const Color(0, 0, 0, 204));
      expect(
        elements.whereType<SceneLine>().where((element) => element.cssClasses.contains('wardley-link')),
        hasLength(1),
      );
      expect(
        elements.whereType<ScenePolygon>().where((element) => element.cssClasses.contains('wardley-link-arrow')),
        hasLength(2),
      );
      expect(
        elements.whereType<SceneLine>().where((element) => element.cssClasses.contains('wardley-trend')),
        hasLength(1),
      );
      expect(elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('wardley-trend')), isEmpty);
      expect(
        elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('wardley-marker')),
        hasLength(2),
      );
      expect(
        elements.whereType<SceneText>().singleWhere((element) => element.text == 'Watch this').position,
        const Point(124, 104),
      );
      final title = elements.whereType<SceneText>().singleWhere(
        (element) => element.cssClasses.contains('wardley-title'),
      );
      expect(title.position, const Point(250, 20));
      expect(title.baseline, TextBaseline.central);
      final anchor = componentLabels.singleWhere((label) => label.text == 'User');
      expect(anchor.baseline, TextBaseline.central);
      expect(anchor.style.color, const Color(0, 0, 0));
      expect(
        elements
            .whereType<SceneCircle>()
            .singleWhere((element) => element.cssClasses.contains('wardley-build-overlay'))
            .stroke
            ?.color,
        const Color(0, 0, 0),
      );
      expect(
        componentLabels.where((label) => label.text != 'User').map((label) => label.baseline),
        everyElement(TextBaseline.alphabetic),
      );
      final linkLabelGroup = elements.whereType<SceneGroup>().singleWhere(
        (element) => element.cssClasses.contains('wardley-link-label-group'),
      );
      final linkLabelRotation = linkLabelGroup.transforms.single as Rotate;
      expect(linkLabelRotation.degrees, closeTo(37.31, .01));
      expect(
        elements.whereType<SceneText>().singleWhere((element) => element.text == 'Watch this').baseline,
        TextBaseline.alphabetic,
      );
      expect(
        elements
            .whereType<SceneText>()
            .where((element) => element.cssClasses.contains('wardley-marker-label'))
            .map((element) => element.baseline),
        everyElement(TextBaseline.alphabetic),
      );
      expectSvgGolden('wardley_semantics', renderSvg(scene));
    });

    test('wardley matches Mermaid line and text geometry', () {
      final ast =
          parse(
                DiagramType.wardley,
                'wardley-beta\n'
                'component API [0.6, 0.5]\n'
                'component Database [0.3, 0.8]\n'
                'API -> Database\n',
              )
              as WardleyAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final elements = _flatten(scene.elements).toList();
      final link = elements.whereType<SceneLine>().singleWhere(
        (element) => element.cssClasses.contains('wardley-link'),
      );
      final axisLabels = elements.whereType<SceneText>().where(
        (element) => element.cssClasses.contains('wardley-axis-label'),
      );
      final nodeLabels = elements.whereType<SceneText>().where(
        (element) => element.cssClasses.contains('wardley-node-label'),
      );
      final components = elements.whereType<SceneCircle>().where(
        (element) => element.cssClasses.contains('wardley-component'),
      );

      expect(link.start.x, closeTo(455.084, 1e-3));
      expect(link.start.y, closeTo(252.787, 1e-3));
      expect(link.end.x, closeTo(686.116, 1e-3));
      expect(link.end.y, closeTo(397.613, 1e-3));
      expect(link.stroke?.color, const Color(51, 51, 51));
      expect(components.map((component) => component.stroke?.color), everyElement(const Color(51, 51, 51)));
      expect(axisLabels.map((label) => label.style.color), everyElement(const Color(19, 19, 0)));
      expect(nodeLabels.map((label) => label.style.color), everyElement(const Color(19, 19, 0)));
      expect(elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('wardley-link')), isEmpty);
      expect(axisLabels.map((label) => label.baseline), everyElement(TextBaseline.alphabetic));
      expect(nodeLabels.map((label) => label.baseline), everyElement(TextBaseline.alphabetic));
      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 900, height: 600));
      expect(scene.viewport, const Bounds(left: 0, top: 0, width: 900, height: 600));
    });

    test('wardley keeps reverse dependency labels upright like Mermaid', () {
      final scene = layoutDiagram(
        const WardleyAst(
          components: [
            WardleyComponentAst(name: 'Right', position: WardleyPositionAst(x: 80, y: 50)),
            WardleyComponentAst(name: 'Left', position: WardleyPositionAst(x: 20, y: 50)),
          ],
          links: [WardleyLinkAst(from: 'Right', to: 'Left', style: WardleyLinkStyle.solid, label: 'reverse')],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final group = _flatten(
        scene.elements,
      ).whereType<SceneGroup>().singleWhere((element) => element.cssClasses.contains('wardley-link-label-group'));

      expect((group.transforms.single as Rotate).degrees, 360);
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

    test('architecture honors directional ports, alignments, and arrowheads', () {
      final scene = layoutDiagram(
        const ArchitectureAst(
          services: [
            ArchitectureServiceAst(id: 'api', icon: 'server', title: 'API'),
            ArchitectureServiceAst(id: 'worker', iconText: 'W', title: 'Worker'),
            ArchitectureServiceAst(id: 'db', title: 'Database'),
          ],
          edges: [
            ArchitectureEdgeAst(
              leftId: 'api',
              leftDirection: ArchitectureDirection.right,
              rightId: 'worker',
              rightDirection: ArchitectureDirection.left,
              rightArrow: true,
              title: 'calls',
            ),
            ArchitectureEdgeAst(
              leftId: 'worker',
              leftDirection: ArchitectureDirection.bottom,
              rightId: 'db',
              rightDirection: ArchitectureDirection.top,
            ),
          ],
          alignments: [
            ArchitectureAlignmentAst(direction: ArchitectureAlignmentDirection.row, members: ['api', 'worker']),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final nodes = elements.whereType<SceneGroup>().where(
        (element) => element.cssClasses.contains('architecture-service'),
      );
      final api = nodes.singleWhere((node) => node.label == 'API');
      final worker = nodes.singleWhere((node) => node.label == 'Worker');
      final apiPosition = (api.transforms.single as Translate);
      final workerPosition = (worker.transforms.single as Translate);
      final edge = elements.whereType<ScenePath>().firstWhere(
        (element) => element.cssClasses.contains('architecture-edge'),
      );

      expect(apiPosition.y, workerPosition.y);
      expect(apiPosition.x, lessThan(workerPosition.x));
      expect(edge.commands, [
        MoveTo(Point(apiPosition.x + 40, apiPosition.y)),
        LineTo(Point((apiPosition.x + workerPosition.x) / 2, apiPosition.y)),
        LineTo(Point(workerPosition.x - 40, workerPosition.y)),
      ]);
      expect(
        elements.whereType<ScenePolygon>().where((element) => element.cssClasses.contains('architecture-arrow')),
        hasLength(1),
      );
      expect(
        elements.whereType<SceneText>().singleWhere((element) => element.text == 'calls').position.y,
        apiPosition.y + const ArchitectureRenderOptions().fontSize,
      );
    });

    test('architecture matches Mermaid compound-group geometry', () {
      final scene = layoutDiagram(
        const ArchitectureAst(
          groups: [ArchitectureGroupAst(id: 'cloud', icon: 'cloud', title: 'Cloud')],
          services: [
            ArchitectureServiceAst(id: 'api', icon: 'server', title: 'API', parent: 'cloud'),
            ArchitectureServiceAst(id: 'db', icon: 'database', title: 'Database', parent: 'cloud'),
          ],
          edges: [
            ArchitectureEdgeAst(
              leftId: 'api',
              leftDirection: ArchitectureDirection.right,
              rightId: 'db',
              rightDirection: ArchitectureDirection.left,
              rightArrow: true,
            ),
          ],
        ),
        textMeasurer: measurer,
      );
      final elements = _flatten(scene.elements).toList();
      final group = elements.whereType<SceneRect>().singleWhere(
        (element) => element.cssClasses.contains('architecture-group'),
      );
      final services = elements
          .whereType<SceneGroup>()
          .where((element) => element.cssClasses.contains('architecture-service'))
          .toList();
      final api = services[0].transforms.single as Translate;
      final database = services[1].transforms.single as Translate;
      final edge = elements.whereType<ScenePath>().singleWhere(
        (element) => element.cssClasses.contains('architecture-edge'),
      );
      final arrow = elements.whereType<ScenePolygon>().singleWhere(
        (element) => element.cssClasses.contains('architecture-arrow'),
      );

      expect(group.bounds.left, closeTo(-142.84328288059254, 1e-9));
      expect(group.bounds.top, -25.5);
      expect(group.bounds.width, closeTo(365.6865657611851, 1e-9));
      expect(group.bounds.height, 182);
      expect(group.stroke, const SceneStroke(color: Color(199, 199, 241), width: 2, dashes: [8]));
      expect(api.x, closeTo(-60.34328288059254, 1e-9));
      expect(api.y, 57);
      expect(database.x, closeTo(140.34328288059251, 1e-9));
      expect(database.y, 57);
      final edgePoints = [
        (edge.commands[0] as MoveTo).point,
        (edge.commands[1] as LineTo).point,
        (edge.commands[2] as LineTo).point,
      ];
      expect(edgePoints.map((point) => point.x), [
        closeTo(-20.34328288059254, 1e-9),
        closeTo(40, 1e-9),
        closeTo(100.34328288059251, 1e-9),
      ]);
      expect(edgePoints.map((point) => point.y), everyElement(57));
      expect(edge.stroke?.cap, StrokeCap.butt);
      expect(edge.stroke?.join, StrokeJoin.miter);
      expect(arrow.points.first.x, closeTo(102.34328288059251, 1e-9));
      expect(arrow.points.first.y, 57);
      expect(scene.bounds, group.bounds);
      expect(scene.viewport.left, closeTo(-182.84328288059254, 1e-9));
      expect(scene.viewport.top, -65.5);
      expect(scene.viewport.width, closeTo(445.6865657611851, 1e-9));
      expect(scene.viewport.height, 262);
    });

    test('architecture typed spacing options control connected node distance', () {
      final scene = layoutDiagram(
        const ArchitectureAst(
          services: [
            ArchitectureServiceAst(id: 'a'),
            ArchitectureServiceAst(id: 'b'),
          ],
          edges: [
            ArchitectureEdgeAst(
              leftId: 'a',
              leftDirection: ArchitectureDirection.right,
              rightId: 'b',
              rightDirection: ArchitectureDirection.left,
            ),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(
          padding: 0,
          architecture: ArchitectureRenderOptions(iconSize: 40, nodeSeparation: 0, idealEdgeLengthMultiplier: 3),
        ),
      );
      final nodes = _flatten(
        scene.elements,
      ).whereType<SceneGroup>().where((element) => element.cssClasses.contains('architecture-service')).toList();
      final first = nodes[0].transforms.single as Translate;
      final second = nodes[1].transforms.single as Translate;

      expect(second.x - first.x, 120);
    });

    test('architecture encloses nested groups and routes group edges to their boundary', () {
      final scene = layoutDiagram(
        const ArchitectureAst(
          groups: [
            ArchitectureGroupAst(id: 'system', icon: 'cloud', title: 'System'),
            ArchitectureGroupAst(id: 'data', title: 'Data', parent: 'system'),
          ],
          services: [
            ArchitectureServiceAst(id: 'api', title: 'API', parent: 'system'),
            ArchitectureServiceAst(id: 'db', title: 'DB', parent: 'data'),
          ],
          junctions: [ArchitectureJunctionAst(id: 'split', parent: 'system')],
          edges: [
            ArchitectureEdgeAst(
              leftId: 'api',
              leftDirection: ArchitectureDirection.right,
              leftGroup: true,
              rightId: 'db',
              rightDirection: ArchitectureDirection.left,
              rightGroup: true,
            ),
          ],
        ),
        textMeasurer: measurer,
        options: const RenderOptions(padding: 0),
      );
      final elements = _flatten(scene.elements).toList();
      final groups = elements.whereType<SceneRect>().where(
        (element) => element.cssClasses.contains('architecture-group'),
      );
      final system = groups.singleWhere((group) => group.label == 'System');
      final data = groups.singleWhere((group) => group.label == 'Data');
      final edge = elements.whereType<ScenePath>().singleWhere(
        (element) => element.cssClasses.contains('architecture-edge'),
      );
      final services = elements
          .whereType<SceneGroup>()
          .where((element) => element.cssClasses.contains('architecture-service'))
          .toList();
      final api = services.singleWhere((service) => service.label == 'API').transforms.single as Translate;
      final database = services.singleWhere((service) => service.label == 'DB').transforms.single as Translate;
      final start = (edge.commands.first as MoveTo).point;
      final end = (edge.commands.last as LineTo).point;

      expect(system.bounds.left, lessThanOrEqualTo(data.bounds.left));
      expect(system.bounds.right, greaterThanOrEqualTo(data.bounds.right));
      expect(system.bounds.top, lessThan(data.bounds.top));
      expect(system.bounds.bottom, greaterThanOrEqualTo(data.bounds.bottom));
      expect(start.x, greaterThan(api.x));
      expect(start.x, lessThan(system.bounds.right));
      expect(end.x, lessThan(database.x));
      expect(end.x, lessThan(data.bounds.left));
      expect(
        elements.whereType<SceneRect>().where((element) => element.cssClasses.contains('architecture-junction')),
        hasLength(1),
      );
      expectSvgGolden('architecture_nested', renderSvg(scene));
    });

    test('architecture separates services across nested compound groups like Mermaid fCoSE', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'group api[API]\n'
                'group public[Public API] in api\n'
                'group private[Private API] in api\n'
                'service serv1(server)[Server] in public\n'
                'service serv2(server)[Server] in private\n'
                'service db(database)[Database] in private\n'
                'service gateway(internet)[Gateway] in api\n'
                'serv1:B -- T:serv2\n'
                'serv2:L -- R:db\n'
                'serv1:L -- R:gateway\n',
              )
              as ArchitectureAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final services = _flatten(scene.elements)
          .whereType<SceneGroup>()
          .where((element) => element.cssClasses.contains('architecture-service'))
          .map((service) => service.transforms.single as Translate)
          .toList();

      expect(services[1].y - services[0].y, closeTo(255.17247257587814, 1e-9));
      expect(services[1].x - services[2].x, closeTo(201.29653714581747, 1e-9));
      expect(services[0].x - services[3].x, closeTo(222.65023530391295, 1e-9));
    });

    test('architecture row alignments center a fan-in using Mermaid proof spacing', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'service src1(server)[Source 1]\n'
                'service src2(server)[Source 2]\n'
                'service src3(server)[Source 3]\n'
                'service proc(server)[Processor]\n'
                'src1:B --> T:proc\n'
                'src2:B --> T:proc\n'
                'src3:B --> T:proc\n'
                'align row src1 src2 src3\n',
              )
              as ArchitectureAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final services = _flatten(scene.elements)
          .whereType<SceneGroup>()
          .where((element) => element.cssClasses.contains('architecture-service'))
          .map((service) => service.transforms.single as Translate)
          .toList();

      expect(services.map((service) => service.y).take(3).toSet(), hasLength(1));
      expect(services[0].x, closeTo(-85.85889726241993, 1e-9));
      expect(services[1].x, closeTo(40.90168892184372, 1e-9));
      expect(services[2].x, closeTo(168.85889726241993, 1e-9));
      expect(services[3].x, closeTo(42.03541549731811, 1e-9));
      expect(services[3].y - services[0].y, closeTo(186.70164581351315, 1e-9));
    });

    test('architecture combines row and column constraints into a compound grid', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'group tier1(cloud)[Tier 1]\n'
                'service a1(server)[A1] in tier1\n'
                'service a2(server)[A2] in tier1\n'
                'service a3(server)[A3] in tier1\n'
                'group tier2(database)[Tier 2]\n'
                'service b1(database)[B1] in tier2\n'
                'service b2(database)[B2] in tier2\n'
                'service b3(database)[B3] in tier2\n'
                'a1:B --> T:b1\n'
                'a2:B --> T:b2\n'
                'a3:B --> T:b3\n'
                'align row a1 a2 a3\n'
                'align row b1 b2 b3\n'
                'align column a1 b1\n'
                'align column a2 b2\n'
                'align column a3 b3\n',
              )
              as ArchitectureAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final services = {
        for (final service in _flatten(
          scene.elements,
        ).whereType<SceneGroup>().where((element) => element.cssClasses.contains('architecture-service')))
          service.label!: service.transforms.single as Translate,
      };

      expect(services['A1']!.y, closeTo(services['A2']!.y, 1e-9));
      expect(services['A2']!.y, closeTo(services['A3']!.y, 1e-9));
      expect(services['B1']!.y, closeTo(services['B2']!.y, 1e-9));
      expect(services['B2']!.y, closeTo(services['B3']!.y, 1e-9));
      expect(services['A1']!.x, closeTo(services['B1']!.x, 1e-9));
      expect(services['A2']!.x, closeTo(services['B2']!.x, 1e-9));
      expect(services['A3']!.x, closeTo(services['B3']!.x, 1e-9));
      expect(services['A2']!.x - services['A1']!.x, closeTo(157.62032405276386, 1e-9));
      expect(services['B1']!.y - services['A1']!.y, closeTo(250.87339226640756, 1e-9));
    });

    test('architecture routes every sibling group boundary direction like Mermaid fCoSE', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'group left_group(cloud)[Left]\n'
                'group right_group(cloud)[Right]\n'
                'group top_group(cloud)[Top]\n'
                'group bottom_group(cloud)[Bottom]\n'
                'group center_group(cloud)[Center]\n'
                'service left_disk(disk)[Left disk] in left_group\n'
                'service right_disk(disk)[Right disk] in right_group\n'
                'service top_disk(disk)[Top disk] in top_group\n'
                'service bottom_disk(disk)[Bottom disk] in bottom_group\n'
                'service center_disk(disk)[Center disk] in center_group\n'
                'left_disk{group}:R --> L:center_disk{group}\n'
                'right_disk{group}:L --> R:center_disk{group}\n'
                'top_disk{group}:B --> T:center_disk{group}\n'
                'bottom_disk{group}:T --> B:center_disk{group}\n',
              )
              as ArchitectureAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final services = {
        for (final service in _flatten(
          scene.elements,
        ).whereType<SceneGroup>().where((element) => element.cssClasses.contains('architecture-service')))
          service.label!: service.transforms.single as Translate,
      };
      final edges = _flatten(
        scene.elements,
      ).whereType<ScenePath>().where((element) => element.cssClasses.contains('architecture-edge')).toList();

      expect(services['Center disk']!.x - services['Left disk']!.x, closeTo(242.9767601208352, 1e-9));
      expect(services['Right disk']!.x - services['Center disk']!.x, closeTo(241.3602280180233, 1e-9));
      expect(services['Center disk']!.y - services['Top disk']!.y, closeTo(242.97676012083514, 1e-9));
      expect(services['Bottom disk']!.y - services['Center disk']!.y, closeTo(241.36022801802325, 1e-9));

      final leftStart = (edges[0].commands.first as MoveTo).point;
      final topStart = (edges[2].commands.first as MoveTo).point;
      final bottomStart = (edges[3].commands.first as MoveTo).point;
      expect(leftStart.x - services['Left disk']!.x, 84);
      expect(topStart.y - services['Top disk']!.y, 102);
      expect(bottomStart.y - services['Bottom disk']!.y, -84);
    });

    test('architecture preserves fCoSE spacing and elbows in a mixed-axis component', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'service db(database)[Database]\n'
                'service s3(disk)[Storage]\n'
                'service serv1(server)[Server 1]\n'
                'service serv2(server)[Server 2]\n'
                'service disk(disk)[Disk]\n'
                'db:L -- R:s3\n'
                'serv1:L -- T:s3\n'
                'serv2:L -- B:s3\n'
                'serv1:T -- B:disk\n',
              )
              as ArchitectureAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final services = {
        for (final service in _flatten(
          scene.elements,
        ).whereType<SceneGroup>().where((element) => element.cssClasses.contains('architecture-service')))
          service.label!: service.transforms.single as Translate,
      };
      final edges = _flatten(
        scene.elements,
      ).whereType<ScenePath>().where((element) => element.cssClasses.contains('architecture-edge')).toList();

      expect(services['Database']!.x - services['Storage']!.x, closeTo(186.83865249837297, 1e-9));
      expect(services['Storage']!.y - services['Server 1']!.y, closeTo(126.62426221746131, 1e-9));
      expect(services['Server 2']!.y - services['Storage']!.y, closeTo(126.79396513402435, 1e-9));
      expect(services['Server 1']!.y - services['Disk']!.y, closeTo(200.58493229670734, 1e-9));

      final upperElbow = (edges[1].commands[1] as LineTo).point;
      final lowerElbow = (edges[2].commands[1] as LineTo).point;
      expect(upperElbow, Point(services['Storage']!.x, services['Server 1']!.y));
      expect(lowerElbow, Point(services['Storage']!.x, services['Server 2']!.y));
    });

    test('architecture renders dense directional meshes and Cytoscape-style edge labels', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'service servC(server)[Center]\n'
                'service servL(server)[Left]\n'
                'service servR(server)[Right]\n'
                'service servT(server)[Top]\n'
                'service servB(server)[Bottom]\n'
                'servC:L -[Label]-> R:servL\n'
                'servC:R -[Label]-> L:servR\n'
                'servC:T -[Label]-> B:servT\n'
                'servC:B -[Label]-> T:servB\n'
                'servL:T -[Label]-> L:servT\n'
                'servL:B -[Label]-> L:servB\n'
                'servR:T -[Label]-> R:servT\n'
                'servR:B -[Label]-> R:servB\n',
              )
              as ArchitectureAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final flattened = _flatten(scene.elements).toList();
      final services = {
        for (final service in flattened.whereType<SceneGroup>().where(
          (element) => element.cssClasses.contains('architecture-service'),
        ))
          service.label!: service.transforms.single as Translate,
      };
      final arrows = flattened.whereType<ScenePolygon>().where(
        (element) => element.cssClasses.contains('architecture-arrow'),
      );
      final transformedLabels = flattened
          .whereType<SceneGroup>()
          .where((element) => element.role == SemanticRole.label)
          .toList();

      expect(services['Center']!.x - services['Left']!.x, closeTo(177.17119140792983, 1e-9));
      expect(services['Right']!.x - services['Center']!.x, closeTo(177.17119140792983, 1e-9));
      expect(services['Center']!.y - services['Top']!.y, closeTo(177.17119140792983, 1e-9));
      expect(services['Bottom']!.y - services['Center']!.y, closeTo(177.17119140792983, 1e-9));
      expect(arrows, hasLength(8));
      expect(transformedLabels.where((label) => label.transforms.length == 2), hasLength(2));
      expect(transformedLabels.where((label) => label.transforms.length == 3), hasLength(4));
      expect(
        transformedLabels
            .where((label) => label.transforms.length == 3)
            .map((label) => (label.transforms.last as Rotate).degrees)
            .toSet(),
        {-45, 45},
      );
    });

    test('architecture bounds a junction spine and packs its companion group', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'group companion[Companion]\n'
                'service first(server)[First] in companion\n'
                'service second(server)[Second] in companion\n'
                'first:R -- L:second\n'
                'group hub[Hub]\n'
                'service firewall(server)[Firewall] in hub\n'
                'service server(server)[Server] in hub\n'
                'firewall:R -- L:server\n'
                'service db1(database)[DB1] in hub\n'
                'service db2(database)[DB2] in hub\n'
                'junction mid in hub\n'
                'server:B -- T:mid\n'
                'junction left in hub\n'
                'left:R -- L:mid\n'
                'left:B -- T:db1\n'
                'junction right in hub\n'
                'mid:R -- L:right\n'
                'right:B -- T:db2\n',
              )
              as ArchitectureAst;
      final scene = layoutDiagram(ast, textMeasurer: measurer, options: const RenderOptions(padding: 0));
      final flattened = _flatten(scene.elements).toList();
      final junctions = {
        for (final junction in flattened.whereType<SceneRect>().where(
          (element) => element.cssClasses.contains('architecture-junction'),
        ))
          junction.label!: junction.bounds.center,
      };
      final services = {
        for (final service in flattened.whereType<SceneGroup>().where(
          (element) => element.cssClasses.contains('architecture-service'),
        ))
          service.label!: service.transforms.single as Translate,
      };
      final groups = {
        for (final group in flattened.whereType<SceneRect>().where(
          (element) => element.cssClasses.contains('architecture-group'),
        ))
          group.label!: group.bounds,
      };

      expect(junctions['mid']!.x - junctions['left']!.x, closeTo(190.48260469994892, 1e-9));
      expect(junctions['right']!.x - junctions['mid']!.x, closeTo(179.1161888537045, 1e-9));
      expect(services['DB1']!.y - junctions['left']!.y, closeTo(201.68232195491382, 1e-9));
      expect(junctions['mid']!.y - services['Server']!.y, closeTo(208.83534648414917, 1e-9));
      expect(groups['Hub']!.left - groups['Companion']!.right, closeTo(118.04457915216253, 1e-9));
    });
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element case SceneGroup(:final children)) yield* _flatten(children);
  }
}
