part of '../layout.dart';

// Mermaid's parity CLI renders into an SVG named `my-svg`; hashing the same ID
// preserves its default seeded boundary geometry. The other values mirror the
// renderer's typography, badge sizing, and boundary stroke rules.
const _cynefinDefaultSvgId = 'my-svg';
const _cynefinBadgeHorizontalPadding = 16.0;
const _cynefinConfusionStrokeWidth = 1.5;
const _cynefinBadgeStrokeWidth = 1.0;
// Mermaid applies these opacities in renderer CSS, independently of the
// configured theme color. Keeping them here preserves that behavior for every
// scene backend instead of baking alpha into only the default theme values.
const _cynefinDomainOpacity = .4;
const _cynefinConfusionOpacity = .5;
const _cynefinItemOpacity = .95;
const _cynefinOverflowOpacity = .6;

_LayoutResult _layoutCynefin(CynefinAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const CynefinRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  final width = config.width;
  final height = config.height;
  final padding = config.padding;
  final totalWidth = width + padding * 2;
  final totalHeight = height + padding * 2;
  final halfWidth = width / 2;
  final halfHeight = height / 2;
  final positions = <CynefinDomain, Bounds>{
    CynefinDomain.complex: Bounds(left: padding, top: padding, width: halfWidth, height: halfHeight),
    CynefinDomain.complicated: Bounds(left: padding + halfWidth, top: padding, width: halfWidth, height: halfHeight),
    CynefinDomain.chaotic: Bounds(left: padding, top: padding + halfHeight, width: halfWidth, height: halfHeight),
    CynefinDomain.clear: Bounds(
      left: padding + halfWidth,
      top: padding + halfHeight,
      width: halfWidth,
      height: halfHeight,
    ),
    CynefinDomain.confusion: Bounds(
      left: padding + halfWidth * .7,
      top: padding + halfHeight * .7,
      width: halfWidth * .6,
      height: halfHeight * .6,
    ),
  };
  final colors = <CynefinDomain, Color>{
    CynefinDomain.complex: theme.complexBackground,
    CynefinDomain.complicated: theme.complicatedBackground,
    CynefinDomain.chaotic: theme.chaoticBackground,
    CynefinDomain.clear: theme.clearBackground,
    CynefinDomain.confusion: theme.confusionBackground,
  };
  final byDomain = {for (final domain in ast.domains) domain.domain: domain};
  final elements = <SceneElement>[];
  const quadrants = [CynefinDomain.complex, CynefinDomain.complicated, CynefinDomain.chaotic, CynefinDomain.clear];
  for (final domain in quadrants) {
    final bounds = positions[domain]!;
    elements.add(
      SceneRect(
        id: context.id('cynefin-domain'),
        bounds: bounds,
        fill: SolidFill(_colorWithOpacity(colors[domain]!, _cynefinDomainOpacity)),
        role: SemanticRole.group,
        cssClasses: const ['cynefinDomain'],
        label: domain.name,
      ),
    );
  }

  final seed = config.seed == 0 ? cynefinHashString(_cynefinDefaultSvgId) : config.seed;
  elements.addAll([
    ScenePath(
      id: context.id('cynefin-boundary'),
      commands: generateCynefinFoldPath(
        width,
        height,
        seed,
        amplitude: config.boundaryAmplitude,
        offsetX: padding,
        offsetY: padding,
      ),
      fill: const NoFill(),
      stroke: SceneStroke(color: theme.boundaryColor, width: theme.boundaryWidth, dashes: config.boundaryDashes),
      role: SemanticRole.edge,
      cssClasses: const ['cynefinBoundary'],
    ),
    ScenePath(
      id: context.id('cynefin-boundary'),
      commands: generateCynefinHorizontalPath(
        width,
        height,
        seed + 100,
        amplitude: config.boundaryAmplitude,
        offsetX: padding,
        offsetY: padding,
      ),
      fill: const NoFill(),
      stroke: SceneStroke(color: theme.boundaryColor, width: theme.boundaryWidth, dashes: config.boundaryDashes),
      role: SemanticRole.edge,
      cssClasses: const ['cynefinBoundary'],
    ),
    ScenePath(
      id: context.id('cynefin-cliff'),
      commands: generateCynefinCliffPath(width, height, offsetX: padding, offsetY: padding),
      fill: const NoFill(),
      stroke: SceneStroke(color: theme.cliffColor, width: theme.cliffWidth),
      role: SemanticRole.edge,
      cssClasses: const ['cynefinCliff'],
    ),
    ScenePath(
      id: context.id('cynefin-confusion'),
      commands: generateCynefinConfusionPath(padding + width / 2, padding + height / 2, width * .15, height * .15),
      fill: SolidFill(_colorWithOpacity(colors[CynefinDomain.confusion]!, _cynefinConfusionOpacity)),
      stroke: SceneStroke(
        color: theme.boundaryColor,
        width: _cynefinConfusionStrokeWidth,
        dashes: config.confusionDashes,
      ),
      role: SemanticRole.group,
      cssClasses: const ['cynefinConfusion'],
      label: 'Confusion',
    ),
  ]);

  const descriptions = <CynefinDomain, (String, String)>{
    CynefinDomain.complex: ('Probe → Sense → Respond', 'Emergent Practices'),
    CynefinDomain.complicated: ('Sense → Analyse → Respond', 'Good Practices'),
    CynefinDomain.clear: ('Sense → Categorise → Respond', 'Best Practices'),
    CynefinDomain.chaotic: ('Act → Sense → Respond', 'Novel Practices'),
    CynefinDomain.confusion: ('', 'Disorder'),
  };
  const domainOrder = [...quadrants, CynefinDomain.confusion];
  for (final domain in domainOrder) {
    final bounds = positions[domain]!;
    final center = bounds.center;
    final isConfusion = domain == CynefinDomain.confusion;
    elements.add(
      _text(
        context,
        '${domain.name[0].toUpperCase()}${domain.name.substring(1)}',
        center.x,
        center.y - (config.showDomainDescriptions ? (isConfusion ? 10 : 30) : 0),
        anchor: TextAnchor.middle,
        baseline: TextBaseline.middle,
        role: SemanticRole.title,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: theme.domainFontSize,
          weight: FontWeight.bold,
          color: theme.labelColor,
        ),
        cssClasses: const ['cynefinDomainLabel'],
      ),
    );
  }
  if (config.showDomainDescriptions) {
    final subtitleStyle = SceneTextStyle(
      fontFamily: context.options.theme.fontFamily,
      fontSize: theme.itemFontSize - 1,
      color: theme.textColor,
    );
    for (final domain in domainOrder) {
      final center = positions[domain]!.center;
      final isConfusion = domain == CynefinDomain.confusion;
      final (model, practice) = descriptions[domain]!;
      if (model.isNotEmpty) {
        elements.add(
          _text(
            context,
            model,
            center.x,
            center.y - 10,
            anchor: TextAnchor.middle,
            baseline: TextBaseline.middle,
            style: subtitleStyle,
            cssClasses: const ['cynefinSubtitle'],
          ),
        );
      }
      elements.add(
        _text(
          context,
          practice,
          center.x,
          center.y + (isConfusion ? 8 : 5),
          anchor: TextAnchor.middle,
          baseline: TextBaseline.middle,
          style: subtitleStyle,
          cssClasses: const ['cynefinSubtitle'],
        ),
      );
    }
  }

  final itemStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: theme.itemFontSize,
    color: theme.textColor,
  );
  for (final domain in domainOrder) {
    final items = byDomain[domain]?.items ?? const [];
    if (items.isEmpty) continue;
    final center = positions[domain]!.center;
    final isConfusion = domain == CynefinDomain.confusion;
    final renderedItems = isConfusion && items.length > 3 ? items.take(3).toList() : items;
    final startY =
        center.y +
        (isConfusion ? (config.showDomainDescriptions ? 22 : 14) : (config.showDomainDescriptions ? 25 : 15));
    for (var i = 0; i < renderedItems.length; i++) {
      _addCynefinBadge(
        context,
        elements,
        renderedItems[i].label,
        center.x,
        startY + i * 30,
        colors[domain]!,
        theme.boundaryColor,
        itemStyle,
        overflow: false,
      );
    }
    if (isConfusion && items.length > 3) {
      _addCynefinBadge(
        context,
        elements,
        '+${items.length - 3} more',
        center.x,
        startY + renderedItems.length * 30,
        colors[domain]!,
        theme.boundaryColor,
        itemStyle,
        overflow: true,
      );
    }
  }

  for (final transition in ast.transitions) {
    if (transition.from == transition.to) continue;
    final start = positions[transition.from]!.center;
    final end = positions[transition.to]!.center;
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) continue;
    final middle = Point((start.x + end.x) / 2, (start.y + end.y) / 2);
    final control = Point(middle.x - dy / length * length * .15, middle.y + dx / length * length * .15);
    elements.add(
      ScenePath(
        id: context.id('cynefin-arrow'),
        commands: [MoveTo(start), QuadraticTo(control, end)],
        fill: const NoFill(),
        stroke: SceneStroke(color: theme.arrowColor, width: theme.arrowWidth),
        role: SemanticRole.edge,
        cssClasses: const ['cynefinArrowLine'],
      ),
    );
    final tangentX = end.x - control.x;
    final tangentY = end.y - control.y;
    final tangentLength = math.sqrt(tangentX * tangentX + tangentY * tangentY);
    final unitX = tangentX / tangentLength;
    final unitY = tangentY / tangentLength;
    final base = Point(end.x - unitX * 9, end.y - unitY * 9);
    elements.add(
      ScenePolygon(
        id: context.id('cynefin-arrow-head'),
        points: [end, Point(base.x - unitY * 4, base.y + unitX * 4), Point(base.x + unitY * 4, base.y - unitX * 4)],
        fill: SolidFill(theme.arrowColor),
        role: SemanticRole.edge,
        cssClasses: const ['cynefinArrowHead'],
      ),
    );
    if (transition.label case final label?) {
      elements.add(
        _text(
          context,
          label,
          control.x,
          control.y - 6,
          anchor: TextAnchor.middle,
          style: itemStyle,
          cssClasses: const ['cynefinArrowLabel'],
        ),
      );
    }
  }

  if (ast.title case final title?) {
    elements.add(
      _text(
        context,
        title,
        totalWidth / 2,
        padding / 2,
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
        cssClasses: const ['cynefinTitle'],
      ),
    );
  }
  return _LayoutResult(totalWidth, totalHeight, elements);
}

void _addCynefinBadge(
  _LayoutContext context,
  List<SceneElement> elements,
  String label,
  double centerX,
  double top,
  Color fill,
  Color strokeColor,
  SceneTextStyle style, {
  required bool overflow,
}) {
  const height = 26.0;
  final width = context.measurer.measure(label, style).width + _cynefinBadgeHorizontalPadding;
  final bounds = Bounds(left: centerX - width / 2, top: top, width: width, height: height);
  elements.add(
    SceneRect(
      id: context.id(overflow ? 'cynefin-item-overflow' : 'cynefin-item'),
      bounds: bounds,
      radiusX: 4,
      radiusY: 4,
      fill: SolidFill(_colorWithOpacity(fill, overflow ? _cynefinOverflowOpacity : _cynefinItemOpacity)),
      stroke: SceneStroke(color: strokeColor, width: _cynefinBadgeStrokeWidth),
      role: SemanticRole.node,
      cssClasses: [overflow ? 'cynefinItemOverflow' : 'cynefinItem'],
      label: label,
    ),
  );
  elements.add(
    _text(
      context,
      label,
      centerX,
      top + height / 2,
      anchor: TextAnchor.middle,
      style: style,
      cssClasses: const ['cynefinItemText'],
    ),
  );
}
