import 'errors.dart';

/// A Mermaid grammar supported by this parser package.
///
/// [wireName] is used only at string interoperability boundaries, such as
/// accepting the diagram type returned by Mermaid's diagram detector.
enum DiagramType {
  architecture('architecture'),
  cynefin('cynefin'),
  eventModeling('eventmodeling'),
  gitGraph('gitGraph'),
  info('info'),
  packet('packet'),
  pie('pie'),
  radar('radar'),
  railroad('railroad'),
  railroadAbnf('railroadAbnf'),
  railroadEbnf('railroadEbnf'),
  railroadPeg('railroadPeg'),
  treeView('treeView'),
  treemap('treemap'),
  wardley('wardley');

  const DiagramType(this.wireName);

  final String wireName;

  static DiagramType? tryFromWireName(String wireName) {
    for (final type in values) {
      if (type.wireName == wireName) return type;
    }
    return null;
  }

  static DiagramType fromWireName(String wireName) =>
      tryFromWireName(wireName) ?? (throw UnsupportedDiagramTypeException(wireName));
}
