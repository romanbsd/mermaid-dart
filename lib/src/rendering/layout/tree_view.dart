part of '../layout.dart';

// Mermaid treeView renders a synthetic filesystem root. The remaining values
// describe its icon, description, and hover-highlight geometry.
const _treeRootName = '/';
const _treeLabelFontSize = 16.0;
const _treeIconSize = 14.0;
const _treeIconGap = 4.0;
const _treeIconLabelOffset = _treeIconSize + _treeIconGap;
const _treeDescriptionGap = 16.0;
const _treeHighlightVerticalInset = 1.0;
const _treeHighlightRightOverflow = 8.0;
const _treeHighlightStrokeAllowance = 2.0;
const _treeHighlightCornerRadius = 3.0;
final _treeClassWhitespace = RegExp(r'\s+');

final class _TreeLayoutNode {
  _TreeLayoutNode({
    required this.name,
    required this.directory,
    required this.depth,
    required this.cssClasses,
    this.description,
    this.explicitIcon,
  });

  final String name;
  final bool directory;
  final int depth;
  final List<String> cssClasses;
  final String? description;
  final String? explicitIcon;
  int? lastChildIndex;

  bool get highlighted => cssClasses.contains('highlight');
}

final class _TreeLayoutRow {
  const _TreeLayoutRow({
    required this.node,
    required this.x,
    required this.top,
    required this.height,
    required this.labelRightEdge,
    required this.children,
  });

  final _TreeLayoutNode node;
  final double x;
  final double top;
  final double height;
  final double labelRightEdge;
  final List<SceneElement> children;

  double get centerY => top + height / 2;
}

SceneTextStyle _treeTextStyle(
  _LayoutContext context,
  Color color, {
  FontWeight weight = FontWeight.normal,
  FontStyle style = FontStyle.normal,
}) => SceneTextStyle(
  fontFamily: context.textStyle.fontFamily,
  // Both label and description selectors fix their size at 16px, overriding
  // the global SVG font size while still inheriting its font family.
  fontSize: _treeLabelFontSize,
  weight: weight,
  style: style,
  color: color,
  lineHeight: context.textStyle.lineHeight,
);

SceneStroke _treeStroke(Color color, double width) => SceneStroke(color: color, width: width);

String _treeQualifyIcon(String icon, TreeViewRenderOptions config) {
  if (icon.contains(':')) return icon;
  if (TreeViewRenderOptions.builtInIconNames.contains(icon) || config.defaultIconPack.isEmpty) {
    return '${TreeViewRenderOptions.builtInIconPack}:$icon';
  }
  return '${config.defaultIconPack}:$icon';
}

String? _treeIconReference({
  required String name,
  required bool directory,
  required String? explicitIcon,
  required TreeViewRenderOptions config,
}) {
  if (explicitIcon == TreeViewRenderOptions.noIcon) return null;
  if (explicitIcon != null && explicitIcon.isNotEmpty) {
    return _treeQualifyIcon(explicitIcon, config);
  }
  if (!config.showIcons) return null;

  String? detected;
  if (!directory) {
    detected = config.filenameIcons[name];
    if (detected == null || detected.isEmpty) {
      final dotIndex = name.lastIndexOf('.');
      if (dotIndex > 0) {
        final extension = name.substring(dotIndex).toLowerCase();
        detected = config.extensionIcons[extension] ?? config.extensionIcons[extension.substring(1)];
      }
    }
    if (detected == TreeViewRenderOptions.noIcon) return null;
    if (detected != null && detected.isNotEmpty) {
      return _treeQualifyIcon(detected, config);
    }
  }
  return directory ? TreeViewRenderOptions.builtInFolderIcon : TreeViewRenderOptions.builtInFileIcon;
}

List<_TreeLayoutNode> _buildTreeLayoutNodes(TreeViewAst ast) {
  final nodes = <_TreeLayoutNode>[
    _TreeLayoutNode(name: _treeRootName, directory: true, depth: 0, cssClasses: const []),
  ];
  final ancestors = <({int indent, int nodeIndex})>[];
  for (final astNode in ast.nodes) {
    final indent = astNode.indent ?? 0;
    while (ancestors.isNotEmpty && ancestors.last.indent >= indent) {
      ancestors.removeLast();
    }
    final parentIndex = ancestors.isEmpty ? 0 : ancestors.last.nodeIndex;
    final directory = astNode.name.endsWith('/');
    final nodeIndex = nodes.length;
    nodes[parentIndex].lastChildIndex = nodeIndex;
    nodes.add(
      _TreeLayoutNode(
        name: directory ? astNode.name.substring(0, astNode.name.length - 1) : astNode.name,
        directory: directory,
        depth: ancestors.length + 1,
        cssClasses: astNode.cssClass?.split(_treeClassWhitespace) ?? const [],
        description: astNode.description,
        explicitIcon: astNode.icon,
      ),
    );
    ancestors.add((indent: indent, nodeIndex: nodeIndex));
  }
  return nodes;
}

_LayoutResult _layoutTree(TreeViewAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const TreeViewRenderOptions());
  final textStyle = _treeTextStyle(context, config.labelColor);
  final directoryStyle = _treeTextStyle(context, config.labelColor, weight: FontWeight.bold);
  final descriptionStyle = _treeTextStyle(context, config.descriptionColor, style: FontStyle.italic);
  final elements = <SceneElement>[];
  final nodes = _buildTreeLayoutNodes(ast);
  final rows = <_TreeLayoutRow>[];
  var totalHeight = 0.0;
  var totalWidth = 0.0;
  for (final node in nodes) {
    final x = node.depth * (config.rowIndent + config.paddingX);
    final labelStyle = node.directory ? directoryStyle : textStyle;
    final measured = context.measurer.measure(node.name, labelStyle);
    final height = measured.height + config.paddingY * 2;
    final centerY = totalHeight + height / 2;
    final children = <SceneElement>[];
    final icon = _treeIconReference(
      name: node.name,
      directory: node.directory,
      explicitIcon: node.explicitIcon,
      config: config,
    );
    final hasIcon = icon != null;
    final labelX = x + config.paddingX + (hasIcon ? _treeIconLabelOffset : 0);
    if (icon != null) {
      children.add(
        _scaledIcon(
          context,
          icon,
          Point(x + config.paddingX, totalHeight + config.paddingY),
          _treeIconSize,
          idPrefix: 'tree',
          fill: SolidFill(config.iconColor),
          stroke: _treeStroke(config.iconColor, config.lineThickness),
          cssClasses: const ['treeView-node-icon'],
        ),
      );
    }
    children.add(
      _text(
        context,
        node.name,
        labelX,
        centerY,
        baseline: TextBaseline.middle,
        style: labelStyle,
        cssClasses: ['treeView-node-label', if (node.directory) 'treeView-node-dir', ...node.cssClasses],
      ),
    );
    rows.add(
      _TreeLayoutRow(
        node: node,
        x: x,
        top: totalHeight,
        height: height,
        labelRightEdge: labelX + measured.width,
        children: children,
      ),
    );
    totalWidth = math.max(totalWidth, x + measured.width + config.paddingX * 2 + (hasIcon ? _treeIconLabelOffset : 0));
    totalHeight += height;
  }

  final describedRows = rows.where((row) => row.node.description != null);
  if (describedRows.isNotEmpty) {
    final descriptionX = rows.map((row) => row.labelRightEdge).reduce(math.max) + _treeDescriptionGap;
    for (final row in describedRows) {
      final description = row.node.description!;
      row.children.add(
        _text(
          context,
          description,
          descriptionX,
          row.centerY,
          baseline: TextBaseline.middle,
          style: descriptionStyle,
          cssClasses: const ['treeView-node-description'],
        ),
      );
      totalWidth = math.max(
        totalWidth,
        descriptionX + context.measurer.measure(description, descriptionStyle).width + config.paddingX,
      );
    }
  }

  for (final row in rows) {
    final node = row.node;
    if (node.highlighted) {
      final width = totalWidth - row.x + _treeHighlightRightOverflow;
      row.children.insert(
        0,
        SceneRect(
          id: context.id('tree-highlight'),
          bounds: Bounds(
            left: row.x,
            top: row.top + _treeHighlightVerticalInset,
            width: width,
            height: row.height - _treeHighlightVerticalInset * 2,
          ),
          radiusX: _treeHighlightCornerRadius,
          radiusY: _treeHighlightCornerRadius,
          fill: SolidFill(config.highlightBackground),
          stroke: _treeStroke(config.highlightStroke, config.highlightStrokeWidth),
          cssClasses: const ['treeView-highlight-bg'],
        ),
      );
      totalWidth = math.max(totalWidth, row.x + width + _treeHighlightStrokeAllowance);
    }
    elements.add(
      SceneLine(
        id: context.id('tree-edge'),
        start: Point(row.x - config.rowIndent, row.centerY),
        end: Point(row.x, row.centerY),
        stroke: _treeStroke(config.lineColor, config.lineThickness),
        role: SemanticRole.edge,
        cssClasses: const ['treeView-node-line'],
      ),
    );
    if (node.lastChildIndex case final lastChildIndex?) {
      final lastChild = rows[lastChildIndex];
      elements.add(
        SceneLine(
          id: context.id('tree-edge'),
          start: Point(row.x + config.paddingX, row.top + row.height),
          end: Point(row.x + config.paddingX, lastChild.centerY + config.lineThickness / 2),
          stroke: _treeStroke(config.lineColor, config.lineThickness),
          role: SemanticRole.edge,
          cssClasses: const ['treeView-node-line'],
        ),
      );
    }
    elements.add(
      SceneGroup(
        id: context.id('tree-node'),
        children: row.children,
        role: SemanticRole.node,
        label: node.name,
        cssClasses: const ['treeView-node'],
      ),
    );
  }
  return _LayoutResult(totalWidth, totalHeight, [
    SceneGroup(id: context.id('tree-view'), children: elements, cssClasses: const ['tree-view']),
  ], bounds: Bounds(left: -config.lineThickness / 2, top: 0, width: totalWidth, height: totalHeight));
}
