import 'dart:io';

import 'package:mermaid_dart/src/rendering/svg_normalizer.dart';
import 'package:test/test.dart';

void expectSvgGolden(String name, String svg) {
  final file = File('test/rendering/goldens/$name.svg');
  if (Platform.environment['UPDATE_GOLDENS'] == '1') {
    file.writeAsStringSync('${normalizeSvg(svg)}\n');
  }
  final expected = file.readAsStringSync().trim();
  expect(normalizeSvg(svg), normalizeSvg(expected));
}
