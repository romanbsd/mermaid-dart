import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';

void main() {
  test('measures text with the same Flutter metrics used for painting', () {
    const style = mermaid.SceneTextStyle(
      fontFamily: 'sans-serif',
      fontSize: 20,
      weight: mermaid.FontWeight.bold,
      style: mermaid.FontStyle.italic,
      lineHeight: 1.4,
    );
    const measurer = FlutterTextMeasurer();

    final actual = measurer.measure('first\nsecond', style);
    final expected = TextPainter(
      text: TextSpan(text: 'first\nsecond', style: flutterTextStyle(style)),
      textDirection: TextDirection.ltr,
    )..layout();

    expect(actual.width, expected.width);
    expect(actual.height, expected.height);
  });
}
