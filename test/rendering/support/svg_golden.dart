import 'dart:io';

import 'package:test/test.dart';
import 'package:xml/xml.dart';

void expectSvgGolden(String name, String svg) {
  final expected = File('test/rendering/goldens/$name.svg').readAsStringSync().trim();
  expect(normalizeSvg(svg), expected);
}

String normalizeSvg(String svg) => _normalizeNode(XmlDocument.parse(svg).rootElement);

String _normalizeNode(XmlNode node) {
  if (node is XmlText) return XmlText(node.value.trim()).toXmlString();
  if (node is! XmlElement) return '';
  final attributes = node.attributes.toList()
    ..sort((left, right) => left.name.qualified.compareTo(right.name.qualified));
  final children = node.children.map(_normalizeNode).where((child) => child.isNotEmpty).join();
  final attributeText = attributes
      .map((attribute) => ' ${attribute.name.qualified}="${XmlText(attribute.value).toXmlString()}"')
      .join();
  return '<${node.name.qualified}$attributeText>$children</${node.name.qualified}>';
}
