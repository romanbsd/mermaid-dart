part of '../layout.dart';

_LayoutResult _layoutInfo(InfoAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const InfoRenderOptions());
  // Info text inherits the SVG root fill while retaining its renderer-fixed
  // 32px size.
  final style = _mermaidTextStyle(context, 32, color: context.options.theme.text);
  return _LayoutResult(400, 100, [
    _text(
      context,
      'v${config.version}',
      100,
      40,
      anchor: TextAnchor.middle,
      baseline: TextBaseline.alphabetic,
      style: style,
      cssClasses: const ['version'],
    ),
  ]);
}
