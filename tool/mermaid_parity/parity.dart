import 'dart:convert';
import 'dart:io';

import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart/src/rendering/svg_normalizer.dart';
import 'package:xml/xml.dart';

final class ParityManifest {
  ParityManifest({required this.mermaidVersion, required this.fixtures}) {
    if (mermaidVersion.isEmpty) throw const FormatException('mermaidVersion must not be empty');
    final identifiers = fixtures.map((fixture) => fixture.id).toSet();
    if (identifiers.length != fixtures.length) {
      throw const FormatException('Fixture IDs must be unique');
    }
  }

  factory ParityManifest.fromJson(Object? json) {
    if (json case {'mermaidVersion': final String version, 'fixtures': final List<Object?> fixtures}) {
      return ParityManifest(
        mermaidVersion: version,
        fixtures: fixtures.map(ParityFixture.fromJson).toList(growable: false),
      );
    }
    throw const FormatException('Invalid parity fixture manifest');
  }

  static ParityManifest load(File file) => ParityManifest.fromJson(jsonDecode(file.readAsStringSync()));

  final String mermaidVersion;
  final List<ParityFixture> fixtures;
}

final class ParityFixture {
  const ParityFixture({required this.id, required this.type, required this.source});

  factory ParityFixture.fromJson(Object? json) {
    if (json case {'id': final String id, 'type': final String type, 'source': final String source}) {
      if (id.isEmpty || source.isEmpty) throw const FormatException('Fixture fields must not be empty');
      return ParityFixture(id: id, type: DiagramType.fromWireName(type), source: source);
    }
    throw const FormatException('Invalid parity fixture');
  }

  final String id;
  final DiagramType type;
  final String source;
}

final class SvgSnapshot {
  SvgSnapshot._({required this.canonicalSvg, required this.viewBox, required this.text, required this.elementCounts});

  factory SvgSnapshot.fromSvg(String svg) {
    final canonicalSvg = canonicalizeSvgForComparison(svg);
    final document = XmlDocument.parse(canonicalSvg);
    const elementNames = {'circle', 'ellipse', 'line', 'path', 'polygon', 'polyline', 'rect', 'text'};
    final elements = document.descendants.whereType<XmlElement>().toList();
    final textElements = elements.where(
      (element) => element.name.local == 'text' || element.name.local == 'foreignObject',
    );
    return SvgSnapshot._(
      canonicalSvg: canonicalSvg,
      viewBox: document.rootElement.getAttribute('viewBox'),
      text: [for (final element in textElements) element.innerText.trim().replaceAll(RegExp(r'\s+'), ' ')],
      elementCounts: {
        for (final name in elementNames)
          name: name == 'text' ? textElements.length : elements.where((element) => element.name.local == name).length,
      },
    );
  }

  final String canonicalSvg;
  final String? viewBox;
  final List<String> text;
  final Map<String, int> elementCounts;
}

final class SvgComparison {
  const SvgComparison({
    required this.exact,
    required this.sameViewport,
    required this.sameText,
    required this.sameElementCounts,
  });

  factory SvgComparison.compare(SvgSnapshot dart, SvgSnapshot mermaid) => SvgComparison(
    exact: dart.canonicalSvg == mermaid.canonicalSvg,
    sameViewport: dart.viewBox == mermaid.viewBox,
    sameText: _listEquals(dart.text, mermaid.text),
    sameElementCounts: _mapEquals(dart.elementCounts, mermaid.elementCounts),
  );

  final bool exact;
  final bool sameViewport;
  final bool sameText;
  final bool sameElementCounts;

  String get summary => exact
      ? 'exact'
      : [
          if (!sameViewport) 'viewport',
          if (!sameText) 'text',
          if (!sameElementCounts) 'elements',
          'geometry/style',
        ].join(', ');
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (left.length != right.length) return false;
  for (final MapEntry(:key, :value) in left.entries) {
    if (right[key] != value) return false;
  }
  return true;
}
