import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('geometry-first rendering', () {
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
          nodes: [TreeViewNodeAst(name: 'Inbox', icon: 'unknown:inbox')],
        ),
      );
      final icon = _flatten(scene.elements).whereType<SceneIcon>().single;
      expect(icon.label, 'unknown:inbox');
      expect(icon.geometry.paths, isNotEmpty);
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

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element case SceneGroup(:final children)) yield* _flatten(children);
  }
}
