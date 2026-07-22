import 'ast.dart';
import 'architecture_parser.dart';
import 'cynefin_parser.dart';
import 'errors.dart';
import 'git_graph_parser.dart';
import 'info_parser.dart';
import 'packet_parser.dart';
import 'pie_parser.dart';
import 'radar_parser.dart';
import 'tree_view_parser.dart';

typedef _DiagramParser = DiagramAst Function(String source);

const Map<String, _DiagramParser> _parsers = {
  'architecture': parseArchitecture,
  'cynefin': parseCynefin,
  'gitGraph': parseGitGraph,
  'info': parseInfo,
  'packet': parsePacket,
  'pie': parsePie,
  'radar': parseRadar,
  'treeView': parseTreeView,
};

/// Parses [source] using the Mermaid grammar identified by [diagramType].
///
/// The string-based dispatch mirrors `@mermaid-js/parser` and lets additional
/// Mermaid grammars be added without changing this public API.
DiagramAst parse(String diagramType, String source) {
  final parser = _parsers[diagramType];
  if (parser == null) {
    throw UnsupportedDiagramTypeException(diagramType);
  }
  return parser(source);
}
