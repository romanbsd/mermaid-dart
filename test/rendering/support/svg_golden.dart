import 'dart:io';

import 'package:mermaid_dart/src/rendering/svg_normalizer.dart';
import 'package:test/test.dart';

void expectSvgGolden(String name, String svg) {
  final expected = File('test/rendering/goldens/$name.svg').readAsStringSync().trim();
  expect(normalizeSvg(svg), expected);
}
