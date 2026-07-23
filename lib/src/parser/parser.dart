import 'ast.dart';
import 'architecture_parser.dart';
import 'cynefin_parser.dart';
import 'diagram_type.dart';
import 'event_modeling_parser.dart';
import 'flowchart_parser.dart';
import 'gantt_parser.dart';
import 'git_graph_parser.dart';
import 'info_parser.dart';
import 'kanban_parser.dart';
import 'packet_parser.dart';
import 'pie_parser.dart';
import 'radar_parser.dart';
import 'railroad_abnf_parser.dart';
import 'railroad_ebnf_parser.dart';
import 'railroad_parser.dart';
import 'railroad_peg_parser.dart';
import 'sequence_parser.dart';
import 'tree_view_parser.dart';
import 'treemap_parser.dart';
import 'wardley_parser.dart';

/// Parses [source] using the Mermaid grammar identified by [diagramType].
///
/// The returned concrete [DiagramAst] subtype matches [diagramType]. Syntax
/// failures throw [MermaidParseException] with a one-based source location.
DiagramAst parse(DiagramType diagramType, String source) => switch (diagramType) {
  DiagramType.architecture => parseArchitecture(source),
  DiagramType.cynefin => parseCynefin(source),
  DiagramType.eventModeling => parseEventModeling(source),
  DiagramType.flowchart => parseFlowchart(source),
  DiagramType.gantt => parseGantt(source),
  DiagramType.gitGraph => parseGitGraph(source),
  DiagramType.info => parseInfo(source),
  DiagramType.kanban => parseKanban(source),
  DiagramType.packet => parsePacket(source),
  DiagramType.pie => parsePie(source),
  DiagramType.radar => parseRadar(source),
  DiagramType.railroad => parseRailroad(source),
  DiagramType.railroadAbnf => parseRailroadAbnf(source),
  DiagramType.railroadEbnf => parseRailroadEbnf(source),
  DiagramType.railroadPeg => parseRailroadPeg(source),
  DiagramType.sequence => parseSequence(source),
  DiagramType.treeView => parseTreeView(source),
  DiagramType.treemap => parseTreemap(source),
  DiagramType.wardley => parseWardley(source),
};

/// Parses [source] using Mermaid's string [diagramType] identifier.
///
/// Prefer [parse] in typed Dart code. This entry point is intended for
/// interoperability with Mermaid detectors and serialized configuration.
/// An unknown name throws [UnsupportedDiagramTypeException].
DiagramAst parseByName(String diagramType, String source) => parse(DiagramType.fromWireName(diagramType), source);
