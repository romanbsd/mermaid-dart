# mermaid_dart

A pure Dart port of Mermaid.js. The project is being implemented in verified,
diagram-by-diagram slices while preserving Mermaid's grammar and algorithms.

## Parser status

The public `parse(DiagramType, source)` API and the `info`, `pie`, `packet`,
`radar`, `cynefin`, `gitGraph`, `architecture`, `treeView`, `eventmodeling`,
`railroad`, `railroadEbnf`, `railroadAbnf`, `railroadPeg`, `treemap`, and
`wardley` diagram grammars are implemented. The parser supports Mermaid titles,
accessibility metadata, comments, directives, frontmatter, and source-located
syntax errors.

Pie diagrams support `showData`, quoted labels, integer and decimal values,
negative values, and escaped label characters.

Packet diagrams support explicit bit positions, bit ranges, relative-width
blocks, and both `packet` and `packet-beta` headers.

Radar diagrams support labeled axes, positional and axis-qualified curves,
legend and scale options, and circle or polygon graticules.

Cynefin diagrams support all five enum-backed domains, domain items, and
optionally labeled transitions.

Git graphs support enum-backed directions and commit types, commits, branches,
checkout and switch statements, merges, cherry-picks, tags, and ordering.

Architecture diagrams support groups, services, junctions, labeled and
bidirectional edges, group-boundary modifiers, and enum-backed alignment hints.

Tree views support indentation, quoted and bare names, CSS classes, Iconify
annotations, descriptions, and directory names.

Event models support time and reset frames, enum-backed entity and payload
types, frame/data references, inline and block payloads, notes, and GWT flows.

The four railroad syntax frontends lower into one renderer-ready
`RailroadAst`. Its shared sealed node hierarchy covers terminals,
nonterminals, sequences, choices, optionals, repetitions, and special nodes,
so rendering logic does not depend on the source grammar.

Treemaps support sections, numeric leaves, indentation-preserving hierarchy
rows, inline class selectors, typed class definitions, and both stable and
beta headers.

Wardley maps support enum-backed strategies, link flows and line styles,
percentage-normalized coordinates, custom evolution stages, anchors,
components, pipelines, notes, annotations, accelerators, deaccelerators,
evolution trends, and size directives.

Use `parseByName(type, source)` when a diagram type arrives from an external
string-based API. Unsupported names throw `UnsupportedDiagramTypeException`.

## Mermaid.js parity

The differential harness compares deterministic Dart SVG output with SVGs from
the pinned Mermaid CLI 11.16.0 reference renderer. Its canonical comparison
ignores XML attribute order, generated IDs and their references, class-token
order, formatting whitespace, and insignificant numeric precision. Viewport,
visible text, element counts, geometry, and styles remain visible in the report.

Install the isolated reference toolchain and generate reference SVGs:

```sh
npm ci --prefix tool/mermaid_parity/reference
dart run tool/mermaid_parity.dart --update-reference --report-only
```

The runner uses `PUPPETEER_EXECUTABLE_PATH` when set, otherwise it detects
common Chrome/Chromium installations before falling back to Puppeteer's
downloaded browser.

After references exist, rerun the comparison without invoking Node:

```sh
dart run tool/mermaid_parity.dart --report-only
dart run tool/mermaid_parity.dart --fixture pie-usage --report-only
```

Omit `--report-only` to use visual parity as a failing CI gate. Exact canonical
SVG matches are reported separately because Mermaid uses CSS and wrapper markup
while the Dart serializer emits resolved backend-neutral scene styles.
Generated references and comparison artifacts are intentionally git-ignored.

## Usage

```dart
import 'package:mermaid_dart/mermaid_dart.dart';

void main() {
  final ast = parse(
    DiagramType.info,
    'info showInfo\ntitle Mermaid in Dart\naccDescr: Parser example',
  );
  print(ast);
}
```
