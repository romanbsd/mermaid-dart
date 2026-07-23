part of '../layout.dart';

// Mermaid treeView renders a synthetic filesystem root. The remaining values
// describe its icon, description, and hover-highlight geometry.
const _treeRootName = '/';
const _treeIconSize = 14.0;
const _treeIconGap = 4.0;
const _treeIconLabelOffset = _treeIconSize + _treeIconGap;
const _treeDescriptionGap = 16.0;
const _treeHighlightVerticalInset = 1.0;
const _treeHighlightRightOverflow = 8.0;
const _treeHighlightStrokeAllowance = 2.0;
SceneTextStyle _treeTextStyle(_LayoutContext context, Color color) => SceneTextStyle(
  fontFamily: context.textStyle.fontFamily,
  fontSize: context.textStyle.fontSize,
  color: color,
  lineHeight: context.textStyle.lineHeight,
);

SceneStroke _treeStroke(Color color, double width) => SceneStroke(color: color, width: width);

String _treeQualifyIcon(String icon, TreeViewRenderOptions config) {
  if (icon.contains(':')) return icon;
  if (icon == 'file' || icon == 'folder' || config.defaultIconPack.isEmpty) {
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
  if (explicitIcon == 'none') return null;
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
    if (detected == 'none') return null;
    if (detected != null && detected.isNotEmpty) {
      return _treeQualifyIcon(detected, config);
    }
  }
  return directory ? TreeViewRenderOptions.builtInFolderIcon : TreeViewRenderOptions.builtInFileIcon;
}

_LayoutResult _layoutTree(TreeViewAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const TreeViewRenderOptions());
  final textStyle = _treeTextStyle(context, config.labelColor);
  final descriptionStyle = _treeTextStyle(context, config.descriptionColor);
  final elements = <SceneElement>[];
  final indentStack = <int>[];
  final depths = <int>[];
  for (final node in ast.nodes) {
    final indent = node.indent ?? 0;
    while (indentStack.isNotEmpty && indentStack.last >= indent) {
      indentStack.removeLast();
    }
    depths.add(indentStack.length);
    indentStack.add(indent);
  }
  final nodes = <({TreeViewNodeAst? ast, String name, bool directory, int depth})>[
    (ast: null, name: _treeRootName, directory: true, depth: 0),
    for (var i = 0; i < ast.nodes.length; i++)
      (
        ast: ast.nodes[i],
        name: ast.nodes[i].name.endsWith('/')
            ? ast.nodes[i].name.substring(0, ast.nodes[i].name.length - 1)
            : ast.nodes[i].name,
        directory: ast.nodes[i].name.endsWith('/'),
        depth: depths[i] + 1,
      ),
  ];

  final labelRightEdges = <double>[];
  final rowTops = <double>[];
  final rowHeights = <double>[];
  final labelGroups = <List<SceneElement>>[];
  var totalHeight = 0.0;
  var totalWidth = 0.0;
  for (var i = 0; i < nodes.length; i++) {
    final node = nodes[i];
    final x = node.depth * (config.rowIndent + config.paddingX);
    final measured = context.measurer.measure(node.name, textStyle);
    final height = measured.height + config.paddingY * 2;
    final centerY = totalHeight + height / 2;
    final children = <SceneElement>[];
    final icon = _treeIconReference(
      name: node.name,
      directory: node.directory,
      explicitIcon: node.ast?.icon,
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
        style: textStyle,
        cssClasses: [
          'treeView-node-label',
          if (node.directory) 'treeView-node-dir',
          if (node.ast?.cssClass case final cssClass?) ...cssClass.split(RegExp(r'\s+')),
        ],
      ),
    );
    labelGroups.add(children);
    labelRightEdges.add(labelX + measured.width);
    rowTops.add(totalHeight);
    rowHeights.add(height);
    totalWidth = math.max(totalWidth, x + measured.width + config.paddingX * 2 + (hasIcon ? _treeIconLabelOffset : 0));
    totalHeight += height;
  }

  final descriptionIndices = <int>[
    for (var i = 0; i < nodes.length; i++)
      if (nodes[i].ast?.description != null) i,
  ];
  if (descriptionIndices.isNotEmpty) {
    final descriptionX = labelRightEdges.reduce(math.max) + _treeDescriptionGap;
    for (final i in descriptionIndices) {
      final description = nodes[i].ast!.description!;
      labelGroups[i].add(
        _text(
          context,
          description,
          descriptionX,
          rowTops[i] + rowHeights[i] / 2,
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

  for (var i = 0; i < nodes.length; i++) {
    final node = nodes[i];
    final depth = node.depth;
    final x = depth * (config.rowIndent + config.paddingX);
    final centerY = rowTops[i] + rowHeights[i] / 2;
    if (node.ast?.cssClass?.split(RegExp(r'\s+')).contains('highlight') ?? false) {
      final width = totalWidth - x + _treeHighlightRightOverflow;
      labelGroups[i].insert(
        0,
        SceneRect(
          id: context.id('tree-highlight'),
          bounds: Bounds(
            left: x,
            top: rowTops[i] + _treeHighlightVerticalInset,
            width: width,
            height: rowHeights[i] - _treeHighlightVerticalInset * 2,
          ),
          radiusX: 3,
          radiusY: 3,
          fill: SolidFill(config.highlightBackground),
          stroke: _treeStroke(config.highlightStroke, config.highlightStrokeWidth),
          cssClasses: const ['treeView-highlight-bg'],
        ),
      );
      totalWidth = math.max(totalWidth, x + width + _treeHighlightStrokeAllowance);
    }
    elements.add(
      SceneLine(
        id: context.id('tree-edge'),
        start: Point(x - config.rowIndent, centerY),
        end: Point(x, centerY),
        stroke: _treeStroke(config.lineColor, config.lineThickness),
        role: SemanticRole.edge,
        cssClasses: const ['treeView-node-line'],
      ),
    );
    var lastChild = -1;
    for (var candidate = i + 1; candidate < nodes.length && nodes[candidate].depth > depth; candidate++) {
      if (nodes[candidate].depth == depth + 1) lastChild = candidate;
    }
    if (lastChild >= 0) {
      elements.add(
        SceneLine(
          id: context.id('tree-edge'),
          start: Point(x + config.paddingX, rowTops[i] + rowHeights[i]),
          end: Point(x + config.paddingX, rowTops[lastChild] + rowHeights[lastChild] / 2 + config.lineThickness / 2),
          stroke: _treeStroke(config.lineColor, config.lineThickness),
          role: SemanticRole.edge,
          cssClasses: const ['treeView-node-line'],
        ),
      );
    }
    elements.add(
      SceneGroup(
        id: context.id('tree-node'),
        children: labelGroups[i],
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
