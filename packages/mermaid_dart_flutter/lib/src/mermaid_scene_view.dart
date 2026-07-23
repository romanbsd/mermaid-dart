import 'package:flutter/widgets.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;

import 'flutter_icon_data_resolver.dart';
import 'mermaid_scene_painter.dart';

/// Displays a laid-out Mermaid scene at its intrinsic viewport size.
final class MermaidSceneView extends StatelessWidget {
  /// Creates a Flutter view of [scene].
  const MermaidSceneView({
    required this.scene,
    this.includeSemantics = true,
    this.textScaler = TextScaler.noScaling,
    this.iconDataResolver,
    super.key,
  });

  /// The geometry-complete scene to display.
  final mermaid.DiagramScene scene;

  /// Whether to expose the scene title and description through [Semantics].
  final bool includeSemantics;

  /// The platform text scaling applied while painting.
  final TextScaler textScaler;

  /// Resolves scene icon references to Flutter font glyphs.
  final FlutterIconDataResolver? iconDataResolver;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final canvas = SizedBox(
      width: scene.viewport.width,
      height: scene.viewport.height,
      child: CustomPaint(
        painter: MermaidScenePainter(
          scene,
          textDirection: textDirection,
          textScaler: textScaler,
          iconDataResolver: iconDataResolver,
        ),
      ),
    );
    if (!includeSemantics) return canvas;
    final title = scene.accessibilityTitle ?? scene.title;
    final description = scene.accessibilityDescription ?? scene.description;
    return Semantics(
      image: true,
      label: [
        title,
        description,
      ].whereType<String>().where((value) => value.isNotEmpty).join('\n'),
      child: canvas,
    );
  }
}
