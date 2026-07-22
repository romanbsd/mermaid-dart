import 'dart:io';

import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import '../../tool/mermaid_parity/parity.dart';

void main() {
  test('fixture manifest is pinned and covers every renderer family', () {
    final manifest = ParityManifest.load(File('tool/mermaid_parity/fixtures.json'));

    expect(manifest.mermaidVersion, '11.16.0');
    expect(manifest.fixtures.map((fixture) => fixture.id), hasLength(21));
    expect(manifest.fixtures.map((fixture) => fixture.id).toSet(), hasLength(21));
    expect(
      manifest.fixtures.map((fixture) => fixture.id),
      containsAll([
        'event-modeling-unicode-multiline',
        'git-special-commits',
        'git-special-commits-tb',
        'git-special-commits-bt',
        'tree-highlighted-styles',
        'tree-unicode-invalid-icon',
        'wardley-strategies',
      ]),
    );
    final railroad = manifest.fixtures.singleWhere((fixture) => fixture.id == 'railroad-sequence');
    expect(railroad.textMeasurements['a'], const Size(8.40625, 19));
    expect(railroad.textMeasurements['rule ='], const Size(41.625, 19));
    expect(
      manifest.fixtures.map((fixture) => fixture.type.name).toSet(),
      containsAll({
        'architecture',
        'cynefin',
        'eventModeling',
        'gitGraph',
        'info',
        'packet',
        'pie',
        'radar',
        'railroad',
        'treeView',
        'treemap',
        'wardley',
      }),
    );

    for (final fixture in manifest.fixtures) {
      expect(
        XmlDocument.parse(renderDiagramSvg(fixture.type, fixture.source)).rootElement.name.local,
        'svg',
        reason: fixture.id,
      );
    }
  });

  test('comparison distinguishes structural differences from exact parity', () {
    final left = SvgSnapshot.fromSvg('<svg viewBox="0 0 10 10"><text x="1">A</text><path d="M0 0L1 1"/></svg>');
    final equivalent = SvgSnapshot.fromSvg(
      '<svg viewBox="0 0 10.0000 10"><text x="1.0">A</text><path d="M0 0L1 1"/></svg>',
    );
    final different = SvgSnapshot.fromSvg(
      '<svg viewBox="0 0 20 10"><text x="1">B</text><rect width="1" height="1"/></svg>',
    );

    expect(SvgComparison.compare(left, equivalent).exact, isTrue);
    expect(SvgComparison.compare(left, equivalent).sameViewport, isTrue);
    expect(SvgComparison.compare(left, equivalent).visualParity, isTrue);
    final comparison = SvgComparison.compare(left, different);
    expect(comparison.exact, isFalse);
    expect(comparison.sameViewport, isFalse);
    expect(comparison.sameText, isFalse);
    expect(comparison.sameElementCounts, isFalse);
    expect(comparison.sameGeometry, isFalse);
    expect(comparison.visualParity, isFalse);
    expect(comparison.summary, 'viewport, text, elements, geometry');
  });

  test('comparison normalizes equivalent paint and detects paint differences', () {
    final attributes = SvgSnapshot.fromSvg(
      '<svg><rect class="node" fill="#ff0000" stroke="#000" '
      'stroke-width="2" opacity="0.5" width="10" height="10"/></svg>',
    );
    final stylesheet = SvgSnapshot.fromSvg(
      '<svg><style>.node { fill: hsl(0, 100%, 50%) !important; '
      'stroke: rgb(0, 0, 0); '
      'stroke-width: 2px; opacity: .5; }</style>'
      '<rect class="node" width="10" height="10"/></svg>',
    );
    final different = SvgSnapshot.fromSvg(
      '<svg><rect fill="#00ff00" stroke="#000" stroke-width="2" '
      'opacity="0.5" width="10" height="10"/></svg>',
    );

    final equivalent = SvgComparison.compare(attributes, stylesheet);
    expect(equivalent.samePaint, isTrue);
    expect(equivalent.visualParity, isTrue);

    final comparison = SvgComparison.compare(attributes, different);
    expect(comparison.sameGeometry, isTrue);
    expect(comparison.samePaint, isFalse);
    expect(comparison.visualParity, isFalse);
    expect(comparison.summary, 'paint');
  });

  test('paint comparison ignores fill properties that cannot affect lines', () {
    final left = SvgSnapshot.fromSvg('<svg fill="#ff0000"><line x1="0" y1="0" x2="10" y2="10" stroke="#000"/></svg>');
    final right = SvgSnapshot.fromSvg('<svg fill="#00ff00"><line x1="0" y1="0" x2="10" y2="10" stroke="#000"/></svg>');

    expect(SvgComparison.compare(left, right).samePaint, isTrue);
  });

  test('unrelated stylesheet properties do not override presentation attributes', () {
    final styled = SvgSnapshot.fromSvg(
      '<svg id="chart"><style>#chart { fill: #333; } '
      '#chart .slice { stroke: #000; opacity: .7; }</style>'
      '<path class="slice" fill="#ececff" d="M0 0L10 0Z"/></svg>',
    );
    final explicit = SvgSnapshot.fromSvg('<svg><path fill="#ececff" stroke="#000" opacity=".7" d="M0 0L10 0Z"/></svg>');

    expect(SvgComparison.compare(styled, explicit).samePaint, isTrue);
  });

  test('resolves inherited styles from a canonicalized root ID selector', () {
    final stylesheet = SvgSnapshot.fromSvg(
      '<svg id="diagram"><style>#diagram { fill: #333; }</style><text>Label</text></svg>',
    );
    final explicit = SvgSnapshot.fromSvg('<svg><text fill="#333">Label</text></svg>');

    expect(SvgComparison.compare(stylesheet, explicit).samePaint, isTrue);
  });

  test('normalizes element opacity to equivalent fill and stroke opacity', () {
    final elementOpacity = SvgSnapshot.fromSvg(
      '<svg><path fill="#f00" stroke="#000" opacity=".7" d="M0 0L10 0Z"/></svg>',
    );
    final channelOpacity = SvgSnapshot.fromSvg(
      '<svg><path fill="#f00" fill-opacity=".7" stroke="#000" '
      'stroke-opacity=".7" d="M0 0L10 0Z"/></svg>',
    );

    expect(SvgComparison.compare(elementOpacity, channelOpacity).samePaint, isTrue);
  });

  test('normalizes rgba alpha to equivalent channel opacity', () {
    final rgba = SvgSnapshot.fromSvg(
      '<svg><rect fill="rgba(255, 193, 7, 0.15)" stroke="#ffc107" width="10" height="10"/></svg>',
    );
    final channelOpacity = SvgSnapshot.fromSvg(
      '<svg><rect fill="#ffc107" fill-opacity=".15" stroke="#ffc107" width="10" height="10"/></svg>',
    );

    expect(SvgComparison.compare(rgba, channelOpacity).samePaint, isTrue);
  });

  test('ignores opacity on disabled paint channels', () {
    final elementOpacity = SvgSnapshot.fromSvg(
      '<svg><rect fill="#ffffde" stroke="none" opacity=".5" width="10" height="10"/></svg>',
    );
    final fillOpacity = SvgSnapshot.fromSvg(
      '<svg><rect fill="#ffffde" stroke="none" fill-opacity=".5" width="10" height="10"/></svg>',
    );

    expect(SvgComparison.compare(elementOpacity, fillOpacity).samePaint, isTrue);
  });

  test('treats foreignObject and SVG text as equivalent visible text', () {
    final svgText = SvgSnapshot.fromSvg('<svg><text x="1">Multi line</text></svg>');
    final htmlText = SvgSnapshot.fromSvg(
      '<svg><foreignObject><div><span> Multi\nline </span></div></foreignObject></svg>',
    );

    final comparison = SvgComparison.compare(svgText, htmlText);
    expect(comparison.sameText, isTrue);
    expect(comparison.sameElementCounts, isTrue);
    expect(comparison.exact, isFalse);
  });

  test('normalizes centered foreignObject labels to positioned scene text', () {
    final htmlText = SvgSnapshot.fromSvg(
      '<svg><foreignObject x="10" y="20" width="100" height="40">'
      '<div><b>Updated</b><br/><br/><code>a:&#160;b</code></div>'
      '</foreignObject></svg>',
    );
    final svgText = SvgSnapshot.fromSvg(
      '<svg><text x="60" y="40" font-size="16" text-anchor="middle" '
      'dominant-baseline="central">Updated\n\na: b</text></svg>',
    );

    final comparison = SvgComparison.compare(svgText, htmlText);
    expect(comparison.sameText, isTrue);
    expect(comparison.sameGeometry, isTrue);
  });

  test('ignores empty text and normalizes SVG text defaults', () {
    final explicit = SvgSnapshot.fromSvg(
      '<svg><text x="1" y="2" font-size="16" '
      'dominant-baseline="alphabetic">Label</text></svg>',
    );
    final implicit = SvgSnapshot.fromSvg(
      '<svg><text x="1" y="2" dominant-baseline="auto">Label</text>'
      '<text x="0" y="0"></text></svg>',
    );

    final comparison = SvgComparison.compare(explicit, implicit);
    expect(comparison.sameText, isTrue);
    expect(comparison.sameElementCounts, isTrue);
    expect(comparison.sameGeometry, isTrue);
  });

  test('compares visual text geometry across equivalent SVG styling forms', () {
    final mermaid = SvgSnapshot.fromSvg(
      '<svg><g><text x="100" y="40" font-size="32" '
      'style="text-anchor: middle">v11.16.0</text></g></svg>',
    );
    final dart = SvgSnapshot.fromSvg(
      '<svg viewBox="0 0 400 100"><text x="100" y="40" '
      'font-size="32" text-anchor="middle" dominant-baseline="alphabetic">'
      'v11.16.0</text></svg>',
    );

    final comparison = SvgComparison.compare(dart, mermaid);
    expect(comparison.sameViewport, isTrue, reason: 'an absent viewport is compatible');
    expect(comparison.sameGeometry, isTrue);
    expect(comparison.visualParity, isTrue);
    expect(comparison.exact, isFalse);
  });

  test('normalizes Mermaid createText wrappers to positioned SVG text', () {
    final mermaid = SvgSnapshot.fromSvg(
      '<svg><g transform="translate(10 20)" dominant-baseline="middle" '
      'text-anchor="middle"><text y="-10.1" font-size="16">'
      '<tspan x="0" y="-0.1em" dy="1.1em">API</tspan>'
      '</text></g></svg>',
    );
    final dart = SvgSnapshot.fromSvg(
      '<svg><text x="10" y="36" font-size="16" text-anchor="middle" '
      'dominant-baseline="middle">API</text></svg>',
    );

    expect(SvgComparison.compare(dart, mermaid).sameGeometry, isTrue);
  });

  test('ignores resolver-owned icon internals and zero-sized backgrounds', () {
    final mermaid = SvgSnapshot.fromSvg(
      '<svg><rect width="0" height="0"/><svg width="80" height="80">'
      '<circle cx="40" cy="40" r="20"/></svg></svg>',
    );
    final dart = SvgSnapshot.fromSvg('<svg><g data-role="icon"><path d="M0 0 L80 80"/></g></svg>');

    final comparison = SvgComparison.compare(dart, mermaid);
    expect(comparison.sameElementCounts, isTrue);
    expect(comparison.sameGeometry, isTrue);
  });

  test('ignores hidden and clipping-only treemap geometry', () {
    final mermaid = SvgSnapshot.fromSvg(
      '<svg><g style="display: none"><rect width="100" height="40"/>'
      '<text>hidden</text></g><clipPath><rect width="90" height="30"/></clipPath>'
      '<rect class="treemapSectionHeader" fill="none" width="80" height="25"/>'
      '<rect x="10" y="20" width="70" height="50"/><text x="20" y="30">shown</text></svg>',
    );
    final scene = SvgSnapshot.fromSvg(
      '<svg><rect x="10" y="20" width="70" height="50"/>'
      '<text x="20" y="30">shown</text></svg>',
    );

    final comparison = SvgComparison.compare(scene, mermaid);
    expect(comparison.sameText, isTrue);
    expect(comparison.sameElementCounts, isTrue);
    expect(comparison.sameGeometry, isTrue);
  });

  test('ignores backend-specific event-modeling arrowhead representations', () {
    final marker = SvgSnapshot.fromSvg(
      '<svg><defs><marker><polygon points="0 0,10 3.5,0 7"/></marker></defs>'
      '<path d="M1 2 L3 4"/></svg>',
    );
    final positioned = SvgSnapshot.fromSvg(
      '<svg><path d="M1 2 L3 4"/><polygon class="em-arrowhead" points="3,4 1,2 2,1"/></svg>',
    );

    final comparison = SvgComparison.compare(positioned, marker);
    expect(comparison.sameElementCounts, isTrue);
    expect(comparison.sameGeometry, isTrue);
  });

  test('ignores backend-specific Wardley marker arrowheads', () {
    final marker = SvgSnapshot.fromSvg(
      '<svg><defs><marker><path d="M0 0 L10 5 L0 10Z"/></marker></defs>'
      '<line class="wardley-link" x1="1" y1="2" x2="3" y2="4"/>'
      '<line class="wardley-trend" x1="5" y1="6" x2="7" y2="8"/></svg>',
    );
    final positioned = SvgSnapshot.fromSvg(
      '<svg><line class="wardley-link" x1="1" y1="2" x2="3" y2="4"/>'
      '<polygon class="wardley-link-arrow" points="3,4 1,2 2,1"/>'
      '<line class="wardley-trend" x1="5" y1="6" x2="7" y2="8"/>'
      '<polygon class="wardley-trend-arrow" points="7,8 5,6 6,5"/></svg>',
    );

    final comparison = SvgComparison.compare(positioned, marker);
    expect(comparison.sameElementCounts, isTrue);
    expect(comparison.sameGeometry, isTrue);
  });

  test('normalizes an omitted rectangle ry to its rx value', () {
    final implicit = SvgSnapshot.fromSvg('<svg><rect x="1" y="2" width="3" height="4" rx="5"/></svg>');
    final explicit = SvgSnapshot.fromSvg('<svg><rect x="1" y="2" width="3" height="4" rx="5" ry="5"/></svg>');

    expect(SvgComparison.compare(explicit, implicit).sameGeometry, isTrue);
  });

  test('normalizes equivalent centered text baselines', () {
    final middle = SvgSnapshot.fromSvg('<svg><text x="1" y="2" dominant-baseline="middle">Label</text></svg>');
    final central = SvgSnapshot.fromSvg('<svg><text x="1" y="2" dominant-baseline="central">Label</text></svg>');

    expect(SvgComparison.compare(central, middle).sameGeometry, isTrue);
  });

  test('compares translated local geometry with absolute geometry', () {
    final local = SvgSnapshot.fromSvg(
      '<svg><g transform="translate(10, 20)">'
      '<circle cx="1" cy="2" r="3"/>'
      '<rect x="1" y="2" width="4" height="5"/>'
      '<text x="1" y="2">Label</text>'
      '<path d="M0 0L2 2A3 4 0 0 1 5 6Z"/>'
      '</g></svg>',
    );
    final absolute = SvgSnapshot.fromSvg(
      '<svg>'
      '<circle cx="11" cy="22" r="3"/>'
      '<rect x="11" y="22" width="4" height="5"/>'
      '<text x="11" y="22">Label</text>'
      '<path d="M10 20L12 22A3 4 0 0 1 15 26Z"/>'
      '</svg>',
    );

    final comparison = SvgComparison.compare(local, absolute);
    expect(comparison.sameGeometry, isTrue);
    expect(comparison.visualParity, isTrue);
    expect(comparison.exact, isFalse);
  });

  test('ignores paint-equivalent sibling order in geometry comparison', () {
    final shapesFirst = SvgSnapshot.fromSvg(
      '<svg><circle cx="1" cy="2" r="3"/><rect x="4" y="5" width="6" height="7"/>'
      '<text x="1" y="9">A</text><text x="2" y="9">B</text></svg>',
    );
    final reverseOrder = SvgSnapshot.fromSvg(
      '<svg><text x="2" y="9">B</text><text x="1" y="9">A</text>'
      '<rect x="4" y="5" width="6" height="7"/><circle cx="1" cy="2" r="3"/></svg>',
    );

    final comparison = SvgComparison.compare(shapesFirst, reverseOrder);
    expect(comparison.sameText, isTrue);
    expect(comparison.sameGeometry, isTrue);
    expect(comparison.exact, isFalse);
  });

  test('resolves simple stylesheet font sizes for text geometry', () {
    final stylesheet = SvgSnapshot.fromSvg(
      '<svg><style>.label { font-size: 17px; text-anchor: middle; '
      'dominant-baseline: middle; }</style><text class="label">A</text></svg>',
    );
    final attribute = SvgSnapshot.fromSvg(
      '<svg><text class="label" font-size="17" text-anchor="middle" '
      'dominant-baseline="middle">A</text></svg>',
    );

    expect(SvgComparison.compare(stylesheet, attribute).sameGeometry, isTrue);
  });

  test('tolerates sub-centipixel geometry differences', () {
    final left = SvgSnapshot.fromSvg('<svg><path d="M0 0L264.263 1"/></svg>');
    final right = SvgSnapshot.fromSvg('<svg><path d="M0 0L264.264 1"/></svg>');

    expect(SvgComparison.compare(left, right).sameGeometry, isTrue);
  });

  test('manifest rejects duplicate IDs', () {
    expect(
      () => ParityManifest.fromJson({
        'mermaidVersion': '11.16.0',
        'fixtures': [
          {'id': 'same', 'type': 'info', 'source': 'info'},
          {'id': 'same', 'type': 'pie', 'source': 'pie'},
        ],
      }),
      throwsFormatException,
    );
  });

  test('fixture text measurer uses exact entries and deterministic fallback', () {
    const fixture = ParityFixture(
      id: 'measured',
      type: DiagramType.info,
      source: 'info',
      textMeasurements: {'exact': Size(12, 34)},
    );
    const style = SceneTextStyle(fontSize: 10);

    expect(fixture.textMeasurer.measure('exact', style), const Size(12, 34));
    expect(
      fixture.textMeasurer.measure('fallback', style),
      const DeterministicTextMeasurer().measure('fallback', style),
    );
  });
}
