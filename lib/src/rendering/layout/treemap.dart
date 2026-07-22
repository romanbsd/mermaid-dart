part of '../layout.dart';

_LayoutResult _layoutTreemap(TreemapAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const TreemapRenderOptions());
  final classStyles = <String, _TreemapClassStyle>{
    for (final definition in ast.rows.whereType<TreemapClassDefAst>())
      definition.name: _parseTreemapClassStyle(definition.style),
  };
  final artificialRoot = _TreemapLayoutNode('root');
  final stack = <({int indent, _TreemapLayoutNode node})>[];
  for (final row in ast.rows.whereType<TreemapNodeRowAst>()) {
    final item = row.item;
    final node = switch (item) {
      TreemapSectionAst(:final name, :final classSelector) => _TreemapLayoutNode(name, cssClass: classSelector),
      TreemapLeafAst(:final name, :final value, :final classSelector) => _TreemapLayoutNode(
        name,
        ownValue: value.toDouble().abs(),
        cssClass: classSelector,
      ),
    };
    while (stack.isNotEmpty && stack.last.indent >= row.indent) {
      stack.removeLast();
    }
    (stack.isEmpty ? artificialRoot : stack.last.node).children.add(node);
    if (item is TreemapSectionAst) {
      stack.add((indent: row.indent, node: node));
    }
  }

  void sortByValue(_TreemapLayoutNode node) {
    for (final child in node.children) {
      sortByValue(child);
    }
    node.children.sort((left, right) => right.value.compareTo(left.value));
  }

  final root = artificialRoot.children.length == 1 ? artificialRoot.children.single : artificialRoot;
  sortByValue(root);
  final titleHeight = ast.title == null ? 0.0 : 30.0;
  final width = config.width;
  final height = config.height;
  final elements = <SceneElement>[];
  if (ast.title case final title?) {
    elements.add(
      _text(
        context,
        title,
        width / 2,
        titleHeight / 2,
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
        cssClasses: const ['treemapTitle'],
      ),
    );
  }

  final container = <SceneElement>[];
  var nextColor = 0;
  final sectionColors = <_TreemapLayoutNode, Color>{root: _palette.first};

  void drawLeaf(_TreemapLayoutNode leaf, Bounds bounds, Color color, int index) {
    final customStyle = leaf.cssClass == null ? null : classStyles[leaf.cssClass];
    final fillColor = customStyle?.fill ?? color;
    final strokeColor = customStyle?.stroke ?? fillColor;
    final groupChildren = <SceneElement>[
      SceneRect(
        id: context.id('treemap-leaf'),
        bounds: bounds,
        fill: SolidFill(fillColor),
        stroke: SceneStroke(color: strokeColor, width: 3),
        role: SemanticRole.node,
        cssClasses: const ['treemapLeaf'],
        label: leaf.label,
      ),
    ];
    final complex = _countTreemapLeaves(root) > 20;
    final labelPadding = complex ? 2.0 : 4.0;
    final minimum = complex ? 4.0 : 8.0;
    final threshold = complex ? 8.0 : 10.0;
    final availableWidth = bounds.width - labelPadding * 2;
    final availableHeight = bounds.height - labelPadding * 2;
    var labelSize = complex ? 16.0 : 38.0;
    final labelColor = customStyle?.text ?? context.options.theme.primaryText;
    SceneTextStyle labelStyle() =>
        SceneTextStyle(fontFamily: context.options.theme.fontFamily, fontSize: labelSize, color: labelColor);
    while (labelSize > minimum && context.measurer.measure(leaf.label, labelStyle()).width > availableWidth) {
      labelSize--;
    }
    final spacing = complex ? 1.0 : 2.0;
    var valueSize = math.max(complex ? 4.0 : 6.0, math.min(complex ? 14.0 : 28.0, (labelSize * .6).roundToDouble()));
    while (labelSize > minimum && labelSize + spacing + valueSize > availableHeight) {
      labelSize--;
      valueSize = math.max(complex ? 4.0 : 6.0, math.min(complex ? 14.0 : 28.0, (labelSize * .6).roundToDouble()));
    }
    final labelFits =
        availableWidth >= threshold &&
        availableHeight >= threshold &&
        context.measurer.measure(leaf.label, labelStyle()).width <= availableWidth &&
        labelSize <= availableHeight;
    if (labelFits) {
      groupChildren.add(
        _text(
          context,
          leaf.label,
          bounds.center.x,
          bounds.center.y,
          anchor: TextAnchor.middle,
          style: labelStyle(),
          cssClasses: const ['treemapLabel'],
        ),
      );
      if (config.showValues && leaf.ownValue != null) {
        final value = _formatTreemapValue(leaf.ownValue!, config.valueFormat);
        final valueStyle = SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: valueSize,
          color: labelColor,
        );
        final valueY = bounds.center.y + labelSize / 2 + spacing;
        if (context.measurer.measure(value, valueStyle).width <= availableWidth &&
            valueY + valueSize <= bounds.bottom - 4) {
          groupChildren.add(
            _text(
              context,
              value,
              bounds.center.x,
              valueY,
              anchor: TextAnchor.middle,
              baseline: TextBaseline.hanging,
              style: valueStyle,
              cssClasses: const ['treemapValue'],
            ),
          );
        }
      }
    }
    container.add(
      SceneGroup(
        id: context.id('treemap-leaf-group'),
        children: groupChildren,
        role: SemanticRole.node,
        label: leaf.label,
        cssClasses: ['treemapNode', 'treemapLeafGroup', 'leaf$index', if (leaf.cssClass != null) leaf.cssClass!],
      ),
    );
  }

  void layoutChildren(_TreemapLayoutNode parent, Bounds parentBounds, int depth) {
    if (parent.children.isEmpty) return;
    final inner = Bounds(
      left: parentBounds.left + config.sectionPadding,
      top: parentBounds.top + config.sectionHeaderHeight + config.sectionPadding,
      width: math.max(0, parentBounds.width - config.sectionPadding * 2),
      height: math.max(0, parentBounds.height - config.sectionHeaderHeight - config.sectionPadding * 2),
    );
    final tiles = squarifyTreemap(
      [for (final child in parent.children) TreemapItem(child.value, child)],
      inner,
      innerPadding: config.innerPadding,
    );
    for (var i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      final child = tile.data;
      final bounds = tile.bounds;
      if (child.children.isEmpty) {
        drawLeaf(child, bounds, sectionColors[parent] ?? _palette.first, i);
        continue;
      }
      final color = _palette[(++nextColor) % _palette.length];
      final customStyle = child.cssClass == null ? null : classStyles[child.cssClass];
      final fillColor = customStyle?.fill ?? color;
      final strokeColor = customStyle?.stroke ?? fillColor;
      final textColor = customStyle?.text ?? context.options.theme.primaryText;
      sectionColors[child] = fillColor;
      container.add(
        SceneRect(
          id: context.id('treemap-section'),
          bounds: bounds,
          fill: SolidFill(fillColor),
          stroke: SceneStroke(color: strokeColor, width: 2),
          role: SemanticRole.group,
          cssClasses: ['treemapSection', 'section$nextColor', if (child.cssClass != null) child.cssClass!],
          label: child.label,
        ),
      );
      container.add(
        _text(
          context,
          child.label,
          bounds.left + 6,
          bounds.top + config.sectionHeaderHeight / 2,
          style: SceneTextStyle(
            fontFamily: context.options.theme.fontFamily,
            fontSize: 12,
            weight: FontWeight.bold,
            color: textColor,
          ),
          cssClasses: const ['treemapSectionLabel'],
        ),
      );
      if (config.showValues) {
        container.add(
          _text(
            context,
            _formatTreemapValue(child.value, config.valueFormat),
            bounds.right - 10,
            bounds.top + config.sectionHeaderHeight / 2,
            anchor: TextAnchor.end,
            style: SceneTextStyle(
              fontFamily: context.options.theme.fontFamily,
              fontSize: 10,
              style: FontStyle.italic,
              color: textColor,
            ),
            cssClasses: const ['treemapSectionValue'],
          ),
        );
      }
      layoutChildren(child, bounds, depth + 1);
    }
  }

  if (root.children.isEmpty && root.ownValue != null) {
    drawLeaf(root, Bounds(left: 0, top: titleHeight, width: width, height: height), _palette.first, 0);
  } else {
    layoutChildren(root, Bounds(left: 0, top: titleHeight, width: width, height: height), 0);
  }
  elements.add(
    SceneGroup(id: context.id('treemap-container'), children: container, cssClasses: const ['treemapContainer']),
  );
  return _LayoutResult(width, height + titleHeight, elements);
}

int _countTreemapLeaves(_TreemapLayoutNode node) =>
    node.children.isEmpty ? 1 : node.children.fold(0, (sum, child) => sum + _countTreemapLeaves(child));

String _formatTreemapValue(double value, TreemapValueFormat format) {
  final decimals = value % 1 == 0 ? 0 : 2;
  final plain = value.toStringAsFixed(decimals);
  if (format == TreemapValueFormat.plain) return plain;
  final parts = plain.split('.');
  final grouped = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final result = parts.length == 1 ? grouped : '$grouped.${parts.last}';
  return format == TreemapValueFormat.currencyGrouped ? '\$$result' : result;
}

_TreemapClassStyle _parseTreemapClassStyle(String? source) {
  Color? fill;
  Color? stroke;
  Color? text;
  for (final declaration in (source ?? '').split(RegExp(r'[,;]'))) {
    final separator = declaration.indexOf(':');
    if (separator < 0) continue;
    final property = declaration.substring(0, separator).trim().toLowerCase();
    final value = declaration.substring(separator + 1).trim();
    final color = _parseCssColor(value);
    if (color == null) continue;
    switch (property) {
      case 'fill':
        fill = color;
      case 'stroke':
        stroke = color;
      case 'color':
        text = color;
    }
  }
  return _TreemapClassStyle(fill: fill, stroke: stroke, text: text);
}

Color? _parseCssColor(String value) {
  if (RegExp(r'^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(value)) {
    return Color.fromHex(value);
  }
  return switch (value.toLowerCase()) {
    'black' => const Color(0, 0, 0),
    'white' => const Color(255, 255, 255),
    'red' => const Color(255, 0, 0),
    'green' => const Color(0, 128, 0),
    'blue' => const Color(0, 0, 255),
    'yellow' => const Color(255, 255, 0),
    _ => null,
  };
}
