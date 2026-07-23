import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paints scene geometry directly to a Canvas', () async {
    const scene = mermaid.DiagramScene(
      diagramType: mermaid.DiagramType.info,
      viewport: mermaid.Bounds(left: -5, top: -5, width: 20, height: 20),
      bounds: mermaid.Bounds(left: 0, top: 0, width: 10, height: 10),
      elements: [
        mermaid.SceneRect(
          id: 'rect',
          bounds: mermaid.Bounds(left: 0, top: 0, width: 10, height: 10),
          fill: mermaid.SolidFill(mermaid.Color(255, 0, 0)),
        ),
      ],
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    const MermaidScenePainter(scene).paint(canvas, const ui.Size(20, 20));
    final image = await recorder.endRecording().toImage(20, 20);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    expect(_pixel(bytes!, image.width, 10, 10), const [255, 0, 0, 255]);
    expect(_pixel(bytes, image.width, 1, 1), const [0, 0, 0, 0]);
  });

  test('applies group transforms and clip paths', () async {
    const clipPath = mermaid.ScenePath(
      id: 'clip-path',
      commands: [
        mermaid.MoveTo(mermaid.Point(0, 0)),
        mermaid.LineTo(mermaid.Point(5, 0)),
        mermaid.LineTo(mermaid.Point(5, 5)),
        mermaid.LineTo(mermaid.Point(0, 5)),
        mermaid.ClosePath(),
      ],
    );
    const scene = mermaid.DiagramScene(
      diagramType: mermaid.DiagramType.info,
      viewport: mermaid.Bounds(left: 0, top: 0, width: 20, height: 10),
      bounds: mermaid.Bounds(left: 10, top: 0, width: 5, height: 5),
      clips: [mermaid.SceneClip(id: 'clip', path: clipPath)],
      elements: [
        mermaid.SceneGroup(
          id: 'group',
          transforms: [mermaid.Translate(10, 0)],
          clipId: 'clip',
          children: [
            mermaid.SceneRect(
              id: 'rect',
              bounds: mermaid.Bounds(left: 0, top: 0, width: 10, height: 10),
              fill: mermaid.SolidFill(mermaid.Color(0, 0, 255)),
            ),
          ],
        ),
      ],
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    const MermaidScenePainter(scene).paint(canvas, const ui.Size(20, 10));
    final image = await recorder.endRecording().toImage(20, 10);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    expect(_pixel(bytes!, image.width, 12, 2), const [0, 0, 255, 255]);
    expect(_pixel(bytes, image.width, 17, 2), const [0, 0, 0, 0]);
  });

  test('paints an IconData glyph for a referenced scene icon', () async {
    const resolver = FlutterIconDataResolver({'app:letter': IconData(0x41)});
    const scene = mermaid.DiagramScene(
      diagramType: mermaid.DiagramType.architecture,
      viewport: mermaid.Bounds(left: 0, top: 0, width: 24, height: 24),
      bounds: mermaid.Bounds(left: 0, top: 0, width: 24, height: 24),
      elements: [
        mermaid.SceneIcon(
          id: 'letter',
          reference: 'app:letter',
          position: mermaid.Point(0, 0),
          geometry: mermaid.IconGeometry(
            bounds: mermaid.Bounds(left: 0, top: 0, width: 24, height: 24),
          ),
          fill: mermaid.SolidFill(mermaid.Color(255, 0, 0)),
        ),
      ],
    );
    final recorder = ui.PictureRecorder();

    const MermaidScenePainter(
      scene,
      iconDataResolver: resolver,
    ).paint(ui.Canvas(recorder), const ui.Size(24, 24));
    final image = await recorder.endRecording().toImage(24, 24);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    expect(
      _hasColor(bytes!, image.width, image.height, const [255, 0, 0, 255]),
      isTrue,
    );
  });
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

bool _hasColor(ByteData bytes, int width, int height, List<int> expected) {
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      if (_pixel(bytes, width, x, y) case final pixel
          when pixel[0] == expected[0] &&
              pixel[1] == expected[1] &&
              pixel[2] == expected[2] &&
              pixel[3] == expected[3]) {
        return true;
      }
    }
  }
  return false;
}
