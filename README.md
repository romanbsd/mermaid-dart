# mermaid_dart

A pure Dart port of Mermaid.js. The project is being implemented in verified,
diagram-by-diagram slices while preserving Mermaid's grammar and algorithms.

## Parser status

The public `parse(diagramType, source)` API and the `info`, `pie`, and `packet`
diagram grammars are implemented. The parser supports Mermaid titles,
accessibility metadata, comments, directives, frontmatter, and source-located
syntax errors.

Pie diagrams support `showData`, quoted labels, integer and decimal values,
negative values, and escaped label characters.

Packet diagrams support explicit bit positions, bit ranges, relative-width
blocks, and both `packet` and `packet-beta` headers.

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
