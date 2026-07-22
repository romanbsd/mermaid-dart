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
  const ParityFixture({required this.id, required this.type, required this.source, this.textMeasurements = const {}});

  factory ParityFixture.fromJson(Object? json) {
    if (json case {'id': final String id, 'type': final String type, 'source': final String source}) {
      if (id.isEmpty || source.isEmpty) throw const FormatException('Fixture fields must not be empty');
      final textMeasurements = switch (json['textMeasurements']) {
        null => const <String, Size>{},
        final Map<String, Object?> values => {
          for (final MapEntry(:key, :value) in values.entries) key: _textMeasurement(value),
        },
        _ => throw const FormatException('Invalid fixture textMeasurements'),
      };
      return ParityFixture(
        id: id,
        type: DiagramType.fromWireName(type),
        source: source,
        textMeasurements: textMeasurements,
      );
    }
    throw const FormatException('Invalid parity fixture');
  }

  final String id;
  final DiagramType type;
  final String source;
  final Map<String, Size> textMeasurements;

  TextMeasurer get textMeasurer => _FixtureTextMeasurer(textMeasurements);
}

Size _textMeasurement(Object? json) {
  if (json case {'width': final num width, 'height': final num height} when width >= 0 && height >= 0) {
    return Size(width.toDouble(), height.toDouble());
  }
  throw const FormatException('Invalid fixture text measurement');
}

final class _FixtureTextMeasurer implements TextMeasurer {
  const _FixtureTextMeasurer(this.measurements);

  final Map<String, Size> measurements;

  @override
  Size measure(String text, SceneTextStyle style) =>
      measurements[text] ?? const DeterministicTextMeasurer().measure(text, style);
}

final class SvgSnapshot {
  SvgSnapshot._({
    required this.canonicalSvg,
    required this.viewBox,
    required this.text,
    required this.elementCounts,
    required this.geometry,
  });

  factory SvgSnapshot.fromSvg(String svg) {
    final canonicalSvg = canonicalizeSvgForComparison(svg);
    final document = XmlDocument.parse(canonicalSvg);
    const elementNames = {'circle', 'ellipse', 'line', 'path', 'polygon', 'polyline', 'rect', 'text'};
    final elements = document.descendants.whereType<XmlElement>().toList();
    final comparableElements = elements.where((element) => _isComparableGeometryElement(element, document.rootElement));
    final textElements = comparableElements.where(
      (element) =>
          (element.name.local == 'text' || element.name.local == 'foreignObject') &&
          element.innerText.trim().isNotEmpty,
    );
    return SvgSnapshot._(
      canonicalSvg: canonicalSvg,
      viewBox: document.rootElement.getAttribute('viewBox'),
      text: [for (final element in textElements) _normalizedVisibleText(element)]..sort(),
      elementCounts: {
        for (final name in elementNames)
          name: name == 'text'
              ? textElements.length
              : comparableElements.where((element) => element.name.local == name).length,
      },
      geometry: _geometrySignatures(document.rootElement),
    );
  }

  final String canonicalSvg;
  final String? viewBox;
  final List<String> text;
  final Map<String, int> elementCounts;
  final List<String> geometry;
}

final class SvgComparison {
  const SvgComparison({
    required this.exact,
    required this.sameViewport,
    required this.sameText,
    required this.sameElementCounts,
    required this.sameGeometry,
  });

  factory SvgComparison.compare(SvgSnapshot dart, SvgSnapshot mermaid) => SvgComparison(
    exact: dart.canonicalSvg == mermaid.canonicalSvg,
    sameViewport: dart.viewBox == null || mermaid.viewBox == null || dart.viewBox == mermaid.viewBox,
    sameText: _listEquals(dart.text, mermaid.text),
    sameElementCounts: _mapEquals(dart.elementCounts, mermaid.elementCounts),
    sameGeometry: _listEquals(dart.geometry, mermaid.geometry),
  );

  final bool exact;
  final bool sameViewport;
  final bool sameText;
  final bool sameElementCounts;
  final bool sameGeometry;

  bool get visualParity => sameViewport && sameText && sameElementCounts && sameGeometry;

  String get summary => exact
      ? 'exact'
      : [
          if (!sameViewport) 'viewport',
          if (!sameText) 'text',
          if (!sameElementCounts) 'elements',
          if (!sameGeometry) 'geometry',
        ].join(', ');
}

const _visibleElements = {'circle', 'ellipse', 'foreignObject', 'line', 'path', 'polygon', 'polyline', 'rect', 'text'};

List<String> _geometrySignatures(XmlElement root) {
  final signatures = <String>[];
  final styleSheets = root.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 'style')
      .map((element) => element.innerText)
      .join('\n');

  void visit(XmlElement element, String inheritedTransform) {
    if (!_isComparableGeometryElement(element, root)) return;
    final ownTransform = element.getAttribute('transform') ?? '';
    final transform = [inheritedTransform, ownTransform].where((value) => value.isNotEmpty).join(' ');
    final isEmptyText =
        (element.name.local == 'text' || element.name.local == 'foreignObject') && element.innerText.trim().isEmpty;
    if (_visibleElements.contains(element.name.local) && !isEmptyText) {
      signatures.add(_geometrySignature(element, transform, styleSheets));
    }
    for (final child in element.childElements) {
      visit(child, transform);
    }
  }

  visit(root, '');
  return signatures..sort();
}

String _geometrySignature(XmlElement element, String transform, String styleSheets) {
  final styles = <String, String>{
    for (final declaration in (element.getAttribute('style') ?? '').split(';'))
      if (declaration.split(':') case [final name, final value]) name.trim(): value.trim(),
  };
  String attribute(String name, [String fallback = '']) => element.getAttribute(name) ?? styles[name] ?? fallback;
  final translation = _Translation.parse(transform);
  String x(String value) => translation == null ? value : _translatedNumber(value, translation.dx);
  String y(String value) => translation == null ? value : _translatedNumber(value, translation.dy);
  final name = element.name.local;
  final values = switch (name) {
    'circle' => [x(attribute('cx', '0')), y(attribute('cy', '0')), attribute('r', '0')],
    'ellipse' => [x(attribute('cx', '0')), y(attribute('cy', '0')), attribute('rx', '0'), attribute('ry', '0')],
    'line' => [x(attribute('x1', '0')), y(attribute('y1', '0')), x(attribute('x2', '0')), y(attribute('y2', '0'))],
    'path' => [_translatedPath(attribute('d'), translation)],
    'polygon' || 'polyline' => [_translatedPoints(attribute('points'), translation)],
    'rect' => [
      x(attribute('x', '0')),
      y(attribute('y', '0')),
      attribute('width', '0'),
      attribute('height', '0'),
      attribute('rx', '0'),
      attribute('ry', attribute('rx', '0')),
    ],
    'foreignObject' => _foreignObjectGeometryValues(element, translation),
    'text' => _textGeometryValues(element, translation, styleSheets, attribute),
    _ => const <String>[],
  };
  final kind = name == 'foreignObject' ? 'text' : name;
  final text = name == 'text' || name == 'foreignObject' ? _normalizedVisibleText(element) : '';
  return [kind, if (translation == null) _normalizedTransform(transform) else '', ...values, text].join('|');
}

bool _isComparableGeometryElement(XmlElement element, XmlElement root) {
  for (XmlElement? ancestor = element; ancestor != null && ancestor != root; ancestor = ancestor.parentElement) {
    final classes = (ancestor.getAttribute('class') ?? '').split(RegExp(r'\s+'));
    if (ancestor.name.local == 'svg' ||
        ancestor.name.local == 'defs' ||
        ancestor.getAttribute('data-role') == 'icon' ||
        classes.contains('em-arrowhead')) {
      return false;
    }
  }
  if (element.name.local == 'rect' &&
      (_numberAttribute(element, 'width') ?? 0) == 0 &&
      (_numberAttribute(element, 'height') ?? 0) == 0) {
    return false;
  }
  return true;
}

double? _numberAttribute(XmlElement element, String name) => double.tryParse(element.getAttribute(name) ?? '');

List<String> _foreignObjectGeometryValues(XmlElement element, _Translation? translation) {
  final left = _numberAttribute(element, 'x') ?? 0;
  final top = _numberAttribute(element, 'y') ?? 0;
  final width = _numberAttribute(element, 'width') ?? 0;
  final height = _numberAttribute(element, 'height') ?? 0;
  return [
    _formatNumber(left + width / 2 + (translation?.dx ?? 0)),
    _formatNumber(top + height / 2 + (translation?.dy ?? 0)),
    '16',
    'middle',
    'central',
  ];
}

String _normalizedVisibleText(XmlElement element) {
  final buffer = StringBuffer();

  void collect(XmlNode node) {
    switch (node) {
      case XmlText(:final value):
        buffer.write(value.replaceAll('\u00a0', ' '));
      case XmlElement() when node.name.local == 'br':
        buffer.write(' ');
      case XmlElement(:final children) when node.name.local == 'tspan':
        for (final child in children) {
          collect(child);
        }
        buffer.write(' ');
      case XmlElement(:final children):
        for (final child in children) {
          collect(child);
        }
      default:
        break;
    }
  }

  collect(element);
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

List<String> _textGeometryValues(
  XmlElement element,
  _Translation? translation,
  String styleSheets,
  String Function(String name, [String fallback]) attribute,
) {
  final fontSize = _svgLength(attribute('font-size', _stylesheetFontSize(element, styleSheets) ?? '16'), 16);
  final span = element.descendants.whereType<XmlElement>().where((child) => child.name.local == 'tspan').firstOrNull;
  final localX = _svgLength(span?.getAttribute('x') ?? attribute('x', '0'), fontSize);
  final localY =
      _svgLength(span?.getAttribute('y') ?? attribute('y', '0'), fontSize) +
      _svgLength(span?.getAttribute('dy') ?? '0', fontSize);
  final anchor =
      attribute('text-anchor', '').nullIfEmpty ??
      _inheritedAttribute(element, 'text-anchor') ??
      _stylesheetTextAnchor(element, styleSheets) ??
      'start';
  final rawBaseline =
      attribute('dominant-baseline', '').nullIfEmpty ??
      _inheritedAttribute(element, 'dominant-baseline') ??
      _stylesheetBaseline(element, styleSheets) ??
      'alphabetic';
  final baseline = switch (rawBaseline) {
    'auto' => 'alphabetic',
    'start' => 'hanging',
    final value => value,
  };
  return [
    _formatNumber(localX + (translation?.dx ?? 0)),
    _formatNumber(localY + (translation?.dy ?? 0)),
    _formatNumber(fontSize),
    anchor,
    baseline,
  ];
}

String? _inheritedAttribute(XmlElement element, String name) {
  for (var ancestor = element.parentElement; ancestor != null; ancestor = ancestor.parentElement) {
    if (ancestor.getAttribute(name) case final value?) return value;
  }
  return null;
}

double _svgLength(String value, double fontSize) {
  final trimmed = value.trim();
  if (trimmed.endsWith('em')) return double.parse(trimmed.substring(0, trimmed.length - 2)) * fontSize;
  if (trimmed.endsWith('px')) return double.parse(trimmed.substring(0, trimmed.length - 2));
  return double.parse(trimmed);
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

String _normalizedTransform(String transform) => _transformFunction
    .allMatches(transform)
    .map((match) {
      final values = _pathToken.allMatches(match[2]!).map((value) => _formatNumber(double.parse(value[0]!))).join(' ');
      return '${match[1]!.toLowerCase()}($values)';
    })
    .join(' ');

final class _Translation {
  const _Translation(this.dx, this.dy);

  static _Translation? parse(String transform) {
    if (transform.trim().isEmpty) return const _Translation(0, 0);
    final matches = _translate.allMatches(transform).toList();
    if (matches.isEmpty || transform.replaceAll(_translate, '').trim().isNotEmpty) return null;
    var dx = 0.0;
    var dy = 0.0;
    for (final match in matches) {
      dx += double.parse(match[1]!);
      dy += double.parse(match[2] ?? '0');
    }
    return _Translation(dx, dy);
  }

  final double dx;
  final double dy;
}

final _translate = RegExp(
  r'translate\(\s*(-?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?)'
  r'(?:\s*[, ]\s*(-?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?))?\s*\)',
  caseSensitive: false,
);
final _pathToken = RegExp(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?', caseSensitive: false);
final _transformFunction = RegExp(r'([A-Za-z]+)\s*\(([^)]*)\)');

String _translatedNumber(String value, double offset) => _formatNumber(double.parse(value) + offset);

String _formatNumber(double value) {
  var formatted = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  if (formatted == '-0') formatted = '0';
  return formatted;
}

String? _stylesheetFontSize(XmlElement element, String styleSheets) {
  String? fontSize;
  for (final rule in _cssRule.allMatches(styleSheets)) {
    final declaration = _cssFontSize.firstMatch(rule[2]!);
    if (declaration == null) continue;
    for (final selector in rule[1]!.split(',')) {
      if (_matchesSimpleSelector(element, selector.trim())) {
        fontSize = _formatNumber(double.parse(declaration[1]!));
      }
    }
  }
  return fontSize;
}

String? _stylesheetBaseline(XmlElement element, String styleSheets) =>
    _stylesheetValue(element, styleSheets, _cssBaseline);

String? _stylesheetTextAnchor(XmlElement element, String styleSheets) =>
    _stylesheetValue(element, styleSheets, _cssTextAnchor);

String? _stylesheetValue(XmlElement element, String styleSheets, RegExp declarationPattern) {
  String? value;
  for (final rule in _cssRule.allMatches(styleSheets)) {
    final declaration = declarationPattern.firstMatch(rule[2]!);
    if (declaration == null) continue;
    for (final selector in rule[1]!.split(',')) {
      if (_matchesSimpleSelector(element, selector.trim())) value = declaration[1];
    }
  }
  return value;
}

bool _matchesSimpleSelector(XmlElement element, String selector) {
  final parts = selector.split(RegExp(r'\s+'));
  if (parts.first.startsWith('#')) parts.removeAt(0);
  if (parts.isEmpty) return true;
  if (!_matchesSelectorPart(element, parts.last)) return false;
  var ancestor = element.parentElement;
  for (var index = parts.length - 2; index >= 0; index--) {
    while (ancestor != null && !_matchesSelectorPart(ancestor, parts[index])) {
      ancestor = ancestor.parentElement;
    }
    if (ancestor == null) return false;
    ancestor = ancestor.parentElement;
  }
  return true;
}

bool _matchesSelectorPart(XmlElement element, String selector) {
  selector = selector.replaceFirst(RegExp(r':.*$'), '');
  if (selector.startsWith('#')) return element.getAttribute('id') == selector.substring(1);
  if (selector.startsWith('.')) {
    return (element.getAttribute('class') ?? '').split(RegExp(r'\s+')).contains(selector.substring(1));
  }
  return element.name.local == selector;
}

final _cssRule = RegExp(r'([^{}]+)\{([^{}]*)\}');
final _cssFontSize = RegExp(r'font-size\s*:\s*(-?(?:\d+\.?\d*|\.\d+))px', caseSensitive: false);
final _cssBaseline = RegExp(r'dominant-baseline\s*:\s*([\w-]+)', caseSensitive: false);
final _cssTextAnchor = RegExp(r'text-anchor\s*:\s*([\w-]+)', caseSensitive: false);

String _translatedPoints(String points, _Translation? translation) {
  final values = _pathToken.allMatches(points).map((match) => double.parse(match[0]!)).toList();
  return [
    for (var index = 0; index < values.length; index += 2)
      '${_formatNumber(values[index] + (translation?.dx ?? 0))},'
          '${_formatNumber(values[index + 1] + (translation?.dy ?? 0))}',
  ].join(' ');
}

String _translatedPath(String path, _Translation? translation) {
  final tokens = _pathToken.allMatches(path).map((match) => match[0]!).toList();
  final result = <String>[];
  String? command;
  var parameter = 0;
  for (final token in tokens) {
    if (RegExp(r'^[A-Za-z]$').hasMatch(token)) {
      command = token;
      parameter = 0;
      result.add(token);
      continue;
    }
    final value = double.parse(token);
    final offset = command == null || command == command.toLowerCase()
        ? 0.0
        : switch (command.toUpperCase()) {
            'H' => translation?.dx ?? 0,
            'V' => translation?.dy ?? 0,
            'M' || 'L' || 'T' => parameter.isEven ? translation?.dx ?? 0 : translation?.dy ?? 0,
            'C' => switch (parameter % 6) {
              0 || 2 || 4 => translation?.dx ?? 0,
              _ => translation?.dy ?? 0,
            },
            'S' || 'Q' => switch (parameter % 4) {
              0 || 2 => translation?.dx ?? 0,
              _ => translation?.dy ?? 0,
            },
            'A' => switch (parameter % 7) {
              5 => translation?.dx ?? 0,
              6 => translation?.dy ?? 0,
              _ => 0,
            },
            _ => 0,
          };
    result.add(_formatNumber(value + offset));
    parameter++;
  }
  return result.join(' ');
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
