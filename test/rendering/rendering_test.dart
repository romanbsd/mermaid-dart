import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('geometry-first rendering', () {
    test('architecture options expose Mermaid layout defaults', () {
      const options = ArchitectureRenderOptions();

      expect(options.randomize, isFalse);
      expect(options.edgeElasticity, 0.45);
      expect(options.numIter, 2500);
      expect(options.seed, 1);
    });

    test('architecture config font size affects layout but rendered labels use the theme font size', () {
      final scene = layoutDiagram(
        parse(DiagramType.architecture, 'architecture-beta\nservice api(server)[API]\n'),
        options: const RenderOptions(architecture: ArchitectureRenderOptions(fontSize: 14)),
      );
      final label = _flatten(scene.elements).whereType<SceneText>().singleWhere((element) => element.text == 'API');

      expect(label.style.fontSize, const MermaidTheme().fontSize);
    });

    test('event modeling config controls viewport padding while rowHeight remains compatibility-only', () {
      const ast = EventModelingAst(
        frames: [
          EventModelTimeFrameAst(name: '01', entityType: EventModelEntityType.command, entityIdentifier: 'Cart.Update'),
        ],
      );
      final defaultScene = layoutDiagram(ast, options: const RenderOptions(padding: 0));
      final configuredScene = layoutDiagram(
        ast,
        options: const RenderOptions(padding: 0, eventModeling: EventModelingRenderOptions(padding: 55, rowHeight: 48)),
      );
      final defaultFrame = _flatten(defaultScene.elements).whereType<SceneRect>().last;
      final configuredFrame = _flatten(configuredScene.elements).whereType<SceneRect>().last;

      expect(const EventModelingRenderOptions().padding, 30);
      expect(const EventModelingRenderOptions().rowHeight, 32);
      expect(configuredScene.viewport.left, -55);
      expect(configuredScene.viewport.top, -55);
      expect(configuredScene.bounds, defaultScene.bounds);
      expect(configuredFrame.bounds, defaultFrame.bounds);
    });

    test('Cynefin config controls canvas, descriptions, and deterministic boundaries', () {
      final ast = parse(DiagramType.cynefin, 'cynefin-beta\ncomplex "Probe"\ncomplicated "Analyze"\n');
      const cynefinOptions = CynefinRenderOptions(
        width: 720,
        height: 480,
        padding: 30,
        showDomainDescriptions: false,
        boundaryAmplitude: 0,
        seed: 42,
      );
      const options = RenderOptions(padding: 0, cynefin: cynefinOptions);
      final first = layoutDiagram(ast, options: options);
      final second = layoutDiagram(ast, options: options);
      final elements = _flatten(first.elements).toList();
      final boundaries = elements
          .whereType<ScenePath>()
          .where((element) => element.cssClasses.contains('cynefinBoundary'))
          .toList();
      final foldXCoordinates = [
        for (final command in boundaries.first.commands)
          ...switch (command) {
            MoveTo(:final point) => [point.x],
            CubicTo(:final control1, :final control2, :final end) => [control1.x, control2.x, end.x],
            _ => const <double>[],
          },
      ];
      final horizontalYCoordinates = [
        for (final command in boundaries.last.commands)
          ...switch (command) {
            MoveTo(:final point) => [point.y],
            CubicTo(:final control1, :final control2, :final end) => [control1.y, control2.y, end.y],
            _ => const <double>[],
          },
      ];

      expect(first.bounds, const Bounds(left: 0, top: 0, width: 780, height: 540));
      expect(first.elements, second.elements);
      expect(
        elements.whereType<SceneText>().where((element) => element.cssClasses.contains('cynefinSubtitle')),
        isEmpty,
      );
      expect(foldXCoordinates, everyElement(cynefinOptions.padding + cynefinOptions.width / 2));
      expect(horizontalYCoordinates, everyElement(cynefinOptions.padding + cynefinOptions.height / 2));
    });

    test('Railroad config controls shared layout geometry and paint', () {
      final scene = layoutDiagram(
        parse(
          DiagramType.railroad,
          'railroad-beta\n'
          'rule = sequence(terminal("a"), nonterminal("b"), special("c")) ;\n',
        ),
        options: const RenderOptions(
          padding: 0,
          railroad: RailroadRenderOptions(
            compactMode: true,
            padding: 12,
            verticalSeparation: 16,
            horizontalSeparation: 18,
            arcRadius: 6,
            fontSize: 18,
            fontFamily: 'monospace',
            terminalFill: Color(17, 34, 51),
            terminalStroke: Color(68, 85, 102),
            terminalTextColor: Color(119, 136, 153),
            nonTerminalFill: Color(170, 187, 204),
            nonTerminalStroke: Color(221, 238, 255),
            nonTerminalTextColor: Color(1, 35, 69),
            lineColor: Color(103, 137, 171),
            strokeWidth: 3,
            markerFill: Color(205, 239, 18),
            specialFill: Color(52, 86, 120),
            specialStroke: Color(154, 188, 222),
            ruleNameColor: Color(240, 225, 210),
            showMarkers: true,
            markerRadius: 7,
          ),
        ),
      );
      final elements = _flatten(scene.elements).toList();
      final terminal = elements.whereType<SceneRect>().singleWhere((element) => element.label == 'a');
      final nonTerminal = elements.whereType<SceneRect>().singleWhere((element) => element.label == 'b');
      final special = elements.whereType<SceneRect>().singleWhere((element) => element.label == '? c ?');
      final ruleName = elements.whereType<SceneText>().singleWhere((element) => element.text == 'rule =');
      final markers = elements.whereType<SceneCircle>().toList();
      final lines = elements.whereType<ScenePath>().where((element) => element.cssClasses.contains('railroad-line'));

      expect(terminal.fill, const SolidFill(Color(17, 34, 51)));
      expect(terminal.stroke?.color, const Color(68, 85, 102));
      expect(terminal.radiusX, 10);
      expect(nonTerminal.fill, const SolidFill(Color(170, 187, 204)));
      expect(nonTerminal.stroke?.color, const Color(221, 238, 255));
      expect(special.fill, const SolidFill(Color(52, 86, 120)));
      expect(special.stroke?.color, const Color(154, 188, 222));
      expect(special.stroke?.dashes, const [5, 3]);
      expect(ruleName.style.color, const Color(240, 225, 210));
      expect(ruleName.style.fontFamily, 'monospace');
      expect(ruleName.style.fontSize, 18);
      expect(lines.map((line) => line.stroke?.color), everyElement(const Color(103, 137, 171)));
      expect(lines.map((line) => line.stroke?.width), everyElement(3));
      expect(markers, hasLength(2));
      expect(markers.map((marker) => marker.fill), everyElement(const SolidFill(Color(205, 239, 18))));
      expect(markers.map((marker) => marker.radius), everyElement(7));
    });

    test('Wardley config controls canvas, grid, nodes, labels, and typography', () {
      final scene = layoutDiagram(
        parse(DiagramType.wardley, 'wardley-beta\ncomponent API [0.6, 0.5]\n'),
        options: const RenderOptions(
          wardley: WardleyRenderOptions(
            width: 720,
            height: 480,
            padding: 60,
            nodeRadius: 10,
            nodeLabelOffset: 14,
            axisFontSize: 14,
            labelFontSize: 12,
            showGrid: true,
          ),
        ),
      );
      final elements = _flatten(scene.elements).toList();
      final component = elements.whereType<SceneCircle>().singleWhere(
        (element) => element.cssClasses.contains('wardley-component'),
      );
      final nodeLabel = elements.whereType<SceneText>().singleWhere(
        (element) => element.cssClasses.contains('wardley-node-label'),
      );
      final axisLabels = elements.whereType<SceneText>().where(
        (element) => element.cssClasses.contains('wardley-axis-label'),
      );

      expect(scene.bounds, const Bounds(left: 0, top: 0, width: 720, height: 480));
      final gridLines = elements
          .whereType<SceneLine>()
          .where((element) => element.cssClasses.contains('wardley-grid-line'))
          .toList();
      expect(gridLines, hasLength(6));
      expect(gridLines.map((line) => line.stroke?.color), everyElement(const Color(211, 211, 211)));
      expect(component.radius, 10);
      expect(nodeLabel.position.x - component.center.x, 14);
      expect(nodeLabel.position.y - component.center.y, -14);
      expect(nodeLabel.style.fontSize, 12);
      expect(axisLabels.map((label) => label.style.fontSize), everyElement(14));
    });

    test('architecture seed is deterministic and inert without randomization', () {
      const source = '''architecture-beta
group sub1(cloud)[Subscription A]
group vnet1(cloud)[VNet A] in sub1
service vm1(server)[VM] in vnet1
group sub2(cloud)[Subscription B]
service web(server)[Web App] in sub2
service db(database)[Registry] in sub2
vm1:R --> L:web
web:R --> L:db
''';
      final ast = parse(DiagramType.architecture, source);
      const seededOptions = RenderOptions(architecture: ArchitectureRenderOptions(seed: 42));
      final first = layoutDiagram(ast, options: seededOptions);
      final second = layoutDiagram(ast, options: seededOptions);
      final defaultSeed = layoutDiagram(ast);
      final scaled = layoutDiagram(
        ast,
        options: const RenderOptions(
          architecture: ArchitectureRenderOptions(
            padding: 32,
            iconSize: 64,
            fontSize: 14,
            randomize: false,
            nodeSeparation: 60,
            idealEdgeLengthMultiplier: 1.2,
            edgeElasticity: 0.35,
            numIter: 1500,
            seed: 42,
          ),
        ),
      );
      final scaledPositions = _flatten(scaled.elements)
          .whereType<SceneGroup>()
          .where((element) => element.cssClasses.contains('architecture-service'))
          .map((element) => element.transforms.single as Translate)
          .toList();

      expect(first.viewport, second.viewport);
      expect(first.elements, second.elements);
      expect(first.bounds, defaultSeed.bounds);
      expect(first.elements, defaultSeed.elements);
      expect(scaledPositions[1].x - scaledPositions[0].x, closeTo(265.4381847126528, 1e-9));
      expect(scaledPositions[2].x - scaledPositions[1].x, closeTo(142.98082659872362, 1e-9));
    });

    test('architecture compounds preserve cross-boundary gateway spacing', () {
      const source = '''architecture-beta
group api(cloud)[API]
service db(database)[Database] in api
service disk1(disk)[Storage] in api
service disk2(disk)[Storage] in api
service server(server)[Server] in api
service gateway(internet)[Gateway]
db:L -- R:server
disk1:T -- B:server
disk2:T -- B:db
server:T -- B:gateway
''';
      final scene = layoutDiagram(parse(DiagramType.architecture, source));
      expect(scene.bounds.width, closeTo(367.2142487159315, 1e-9));
      expect(scene.bounds.height, closeTo(580.0184756092636, 1e-9));
    });

    test('architecture plain services use proof spacing and outline paths', () {
      const source = '''architecture-beta
service cell[Table Cell]
service colspan[colspan]
service rowspan[rowspan]
cell:R --> L:colspan
cell:B --> T:rowspan
''';
      final scene = layoutDiagram(parse(DiagramType.architecture, source));
      final elements = _flatten(scene.elements).toList();
      final services = elements
          .whereType<SceneGroup>()
          .where((element) => element.cssClasses.contains('architecture-service'))
          .toList();
      final cell = services.singleWhere((element) => element.label == 'Table Cell').transforms.single as Translate;
      final colspan = services.singleWhere((element) => element.label == 'colspan').transforms.single as Translate;
      final rowspan = services.singleWhere((element) => element.label == 'rowspan').transforms.single as Translate;
      final outlines = elements.whereType<ScenePath>().where(
        (element) => element.cssClasses.contains('architecture-node-background'),
      );

      expect(colspan.x - cell.x, closeTo(200.92563261830128, 1e-9));
      expect(rowspan.y - cell.y, closeTo(200.92563261830128, 1e-9));
      expect(outlines, hasLength(3));
    });

    test('geometry primitives translate and create centered bounds', () {
      expect(const Point(2, 3).translated(4, -1), const Point(6, 2));
      expect(
        const Bounds(left: 2, top: 3, width: 5, height: 7).translated(4, -1),
        const Bounds(left: 6, top: 2, width: 5, height: 7),
      );
      expect(
        Bounds.fromCenter(const Point(10, 20), const Size(8, 6)),
        const Bounds(left: 6, top: 17, width: 8, height: 6),
      );
      expect(ArchitectureDirection.left.opposite, ArchitectureDirection.right);
      expect(ArchitectureDirection.top.opposite, ArchitectureDirection.bottom);
    });

    test('lays out positioned backend-neutral geometry deterministically', () {
      const ast = PieAst(
        title: 'Usage',
        sections: [
          PieSectionAst(label: 'A', value: 2),
          PieSectionAst(label: 'B', value: 1),
        ],
      );

      final first = layoutDiagram(ast);
      final second = layoutDiagram(ast);

      expect(first.viewport, second.viewport);
      expect(first.elements, second.elements);
      expect(_flatten(first.elements).whereType<ScenePath>(), isNotEmpty);
      expect(first.title, 'Usage');
    });

    test('serializes valid accessible SVG and escapes text', () {
      const scene = DiagramScene(
        diagramType: DiagramType.info,
        viewport: Bounds(left: 0, top: 0, width: 100, height: 50),
        bounds: Bounds(left: 0, top: 0, width: 100, height: 50),
        title: 'A & B',
        description: '<safe>',
        elements: [
          SceneText(
            id: 'label-0',
            position: Point(10, 20),
            text: 'x < y',
            bounds: Bounds(left: 10, top: 8, width: 35, height: 16),
          ),
        ],
      );

      final document = XmlDocument.parse(renderSvg(scene));
      final root = document.rootElement;
      expect(root.name.local, 'svg');
      expect(root.name.namespaceUri, 'http://www.w3.org/2000/svg');
      expect(root.getAttribute('viewBox'), '0 0 100 50');
      expect(root.findElements('title').single.innerText, 'A & B');
      expect(root.findAllElements('text').single.innerText, 'x < y');
      expect(root.findAllElements('text').single.getAttribute('x'), '10');
    });

    test('serializes backend-neutral clip definitions and group references', () {
      const clipId = 'content-clip';
      const scene = DiagramScene(
        diagramType: DiagramType.treemap,
        viewport: Bounds(left: 0, top: 0, width: 100, height: 50),
        bounds: Bounds(left: 0, top: 0, width: 100, height: 50),
        clips: [
          SceneClip(
            id: clipId,
            path: ScenePath(
              id: 'clip-shape',
              commands: [
                MoveTo(Point(0, 0)),
                LineTo(Point(40, 0)),
                LineTo(Point(40, 20)),
                LineTo(Point(0, 20)),
                ClosePath(),
              ],
            ),
          ),
        ],
        elements: [
          SceneGroup(
            id: 'clipped-content',
            clipId: clipId,
            children: [
              SceneText(
                id: 'clipped-label',
                position: Point(0, 16),
                text: 'A long clipped label',
                bounds: Bounds(left: 0, top: 0, width: 120, height: 20),
              ),
            ],
          ),
        ],
      );

      final root = XmlDocument.parse(renderSvg(scene)).rootElement;
      expect(root.findAllElements('clipPath').single.getAttribute('id'), clipId);
      expect(
        root
            .findAllElements('g')
            .singleWhere((element) => element.getAttribute('id') == 'clipped-content')
            .getAttribute('clip-path'),
        'url(#$clipId)',
      );
    });

    test('Treemap exposes applied clips for bounded labels and headers', () {
      final scene = layoutDiagram(
        parse(DiagramType.treemap, 'treemap\n"Products"\n  "A very long product label": 3\n  "Small": 1\n'),
      );
      final clipIds = scene.clips.map((clip) => clip.id).toSet();
      final clippedGroups = _flatten(
        scene.elements,
      ).whereType<SceneGroup>().where((group) => group.clipId != null).toList();

      expect(scene.clips, isNotEmpty);
      expect(clippedGroups, isNotEmpty);
      expect(clippedGroups.map((group) => group.clipId), everyElement(isIn(clipIds)));
    });

    test('Mermaid useMaxWidth controls SVG sizing without changing scene geometry', () {
      final ast = parse(DiagramType.packet, 'packet-beta\n0-7: "Header"\n');
      final responsiveScene = layoutDiagram(ast);
      final fixedScene = layoutDiagram(
        ast,
        options: const RenderOptions(packet: PacketRenderOptions(useMaxWidth: false)),
      );

      expect(responsiveScene.viewport, fixedScene.viewport);
      expect(responsiveScene.widthPolicy, SceneWidthPolicy.fitContainer);
      expect(fixedScene.widthPolicy, SceneWidthPolicy.fixed);

      final responsiveRoot = XmlDocument.parse(renderSvg(responsiveScene)).rootElement;
      expect(responsiveRoot.getAttribute('width'), '100%');
      expect(responsiveRoot.getAttribute('height'), isNull);
      expect(
        responsiveRoot.getAttribute('style'),
        'max-width: ${responsiveScene.viewport.width.toStringAsFixed(0)}px;',
      );

      final fixedRoot = XmlDocument.parse(renderSvg(fixedScene)).rootElement;
      expect(fixedRoot.getAttribute('width'), fixedScene.viewport.width.toStringAsFixed(0));
      expect(fixedRoot.getAttribute('height'), fixedScene.viewport.height.toStringAsFixed(0));
    });

    test('SVG width mode can override the scene sizing policy', () {
      final scene = layoutDiagram(
        const PacketAst(),
        options: const RenderOptions(packet: PacketRenderOptions(useMaxWidth: false)),
      );
      final root = XmlDocument.parse(
        renderSvg(scene, options: const SvgRenderOptions(widthMode: SvgWidthMode.fitContainer)),
      ).rootElement;

      expect(root.getAttribute('width'), '100%');
      expect(root.getAttribute('height'), isNull);
    });

    test('architecture titles preserve geometry and accessibility metadata', () {
      const source = '''architecture-beta
title Simple Architecture Diagram
accTitle: Accessibility Title
accDescr: Accessibility Description
group api(cloud)[API]
service db(database)[Database] in api
service disk1(disk)[Storage] in api
service disk2(disk)[Storage] in api
service server(server)[Server] in api
db:L -- R:server
disk1:T -- B:server
disk2:T -- B:db
''';
      const sourceWithoutTitle = '''architecture-beta
group api(cloud)[API]
service db(database)[Database] in api
service disk1(disk)[Storage] in api
service disk2(disk)[Storage] in api
service server(server)[Server] in api
db:L -- R:server
disk1:T -- B:server
disk2:T -- B:db
''';

      final scene = layoutDiagram(parse(DiagramType.architecture, source));
      final untitled = layoutDiagram(parse(DiagramType.architecture, sourceWithoutTitle));

      expect(scene.title, 'Simple Architecture Diagram');
      expect(scene.accessibilityTitle, 'Accessibility Title');
      expect(scene.accessibilityDescription, 'Accessibility Description');
      expect(
        _flatten(scene.elements).whereType<SceneText>().where((element) => element.role == SemanticRole.title),
        isEmpty,
      );
      expect(scene.bounds, untitled.bounds);
      // Mermaid 11.16's seeded fCoSE proof layout leaves distinct horizontal
      // and vertical residuals for this single-compound orthogonal tree.
      expect(scene.bounds.width, closeTo(201.82715103496474 + 165, 1e-9));
      expect(scene.bounds.height, closeTo(200.92263355778473 + 182, 1e-9));

      final document = XmlDocument.parse(renderSvg(scene));
      final root = document.rootElement;
      expect(root.getAttribute('aria-labelledby'), 'diagram-title');
      expect(root.getAttribute('aria-describedby'), 'diagram-description');
      expect(root.findElements('title').single.innerText, 'Accessibility Title');
      expect(root.findElements('desc').single.innerText, 'Accessibility Description');
    });

    test('shared title bands include translated content in scene bounds', () {
      final scene = layoutDiagram(const RailroadAst(title: 'Grammar'));
      final untitled = layoutDiagram(const RailroadAst());
      final content = scene.elements.whereType<SceneGroup>().singleWhere(
        (element) => element.id.startsWith('content-'),
      );
      final translation = content.transforms.single as Translate;

      expect(
        scene.elements.whereType<SceneText>().singleWhere((element) => element.role == SemanticRole.title).text,
        'Grammar',
      );
      expect(translation.y, greaterThan(0));
      expect(scene.bounds.bottom, untitled.bounds.bottom + translation.y);
    });

    test('serializes fractional geometry without replacement artifacts', () {
      const scene = DiagramScene(
        diagramType: DiagramType.info,
        viewport: Bounds(left: 0, top: 0, width: 10.5, height: 5.25),
        bounds: Bounds(left: 0, top: 0, width: 10.5, height: 5.25),
        elements: [SceneLine(id: 'precise', start: Point(0, 209.144957), end: Point(10, 20))],
      );
      final svg = renderSvg(scene);
      expect(svg, contains('viewBox="0 0 10.5 5.25"'));
      expect(svg, contains('y1="209.144957"'));
      expect(svg, isNot(contains(r'$1')));
    });

    test('parse-layout-render convenience covers every diagram type', () {
      const minimalSources = {
        DiagramType.architecture: 'architecture-beta',
        DiagramType.classDiagram: 'classDiagram',
        DiagramType.cynefin: 'cynefin-beta',
        DiagramType.entityRelationship: 'erDiagram',
        DiagramType.eventModeling: 'eventmodeling',
        DiagramType.flowchart: 'flowchart TD',
        DiagramType.gantt: 'gantt',
        DiagramType.gitGraph: 'gitGraph',
        DiagramType.info: 'info',
        DiagramType.kanban: 'kanban',
        DiagramType.mindmap: 'mindmap\nroot',
        DiagramType.packet: 'packet-beta',
        DiagramType.pie: 'pie',
        DiagramType.radar: 'radar-beta',
        DiagramType.railroad: 'railroad-beta',
        DiagramType.railroadAbnf: 'railroad-abnf-beta',
        DiagramType.railroadEbnf: 'railroad-ebnf-beta',
        DiagramType.railroadPeg: 'railroad-peg-beta',
        DiagramType.sequence: 'sequenceDiagram',
        DiagramType.stateDiagram: 'stateDiagram-v2',
        DiagramType.timeline: 'timeline',
        DiagramType.treeView: 'treeView-beta',
        DiagramType.treemap: 'treemap-beta',
        DiagramType.wardley: 'wardley-beta',
      };

      for (final type in DiagramType.values) {
        final diagram = parse(type, minimalSources[type]!);
        final scene = layoutDiagram(diagram);
        final root = XmlDocument.parse(renderSvg(scene)).rootElement;

        expect(diagram.type, type, reason: type.name);
        expect(scene.diagramType, type, reason: type.name);
        expect(root.name.local, 'svg', reason: type.name);
        expect(root.getAttribute('aria-roledescription'), type.wireName, reason: type.name);
      }
    });

    test('all railroad syntaxes use the same positioned renderer', () {
      const sources = {
        DiagramType.railroad: '''railroad-beta
rule = sequence(terminal("a"), optional(nonterminal("b"))) ;
''',
        DiagramType.railroadEbnf: '''railroad-ebnf-beta
rule = "a" b? ;
''',
        DiagramType.railroadAbnf: '''railroad-abnf-beta
rule = "a" [b] ;
''',
        DiagramType.railroadPeg: '''railroad-peg-beta
rule <- "a" b? ;
''',
      };
      final scenes = [for (final entry in sources.entries) layoutDiagram(parse(entry.key, entry.value))];

      expect(scenes.skip(1).map((scene) => scene.viewport), everyElement(scenes.first.viewport));
      expect(scenes.skip(1).map((scene) => scene.elements), everyElement(scenes.first.elements));
      final document = XmlDocument.parse(renderSvg(scenes.first));
      expect(document.findAllElements('circle'), hasLength(2));
      expect(document.findAllElements('path'), isNotEmpty);
    });

    test('fallback text measurement is Unicode grapheme aware', () {
      const measurer = DeterministicTextMeasurer();
      const style = SceneTextStyle(fontSize: 16);
      expect(measurer.measure('e\u0301', style), measurer.measure('e', style));
      expect(measurer.measure('a\nb', style).height, greaterThan(measurer.measure('a', style).height));
    });

    test('renderer text emphasis matches Mermaid semantics', () {
      final cynefinTexts = _flatten(
        layoutDiagram(parse(DiagramType.cynefin, 'cynefin-beta\ncomplex "Probe"\n')).elements,
      ).whereType<SceneText>();
      expect(
        cynefinTexts.where((text) => text.cssClasses.contains('cynefinSubtitle')).map((text) => text.style.style),
        everyElement(FontStyle.italic),
      );

      final gitTexts = _flatten(
        layoutDiagram(
          parse(DiagramType.gitGraph, 'gitGraph\ncommit id: "A"\nbranch develop\ncheckout develop\ncommit id: "B"\n'),
        ).elements,
      ).whereType<SceneText>();
      expect(
        gitTexts.where((text) => text.cssClasses.contains('git-branch-label')).map((text) => text.style.weight),
        everyElement(FontWeight.normal),
      );

      final treeTexts = _flatten(
        layoutDiagram(
          parse(DiagramType.treeView, 'treeView-beta\n"café 👩‍💻.dart" icon(missing:unknown) ## é Unicode\n'),
        ).elements,
      ).whereType<SceneText>();
      expect(
        treeTexts.where((text) => text.cssClasses.contains('treeView-node-dir')).map((text) => text.style.weight),
        everyElement(FontWeight.bold),
      );
      expect(
        treeTexts
            .where(
              (text) =>
                  text.cssClasses.contains('treeView-node-label') && !text.cssClasses.contains('treeView-node-dir'),
            )
            .map((text) => text.style.weight),
        everyElement(FontWeight.normal),
      );
      expect(
        treeTexts
            .where((text) => text.cssClasses.contains('treeView-node-description'))
            .map((text) => text.style.style),
        everyElement(FontStyle.italic),
      );
    });

    test('single-section pies use two arcs to form a complete circle', () {
      final scene = layoutDiagram(const PieAst(sections: [PieSectionAst(label: 'all', value: 1)]));
      final path = _flatten(scene.elements).whereType<ScenePath>().single;
      expect(path.commands.whereType<ArcTo>(), hasLength(2));
    });

    test('placeholder icons are stable backend-neutral paths', () {
      const resolver = PlaceholderIconResolver();
      expect(resolver.resolve('missing'), resolver.resolve('also-missing'));
      expect(resolver.resolve('missing').paths, hasLength(3));
    });

    test('tree icons use a placeholder when application resolution fails', () {
      final scene = layoutDiagram(
        const TreeViewAst(
          nodes: [TreeViewNodeAst(name: 'Inbox', icon: 'unknown:inbox', description: 'Missing icon')],
        ),
      );
      final elements = _flatten(scene.elements).toList();
      final icon = elements.whereType<SceneIcon>().single;
      final description = elements.whereType<SceneText>().singleWhere(
        (element) => element.cssClasses.contains('treeView-node-description'),
      );
      expect(icon.label, 'unknown:inbox');
      expect(icon.geometry.paths, isNotEmpty);
      expect(icon.fill, const SolidFill(TreeViewRenderOptions.defaultIconColor));
      expect(icon.stroke?.color, TreeViewRenderOptions.defaultIconColor);
      expect(description.style.color, TreeViewRenderOptions.defaultDescriptionColor);
      expect(
        XmlDocument.parse(
          renderSvg(scene),
        ).findAllElements('g').where((element) => element.getAttribute('aria-label') == 'unknown:inbox'),
        hasLength(2),
      );
    });

    test('tree icons follow Mermaid selection and pack qualification rules', () {
      final scene = layoutDiagram(
        const TreeViewAst(
          nodes: [
            TreeViewNodeAst(name: 'src/'),
            TreeViewNodeAst(name: 'Dockerfile', indent: 2),
            TreeViewNodeAst(name: 'APP.DART', indent: 2),
            TreeViewNodeAst(name: 'notes.md', indent: 2, icon: 'star'),
            TreeViewNodeAst(name: 'hidden.txt', indent: 2, icon: 'none'),
          ],
        ),
        options: const RenderOptions(
          treeView: TreeViewRenderOptions(
            showIcons: true,
            defaultIconPack: 'devicons',
            filenameIcons: {'Dockerfile': 'docker'},
            extensionIcons: {'.dart': 'dart'},
          ),
        ),
      );

      expect(_flatten(scene.elements).whereType<SceneIcon>().map((icon) => icon.label), [
        TreeViewRenderOptions.builtInFolderIcon,
        TreeViewRenderOptions.builtInFolderIcon,
        'devicons:docker',
        'devicons:dart',
        'devicons:star',
      ]);
    });

    test('architecture icons use application geometry with a labeled placeholder fallback', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'service unknown(iconnamedoesntexist)[Unknown Icon]\n',
              )
              as ArchitectureAst;
      final fallbackScene = layoutDiagram(ast);
      final fallbackElements = _flatten(fallbackScene.elements).toList();
      final fallback = fallbackElements.whereType<SceneIcon>().single;
      final resolved = _flatten(
        layoutDiagram(ast, iconResolver: const _TestIconResolver()).elements,
      ).whereType<SceneIcon>().single;

      expect(fallback.label, 'iconnamedoesntexist');
      expect(fallback.reference, 'iconnamedoesntexist');
      expect(fallback.geometry, const PlaceholderIconResolver().resolve('iconnamedoesntexist'));
      expect(fallbackScene.bounds.width, closeTo(115.2, 1e-9));
      expect(
        (fallbackElements
                    .whereType<SceneGroup>()
                    .singleWhere((element) => element.cssClasses.contains('architecture-service'))
                    .transforms
                    .single
                as Translate)
            .y,
        40,
      );
      expect(resolved.label, 'iconnamedoesntexist');
      expect(resolved.reference, 'iconnamedoesntexist');
      expect(resolved.geometry, _TestIconResolver.geometry);
      expect(resolved.role, SemanticRole.icon);
    });

    test('treemap layout preserves nested section geometry', () {
      final scene = layoutDiagram(
        const TreemapAst(
          rows: [
            TreemapNodeRowAst(indent: 0, item: TreemapSectionAst(name: 'Products')),
            TreemapNodeRowAst(indent: 1, item: TreemapSectionAst(name: 'Category')),
            TreemapNodeRowAst(indent: 2, item: TreemapLeafAst(name: 'A', value: 2)),
            TreemapNodeRowAst(indent: 2, item: TreemapLeafAst(name: 'B', value: 1)),
          ],
        ),
      );
      final rectangles = _flatten(scene.elements).whereType<SceneRect>().toList();
      expect(rectangles.where((element) => element.role == SemanticRole.group), hasLength(2));
      expect(rectangles.where((element) => element.role == SemanticRole.node), hasLength(2));
      expect(rectangles.every((element) => element.bounds.width >= 0 && element.bounds.height >= 0), isTrue);
    });

    test('treemap options follow Mermaid canvas, padding, and value configuration', () {
      final scene = layoutDiagram(
        const TreemapAst(
          rows: [
            TreemapNodeRowAst(indent: 0, item: TreemapSectionAst(name: 'Products')),
            TreemapNodeRowAst(indent: 1, item: TreemapLeafAst(name: 'Large', value: 3000)),
            TreemapNodeRowAst(indent: 1, item: TreemapLeafAst(name: 'Small', value: 1000)),
          ],
        ),
        options: const RenderOptions(
          padding: 0,
          treemap: TreemapRenderOptions(
            useMaxWidth: false,
            padding: 4,
            diagramPadding: 12,
            nodeWidth: 80,
            nodeHeight: 55,
            borderWidth: 2,
            valueFontSize: 16,
            labelFontSize: 18,
            valueFormat: TreemapValueFormat.currencyGrouped,
          ),
        ),
      );
      final elements = _flatten(scene.elements).toList();
      final values = elements
          .whereType<SceneText>()
          .where((element) => element.cssClasses.any((name) => name.contains('Value')))
          .map((element) => element.text)
          .toSet();
      final leaves = elements
          .whereType<SceneRect>()
          .where((element) => element.cssClasses.contains('treemapLeaf'))
          .map((element) => element.bounds)
          .toList();

      expect(scene.bounds, const Bounds(left: 10, top: 35, width: 780, height: 505));
      expect(scene.viewport, scene.bounds.expand(12));
      expect(values, containsAll({'\$4,000', '\$3,000', '\$1,000'}));
      expect(leaves, hasLength(2));
      final gap = leaves[0].right <= leaves[1].left
          ? leaves[1].left - leaves[0].right
          : leaves[1].top - leaves[0].bottom;
      expect(gap, closeTo(4, 1e-9));
    });

    test('global Mermaid theme palettes feed pie, radar, and treemap colors', () {
      const pieColors = [Color(17, 34, 51), Color(68, 85, 102)];
      const categoricalColors = [Color(119, 136, 153), Color(170, 187, 204)];
      const categoricalPeerColors = [Color(221, 238, 255), Color(18, 52, 86)];
      const categoricalLabelColors = [Color(101, 67, 33), Color(171, 205, 239)];
      const options = RenderOptions(
        theme: MermaidTheme(
          pieColors: pieColors,
          categoricalColors: categoricalColors,
          categoricalPeerColors: categoricalPeerColors,
          categoricalLabelColors: categoricalLabelColors,
        ),
      );

      final pie = layoutDiagram(parse(DiagramType.pie, 'pie\n"A": 2\n"B": 1\n'), options: options);
      final pieSlices = _flatten(
        pie.elements,
      ).whereType<ScenePath>().where((element) => element.cssClasses.contains('pieCircle')).toList();
      expect(pieSlices.map((slice) => (slice.fill! as SolidFill).color), [
        const Color(17, 34, 51, 179),
        const Color(68, 85, 102, 179),
      ]);

      final radar = layoutDiagram(
        parse(DiagramType.radar, 'radar-beta\naxis speed, quality, cost\ncurve current { 3, 4, 2 }\n'),
        options: options,
      );
      final radarCurve = _flatten(
        radar.elements,
      ).whereType<ScenePath>().singleWhere((element) => element.cssClasses.contains('radarCurve-0'));
      expect(radarCurve.stroke?.color, categoricalColors.first);

      final treemap = layoutDiagram(
        parse(DiagramType.treemap, 'treemap\n"Products"\n  "Large": 3\n  "Small": 1\n'),
        options: options,
      );
      final treemapSections = _flatten(
        treemap.elements,
      ).whereType<SceneRect>().where((element) => element.cssClasses.contains('treemapSection')).toList();
      final treemapLabels = _flatten(
        treemap.elements,
      ).whereType<SceneText>().where((element) => element.cssClasses.contains('treemapSectionLabel')).toList();
      expect((treemapSections.single.fill! as SolidFill).color, const Color(119, 136, 153, 153));
      expect(treemapSections.single.stroke?.color, const Color(221, 238, 255, 102));
      expect(treemapLabels.single.style.color, categoricalLabelColors.first);
    });

    test('explicit diagram palettes override themes and empty themes remain safe', () {
      const theme = MermaidTheme(pieColors: [Color(17, 34, 51)], categoricalColors: [Color(68, 85, 102)]);
      const explicitPie = [Color(119, 136, 153)];
      const explicitRadar = [Color(170, 187, 204)];

      expect(const PieRenderOptions(sectionColors: explicitPie).resolveSectionColors(theme), explicitPie);
      expect(const RadarRenderOptions(seriesColors: explicitRadar).resolveSeriesColors(theme), explicitRadar);
      expect(
        const PieRenderOptions().resolveSectionColors(MermaidTheme(pieColors: [])),
        const PieRenderOptions().sectionColors,
      );
      expect(
        const RadarRenderOptions().resolveSeriesColors(MermaidTheme(categoricalColors: [])),
        const RadarRenderOptions().seriesColors,
      );
      expect(
        const TreemapRenderOptions().resolveSectionColors(MermaidTheme(categoricalColors: [])),
        const TreemapRenderOptions().sectionColors,
      );
    });
  });
}

final class _TestIconResolver implements IconResolver {
  const _TestIconResolver();

  static const geometry = IconGeometry(
    bounds: Bounds(left: 0, top: 0, width: 12, height: 6),
    paths: [
      [MoveTo(Point(0, 3)), LineTo(Point(12, 3))],
    ],
  );

  @override
  IconGeometry? resolve(String reference) => reference == 'iconnamedoesntexist' ? geometry : null;
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element case SceneGroup(:final children)) yield* _flatten(children);
  }
}
