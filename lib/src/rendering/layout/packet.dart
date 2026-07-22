part of '../layout.dart';

_LayoutResult _layoutPacket(PacketAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const PacketRenderOptions());
  final labelStyle = _mermaidTextStyle(context, 12);
  final bitStyle = _mermaidTextStyle(context, 10);
  final paddingY = config.paddingY + (config.showBits ? 10 : 0);
  final width = config.bitWidth * config.bitsPerRow + 2;
  final elements = <SceneElement>[];
  var cursor = 0;
  for (final block in ast.blocks) {
    final (start, end) = switch (block) {
      PacketSingleBitBlockAst(:final bit) => (bit, bit),
      PacketRangeBlockAst(:final start, :final end) => (start, end),
      PacketRelativeWidthBlockAst(:final bits) => (cursor, cursor + bits - 1),
    };
    var segmentStart = start;
    while (segmentStart <= end) {
      final row = segmentStart ~/ config.bitsPerRow;
      final rowEnd = (row + 1) * config.bitsPerRow - 1;
      final segmentEnd = math.min(end, rowEnd);
      final x = (segmentStart % config.bitsPerRow) * config.bitWidth + 1;
      final y = row * (config.rowHeight + paddingY) + paddingY;
      final blockWidth = (segmentEnd - segmentStart + 1) * config.bitWidth - config.paddingX;
      elements.add(
        SceneRect(
          id: context.id('packet-block'),
          bounds: Bounds(left: x, top: y, width: blockWidth, height: config.rowHeight),
          fill: SolidFill(context.options.theme.primary),
          stroke: _stroke(context, width: 1),
          role: SemanticRole.node,
          cssClasses: const ['packetBlock'],
          label: block.label,
        ),
      );
      elements.add(
        _text(
          context,
          block.label,
          x + blockWidth / 2,
          y + config.rowHeight / 2,
          anchor: TextAnchor.middle,
          baseline: TextBaseline.middle,
          style: labelStyle,
          cssClasses: const ['packetLabel'],
        ),
      );
      if (config.showBits) {
        final single = segmentStart == segmentEnd;
        elements.add(
          _text(
            context,
            '$segmentStart',
            x + (single ? blockWidth / 2 : 0),
            y - 2,
            anchor: single ? TextAnchor.middle : TextAnchor.start,
            baseline: TextBaseline.alphabetic,
            style: bitStyle,
            cssClasses: const ['packetByte', 'start'],
          ),
        );
        if (!single) {
          elements.add(
            _text(
              context,
              '$segmentEnd',
              x + blockWidth,
              y - 2,
              anchor: TextAnchor.end,
              baseline: TextBaseline.alphabetic,
              style: bitStyle,
              cssClasses: const ['packetByte', 'end'],
            ),
          );
        }
      }
      segmentStart = segmentEnd + 1;
    }
    cursor = end + 1;
  }
  final rows = math.max(1, (cursor + config.bitsPerRow - 1) ~/ config.bitsPerRow);
  final totalRowHeight = config.rowHeight + paddingY;
  final height = totalRowHeight * (rows + 1) - (ast.title == null ? config.rowHeight : 0);
  if (ast.title != null) {
    elements.add(
      _text(
        context,
        ast.title!,
        width / 2,
        height - totalRowHeight / 2,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.middle,
        style: _mermaidTextStyle(context, 14),
        cssClasses: const ['packetTitle'],
        role: SemanticRole.title,
      ),
    );
  }
  return _LayoutResult(width, height, elements);
}
