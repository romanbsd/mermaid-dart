part of '../layout.dart';

// Mermaid Kanban uses 200px columns, 10px internal spacing, 5px rounded
// corners, and a minimum 50px section body. Card heights remain driven by
// measured label and metadata text.
const _kanbanSectionHeaderHeight = 25.0;
const _kanbanSectionInnerPadding = 10.0;
const _kanbanCardHorizontalInset = 7.5;
const _kanbanCardVerticalPadding = 10.0;
const _kanbanCardCornerRadius = 5.0;
const _kanbanCardMetadataGap = 8.0;
const _kanbanMinimumSectionBodyHeight = 50.0;
const _kanbanIconSize = 16.0;
const _kanbanPriorityStrokeWidth = 4.0;

_LayoutResult _layoutKanban(KanbanAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const KanbanRenderOptions());
  if (ast.sections.isEmpty) return const _LayoutResult(1, 1, []);

  final sectionLayouts = <({KanbanSectionAst section, List<double> cardHeights, double height})>[];
  var maximumHeight = 0.0;
  for (final section in ast.sections) {
    final cardHeights = [for (final card in section.cards) _kanbanCardHeight(card, context)];
    final cardsHeight =
        cardHeights.fold(0.0, (sum, height) => sum + height) + math.max(0, cardHeights.length - 1) * config.cardGap;
    final height = math.max(
      _kanbanMinimumSectionBodyHeight,
      _kanbanSectionHeaderHeight + cardsHeight + _kanbanSectionInnerPadding,
    );
    maximumHeight = math.max(maximumHeight, height);
    sectionLayouts.add((section: section, cardHeights: cardHeights, height: height));
  }

  final elements = <SceneElement>[];
  final sectionColors = context.options.theme.categoricalColors.isEmpty
      ? _palette
      : context.options.theme.categoricalColors;
  for (var sectionIndex = 0; sectionIndex < sectionLayouts.length; sectionIndex++) {
    final layout = sectionLayouts[sectionIndex];
    final section = layout.section;
    final left = sectionIndex * (config.sectionWidth + config.sectionGap);
    final sectionColor = _kanbanLighten(
      sectionColors[(sectionIndex + 2) % sectionColors.length],
      _kanbanSectionColorLightnessIncrease,
    );
    final sectionTextColor = context.options.theme.text;
    final children = <SceneElement>[
      SceneRect(
        id: context.id('kanban-section'),
        bounds: Bounds(left: left, top: 0, width: config.sectionWidth, height: layout.height),
        radiusX: _kanbanCardCornerRadius,
        radiusY: _kanbanCardCornerRadius,
        fill: SolidFill(sectionColor),
        stroke: SceneStroke(color: sectionColor),
        role: SemanticRole.group,
        label: section.label,
        cssClasses: ['kanban-section', 'section-$sectionIndex', ...section.cssClasses],
      ),
    ];
    var sectionLabelX = left + config.sectionWidth / 2;
    if (section.icon case final icon?) {
      sectionLabelX -= (_kanbanIconSize + _kanbanCardMetadataGap) / 2;
      children.add(
        _scaledIcon(
          context,
          icon,
          Point(sectionLabelX, (_kanbanSectionHeaderHeight - _kanbanIconSize) / 2),
          _kanbanIconSize,
          idPrefix: 'kanban-section',
          fill: SolidFill(sectionTextColor),
          cssClasses: const ['kanban-section-icon'],
        ),
      );
      sectionLabelX += _kanbanIconSize + _kanbanCardMetadataGap;
    }
    final sectionLabelStyle = _kanbanTextStyle(context, sectionTextColor);
    children.add(
      _text(
        context,
        section.label,
        sectionLabelX,
        context.measurer.measure(section.label, sectionLabelStyle).height / 2,
        anchor: TextAnchor.middle,
        style: sectionLabelStyle,
        cssClasses: const ['kanban-section-label'],
      ),
    );

    var top = _kanbanSectionHeaderHeight;
    for (var cardIndex = 0; cardIndex < section.cards.length; cardIndex++) {
      final card = section.cards[cardIndex];
      final cardHeight = layout.cardHeights[cardIndex];
      children.addAll(
        _kanbanCardElements(
          card,
          context,
          config,
          left: left + _kanbanCardHorizontalInset,
          top: top,
          width: config.sectionWidth - _kanbanCardHorizontalInset * 2,
          height: cardHeight,
        ),
      );
      top += cardHeight + config.cardGap;
    }
    elements.add(
      SceneGroup(
        id: context.id('kanban-column'),
        children: children,
        role: SemanticRole.group,
        label: section.label,
        cssClasses: const ['kanban-column'],
      ),
    );
  }

  final width = ast.sections.length * config.sectionWidth + math.max(0, ast.sections.length - 1) * config.sectionGap;
  return _LayoutResult(
    width,
    maximumHeight,
    elements,
    // Mermaid 11.16 consults mindmap padding here, making the public Kanban
    // padding setting compatibility-only and the effective value 10.
    viewportPadding: _kanbanSectionInnerPadding,
    bounds: Bounds(left: 0, top: 0, width: width, height: maximumHeight),
  );
}

double _kanbanCardHeight(KanbanCardAst card, _LayoutContext context) {
  final style = _kanbanTextStyle(context, context.options.theme.primaryText);
  final labelHeight = context.measurer.measure(card.label, style).height;
  final metadata = [card.ticket, card.assigned].whereType<String>();
  final metadataHeight = metadata.isEmpty
      ? 0.0
      : metadata.map((value) => context.measurer.measure(value, style).height).fold(0.0, math.max);
  return labelHeight + _kanbanCardVerticalPadding * 2 + metadataHeight / 2;
}

List<SceneElement> _kanbanCardElements(
  KanbanCardAst card,
  _LayoutContext context,
  KanbanRenderOptions config, {
  required double left,
  required double top,
  required double width,
  required double height,
}) {
  final bounds = Bounds(left: left, top: top, width: width, height: height);
  final textStyle = _kanbanTextStyle(context, context.options.theme.primaryText);
  final classes = ['kanban-card', ...card.cssClasses];
  final elements = <SceneElement>[
    SceneRect(
      id: context.id('kanban-card'),
      bounds: bounds,
      radiusX: _kanbanCardCornerRadius,
      radiusY: _kanbanCardCornerRadius,
      fill: SolidFill(
        context.options.theme.background.alpha == 0 ? const Color(255, 255, 255) : context.options.theme.background,
      ),
      stroke: SceneStroke(color: context.options.theme.nodeBorder),
      role: SemanticRole.node,
      label: card.label,
      cssClasses: classes,
    ),
  ];
  if (_kanbanPriorityColor(card.priority) case final color?) {
    final priorityInset = (_kanbanCardCornerRadius / 2).floorToDouble();
    elements.add(
      SceneLine(
        id: context.id('kanban-priority'),
        start: Point(left + 2, top + priorityInset),
        end: Point(left + 2, top + height - priorityInset),
        stroke: SceneStroke(color: color, width: _kanbanPriorityStrokeWidth),
        role: SemanticRole.annotation,
        label: card.priority!.wireName,
        cssClasses: ['kanban-priority', 'kanban-priority-${card.priority!.name}'],
      ),
    );
  }

  var labelX = left + _kanbanSectionInnerPadding;
  if (card.icon case final icon?) {
    elements.add(
      _scaledIcon(
        context,
        icon,
        Point(labelX, top + _kanbanCardVerticalPadding),
        _kanbanIconSize,
        idPrefix: 'kanban-card',
        fill: SolidFill(context.options.theme.primaryText),
        cssClasses: const ['kanban-card-icon'],
      ),
    );
    labelX += _kanbanIconSize + _kanbanCardMetadataGap;
  }
  final labelHeight = context.measurer.measure(card.label, textStyle).height;
  final metadata = [card.ticket, card.assigned].whereType<String>();
  final metadataHeight = metadata.isEmpty
      ? 0.0
      : metadata.map((value) => context.measurer.measure(value, textStyle).height).fold(0.0, math.max);
  final centerY = top + height / 2;
  final labelY = centerY - metadataHeight / 2;
  final labelWidth = context.measurer.measure(card.label, textStyle).width;
  elements.add(
    _text(
      context,
      card.label,
      labelX + labelWidth / 2,
      labelY,
      anchor: TextAnchor.middle,
      style: textStyle,
      cssClasses: const ['kanban-card-label'],
    ),
  );
  if (card.ticket case final ticket?) {
    final ticketWidth = context.measurer.measure(ticket, textStyle).width;
    final ticketLink = config.ticketBaseUrl.isEmpty ? null : config.ticketBaseUrl.replaceAll('#TICKET#', ticket);
    elements.add(
      _text(
        context,
        ticket,
        left + _kanbanSectionInnerPadding + ticketWidth / 2,
        centerY + labelHeight / 2,
        anchor: TextAnchor.middle,
        style: textStyle,
        stroke: ticketLink == null ? null : SceneStroke(color: context.options.theme.nodeBorder),
        link: ticketLink,
        cssClasses: ['kanban-ticket', if (config.ticketBaseUrl.isNotEmpty) 'kanban-ticket-link'],
      ),
    );
  }
  if (card.assigned case final assigned?) {
    final assignedWidth = context.measurer.measure(assigned, textStyle).width;
    elements.add(
      _text(
        context,
        assigned,
        left + width - _kanbanSectionInnerPadding - assignedWidth / 2,
        centerY + labelHeight / 2,
        anchor: TextAnchor.middle,
        style: textStyle,
        cssClasses: const ['kanban-assigned'],
      ),
    );
  }
  return elements;
}

SceneTextStyle _kanbanTextStyle(_LayoutContext context, Color color, {FontWeight weight = FontWeight.normal}) =>
    SceneTextStyle(
      fontFamily: context.textStyle.fontFamily,
      fontSize: context.textStyle.fontSize,
      weight: weight,
      color: color,
      lineHeight: context.textStyle.lineHeight,
    );

Color? _kanbanPriorityColor(KanbanPriority? priority) => switch (priority) {
  KanbanPriority.veryHigh => const Color(255, 0, 0),
  KanbanPriority.high => const Color(255, 165, 0),
  KanbanPriority.medium || null => null,
  KanbanPriority.low => const Color(0, 0, 255),
  KanbanPriority.veryLow => const Color(173, 216, 230),
};

// Kanban's generated stylesheet lightens cScale colors by ten HSL percentage
// points and starts columns at cScale2 because of its historical section class
// offset.
const _kanbanSectionColorLightnessIncrease = .1;
const _kanbanColorChannelMaximum = 255.0;

Color _kanbanLighten(Color color, double amount) {
  final channels = [color.red, color.green, color.blue];
  final maximum = channels.reduce((left, right) => left > right ? left : right) / _kanbanColorChannelMaximum;
  final minimum = channels.reduce((left, right) => left < right ? left : right) / _kanbanColorChannelMaximum;
  final lightness = (maximum + minimum) / 2;
  if (lightness >= 1 - amount) return Color(255, 255, 255, color.alpha);
  final factor = amount / (1 - lightness);
  int lighten(int channel) => (channel + (_kanbanColorChannelMaximum - channel) * factor).round();
  return Color(lighten(color.red), lighten(color.green), lighten(color.blue), color.alpha);
}
