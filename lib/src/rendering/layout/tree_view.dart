part of '../layout.dart';

// Mermaid treeView renders a synthetic filesystem root. The remaining values
// describe its icon, description, and hover-highlight geometry.
const _treeRootName = '/';
const _treeIconExtent = 18.0;
const _treeDescriptionGap = 16.0;
const _treeHighlightVerticalInset = 1.0;
const _treeHighlightRightOverflow = 8.0;
const _treeHighlightStrokeAllowance = 2.0;
const _treeInk = Color(0, 0, 0);

SceneTextStyle _treeTextStyle(_LayoutContext context) => SceneTextStyle(
  fontFamily: context.textStyle.fontFamily,
  fontSize: context.textStyle.fontSize,
  color: _treeInk,
  lineHeight: context.textStyle.lineHeight,
);

SceneStroke _treeStroke(double width) => SceneStroke(color: _treeInk, width: width);

_LayoutResult _layoutTree(TreeViewAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const TreeViewRenderOptions());
  final textStyle = _treeTextStyle(context);
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
    final hasIcon = node.ast?.icon != null;
    final labelX = x + config.paddingX + (hasIcon ? _treeIconExtent : 0);
    if (node.ast?.icon case final icon?) {
      children.add(
        _scaledIcon(
          context,
          icon,
          Point(x + config.paddingX, totalHeight + config.paddingY),
          _treeIconExtent,
          idPrefix: 'tree',
          stroke: _treeStroke(config.lineThickness),
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
    totalWidth = math.max(totalWidth, x + measured.width + config.paddingX * 2 + (hasIcon ? _treeIconExtent : 0));
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
          style: textStyle,
          cssClasses: const ['treeView-node-description'],
        ),
      );
      totalWidth = math.max(
        totalWidth,
        descriptionX + context.measurer.measure(description, textStyle).width + config.paddingX,
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
          fill: SolidFill(context.options.theme.tertiary),
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
        stroke: _treeStroke(config.lineThickness),
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
          stroke: _treeStroke(config.lineThickness),
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
