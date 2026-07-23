import 'package:flutter/widgets.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;

import 'flutter_icon_data_resolver.dart';
import 'flutter_text_measurer.dart';
import 'mermaid_scene_view.dart';

/// Parses, lays out, and paints Mermaid source without an SVG intermediary.
final class MermaidDiagram extends StatelessWidget {
  /// Creates a Flutter-rendered Mermaid diagram.
  const MermaidDiagram({
    required this.diagramType,
    required this.source,
    this.options = const mermaid.RenderOptions(),
    this.iconResolver = const mermaid.EmptyIconResolver(),
    this.includeSemantics = true,
    this.textScaler = TextScaler.noScaling,
    super.key,
  });

  /// The Mermaid grammar and renderer family.
  final mermaid.DiagramType diagramType;

  /// The Mermaid source to parse.
  final String source;

  /// Typed layout and theme options.
  final mermaid.RenderOptions options;

  /// Resolves vector icon references during layout.
  final mermaid.IconResolver iconResolver;

  /// Whether to expose diagram accessibility metadata.
  final bool includeSemantics;

  /// The platform text scaling used for measurement and painting.
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final scene = mermaid.layoutDiagram(
      mermaid.parse(diagramType, source),
      options: options,
      textMeasurer: FlutterTextMeasurer(
        textDirection: textDirection,
        textScaler: textScaler,
      ),
      iconResolver: iconResolver,
    );
    return MermaidSceneView(
      scene: scene,
      includeSemantics: includeSemantics,
      textScaler: textScaler,
      iconDataResolver: switch (iconResolver) {
        FlutterIconDataResolver resolver => resolver,
        _ => null,
      },
    );
  }
}
