/// Backend-neutral Mermaid layout, scene, geometry, configuration, and SVG APIs.
///
/// Layout is intentionally separated from serialization so the same
/// [DiagramScene] can be consumed by SVG and future drawing backends.
library;

export 'layout.dart' show layoutDiagram, renderDiagramSvg;
export 'geometry/scene_bounds.dart';
export 'options.dart';
export 'scene.dart';
export 'svg.dart' show renderSvg;
