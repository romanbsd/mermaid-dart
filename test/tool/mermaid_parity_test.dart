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
    final comparison = SvgComparison.compare(left, different);
    expect(comparison.exact, isFalse);
    expect(comparison.sameViewport, isFalse);
    expect(comparison.sameText, isFalse);
    expect(comparison.sameElementCounts, isFalse);
    expect(comparison.summary, 'viewport, text, elements, geometry/style');
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
