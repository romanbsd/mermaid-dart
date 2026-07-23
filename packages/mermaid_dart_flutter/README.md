# mermaid_dart_flutter

Flutter Canvas rendering for the backend-neutral scenes produced by
`mermaid_dart`. The core package remains usable in Dart-only environments.

There are three API levels. All three paint directly to Flutter Canvas; none
uses SVG.

## 1. Source to widget: `MermaidDiagram`

Use `MermaidDiagram` when you have Mermaid source and simply want a widget. It
performs parsing, layout with Flutter text metrics, and painting for you.

```dart
import 'package:flutter/widgets.dart';
import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';

const diagram = MermaidDiagram(
  diagramType: DiagramType.pie,
  source: '''
pie
title Pets
  "Dogs" : 60
  "Cats" : 40
''',
);
```

This is the shortest API. It still accepts `RenderOptions`, an `IconResolver`,
text scaling, and a switch for accessibility semantics.

## Flutter `IconData`

Use `FlutterIconDataResolver` when an application already represents icons
with Flutter's `IconData`. The resolver reserves square geometry during core
layout, and the Canvas painter replaces that geometry with the corresponding
font glyph:

```dart
import 'package:flutter/material.dart';
import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';

const icons = FlutterIconDataResolver({
  'acme:cache': Icons.cached,
  'acme:api': Icons.api,
});

const diagram = MermaidDiagram(
  diagramType: DiagramType.architecture,
  source: '''
architecture-beta
service cache(acme:cache)[Cache]
service api(acme:api)[API]
cache:R -- L:api
''',
  iconResolver: icons,
);
```

`MermaidDiagram` automatically uses the resolver for both layout and painting.
When the application builds or caches a scene itself, pass the same resolver
to both stages:

```dart
final scene = layoutDiagram(
  ast,
  textMeasurer: const FlutterTextMeasurer(),
  iconResolver: icons,
);

return MermaidSceneView(
  scene: scene,
  iconDataResolver: icons,
);
```

`MermaidScenePainter` accepts the same `iconDataResolver` argument for direct
Canvas use. Unknown references are delegated to the resolver's optional
vector `fallback`, then to Mermaid-Dart's normal bundled-icon and placeholder
chain.

An `IconData` glyph has no portable vector path in the generated scene.
Consequently, a reference owned only by `FlutterIconDataResolver` is visible
on Flutter Canvas but not in SVG rendered from that scene. Provide equivalent
`IconGeometry` through `fallback` when identical Flutter and SVG output is
required.

## 2. Scene to widget: `MermaidSceneView`

Parse and lay out the source yourself when you need to:

- catch or display parse errors before building the rendering widget;
- inspect the typed AST or the generated scene;
- cache a scene instead of repeating parsing and layout during widget rebuilds;
- configure layout with `RenderOptions` or a custom `IconResolver`;
- render the same `DiagramScene` as both Flutter Canvas and SVG.

Use `FlutterTextMeasurer` during layout so the calculated text bounds use the
same Flutter font metrics as the painter:

```dart
final ast = parse(DiagramType.info, '''
info
accTitle: Runtime information
accDescr: Generated without SVG
''');

final scene = layoutDiagram(
  ast,
  options: const RenderOptions(padding: 12),
  textMeasurer: const FlutterTextMeasurer(),
  iconResolver: const PlaceholderIconResolver(),
);

return MermaidSceneView(scene: scene);
```

`MermaidSceneView` is an intrinsic-sized convenience wrapper around
`CustomPaint`. It also exposes the scene title and description through Flutter
semantics.

## 3. Scene to Canvas: `MermaidScenePainter`

Use the painter directly when your application owns the `CustomPaint` widget
and needs custom sizing, alignment, stacking, clipping, animation, or repaint
boundaries:

```dart
return SizedBox(
  width: availableWidth,
  height: availableHeight,
  child: CustomPaint(
    painter: MermaidScenePainter(
      scene,
      alignment: Alignment.topCenter,
    ),
  ),
);
```

The painter preserves the scene aspect ratio and scales it to fit the available
canvas. It handles scene primitives, paths and elliptical arcs, group
transforms, clip paths, dashed strokes, icons, text, and the scene background.
When using it directly, add your own `Semantics` widget if accessibility
metadata should be exposed.

## Text direction and scaling

You do not normally need to provide `textDirection`. The defaults are:

- `MermaidDiagram` reads the surrounding Flutter `Directionality`;
- `MermaidSceneView` reads the surrounding Flutter `Directionality`;
- `FlutterTextMeasurer` and `MermaidScenePainter` default to left-to-right.

For right-to-left or bidirectional text, use the same direction and text scaler
during layout and painting so the measured geometry matches the rendered text:

```dart
final direction = Directionality.of(context);
final scaler = MediaQuery.textScalerOf(context);
final scene = layoutDiagram(
  ast,
  textMeasurer: FlutterTextMeasurer(
    textDirection: direction,
    textScaler: scaler,
  ),
);

return MermaidSceneView(scene: scene, textScaler: scaler);
```

`MermaidSceneView` obtains `direction` from the same context automatically. If
you use `MermaidScenePainter` directly for RTL text, pass `textDirection:
direction` to the painter as well.

## Which API should I use?

| Starting point | Requirement | API |
| --- | --- | --- |
| Mermaid source | Render it with minimal setup | `MermaidDiagram` |
| `DiagramScene` | Intrinsic-sized widget with semantics | `MermaidSceneView` |
| `DiagramScene` | Full control over `CustomPaint` and sizing | `MermaidScenePainter` |

## Demo gallery

The [`example`](example) application renders one representative example for
every supported `DiagramType` in a responsive, searchable gallery:

```shell
cd example
flutter run -d chrome
```
