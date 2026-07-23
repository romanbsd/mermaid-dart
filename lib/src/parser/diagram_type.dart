import 'errors.dart';

/// A Mermaid grammar supported by this parser package.
///
/// [wireName] is used only at string interoperability boundaries, such as
/// accepting the diagram type returned by Mermaid's diagram detector.
enum DiagramType {
  /// Selects the architecture variant.
  architecture('architecture'),

  /// Selects the cynefin variant.
  cynefin('cynefin'),

  /// Selects the event modeling variant.
  eventModeling('eventmodeling'),

  /// Selects the Gantt variant.
  gantt('gantt'),

  /// Selects the git graph variant.
  gitGraph('gitGraph'),

  /// Selects the info variant.
  info('info'),

  /// Selects the kanban variant.
  kanban('kanban'),

  /// Selects the packet variant.
  packet('packet'),

  /// Selects the pie variant.
  pie('pie'),

  /// Selects the radar variant.
  radar('radar'),

  /// Selects the railroad variant.
  railroad('railroad'),

  /// Selects the railroad abnf variant.
  railroadAbnf('railroadAbnf'),

  /// Selects the railroad ebnf variant.
  railroadEbnf('railroadEbnf'),

  /// Selects the railroad peg variant.
  railroadPeg('railroadPeg'),

  /// Selects the tree view variant.
  treeView('treeView'),

  /// Selects the treemap variant.
  treemap('treemap'),

  /// Selects the wardley variant.
  wardley('wardley');

  const DiagramType(this.wireName);

  /// Mermaid's canonical case-sensitive identifier for this grammar.
  final String wireName;

  /// Returns the type whose [wireName] equals [wireName], or `null`.
  static DiagramType? tryFromWireName(String wireName) {
    for (final type in values) {
      if (type.wireName == wireName) return type;
    }
    return null;
  }

  /// Returns the type whose [wireName] equals [wireName].
  ///
  /// Throws [UnsupportedDiagramTypeException] when the name is unknown.
  static DiagramType fromWireName(String wireName) =>
      tryFromWireName(wireName) ?? (throw UnsupportedDiagramTypeException(wireName));
}
