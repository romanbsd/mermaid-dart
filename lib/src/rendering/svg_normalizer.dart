import 'package:xml/xml.dart';

/// Produces stable XML without changing SVG values.
///
/// This is useful for same-renderer golden tests, where attribute ordering and
/// formatting whitespace are incidental but every emitted value is relevant.
String normalizeSvg(String svg) => _serialize(XmlDocument.parse(svg).rootElement, const _Canonicalization());

/// Produces a stable SVG representation suitable for comparing renderers.
///
/// In addition to XML normalization, this removes differences caused by
/// generated identifiers, class-token ordering, and insignificant numeric
/// precision. Geometry and visible text remain part of the comparison.
String canonicalizeSvgForComparison(String svg, {int numericPrecision = 3}) {
  final root = XmlDocument.parse(svg).rootElement;
  final identifiers = <String, String>{};
  _visitElements(root, (element) {
    final id = element.getAttribute('id');
    if (id != null) identifiers.putIfAbsent(id, () => 'id${identifiers.length}');
  });
  return _serialize(
    root,
    _Canonicalization(
      identifiers: identifiers,
      numericPrecision: numericPrecision,
      normalizeClasses: true,
      normalizeTextWhitespace: true,
    ),
  );
}

const _numericAttributes = {
  'cx',
  'cy',
  'd',
  'dx',
  'dy',
  'height',
  'points',
  'r',
  'rx',
  'ry',
  'stroke-dasharray',
  'stroke-dashoffset',
  'stroke-width',
  'transform',
  'viewBox',
  'width',
  'x',
  'x1',
  'x2',
  'y',
  'y1',
  'y2',
};

final _number = RegExp(r'(^|[\s,()A-Za-z])(-?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)(?=$|[\s,()A-Za-z-])');
final _urlReference = RegExp(r'url\(#([^\)]+)\)');
final _whitespace = RegExp(r'\s+');

String _serialize(XmlNode node, _Canonicalization options) {
  if (node is XmlText) {
    final value = options.normalizeTextWhitespace ? node.value.trim().replaceAll(_whitespace, ' ') : node.value.trim();
    return XmlText(value).toXmlString();
  }
  if (node is! XmlElement) return '';

  final attributes = [
    for (final attribute in node.attributes)
      (name: attribute.name.qualified, value: _canonicalAttribute(attribute.name.qualified, attribute.value, options)),
  ]..sort((left, right) => left.name.compareTo(right.name));
  final children = node.children.map((child) => _serialize(child, options)).where((child) => child.isNotEmpty).join();
  final attributeText = attributes
      .map((attribute) => ' ${attribute.name}="${XmlText(attribute.value).toXmlString()}"')
      .join();
  return '<${node.name.qualified}$attributeText>$children</${node.name.qualified}>';
}

String _canonicalAttribute(String name, String value, _Canonicalization options) {
  final identifiers = options.identifiers;
  if (name == 'id') return identifiers[value] ?? value;
  if (name == 'class' && options.normalizeClasses) {
    final tokens = value.split(_whitespace)..sort();
    value = tokens.join(' ');
  }
  if (name == 'href' || name == 'xlink:href') {
    if (value.startsWith('#')) {
      value = '#${identifiers[value.substring(1)] ?? value.substring(1)}';
    }
  } else if (name == 'aria-labelledby' || name == 'aria-describedby') {
    value = value.split(_whitespace).map((id) => identifiers[id] ?? id).join(' ');
  } else {
    value = value.replaceAllMapped(_urlReference, (match) => 'url(#${identifiers[match[1]] ?? match[1]})');
  }
  if (options.numericPrecision case final precision? when _numericAttributes.contains(name)) {
    value = value.replaceAllMapped(_number, (match) {
      final parsed = double.parse(match[2]!);
      var formatted = parsed.toStringAsFixed(precision);
      formatted = formatted.replaceFirst(RegExp(r'\.?0+$'), '');
      if (formatted == '-0') formatted = '0';
      return '${match[1]}$formatted';
    });
  }
  return value;
}

void _visitElements(XmlElement element, void Function(XmlElement) visitor) {
  visitor(element);
  for (final child in element.childElements) {
    _visitElements(child, visitor);
  }
}

final class _Canonicalization {
  const _Canonicalization({
    this.identifiers = const {},
    this.numericPrecision,
    this.normalizeClasses = false,
    this.normalizeTextWhitespace = false,
  });

  final Map<String, String> identifiers;
  final int? numericPrecision;
  final bool normalizeClasses;
  final bool normalizeTextWhitespace;
}
