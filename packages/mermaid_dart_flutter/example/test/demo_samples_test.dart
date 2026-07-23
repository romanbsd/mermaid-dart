import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';
import 'package:mermaid_dart_flutter_example/demo_samples.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('contains one renderable sample for every supported diagram type', () {
    expect(
      demoSamples.map((sample) => sample.type).toSet(),
      DiagramType.values.toSet(),
    );
    expect(demoSamples, hasLength(DiagramType.values.length));

    for (final sample in demoSamples) {
      final scene = layoutDiagram(
        parse(sample.type, sample.source),
        textMeasurer: const FlutterTextMeasurer(),
        iconResolver: sample.iconResolver,
      );

      expect(
        scene.elements,
        isNotEmpty,
        reason: '${sample.type.name} should produce visible scene elements',
      );
    }
  });

  test('paints every supported diagram directly to a Flutter Canvas', () {
    for (final sample in demoSamples) {
      final scene = layoutDiagram(
        parse(sample.type, sample.source),
        textMeasurer: const FlutterTextMeasurer(),
        iconResolver: sample.iconResolver,
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      MermaidScenePainter(
        scene,
        iconDataResolver: sample.iconDataResolver,
      ).paint(canvas, ui.Size(scene.viewport.width, scene.viewport.height));

      recorder.endRecording().dispose();
    }
  });

  test('architecture sample demonstrates Flutter IconData resolution', () {
    final sample = demoSamples.singleWhere(
      (sample) => sample.type == DiagramType.architecture,
    );
    final resolver = sample.iconDataResolver;

    expect(resolver, isNotNull);
    expect(resolver!.resolveIconData('gallery:api'), Icons.api);
    expect(sample.source, contains('service api(gallery:api)'));
  });
}
