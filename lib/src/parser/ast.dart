/// Typed abstract syntax trees produced by the Mermaid parsers.
///
/// Every concrete diagram extends [DiagramAst] and preserves common title and
/// accessibility metadata alongside diagram-specific semantic nodes.
library;

import 'package:collection/collection.dart';

import 'diagram_type.dart';

part 'architecture_ast.dart';
part 'ast_value_equality.dart';
part 'class_ast.dart';
part 'common_ast.dart';
part 'cynefin_ast.dart';
part 'er_ast.dart';
part 'event_modeling_ast.dart';
part 'flowchart_ast.dart';
part 'gantt_ast.dart';
part 'gantt_dates.dart';
part 'git_graph_ast.dart';
part 'info_ast.dart';
part 'kanban_ast.dart';
part 'mindmap_ast.dart';
part 'packet_ast.dart';
part 'pie_ast.dart';
part 'quadrant_chart_ast.dart';
part 'radar_ast.dart';
part 'railroad_ast.dart';
part 'sequence_ast.dart';
part 'state_ast.dart';
part 'timeline_ast.dart';
part 'tree_view_ast.dart';
part 'treemap_ast.dart';
part 'wardley_ast.dart';
part 'xy_chart_ast.dart';
