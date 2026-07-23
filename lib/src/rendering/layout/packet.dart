part of '../layout.dart';

// Mermaid packet renderer presentation defaults. They intentionally do not
// reuse the general flowchart palette.
const _packetBlockFill = Color(239, 239, 239);
const _packetInk = Color(0, 0, 0);
const _packetStrokeWidth = 1.0;
const _packetLabelFontSize = 12.0;
const _packetBitFontSize = 10.0;
const _packetTitleFontSize = 14.0;
const _packetBitLabelPadding = 10.0;
const _packetOuterWidth = 2.0;
const _packetBlockLeftInset = 1.0;
const _packetBitLabelOffset = 2.0;

_LayoutResult _layoutPacket(PacketAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const PacketRenderOptions());
  final labelStyle = _packetTextStyle(context, _packetLabelFontSize);
  final bitStyle = _packetTextStyle(context, _packetBitFontSize);
  final paddingY = config.paddingY + (config.showBits ? _packetBitLabelPadding : 0);
  final width = config.bitWidth * config.bitsPerRow + _packetOuterWidth;
  final model = buildPacketLayoutModel(ast, bitsPerRow: config.bitsPerRow);
  final elements = <SceneElement>[];
  for (final segment in model.segments) {
    elements.addAll(
      _packetSegmentElements(
        context,
        segment,
        config: config,
        rowTopPadding: paddingY,
        labelStyle: labelStyle,
        bitStyle: bitStyle,
      ),
    );
  }
  final totalRowHeight = config.rowHeight + paddingY;
  final height = totalRowHeight * (model.rowCount + 1) - (ast.title == null ? config.rowHeight : 0);
  if (ast.title != null) {
    elements.add(
      _text(
        context,
        ast.title!,
        width / 2,
        height - totalRowHeight / 2,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.middle,
        style: _packetTextStyle(context, _packetTitleFontSize, color: config.titleText),
        cssClasses: const ['packetTitle'],
        role: SemanticRole.title,
      ),
    );
  }
  return _LayoutResult(width, height, elements);
}

List<SceneElement> _packetSegmentElements(
  _LayoutContext context,
  PacketSegment segment, {
  required PacketRenderOptions config,
  required double rowTopPadding,
  required SceneTextStyle labelStyle,
  required SceneTextStyle bitStyle,
}) {
  final x = (segment.startBit % config.bitsPerRow) * config.bitWidth + _packetBlockLeftInset;
  final y = segment.row * (config.rowHeight + rowTopPadding) + rowTopPadding;
  final width = segment.bitCount * config.bitWidth - config.paddingX;
  return [
    SceneRect(
      id: context.id('packet-block'),
      bounds: Bounds(left: x, top: y, width: width, height: config.rowHeight),
      fill: const SolidFill(_packetBlockFill),
      stroke: const SceneStroke(color: _packetInk, width: _packetStrokeWidth),
      role: SemanticRole.node,
      cssClasses: const ['packetBlock'],
      label: segment.label,
    ),
    _text(
      context,
      segment.label,
      x + width / 2,
      y + config.rowHeight / 2,
      anchor: TextAnchor.middle,
      baseline: TextBaseline.middle,
      style: labelStyle,
      cssClasses: const ['packetLabel'],
    ),
    if (config.showBits)
      _text(
        context,
        '${segment.startBit}',
        x + (segment.isSingleBit ? width / 2 : 0),
        y - _packetBitLabelOffset,
        anchor: segment.isSingleBit ? TextAnchor.middle : TextAnchor.start,
        baseline: TextBaseline.alphabetic,
        style: bitStyle,
        cssClasses: const ['packetByte', 'start'],
      ),
    if (config.showBits && !segment.isSingleBit)
      _text(
        context,
        '${segment.endBit}',
        x + width,
        y - _packetBitLabelOffset,
        anchor: TextAnchor.end,
        baseline: TextBaseline.alphabetic,
        style: bitStyle,
        cssClasses: const ['packetByte', 'end'],
      ),
  ];
}

SceneTextStyle _packetTextStyle(_LayoutContext context, double fontSize, {Color color = _packetInk}) => SceneTextStyle(
  fontFamily: context.options.theme.resolveFontFamily(fallback: _mermaidFontFamily),
  fontSize: fontSize,
  color: color,
);
