# mermaid_dart

A pure Dart port of Mermaid.js. The project is being implemented in verified,
diagram-by-diagram slices while preserving Mermaid's grammar and algorithms.

## Parser status

The public `parse(diagramType, source)` API and the `info`, `pie`, `packet`,
`radar`, `cynefin`, `gitGraph`, `architecture`, `treeView`, and `eventmodeling`
diagram grammars are implemented. The parser supports Mermaid titles,
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

Other diagram types currently throw `UnsupportedDiagramTypeException` and will
be added incrementally.

## Usage

```dart
import 'package:mermaid_dart/mermaid_dart.dart';

void main() {
  final ast = parse(
    'info',
    'info showInfo\ntitle Mermaid in Dart\naccDescr: Parser example',
  );
  print(ast);
}
```
