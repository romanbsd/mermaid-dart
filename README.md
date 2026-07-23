# mermaid_dart

A pure-Dart Mermaid parser and renderer with verified visual parity against
Mermaid.js 11.16.0 for every diagram type currently supported by this package.

`mermaid_dart` runs without a browser, DOM, or JavaScript runtime. It parses
Mermaid source into typed Dart ASTs, lays those ASTs out as a backend-neutral
scene graph, and can serialize the scene as accessible SVG.

## Status

The parity suite currently covers 73 representative diagrams. All 73 pass
visual comparison against the pinned Mermaid.js 11.16.0 renderer:

```text
Result: 0 exact, 73 visual, 0 different, 0 errors
```

“Visual parity” means the viewport, visible text, element counts, geometry, and
paint agree within the harness tolerances. Canonical SVG strings are not
expected to be identical: Mermaid.js emits browser-oriented wrappers and CSS,
while this package serializes resolved styles from a backend-neutral scene.

Parity applies to the supported diagram types below. It does not imply support
for every diagram family available in Mermaid.js.

## Supported diagrams

| Diagram | `DiagramType` | Typical Mermaid header |
| --- | --- | --- |
| Architecture | `architecture` | `architecture-beta` |
| Cynefin | `cynefin` | `cynefin-beta` |
| Event Modeling | `eventModeling` | `eventmodeling` |
| Git Graph | `gitGraph` | `gitGraph` |
| Info | `info` | `info` |
| Packet | `packet` | `packet`, `packet-beta` |
| Pie | `pie` | `pie` |
| Radar | `radar` | `radar-beta` |
| Railroad | `railroad` | `railroad-beta` |
| Railroad ABNF | `railroadAbnf` | `railroad-abnf-beta` |
| Railroad EBNF | `railroadEbnf` | `railroad-ebnf-beta` |
| Railroad PEG | `railroadPeg` | `railroad-peg-beta` |
| Tree View | `treeView` | `treeView-beta` |
| Treemap | `treemap` | `treemap`, `treemap-beta` |
| Wardley Map | `wardley` | `wardley-beta` |

All four railroad syntaxes lower into the same typed `RailroadAst`, allowing
one layout implementation to render Railroad, ABNF, EBNF, and PEG input.

## Quick start

Import the package and render Mermaid source directly to SVG:

```dart
import 'package:mermaid_dart/mermaid_dart.dart';

void main() {
  final svg = renderDiagramSvg(
    DiagramType.pie,
    '''
pie showData
title Storage
"Used": 75
"Free": 25
''',
  );

  print(svg);
}
```

`renderDiagramSvg` is the convenience API for the complete pipeline:

```text
Mermaid source → typed AST → DiagramScene → SVG
```

## Parse, inspect, and render separately

Use the individual stages when you need to inspect the AST, customize layout,
or render the same scene through another backend:

```dart
import 'package:mermaid_dart/mermaid_dart.dart';

void main() {
  final ast = parse(
    DiagramType.packet,
    '''
packet-beta
0-7: "Source"
8-15: "Destination"
+16: "Payload"
''',
  );

  final scene = layoutDiagram(
    ast,
    options: const RenderOptions(padding: 12),
  );

  final svg = renderSvg(
    scene,
    options: const SvgRenderOptions(
      pretty: true,
      rootId: 'packet-diagram',
      widthMode: SvgWidthMode.fitContainer,
    ),
  );

  print(svg);
}
```

The resulting `DiagramScene` contains absolute geometry, bounds, paths,
transforms, resolved paint and text styles, stable element IDs, semantic roles,
clip paths, viewport policy, and accessibility metadata. It is intentionally
independent of SVG so it can also be consumed by custom drawing backends.

## Typed parsing

`parse` returns the concrete `DiagramAst` subtype associated with the selected
`DiagramType`:

```dart
final ast = parse(
  DiagramType.pie,
  '''
pie
"Dogs": 50
"Cats": 25
''',
);

if (ast case PieAst(:final sections)) {
  for (final section in sections) {
    print('${section.label}: ${section.value}');
  }
}
```

When a diagram type arrives from an external string API, use `parseByName`:

```dart
final ast = parseByName('gitGraph', source);
```

Wire names are case-sensitive. Unknown names throw
`UnsupportedDiagramTypeException`.

Syntax failures throw `MermaidParseException`, which includes the original
source, offset, and one-based line and column:

```dart
try {
  parse(DiagramType.pie, invalidSource);
} on MermaidParseException catch (error) {
  print('${error.line}:${error.column}: ${error.message}');
}
```

The parser handles Mermaid comments, directives, YAML frontmatter, titles, and
accessibility metadata without shifting diagnostic source offsets. Renderer
configuration is supplied through typed Dart options.

## Rendering configuration

Global theme values and diagram-specific settings are strongly typed:

```dart
final svg = renderDiagramSvg(
  DiagramType.pie,
  source,
  options: const RenderOptions(
    padding: 16,
    theme: MermaidTheme(
      background: Color(250, 250, 252),
      primary: Color(75, 92, 190),
      text: Color(24, 24, 27),
      fontFamily: 'Inter, sans-serif',
    ),
    pie: PieRenderOptions(
      donutHole: 0.45,
      legendPosition: PieLegendPosition.bottom,
    ),
  ),
);
```

`RenderOptions` exposes dedicated configuration objects for Architecture,
Cynefin, Event Modeling, Git Graph, Info, Packet, Pie, Radar, Railroad, Tree
View, Treemap, and Wardley Map renderers. Theme and renderer defaults follow
the corresponding Mermaid.js 11.16.0 behavior.

## Text measurement and icons

Layout depends on text metrics. The default `DeterministicTextMeasurer` is
stable across machines and suitable for servers, tests, and reproducible
output. Applications that need exact platform font metrics can implement
`TextMeasurer` and inject it into `layoutDiagram` or `renderDiagramSvg`.

Architecture and Tree View diagrams can resolve vector icons through an
injected `IconResolver`. The core package does not depend on an icon asset
system; unresolved icons use deterministic placeholder geometry.

```dart
final scene = layoutDiagram(
  ast,
  textMeasurer: platformTextMeasurer,
  iconResolver: applicationIconResolver,
);
```

Use the same measurer and resolver across rendering backends when their
geometry must remain identical.

## Accessible SVG

`renderSvg` emits:

- `role="img"` and a Mermaid diagram role description;
- `<title>` and `<desc>` elements when accessibility metadata is available;
- `aria-labelledby` and `aria-describedby` references;
- semantic roles and labels carried by scene elements;
- either fixed dimensions or responsive, container-fitting width.

Mermaid accessibility metadata can be provided in source:

```mermaid
pie
accTitle: Storage usage
accDescr: Used storage is three times larger than free storage
"Used": 75
"Free": 25
```

## Verifying Mermaid.js parity

The differential harness uses an isolated Mermaid CLI 11.16.0 reference
toolchain. Install it and regenerate reference SVGs with:

```sh
npm ci --prefix tool/mermaid_parity/reference
dart run tool/mermaid_parity.dart --update-reference --report-only
```

Once references exist, the comparison runs without invoking Node:

```sh
dart run tool/mermaid_parity.dart --report-only
dart run tool/mermaid_parity.dart --fixture pie-usage --report-only
```

Omit `--report-only` to make visual differences fail the command. Generated
reference SVGs, normalized output, and reports are intentionally ignored by
Git.

The reference renderer uses `PUPPETEER_EXECUTABLE_PATH` when set. Otherwise,
the harness checks common Chrome and Chromium locations before using
Puppeteer's downloaded browser.

## Development

The project is developed in diagram-sized, test-driven slices. Parser behavior
is covered by focused grammar tests, renderer behavior by geometry assertions
and SVG goldens, and upstream compatibility by the differential parity suite.

Before submitting a change, run:

```sh
dart format .
dart analyze
dart test
dart run tool/mermaid_parity.dart --report-only
```
