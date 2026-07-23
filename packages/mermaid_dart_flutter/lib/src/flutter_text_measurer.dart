import 'package:flutter/widgets.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;

/// Measures Mermaid scene text using Flutter's text shaping and font metrics.
final class FlutterTextMeasurer implements mermaid.TextMeasurer {
  /// Creates a Flutter-backed text measurer.
  const FlutterTextMeasurer({
    this.textDirection = TextDirection.ltr,
    this.textScaler = TextScaler.noScaling,
  });

  /// The direction used while shaping text.
  final TextDirection textDirection;

  /// The platform text scaling applied during measurement.
  final TextScaler textScaler;

  @override
  mermaid.Size measure(String text, mermaid.SceneTextStyle style) {
    final painter = createFlutterTextPainter(
      text,
      style,
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();
    return mermaid.Size(painter.width, painter.height);
  }
}

/// Creates the [TextStyle] used by Flutter measurement and Canvas painting.
TextStyle flutterTextStyle(mermaid.SceneTextStyle style) {
  final families = style.fontFamily
      .split(',')
      .map((family) => family.trim().replaceAll(RegExp(r'''^['"]|['"]$'''), ''))
      .where((family) => family.isNotEmpty)
      .toList();
  return TextStyle(
    color: flutterColor(style.color),
    fontFamily: families.firstOrNull,
    fontFamilyFallback: families.length > 1 ? families.sublist(1) : null,
    fontSize: style.fontSize,
    fontWeight: switch (style.weight) {
      mermaid.FontWeight.normal => FontWeight.w400,
      mermaid.FontWeight.medium => FontWeight.w500,
      mermaid.FontWeight.semibold => FontWeight.w600,
      mermaid.FontWeight.bold => FontWeight.w700,
    },
    fontStyle: switch (style.style) {
      mermaid.FontStyle.normal => FontStyle.normal,
      mermaid.FontStyle.italic => FontStyle.italic,
    },
    height: style.lineHeight,
  );
}

/// Creates a laid-out Flutter text painter configuration for scene text.
TextPainter createFlutterTextPainter(
  String text,
  mermaid.SceneTextStyle style, {
  TextDirection textDirection = TextDirection.ltr,
  TextScaler textScaler = TextScaler.noScaling,
}) => TextPainter(
  text: TextSpan(text: text, style: flutterTextStyle(style)),
  textDirection: textDirection,
  textScaler: textScaler,
);

/// Converts a backend-neutral Mermaid color to a Flutter color.
Color flutterColor(mermaid.Color color) =>
    Color.fromARGB(color.alpha, color.red, color.green, color.blue);
