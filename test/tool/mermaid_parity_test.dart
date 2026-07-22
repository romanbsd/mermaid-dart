import 'dart:io';

import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

import '../../tool/mermaid_parity/parity.dart';

void main() {
  test('fixture manifest is pinned and covers every renderer family', () {
    final manifest = ParityManifest.load(File('tool/mermaid_parity/fixtures.json'));

    expect(manifest.mermaidVersion, '11.16.0');
    expect(manifest.fixtures.map((fixture) => fixture.id), hasLength(12));
    expect(manifest.fixtures.map((fixture) => fixture.id).toSet(), hasLength(12));
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
}
