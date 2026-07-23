import 'package:flutter/widgets.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;

/// Resolves Mermaid icon references to Flutter font glyphs.
///
/// During layout, known references use fallback vector geometry when available
/// or an empty square otherwise, so the core renderer reserves and scales the
/// correct icon area. Flutter painters then replace that geometry with the
/// corresponding [IconData] glyph.
final class FlutterIconDataResolver implements mermaid.IconResolver {
  /// Creates a resolver backed by [icons].
  const FlutterIconDataResolver(
    this.icons, {
    this.size = 24,
    this.fallback = const mermaid.EmptyIconResolver(),
  }) : assert(size > 0);

  /// Icon references and their Flutter font glyphs.
  final Map<String, IconData> icons;

  /// The local square coordinate size reserved for each glyph.
  final double size;

  /// Supplies optional vector geometry and resolves unknown references.
  final mermaid.IconResolver fallback;

  /// Returns the Flutter glyph associated with [reference].
  IconData? resolveIconData(String reference) => icons[reference];

  @override
  mermaid.IconGeometry? resolve(String reference) {
    final fallbackGeometry = fallback.resolve(reference);
    if (!icons.containsKey(reference)) return fallbackGeometry;
    return fallbackGeometry ??
        mermaid.IconGeometry(
          bounds: mermaid.Bounds(left: 0, top: 0, width: size, height: size),
        );
  }
}
