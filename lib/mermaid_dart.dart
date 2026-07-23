/// Pure-Dart Mermaid parsing and backend-neutral rendering.
///
/// Use [parse] to create a typed diagram AST, [layoutDiagram] to produce a
/// geometry-complete [DiagramScene], and [renderSvg] or [renderDiagramSvg] to
/// serialize that scene as accessible SVG.
library;

export 'src/parser/ast.dart';
export 'src/parser/diagram_type.dart';
export 'src/parser/errors.dart';
export 'src/parser/parser.dart';
export 'src/rendering/rendering.dart';
