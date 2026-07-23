import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'paints Mermaid architecture icon colors instead of a placeholder',
    () async {
      final geometry = const mermaid.ArchitectureIconResolver().resolve(
        'server',
      );
      final scene = mermaid.DiagramScene(
        diagramType: mermaid.DiagramType.architecture,
        viewport: const mermaid.Bounds(left: 0, top: 0, width: 80, height: 80),
        bounds: const mermaid.Bounds(left: 0, top: 0, width: 80, height: 80),
        elements: [
          mermaid.SceneIcon(
            id: 'server',
            reference: 'server',
            position: const mermaid.Point(0, 0),
            geometry: geometry!,
          ),
        ],
      );
      final recorder = ui.PictureRecorder();

      MermaidScenePainter(
        scene,
      ).paint(ui.Canvas(recorder), const ui.Size(80, 80));
      final image = await recorder.endRecording().toImage(80, 80);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      expect(_pixel(bytes!, image.width, 5, 5), const [8, 126, 191, 255]);
      expect(_pixel(bytes, image.width, 40, 32), const [255, 255, 255, 255]);
    },
  );
}

List<int> _pixel(ByteData bytes, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return [
    bytes.getUint8(offset),
    bytes.getUint8(offset + 1),
    bytes.getUint8(offset + 2),
    bytes.getUint8(offset + 3),
  ];
}
