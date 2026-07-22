import 'scene.dart';

final class MermaidTheme {
  const MermaidTheme({
    this.background = const Color(255, 255, 255, 0),
    this.primary = const Color(236, 236, 255),
    this.primaryBorder = const Color(147, 112, 219),
    this.primaryText = const Color(51, 51, 51),
    this.line = const Color(51, 51, 51),
    this.secondary = const Color(255, 255, 222),
    this.tertiary = const Color(238, 238, 238),
    this.fontFamily = 'Arial, sans-serif',
    this.fontSize = 16,
  });

  final Color background;
  final Color primary;
  final Color primaryBorder;
  final Color primaryText;
  final Color line;
  final Color secondary;
  final Color tertiary;
  final String fontFamily;
  final double fontSize;
}

enum DiagramDirection { leftToRight, topToBottom }

sealed class DiagramRenderOptions {
  const DiagramRenderOptions();
}

final class RailroadRenderOptions extends DiagramRenderOptions {
  const RailroadRenderOptions({this.verticalGap = 32, this.horizontalGap = 20});
  final double verticalGap;
  final double horizontalGap;
}

final class PieRenderOptions extends DiagramRenderOptions {
  const PieRenderOptions({this.radius = 150, this.showLegend = true});
  final double radius;
  final bool showLegend;
}

final class RadarRenderOptions extends DiagramRenderOptions {
  const RadarRenderOptions({this.radius = 150});
  final double radius;
}

final class RenderOptions {
  const RenderOptions({
    this.theme = const MermaidTheme(),
    this.padding = 20,
    this.diagram = const <Type, DiagramRenderOptions>{},
  });

  final MermaidTheme theme;
  final double padding;
  final Map<Type, DiagramRenderOptions> diagram;

  T optionsFor<T extends DiagramRenderOptions>(T fallback) => (diagram[fallback.runtimeType] as T?) ?? fallback;
}

final class SvgRenderOptions {
  const SvgRenderOptions({this.pretty = false, this.includeXmlDeclaration = false, this.rootId});
  final bool pretty;
  final bool includeXmlDeclaration;
  final String? rootId;
}
