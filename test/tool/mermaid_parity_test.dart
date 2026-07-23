import 'dart:io';

import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import '../../tool/mermaid_parity/parity.dart';

void main() {
  test('fixture manifest is pinned and covers every renderer family', () {
    final manifest = ParityManifest.load(File('tool/mermaid_parity/fixtures.json'));

    expect(manifest.mermaidVersion, '11.16.0');
    expect(manifest.fixtures.map((fixture) => fixture.id), hasLength(58));
    expect(manifest.fixtures.map((fixture) => fixture.id).toSet(), hasLength(58));
    expect(
      manifest.fixtures.map((fixture) => fixture.id),
      containsAll([
        'architecture-nested-routing',
        'architecture-external-gateway',
        'architecture-fallback-icon',
        'architecture-title-accessibility',
        'architecture-seed-42',
        'architecture-align-row',
        'architecture-align-column',
        'architecture-junction-group-edge',
        'architecture-align-grid',
        'architecture-group-edges',
        'architecture-split-directioning',
        'architecture-directional-arrows',
        'architecture-edge-labels',
        'architecture-simple-junctions',
        'architecture-edge-length-default',
        'architecture-no-icon-edge-lengths',
        'architecture-edge-length-3',
        'architecture-reasonable-height',
        'architecture-deeply-nested',
        'cynefin-custom-config',
        'event-modeling-unicode-multiline',
        'event-modeling-custom-config',
        'git-special-commits',
        'git-special-commits-tb',
        'git-special-commits-bt',
        'tree-highlighted-styles',
        'tree-custom-layout',
        'tree-automatic-icons',
        'tree-unicode-invalid-icon',
        'pie-donut',
        'pie-bottom-legend',
        'pie-highlighted-slice',
        'pie-text-position',
        'packet-complex-no-bits',
        'radar-custom-geometry',
        'railroad-abnf-sequence',
        'railroad-abnf-bounded-repetition',
        'railroad-abnf-zero-or-more',
        'railroad-custom-config',
        'railroad-ebnf-sequence',
        'railroad-ebnf-choice-repetition',
        'railroad-peg-sequence',
        'wardley-strategies',
        'wardley-custom-config',
      ]),
    );
    final railroad = manifest.fixtures.singleWhere((fixture) => fixture.id == 'railroad-sequence');
    expect(railroad.textMeasurements['a'], const Size(8.40625, 19));
    expect(railroad.textMeasurements['rule ='], const Size(41.625, 19));
    final stretched = manifest.fixtures.singleWhere((fixture) => fixture.id == 'architecture-edge-length-3');
    expect(stretched.renderOptions.architecture.idealEdgeLengthMultiplier, 3);
    final seeded = manifest.fixtures.singleWhere((fixture) => fixture.id == 'architecture-seed-42');
    expect(seeded.renderOptions.architecture.seed, 42);
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
        'railroadAbnf',
        'railroadEbnf',
        'railroadPeg',
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
    final namedColor = SvgSnapshot.fromSvg('<svg><rect fill="lightgrey" width="10" height="10"/></svg>');
    final namedColorHex = SvgSnapshot.fromSvg('<svg><rect fill="#d3d3d3" width="10" height="10"/></svg>');

    final equivalent = SvgComparison.compare(attributes, stylesheet);
    expect(equivalent.samePaint, isTrue);
    expect(equivalent.visualParity, isTrue);
    expect(SvgComparison.compare(namedColor, namedColorHex).samePaint, isTrue);

    final comparison = SvgComparison.compare(attributes, different);
    expect(comparison.sameGeometry, isTrue);
    expect(comparison.samePaint, isFalse);
    expect(comparison.visualParity, isFalse);
    expect(comparison.summary, 'paint');
  });

  test('comparison normalizes equivalent stroke dash delimiters', () {
    final spaces = SvgSnapshot.fromSvg('<svg><path d="M0 0L1 1" stroke="#000" stroke-dasharray="5 3"/></svg>');
    final commas = SvgSnapshot.fromSvg('<svg><path d="M0 0L1 1" stroke="#000" stroke-dasharray="5,3"/></svg>');

    expect(SvgComparison.compare(spaces, commas).samePaint, isTrue);
  });

  test('comparison resolves stylesheet scale into geometry transforms', () {
    final stylesheet = SvgSnapshot.fromSvg('''
<svg>
  <style>.pieCircle.highlighted { scale: 1.05; opacity: 1; }</style>
  <g transform="translate(225 225)">
    <path class="pieCircle highlighted" d="M0 -185 L0 0 Z" fill="#fff" opacity="0.7"/>
  </g>
</svg>
''');
    final explicit = SvgSnapshot.fromSvg('''
<svg>
  <g transform="translate(225 225) scale(1.05)">
    <path class="pieCircle highlighted" d="M0 -185 L0 0 Z" fill="#fff" opacity="1"/>
  </g>
</svg>
''');

    expect(SvgComparison.compare(stylesheet, explicit).visualParity, isTrue);
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

  test('normalizes horizontal and vertical path commands to line segments', () {
    final axisCommands = SvgSnapshot.fromSvg('<svg><path d="M1 2H5V7h-2v-3Z"/></svg>');
    final lines = SvgSnapshot.fromSvg('<svg><path d="M1 2L5 2L5 7l-2 0l0-3Z"/></svg>');

    expect(SvgComparison.compare(axisCommands, lines).sameGeometry, isTrue);
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
    final negativeLeft = SvgSnapshot.fromSvg('<svg><g transform="scale(1.05)"><path d="M0 0L-160.2147 1"/></g></svg>');
    final negativeRight = SvgSnapshot.fromSvg('<svg><g transform="scale(1.05)"><path d="M0 0L-160.215 1"/></g></svg>');

    expect(SvgComparison.compare(left, right).sameGeometry, isTrue);
    expect(SvgComparison.compare(negativeLeft, negativeRight).sameGeometry, isTrue);
  });

  test('normalizes viewport and untransformed size precision consistently', () {
    final left = SvgSnapshot.fromSvg(
      '<svg viewBox="-224.6483 -234.5862 529.2965 600.1725">'
      '<rect width="366.2965" height="520.1725"/></svg>',
    );
    final right = SvgSnapshot.fromSvg(
      '<svg viewBox="-224.648269 -234.586243 529.296509 600.172486">'
      '<rect width="366.296537" height="520.172473"/></svg>',
    );
    final comparison = SvgComparison.compare(left, right);

    expect(comparison.sameViewport, isTrue);
    expect(comparison.sameGeometry, isTrue);
  });

  test('normalizes equivalent cyclic polygon point order', () {
    final first = SvgSnapshot.fromSvg('<svg><polygon points="0,0 10,0 5,10"/></svg>');
    final rotated = SvgSnapshot.fromSvg('<svg><polygon points="10,0 5,10 0,0"/></svg>');

    expect(SvgComparison.compare(first, rotated).sameGeometry, isTrue);
  });

  test('treats fully transparent paint as a disabled paint channel', () {
    final none = SvgSnapshot.fromSvg('<svg><rect width="10" height="10" fill="none"/></svg>');
    final transparent = SvgSnapshot.fromSvg('<svg><rect width="10" height="10" fill="#333" fill-opacity="0"/></svg>');

    expect(SvgComparison.compare(none, transparent).samePaint, isTrue);
  });

  test('compares transformed polygons before canonical numeric rounding', () {
    final absolute = SvgSnapshot.fromSvg(
      '<svg><polygon points="23.5,247.098 10.1667,253.7646 10.1667,240.4313"/></svg>',
    );
    final translated = SvgSnapshot.fromSvg(
      '<svg><g transform="translate(10.166666666666666 240.4313014365598)">'
      '<polygon points="13.333333333333334,6.666666666666667 0,13.333333333333334 0,0"/>'
      '</g></svg>',
    );

    expect(SvgComparison.compare(absolute, translated).sameGeometry, isTrue);
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

  test('fixture architecture options are positive and architecture-only', () {
    Object fixture(String type, num multiplier) => {
      'id': 'configured',
      'type': type,
      'source': type,
      'architectureOptions': {'idealEdgeLengthMultiplier': multiplier},
    };

    expect(() => ParityFixture.fromJson(fixture('architecture', 0)), throwsFormatException);
    expect(() => ParityFixture.fromJson(fixture('info', 3)), throwsFormatException);
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'architecture',
        'source': 'architecture-beta',
        'architectureOptions': {'edgeElasticity': 1.1},
      }),
      throwsFormatException,
    );
  });

  test('fixture pie options are typed and pie-only', () {
    final configured = ParityFixture.fromJson({
      'id': 'configured',
      'type': 'pie',
      'source': 'pie\n"Dogs": 1',
      'pieOptions': {'donutHole': 0.4, 'highlightSlice': 'Dogs', 'legendPosition': 'bottom', 'textPosition': 0.9},
    });

    expect(configured.renderOptions.pie.donutHole, 0.4);
    expect(configured.renderOptions.pie.highlightSlice, 'Dogs');
    expect(configured.renderOptions.pie.legendPosition, PieLegendPosition.bottom);
    expect(configured.renderOptions.pie.textPosition, 0.9);
    expect(configured.mermaidConfig, {
      'pie': {'donutHole': 0.4, 'highlightSlice': 'Dogs', 'legendPosition': 'bottom', 'textPosition': 0.9},
    });
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'packet',
        'source': 'packet\n0: "Flag"',
        'pieOptions': {'donutHole': 0.4},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'pie',
        'source': 'pie\n"Dogs": 1',
        'pieOptions': {'donutHole': 'wide'},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'pie',
        'source': 'pie\n"Dogs": 1',
        'pieOptions': {'legendPosition': 'diagonal'},
      }),
      throwsFormatException,
    );
  });

  test('fixture packet options are typed and packet-only', () {
    final configured = ParityFixture.fromJson({
      'id': 'configured',
      'type': 'packet',
      'source': 'packet\n0: "Flag"',
      'packetOptions': {'showBits': false},
    });

    expect(configured.renderOptions.packet.showBits, isFalse);
    expect(configured.mermaidConfig, {
      'packet': {'showBits': false},
    });
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'pie',
        'source': 'pie\n"Dogs": 1',
        'packetOptions': {'showBits': false},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'packet',
        'source': 'packet\n0: "Flag"',
        'packetOptions': {'showBits': 0},
      }),
      throwsFormatException,
    );
  });

  test('fixture radar options are typed and radar-only', () {
    final configured = ParityFixture.fromJson({
      'id': 'configured',
      'type': 'radar',
      'source': 'radar-beta\naxis speed\ncurve current { 1 }',
      'radarOptions': {
        'width': 720,
        'height': 480,
        'marginTop': 40,
        'marginRight': 60,
        'marginBottom': 30,
        'marginLeft': 50,
        'axisScaleFactor': 0.85,
        'axisLabelFactor': 1.15,
        'curveTension': 0,
      },
    });

    expect(configured.renderOptions.radar.width, 720);
    expect(configured.renderOptions.radar.height, 480);
    expect(configured.renderOptions.radar.marginTop, 40);
    expect(configured.renderOptions.radar.marginRight, 60);
    expect(configured.renderOptions.radar.marginBottom, 30);
    expect(configured.renderOptions.radar.marginLeft, 50);
    expect(configured.renderOptions.radar.axisScaleFactor, 0.85);
    expect(configured.renderOptions.radar.axisLabelFactor, 1.15);
    expect(configured.renderOptions.radar.curveTension, 0);
    expect(configured.mermaidConfig, {
      'radar': {
        'width': 720,
        'height': 480,
        'marginTop': 40,
        'marginRight': 60,
        'marginBottom': 30,
        'marginLeft': 50,
        'axisScaleFactor': 0.85,
        'axisLabelFactor': 1.15,
        'curveTension': 0,
      },
    });
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'pie',
        'source': 'pie\n"Dogs": 1',
        'radarOptions': {'width': 720},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'radar',
        'source': 'radar-beta\naxis speed\ncurve current { 1 }',
        'radarOptions': {'width': 0},
      }),
      throwsFormatException,
    );
  });

  test('fixture event modeling options are typed and event-modeling-only', () {
    final configured = ParityFixture.fromJson({
      'id': 'configured',
      'type': 'eventmodeling',
      'source': 'eventmodeling\ntimeframe 01 command Cart.Update\n',
      'eventModelingOptions': {'padding': 55, 'rowHeight': 48},
    });

    expect(configured.renderOptions.eventModeling.padding, 55);
    expect(configured.renderOptions.eventModeling.rowHeight, 48);
    expect(configured.mermaidConfig, {
      'eventmodeling': {'padding': 55, 'rowHeight': 48},
    });
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'info',
        'source': 'info',
        'eventModelingOptions': {'padding': 55},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'eventmodeling',
        'source': 'eventmodeling\ntimeframe 01 command Cart.Update\n',
        'eventModelingOptions': {'rowHeight': 0},
      }),
      throwsFormatException,
    );
  });

  test('fixture tree view options are typed and tree-view-only', () {
    final configured = ParityFixture.fromJson({
      'id': 'configured',
      'type': 'treeView',
      'source': 'treeView-beta\nsrc/\n',
      'treeViewOptions': {
        'rowIndent': 24,
        'paddingX': 8,
        'paddingY': 7,
        'lineThickness': 3,
        'showIcons': true,
        'defaultIconPack': 'devicons',
        'filenameIcons': {'Dockerfile': 'docker'},
        'extensionIcons': {'.dart': 'dart'},
      },
    });

    expect(configured.renderOptions.treeView.rowIndent, 24);
    expect(configured.renderOptions.treeView.paddingX, 8);
    expect(configured.renderOptions.treeView.paddingY, 7);
    expect(configured.renderOptions.treeView.lineThickness, 3);
    expect(configured.renderOptions.treeView.showIcons, isTrue);
    expect(configured.renderOptions.treeView.defaultIconPack, 'devicons');
    expect(configured.renderOptions.treeView.filenameIcons, {'Dockerfile': 'docker'});
    expect(configured.renderOptions.treeView.extensionIcons, {'.dart': 'dart'});
    expect(configured.mermaidConfig, {
      'treeView': {
        'rowIndent': 24,
        'paddingX': 8,
        'paddingY': 7,
        'lineThickness': 3,
        'showIcons': true,
        'defaultIconPack': 'devicons',
        'filenameIcons': {'Dockerfile': 'docker'},
        'extensionIcons': {'.dart': 'dart'},
      },
    });
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'info',
        'source': 'info',
        'treeViewOptions': {'rowIndent': 24},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'treeView',
        'source': 'treeView-beta\nsrc/\n',
        'treeViewOptions': {'paddingX': -1},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'treeView',
        'source': 'treeView-beta\nsrc/\n',
        'treeViewOptions': {'lineThickness': 0},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'treeView',
        'source': 'treeView-beta\nsrc/\n',
        'treeViewOptions': {
          'filenameIcons': {'Dockerfile': 42},
        },
      }),
      throwsFormatException,
    );
  });

  test('fixture Wardley options are typed and Wardley-only', () {
    final configured = ParityFixture.fromJson({
      'id': 'configured',
      'type': 'wardley',
      'source': 'wardley-beta\ncomponent API [0.6, 0.5]\n',
      'wardleyOptions': {
        'width': 720,
        'height': 480,
        'padding': 60,
        'nodeRadius': 10,
        'nodeLabelOffset': 14,
        'axisFontSize': 14,
        'labelFontSize': 12,
        'showGrid': true,
      },
    });

    expect(configured.renderOptions.wardley.width, 720);
    expect(configured.renderOptions.wardley.height, 480);
    expect(configured.renderOptions.wardley.padding, 60);
    expect(configured.renderOptions.wardley.nodeRadius, 10);
    expect(configured.renderOptions.wardley.nodeLabelOffset, 14);
    expect(configured.renderOptions.wardley.axisFontSize, 14);
    expect(configured.renderOptions.wardley.labelFontSize, 12);
    expect(configured.renderOptions.wardley.showGrid, isTrue);
    expect(configured.mermaidConfig, {
      'wardley-beta': {
        'width': 720,
        'height': 480,
        'padding': 60,
        'nodeRadius': 10,
        'nodeLabelOffset': 14,
        'axisFontSize': 14,
        'labelFontSize': 12,
        'showGrid': true,
      },
    });
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'pie',
        'source': 'pie\n"A": 1\n',
        'wardleyOptions': {'showGrid': true},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'wardley',
        'source': 'wardley-beta\ncomponent API [0.6, 0.5]\n',
        'wardleyOptions': {'nodeRadius': 0},
      }),
      throwsFormatException,
    );
  });

  test('fixture Cynefin options are typed and Cynefin-only', () {
    final configured = ParityFixture.fromJson({
      'id': 'configured',
      'type': 'cynefin',
      'source': 'cynefin-beta\ncomplex "Probe"\n',
      'cynefinOptions': {
        'width': 720,
        'height': 480,
        'padding': 30,
        'showDomainDescriptions': false,
        'boundaryAmplitude': 0,
        'seed': 42,
      },
    });

    expect(configured.renderOptions.cynefin.width, 720);
    expect(configured.renderOptions.cynefin.height, 480);
    expect(configured.renderOptions.cynefin.padding, 30);
    expect(configured.renderOptions.cynefin.showDomainDescriptions, isFalse);
    expect(configured.renderOptions.cynefin.boundaryAmplitude, 0);
    expect(configured.renderOptions.cynefin.seed, 42);
    expect(configured.mermaidConfig, {
      'cynefin': {
        'width': 720,
        'height': 480,
        'padding': 30,
        'showDomainDescriptions': false,
        'boundaryAmplitude': 0,
        'seed': 42,
      },
    });
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'pie',
        'source': 'pie\n"A": 1\n',
        'cynefinOptions': {'seed': 42},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'cynefin',
        'source': 'cynefin-beta\ncomplex "Probe"\n',
        'cynefinOptions': {'boundaryAmplitude': -1},
      }),
      throwsFormatException,
    );
  });

  test('fixture Railroad options are typed and shared by all four syntaxes', () {
    const options = {
      'compactMode': true,
      'padding': 12,
      'verticalSeparation': 16,
      'horizontalSeparation': 18,
      'arcRadius': 6,
      'fontSize': 18,
      'fontFamily': 'monospace',
      'terminalFill': '#112233',
      'terminalStroke': '#445566',
      'terminalTextColor': '#778899',
      'nonTerminalFill': '#aabbcc',
      'nonTerminalStroke': '#ddeeff',
      'nonTerminalTextColor': '#012345',
      'lineColor': '#6789ab',
      'strokeWidth': 3,
      'markerFill': '#cdef12',
      'commentFill': '#345678',
      'commentStroke': '#56789a',
      'commentTextColor': '#789abc',
      'specialFill': '#345678',
      'specialStroke': '#9abcde',
      'ruleNameColor': '#f0e1d2',
      'showMarkers': true,
      'markerRadius': 7,
    };
    const syntaxes = {
      'railroad': 'railroad-beta\nrule = terminal("a") ;\n',
      'railroadEbnf': 'railroad-ebnf-beta\nrule = "a" ;\n',
      'railroadAbnf': 'railroad-abnf-beta\nrule = "a" ;\n',
      'railroadPeg': 'railroad-peg-beta\nrule <- "a" ;\n',
    };

    for (final MapEntry(key: type, value: source) in syntaxes.entries) {
      final configured = ParityFixture.fromJson({
        'id': 'configured-$type',
        'type': type,
        'source': source,
        'railroadOptions': options,
      });

      expect(configured.renderOptions.railroad.compactMode, isTrue);
      expect(configured.renderOptions.railroad.padding, 12);
      expect(configured.renderOptions.railroad.verticalSeparation, 16);
      expect(configured.renderOptions.railroad.horizontalSeparation, 18);
      expect(configured.renderOptions.railroad.arcRadius, 6);
      expect(configured.renderOptions.railroad.fontSize, 18);
      expect(configured.renderOptions.railroad.fontFamily, 'monospace');
      expect(configured.renderOptions.railroad.terminalFill, const Color(17, 34, 51));
      expect(configured.renderOptions.railroad.terminalStroke, const Color(68, 85, 102));
      expect(configured.renderOptions.railroad.terminalTextColor, const Color(119, 136, 153));
      expect(configured.renderOptions.railroad.nonTerminalFill, const Color(170, 187, 204));
      expect(configured.renderOptions.railroad.nonTerminalStroke, const Color(221, 238, 255));
      expect(configured.renderOptions.railroad.nonTerminalTextColor, const Color(1, 35, 69));
      expect(configured.renderOptions.railroad.lineColor, const Color(103, 137, 171));
      expect(configured.renderOptions.railroad.strokeWidth, 3);
      expect(configured.renderOptions.railroad.markerFill, const Color(205, 239, 18));
      expect(configured.renderOptions.railroad.commentFill, const Color(52, 86, 120));
      expect(configured.renderOptions.railroad.commentStroke, const Color(86, 120, 154));
      expect(configured.renderOptions.railroad.commentTextColor, const Color(120, 154, 188));
      expect(configured.renderOptions.railroad.specialFill, const Color(52, 86, 120));
      expect(configured.renderOptions.railroad.specialStroke, const Color(154, 188, 222));
      expect(configured.renderOptions.railroad.ruleNameColor, const Color(240, 225, 210));
      expect(configured.renderOptions.railroad.showMarkers, isTrue);
      expect(configured.renderOptions.railroad.markerRadius, 7);
      expect(configured.mermaidConfig, {'railroad': options});
    }

    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'info',
        'source': 'info',
        'railroadOptions': {'padding': 12},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'railroad',
        'source': 'railroad-beta\nrule = terminal("a") ;\n',
        'railroadOptions': {'padding': -1},
      }),
      throwsFormatException,
    );
    expect(
      () => ParityFixture.fromJson({
        'id': 'configured',
        'type': 'railroad',
        'source': 'railroad-beta\nrule = terminal("a") ;\n',
        'railroadOptions': {'terminalFill': 'not a color'},
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
