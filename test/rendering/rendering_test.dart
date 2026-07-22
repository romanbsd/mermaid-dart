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

    test('architecture seed overrides select a reproducible layout variant', () {
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

      expect(first.viewport, second.viewport);
      expect(first.elements, second.elements);
      expect(first.bounds, isNot(defaultSeed.bounds));
      expect(first.bounds.width, closeTo(713.1729471741228, 1e-9));
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
        viewport: Bounds(left: 0, top: 0, width: 10.5, height: 5.25),
        bounds: Bounds(left: 0, top: 0, width: 10.5, height: 5.25),
      );
      final svg = renderSvg(scene);
      expect(svg, contains('viewBox="0 0 10.5 5.25"'));
      expect(svg, isNot(contains(r'$1')));
    });

    test('parse-layout-render convenience covers every diagram type', () {
      const minimalSources = {
        DiagramType.architecture: 'architecture-beta',
        DiagramType.cynefin: 'cynefin-beta',
        DiagramType.eventModeling: 'eventmodeling',
        DiagramType.gitGraph: 'gitGraph',
        DiagramType.info: 'info',
        DiagramType.packet: 'packet-beta',
        DiagramType.pie: 'pie',
        DiagramType.radar: 'radar-beta',
        DiagramType.railroad: 'railroad-beta',
        DiagramType.railroadAbnf: 'railroad-abnf-beta',
        DiagramType.railroadEbnf: 'railroad-ebnf-beta',
        DiagramType.railroadPeg: 'railroad-peg-beta',
        DiagramType.treeView: 'treeView-beta',
        DiagramType.treemap: 'treemap-beta',
        DiagramType.wardley: 'wardley-beta',
      };

      for (final type in DiagramType.values) {
        final svg = renderDiagramSvg(type, minimalSources[type]!);
        expect(XmlDocument.parse(svg).rootElement.name.local, 'svg', reason: type.name);
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
      final rendered = [for (final entry in sources.entries) renderDiagramSvg(entry.key, entry.value)];

      expect(rendered.skip(1), everyElement(rendered.first));
      final document = XmlDocument.parse(rendered.first);
      expect(document.findAllElements('circle'), hasLength(2));
      expect(document.findAllElements('path'), isNotEmpty);
    });

    test('fallback text measurement is Unicode grapheme aware', () {
      const measurer = DeterministicTextMeasurer();
      const style = SceneTextStyle(fontSize: 16);
      expect(measurer.measure('e\u0301', style), measurer.measure('e', style));
      expect(measurer.measure('a\nb', style).height, greaterThan(measurer.measure('a', style).height));
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
        58,
      );
      expect(resolved.label, 'iconnamedoesntexist');
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
