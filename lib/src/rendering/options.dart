import '../parser/ast.dart';
import 'scene.dart';

// Mermaid's default 12-step categorical theme scales. Radar consumes the
// primary scale; treemap coordinates it with peer borders and label colors.
const _mermaidColorScale = <Color>[
  Color(134, 134, 255),
  Color(255, 255, 120),
  Color(215, 255, 134),
  Color(194, 134, 255),
  Color(255, 134, 255),
  Color(255, 134, 194),
  Color(255, 134, 134),
  Color(255, 194, 134),
  Color(194, 255, 134),
  Color(134, 255, 194),
  Color(134, 255, 255),
  Color(134, 194, 255),
];

const _mermaidColorScalePeers = <Color>[
  Color(57, 57, 255),
  Color(247, 247, 0),
  Color(181, 255, 32),
  Color(156, 57, 255),
  Color(255, 57, 255),
  Color(255, 57, 156),
  Color(255, 57, 57),
  Color(255, 156, 57),
  Color(156, 255, 57),
  Color(57, 255, 156),
  Color(57, 255, 255),
  Color(57, 156, 255),
];

const _mermaidColorScaleLabels = <Color>[
  Color(255, 255, 255),
  Color(0, 0, 0),
  Color(0, 0, 0),
  Color(255, 255, 255),
  Color(0, 0, 0),
  Color(0, 0, 0),
  Color(0, 0, 0),
  Color(0, 0, 0),
  Color(0, 0, 0),
  Color(0, 0, 0),
  Color(0, 0, 0),
  Color(0, 0, 0),
];

// Mermaid's default light-theme pie1 through pie12 palette.
const _mermaidPieColors = <Color>[
  Color(236, 236, 255),
  Color(255, 255, 222),
  Color(181, 255, 32),
  Color(185, 185, 255),
  Color(255, 255, 69),
  Color(215, 255, 134),
  Color(255, 134, 255),
  Color(32, 255, 255),
  Color(255, 32, 32),
  Color(255, 32, 255),
  Color(32, 255, 143),
  Color(255, 83, 83),
];

List<Color> _resolveThemePalette(List<Color>? diagram, List<Color> theme, List<Color> fallback) {
  if (diagram != null && diagram.isNotEmpty) return diagram;
  return theme.isEmpty ? fallback : theme;
}

/// Typed Mermaid architecture theme variables.
final class ArchitectureTheme {
  /// Creates a typed [ArchitectureTheme].
  const ArchitectureTheme({
    this.edgeColor = const Color(51, 51, 51),
    this.edgeArrowColor = const Color(51, 51, 51),
    this.edgeWidth = 3,
    this.groupBorderColor = const Color(199, 199, 241),
    this.groupBorderWidth = 2,
  });

  /// The edge color.
  final Color edgeColor;

  /// The edge arrow color.
  final Color edgeArrowColor;

  /// The edge width.
  final double edgeWidth;

  /// The group border color.
  final Color groupBorderColor;

  /// The group border width.
  final double groupBorderWidth;
}

/// Typed Mermaid Cynefin theme block.
final class CynefinTheme {
  /// Creates a typed [CynefinTheme].
  const CynefinTheme({
    this.domainFontSize = 16,
    this.itemFontSize = 12,
    this.boundaryColor = const Color(51, 51, 51),
    this.boundaryWidth = 2,
    this.cliffColor = const Color(139, 0, 0),
    this.cliffWidth = 4,
    this.arrowColor = const Color(51, 51, 51),
    this.arrowWidth = 2,
    this.complexBackground = const Color(232, 245, 233),
    this.complicatedBackground = const Color(227, 242, 253),
    this.chaoticBackground = const Color(251, 233, 231),
    this.clearBackground = const Color(255, 248, 225),
    this.confusionBackground = const Color(243, 229, 245),
    this.textColor = const Color(51, 51, 51),
    this.labelColor = const Color(19, 19, 0),
  });

  /// The domain font size.
  final double domainFontSize;

  /// The item font size.
  final double itemFontSize;

  /// The boundary color.
  final Color boundaryColor;

  /// The boundary width.
  final double boundaryWidth;

  /// The cliff color.
  final Color cliffColor;

  /// The cliff width.
  final double cliffWidth;

  /// The arrow color.
  final Color arrowColor;

  /// The arrow width.
  final double arrowWidth;

  /// The complex background.
  final Color complexBackground;

  /// The complicated background.
  final Color complicatedBackground;

  /// The chaotic background.
  final Color chaoticBackground;

  /// The clear background.
  final Color clearBackground;

  /// The confusion background.
  final Color confusionBackground;

  /// The text color.
  final Color textColor;

  /// The label color.
  final Color labelColor;
}

/// Typed Mermaid Event Modeling theme variables.
final class EventModelingTheme {
  /// Creates a typed [EventModelingTheme].
  const EventModelingTheme({
    this.uiFill = const Color(255, 255, 255),
    this.uiStroke = const Color(219, 218, 218),
    this.processorFill = const Color(237, 179, 246),
    this.processorStroke = const Color(184, 140, 191),
    this.readModelFill = const Color(211, 241, 162),
    this.readModelStroke = const Color(163, 183, 50),
    this.commandFill = const Color(188, 214, 254),
    this.commandStroke = const Color(103, 154, 195),
    this.eventFill = const Color(255, 183, 120),
    this.eventStroke = const Color(193, 154, 15),
    this.swimlaneBackgroundOdd = const Color(250, 250, 250),
    this.swimlaneBackgroundStroke = const Color(240, 240, 240),
    this.arrowhead = const Color(51, 51, 51),
    this.relationStroke = const Color(51, 51, 51),
  });

  /// The ui fill.
  final Color uiFill;

  /// The ui stroke.
  final Color uiStroke;

  /// The processor fill.
  final Color processorFill;

  /// The processor stroke.
  final Color processorStroke;

  /// The read model fill.
  final Color readModelFill;

  /// The read model stroke.
  final Color readModelStroke;

  /// The command fill.
  final Color commandFill;

  /// The command stroke.
  final Color commandStroke;

  /// The event fill.
  final Color eventFill;

  /// The event stroke.
  final Color eventStroke;

  /// The swimlane background odd.
  final Color swimlaneBackgroundOdd;

  /// The swimlane background stroke.
  final Color swimlaneBackgroundStroke;

  /// The arrowhead.
  final Color arrowhead;

  /// The relation stroke.
  final Color relationStroke;
}

/// Backend-neutral representation of Mermaid's Git Graph shadow variable.
final class ThemeShadow {
  /// Creates a typed [ThemeShadow].
  const ThemeShadow({this.color = const Color(185, 185, 185), this.offsetX = 1, this.offsetY = 2, this.blurRadius = 2});

  /// The color.
  final Color color;

  /// The offset x.
  final double offsetX;

  /// The offset y.
  final double offsetY;

  /// The blur radius.
  final double blurRadius;
}

/// Typed Mermaid Git Graph theme variables.
final class GitGraphTheme {
  /// Creates a typed [GitGraphTheme].
  const GitGraphTheme({
    this.branchColors = GitGraphRenderOptions.defaultBranchColors,
    this.highlightColors = GitGraphRenderOptions.defaultHighlightColors,
    this.branchLabelColors = GitGraphRenderOptions.defaultBranchLabelColors,
    this.tagLabelColor = const Color(19, 19, 0),
    this.tagLabelBackground = const Color(236, 236, 255),
    this.tagLabelBorder = const Color(199, 199, 241),
    this.tagLabelFontSize = 10,
    this.commitLabelColor = const Color(0, 0, 33),
    this.commitLabelBackground = const Color(255, 255, 222),
    this.commitLabelFontSize = 10,
    this.commitLineColor,
    this.tagHoleColor = const Color(51, 51, 51),
    this.primaryColor = const Color(51, 51, 51),
    this.specialColor = const Color(236, 236, 255),
    this.themeColorLimit = 12,
    this.useGradient = false,
    this.gradientStart = const Color(147, 112, 219),
    this.gradientStop = const Color(170, 170, 51),
    this.filterColor = const Color(255, 255, 255),
    this.dropShadow = const ThemeShadow(),
  });

  /// The branch colors.
  final List<Color> branchColors;

  /// The highlight colors.
  final List<Color> highlightColors;

  /// The branch label colors.
  final List<Color> branchLabelColors;

  /// The tag label color.
  final Color tagLabelColor;

  /// The tag label background.
  final Color tagLabelBackground;

  /// The tag label border.
  final Color tagLabelBorder;

  /// The tag label font size.
  final double tagLabelFontSize;

  /// The commit label color.
  final Color commitLabelColor;

  /// The commit label background.
  final Color commitLabelBackground;

  /// The commit label font size.
  final double commitLabelFontSize;

  /// The commit line color.
  final Color? commitLineColor;

  /// The tag hole color.
  final Color tagHoleColor;

  /// The primary color.
  final Color primaryColor;

  /// The special color.
  final Color specialColor;

  /// The theme color limit.
  final int themeColorLimit;

  /// The use gradient.
  final bool useGradient;

  /// The gradient start.
  final Color gradientStart;

  /// The gradient stop.
  final Color gradientStop;

  /// The filter color.
  final Color filterColor;

  /// The drop shadow.
  final ThemeShadow dropShadow;
}

/// Typed Mermaid Pie theme variables other than the slice palette.
final class PieTheme {
  /// Creates a typed [PieTheme].
  const PieTheme({
    this.titleTextSize = 25,
    this.titleTextColor = const Color(0, 0, 0),
    this.sectionTextSize = 17,
    this.sectionTextColor = const Color(51, 51, 51),
    this.legendTextSize = 17,
    this.legendTextColor = const Color(0, 0, 0),
    this.strokeColor = const Color(0, 0, 0),
    this.strokeWidth = 2,
    this.outerStrokeWidth = 2,
    this.outerStrokeColor = const Color(0, 0, 0),
    this.opacity = .7,
  });

  /// The title text size.
  final double titleTextSize;

  /// The title text color.
  final Color titleTextColor;

  /// The section text size.
  final double sectionTextSize;

  /// The section text color.
  final Color sectionTextColor;

  /// The legend text size.
  final double legendTextSize;

  /// The legend text color.
  final Color legendTextColor;

  /// The stroke color.
  final Color strokeColor;

  /// The stroke width.
  final double strokeWidth;

  /// The outer stroke width.
  final double outerStrokeWidth;

  /// The outer stroke color.
  final Color outerStrokeColor;

  /// The opacity.
  final double opacity;
}

/// Typed Mermaid Radar theme block.
final class RadarTheme {
  /// Creates a typed [RadarTheme].
  const RadarTheme({
    this.axisColor = const Color(51, 51, 51),
    this.axisStrokeWidth = 2,
    this.axisLabelFontSize = 12,
    this.curveOpacity = .5,
    this.curveStrokeWidth = 2,
    this.graticuleColor = const Color(222, 222, 222),
    this.graticuleStrokeWidth = 1,
    this.graticuleOpacity = .3,
    this.legendBoxSize = 12,
    this.legendFontSize = 12,
  });

  /// The axis color.
  final Color axisColor;

  /// The axis stroke width.
  final double axisStrokeWidth;

  /// The axis label font size.
  final double axisLabelFontSize;

  /// The curve opacity.
  final double curveOpacity;

  /// The curve stroke width.
  final double curveStrokeWidth;

  /// The graticule color.
  final Color graticuleColor;

  /// The graticule stroke width.
  final double graticuleStrokeWidth;

  /// The graticule opacity.
  final double graticuleOpacity;

  /// Compatibility-only in Mermaid 11.16, whose renderer draws 12px swatches.
  final double legendBoxSize;

  /// The legend font size.
  final double legendFontSize;
}

/// Resolved Mermaid theme values shared by the four railroad frontends.
final class RailroadTheme {
  /// Creates a typed [RailroadTheme].
  const RailroadTheme({
    this.fontSize = 16,
    this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif',
    this.strokeWidth = 2,
    this.terminalFill = const Color(255, 255, 222),
    this.terminalStroke = const Color(170, 170, 51),
    this.terminalTextColor = const Color(0, 0, 33),
    this.nonTerminalFill = const Color(236, 236, 255),
    this.nonTerminalStroke = const Color(147, 112, 219),
    this.nonTerminalTextColor = const Color(51, 51, 51),
    this.lineColor = const Color(51, 51, 51),
    this.markerFill = const Color(51, 51, 51),
    this.commentFill = const Color(232, 232, 232, 204),
    this.commentStroke = const Color(211, 211, 211),
    this.commentTextColor = const Color(51, 51, 51),
    this.specialFill = const Color(238, 238, 238),
    this.specialStroke = const Color(211, 211, 211),
    this.ruleNameColor = const Color(51, 51, 51),
  });

  /// The font size.
  final double fontSize;

  /// The font family.
  final String fontFamily;

  /// The stroke width.
  final double strokeWidth;

  /// The terminal fill.
  final Color terminalFill;

  /// The terminal stroke.
  final Color terminalStroke;

  /// The terminal text color.
  final Color terminalTextColor;

  /// The non terminal fill.
  final Color nonTerminalFill;

  /// The non terminal stroke.
  final Color nonTerminalStroke;

  /// The non terminal text color.
  final Color nonTerminalTextColor;

  /// The line color.
  final Color lineColor;

  /// The marker fill.
  final Color markerFill;

  /// The comment fill.
  final Color commentFill;

  /// The comment stroke.
  final Color commentStroke;

  /// The comment text color.
  final Color commentTextColor;

  /// The special fill.
  final Color specialFill;

  /// The special stroke.
  final Color specialStroke;

  /// The rule name color.
  final Color ruleNameColor;
}

/// Typed Mermaid Wardley theme block.
final class WardleyTheme {
  /// Creates a typed [WardleyTheme].
  const WardleyTheme({
    this.backgroundColor = const Color(255, 255, 255),
    this.axisColor = const Color(51, 51, 51),
    this.axisTextColor = const Color(19, 19, 0),
    this.gridColor = const Color(211, 211, 211),
    this.componentFill = const Color(255, 255, 255),
    this.componentStroke = const Color(51, 51, 51),
    this.componentLabelColor = const Color(19, 19, 0),
    this.linkStroke = const Color(51, 51, 51),
    this.evolutionStroke = const Color(220, 53, 69),
    this.annotationStroke = const Color(51, 51, 51),
    this.annotationTextColor = const Color(19, 19, 0),
    this.annotationFill = const Color(255, 255, 255),
  });

  /// The background color.
  final Color backgroundColor;

  /// The axis color.
  final Color axisColor;

  /// The axis text color.
  final Color axisTextColor;

  /// The grid color.
  final Color gridColor;

  /// The component fill.
  final Color componentFill;

  /// The component stroke.
  final Color componentStroke;

  /// The component label color.
  final Color componentLabelColor;

  /// The link stroke.
  final Color linkStroke;

  /// The evolution stroke.
  final Color evolutionStroke;

  /// The annotation stroke.
  final Color annotationStroke;

  /// The annotation text color.
  final Color annotationTextColor;

  /// The annotation fill.
  final Color annotationFill;
}

/// Typed Mermaid XY-chart theme variables.
final class XyChartTheme {
  const XyChartTheme({
    this.backgroundColor = const Color(255, 255, 255),
    this.titleColor = const Color(19, 19, 0),
    this.dataLabelColor = const Color(19, 19, 0),
    this.legendTextColor = const Color(19, 19, 0),
    this.xAxisTitleColor = const Color(19, 19, 0),
    this.xAxisLabelColor = const Color(19, 19, 0),
    this.xAxisTickColor = const Color(19, 19, 0),
    this.xAxisLineColor = const Color(19, 19, 0),
    this.yAxisTitleColor = const Color(19, 19, 0),
    this.yAxisLabelColor = const Color(19, 19, 0),
    this.yAxisTickColor = const Color(19, 19, 0),
    this.yAxisLineColor = const Color(19, 19, 0),
    this.plotColors = _mermaidXyPlotColors,
  });

  final Color backgroundColor;
  final Color titleColor;
  final Color dataLabelColor;
  final Color legendTextColor;
  final Color xAxisTitleColor;
  final Color xAxisLabelColor;
  final Color xAxisTickColor;
  final Color xAxisLineColor;
  final Color yAxisTitleColor;
  final Color yAxisLabelColor;
  final Color yAxisTickColor;
  final Color yAxisLineColor;
  final List<Color> plotColors;
}

const _mermaidXyPlotColors = [
  Color(236, 236, 255),
  Color(132, 147, 166),
  Color(255, 195, 160),
  Color(220, 221, 225),
  Color(184, 233, 148),
  Color(209, 163, 111),
  Color(195, 205, 230),
  Color(255, 182, 193),
  Color(73, 96, 120),
  Color(248, 243, 227),
];

/// Typed Mermaid quadrant-chart theme variables.
final class QuadrantTheme {
  const QuadrantTheme({
    this.quadrant1Fill = const Color(236, 236, 255),
    this.quadrant2Fill = const Color(241, 241, 255),
    this.quadrant3Fill = const Color(246, 246, 255),
    this.quadrant4Fill = const Color(251, 251, 255),
    this.quadrant1TextFill = const Color(19, 19, 0),
    this.quadrant2TextFill = const Color(14, 14, 0),
    this.quadrant3TextFill = const Color(9, 9, 0),
    this.quadrant4TextFill = const Color(4, 4, 0),
    this.pointFill = const Color(185, 185, 255),
    this.pointTextFill = const Color(19, 19, 0),
    this.xAxisTextFill = const Color(19, 19, 0),
    this.yAxisTextFill = const Color(19, 19, 0),
    this.internalBorderStroke = const Color(199, 199, 241),
    this.externalBorderStroke = const Color(199, 199, 241),
    this.titleFill = const Color(19, 19, 0),
  });

  final Color quadrant1Fill;
  final Color quadrant2Fill;
  final Color quadrant3Fill;
  final Color quadrant4Fill;
  final Color quadrant1TextFill;
  final Color quadrant2TextFill;
  final Color quadrant3TextFill;
  final Color quadrant4TextFill;
  final Color pointFill;
  final Color pointTextFill;
  final Color xAxisTextFill;
  final Color yAxisTextFill;
  final Color internalBorderStroke;
  final Color externalBorderStroke;
  final Color titleFill;
}

/// Resolved Mermaid theme values used by the Mermaid renderers.
final class MermaidTheme {
  /// Mermaid's default SVG font stack when no `fontFamily` theme variable is
  /// supplied.
  static const defaultFontFamily = '"trebuchet ms", verdana, arial, sans-serif';

  /// Creates a typed [MermaidTheme].
  const MermaidTheme({
    this.background = const Color(255, 255, 255, 0),
    this.primary = const Color(236, 236, 255),
    Color? primaryBorder,
    Color? primaryText,
    Color? line,
    this.secondary = const Color(255, 255, 222),
    Color? tertiary,
    Color? secondaryBorder,
    Color? tertiaryBorder,
    Color? secondaryText,
    Color? tertiaryText,
    this.text = const Color(51, 51, 51),
    Color? title,
    Color? mainBackground,
    Color? secondBackground,
    Color? labelBackground,
    Color? nodeBorder,
    double? strokeWidth,
    String? fontFamily,
    this.fontSize = 16,
    this.categoricalColors = _mermaidColorScale,
    this.categoricalPeerColors = _mermaidColorScalePeers,
    this.categoricalLabelColors = _mermaidColorScaleLabels,
    this.pieColors = _mermaidPieColors,
    this.architecture = const ArchitectureTheme(),
    this.cynefin = const CynefinTheme(),
    this.eventModeling = const EventModelingTheme(),
    this.gitGraph = const GitGraphTheme(),
    this.pie = const PieTheme(),
    this.quadrant = const QuadrantTheme(),
    this.radar = const RadarTheme(),
    this.wardley = const WardleyTheme(),
    this.xyChart = const XyChartTheme(),
  }) : _fontFamilyOverride = fontFamily,
       _railroadCommonOverrides = (
         primaryText: primaryText,
         primaryBorder: primaryBorder,
         line: line,
         tertiary: tertiary,
         secondaryBorder: secondaryBorder,
         tertiaryBorder: tertiaryBorder,
         secondaryText: secondaryText,
         tertiaryText: tertiaryText,
         title: title,
         mainBackground: mainBackground,
         secondBackground: secondBackground,
         labelBackground: labelBackground,
         nodeBorder: nodeBorder,
         strokeWidth: strokeWidth,
       );

  /// The background.
  final Color background;

  /// The primary.
  final Color primary;

  /// The secondary.
  final Color secondary;

  /// The text.
  final Color text;
  final ({
    Color? primaryText,
    Color? primaryBorder,
    Color? line,
    Color? tertiary,
    Color? secondaryBorder,
    Color? tertiaryBorder,
    Color? secondaryText,
    Color? tertiaryText,
    Color? title,
    Color? mainBackground,
    Color? secondBackground,
    Color? labelBackground,
    Color? nodeBorder,
    double? strokeWidth,
  })
  _railroadCommonOverrides;

  /// The resolved primary text after applying Mermaid theme precedence.
  Color get primaryText => _railroadCommonOverrides.primaryText ?? const Color(51, 51, 51);

  /// The resolved primary border after applying Mermaid theme precedence.
  Color get primaryBorder => _railroadCommonOverrides.primaryBorder ?? const Color(147, 112, 219);

  /// The resolved line after applying Mermaid theme precedence.
  Color get line => _railroadCommonOverrides.line ?? const Color(51, 51, 51);

  /// The resolved tertiary after applying Mermaid theme precedence.
  Color get tertiary => _railroadCommonOverrides.tertiary ?? const Color(238, 238, 238);

  /// The resolved secondary border after applying Mermaid theme precedence.
  Color get secondaryBorder => _railroadCommonOverrides.secondaryBorder ?? const Color(170, 170, 51);

  /// The resolved tertiary border after applying Mermaid theme precedence.
  Color get tertiaryBorder => _railroadCommonOverrides.tertiaryBorder ?? const Color(211, 211, 211);

  /// The resolved secondary text after applying Mermaid theme precedence.
  Color get secondaryText => _railroadCommonOverrides.secondaryText ?? const Color(0, 0, 33);

  /// The resolved tertiary text after applying Mermaid theme precedence.
  Color get tertiaryText => _railroadCommonOverrides.tertiaryText ?? const Color(51, 51, 51);

  /// The resolved title after applying Mermaid theme precedence.
  Color get title => _railroadCommonOverrides.title ?? const Color(51, 51, 51);

  /// The resolved main background after applying Mermaid theme precedence.
  Color get mainBackground => _railroadCommonOverrides.mainBackground ?? const Color(236, 236, 255);

  /// The resolved second background after applying Mermaid theme precedence.
  Color get secondBackground => _railroadCommonOverrides.secondBackground ?? const Color(255, 255, 222);

  /// The resolved label background after applying Mermaid theme precedence.
  Color get labelBackground => _railroadCommonOverrides.labelBackground ?? const Color(232, 232, 232, 204);

  /// The resolved node border after applying Mermaid theme precedence.
  Color get nodeBorder => _railroadCommonOverrides.nodeBorder ?? const Color(147, 112, 219);

  /// The resolved stroke width after applying Mermaid theme precedence.
  double get strokeWidth => _railroadCommonOverrides.strokeWidth ?? 1;
  final String? _fontFamilyOverride;

  /// The resolved font family after applying Mermaid theme precedence.
  String get fontFamily => _fontFamilyOverride ?? defaultFontFamily;

  /// Uses a renderer-specific Mermaid default unless the caller explicitly
  /// supplied the global `fontFamily` theme variable.
  String resolveFontFamily({required String fallback}) => _fontFamilyOverride ?? fallback;

  /// The font size.
  final double fontSize;

  /// Mermaid's `cScale0` through `cScale11` categorical colors.
  final List<Color> categoricalColors;

  /// Mermaid's `cScalePeer0` through `cScalePeer11` border colors.
  final List<Color> categoricalPeerColors;

  /// Mermaid's `cScaleLabel0` through `cScaleLabel11` text colors.
  final List<Color> categoricalLabelColors;

  /// Mermaid's `pie1` through `pie12` slice colors.
  final List<Color> pieColors;

  /// The architecture.
  final ArchitectureTheme architecture;

  /// The cynefin.
  final CynefinTheme cynefin;

  /// The event modeling.
  final EventModelingTheme eventModeling;

  /// The git graph.
  final GitGraphTheme gitGraph;

  /// The pie.
  final PieTheme pie;

  /// The quadrant chart.
  final QuadrantTheme quadrant;

  /// The radar.
  final RadarTheme radar;

  /// The wardley.
  final WardleyTheme wardley;

  /// The XY chart.
  final XyChartTheme xyChart;
}

/// Defines the supported diagram direction values.
enum DiagramDirection {
  /// Selects the left to right variant.
  leftToRight,

  /// Selects the top to bottom variant.
  topToBottom,
}

/// Base configuration shared by every Mermaid diagram renderer.
sealed class DiagramRenderOptions {
  const DiagramRenderOptions({this.useWidth, this.useMaxWidth});

  /// Optional fixed width inherited from Mermaid's base diagram config.
  ///
  /// Most current renderers retain this for compatibility without consulting
  /// it during layout.
  final double? useWidth;

  /// Whether an SVG backend should scale to the available container width.
  ///
  /// This backend concern never changes the geometry stored in a scene.
  final bool? useMaxWidth;
}

/// Shared spacing and stroke options for directed graph renderers.
sealed class GraphRenderOptions extends DiagramRenderOptions {
  /// Creates graph renderer options.
  const GraphRenderOptions({
    super.useWidth,
    super.useMaxWidth,
    required this.nodeSpacing,
    required this.rankSpacing,
    required this.diagramPadding,
    required this.edgeWidth,
  });

  /// Separation between nodes in the same rank, in scene units.
  final double nodeSpacing;

  /// Separation between consecutive ranks, in scene units.
  final double rankSpacing;

  /// Padding around graph content before global viewport padding.
  final double diagramPadding;

  /// Normal relationship stroke width.
  final double edgeWidth;
}

/// Typed rendering options for Mermaid architecture diagrams.
final class ArchitectureRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [ArchitectureRenderOptions].
  const ArchitectureRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.padding = 40,
    this.iconSize = 80,
    this.fontSize = 16,
    this.randomize = false,
    this.nodeSeparation = 75,
    this.idealEdgeLengthMultiplier = 1.5,
    this.edgeElasticity = 0.45,
    this.numIter = 2500,
    this.seed = 1,
    Color? groupBorderColor,
    Color? edgeColor,
    Color? edgeArrowColor,
    double? edgeWidth,
    double? groupBorderWidth,
  }) : _themeOverrides = (
         groupBorderColor: groupBorderColor,
         edgeColor: edgeColor,
         edgeArrowColor: edgeArrowColor,
         edgeWidth: edgeWidth,
         groupBorderWidth: groupBorderWidth,
       );

  /// The padding.
  final double padding;

  /// The icon size.
  final double iconSize;

  /// Font size used by Mermaid's architecture graph layout.
  ///
  /// Mermaid's SVG drawing layer renders labels with the global theme font
  /// size, while fCoSE still uses this value when sizing positioned nodes.
  final double fontSize;

  /// Whether fCoSE-compatible layouts randomize their initial node positions.
  final bool randomize;

  /// The node separation.
  final double nodeSeparation;

  /// The ideal edge length multiplier.
  final double idealEdgeLengthMultiplier;

  /// Spring elasticity for edges whose endpoints share a compound group.
  final double edgeElasticity;

  /// Maximum proof-layout solver iterations.
  final int numIter;

  /// Reproducible layout seed. Mermaid reserves zero for native randomness.
  final int seed;

  final ({
    Color? groupBorderColor,
    Color? edgeColor,
    Color? edgeArrowColor,
    double? edgeWidth,
    double? groupBorderWidth,
  })
  _themeOverrides;

  /// The resolved group border color after applying Mermaid theme precedence.
  Color get groupBorderColor => _themeOverrides.groupBorderColor ?? const Color(199, 199, 241);

  /// The resolved edge color after applying Mermaid theme precedence.
  Color get edgeColor => _themeOverrides.edgeColor ?? const Color(51, 51, 51);

  /// The resolved edge arrow color after applying Mermaid theme precedence.
  Color get edgeArrowColor => _themeOverrides.edgeArrowColor ?? const Color(51, 51, 51);

  /// The resolved edge width after applying Mermaid theme precedence.
  double get edgeWidth => _themeOverrides.edgeWidth ?? 3;

  /// The resolved group border width after applying Mermaid theme precedence.
  double get groupBorderWidth => _themeOverrides.groupBorderWidth ?? 2;

  /// Resolves renderer-specific values against the global [MermaidTheme].
  ArchitectureTheme resolveTheme(MermaidTheme theme) {
    final inherited = theme.architecture;
    return ArchitectureTheme(
      edgeColor: _themeOverrides.edgeColor ?? inherited.edgeColor,
      edgeArrowColor: _themeOverrides.edgeArrowColor ?? inherited.edgeArrowColor,
      edgeWidth: _themeOverrides.edgeWidth ?? inherited.edgeWidth,
      groupBorderColor: _themeOverrides.groupBorderColor ?? inherited.groupBorderColor,
      groupBorderWidth: _themeOverrides.groupBorderWidth ?? inherited.groupBorderWidth,
    );
  }
}

/// Typed rendering options for Mermaid cynefin diagrams.
final class CynefinRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [CynefinRenderOptions].
  const CynefinRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.width = 800,
    this.height = 600,
    this.padding = 40,
    this.showDomainDescriptions = true,
    this.boundaryAmplitude = 8,
    this.seed = 0,
    Color? complexColor,
    Color? complicatedColor,
    Color? chaoticColor,
    Color? clearColor,
    Color? confusionColor,
    Color? cliffColor,
    Color? domainLabelColor,
    Color? textColor,
    Color? strokeColor,
    double? domainFontSize,
    double? itemFontSize,
    double? boundaryWidth,
    Color? arrowColor,
    double? arrowWidth,
    double? cliffWidth,
    this.boundaryDashes = const [6, 3],
    this.confusionDashes = const [4, 2],
  }) : _themeOverrides = (
         complexColor: complexColor,
         complicatedColor: complicatedColor,
         chaoticColor: chaoticColor,
         clearColor: clearColor,
         confusionColor: confusionColor,
         cliffColor: cliffColor,
         domainLabelColor: domainLabelColor,
         textColor: textColor,
         strokeColor: strokeColor,
         domainFontSize: domainFontSize,
         itemFontSize: itemFontSize,
         boundaryWidth: boundaryWidth,
         arrowColor: arrowColor,
         arrowWidth: arrowWidth,
         cliffWidth: cliffWidth,
       );

  /// The width.
  final double width;

  /// The height.
  final double height;

  /// The padding.
  final double padding;

  /// The show domain descriptions.
  final bool showDomainDescriptions;

  /// The boundary amplitude.
  final double boundaryAmplitude;

  /// The seed.
  final int seed;
  final ({
    Color? complexColor,
    Color? complicatedColor,
    Color? chaoticColor,
    Color? clearColor,
    Color? confusionColor,
    Color? cliffColor,
    Color? domainLabelColor,
    Color? textColor,
    Color? strokeColor,
    double? domainFontSize,
    double? itemFontSize,
    double? boundaryWidth,
    Color? arrowColor,
    double? arrowWidth,
    double? cliffWidth,
  })
  _themeOverrides;

  /// The boundary dashes.
  final List<double> boundaryDashes;

  /// The confusion dashes.
  final List<double> confusionDashes;

  /// The resolved complex color after applying Mermaid theme precedence.
  Color get complexColor => _themeOverrides.complexColor ?? const CynefinTheme().complexBackground;

  /// The resolved complicated color after applying Mermaid theme precedence.
  Color get complicatedColor => _themeOverrides.complicatedColor ?? const CynefinTheme().complicatedBackground;

  /// The resolved chaotic color after applying Mermaid theme precedence.
  Color get chaoticColor => _themeOverrides.chaoticColor ?? const CynefinTheme().chaoticBackground;

  /// The resolved clear color after applying Mermaid theme precedence.
  Color get clearColor => _themeOverrides.clearColor ?? const CynefinTheme().clearBackground;

  /// The resolved confusion color after applying Mermaid theme precedence.
  Color get confusionColor => _themeOverrides.confusionColor ?? const CynefinTheme().confusionBackground;

  /// The resolved cliff color after applying Mermaid theme precedence.
  Color get cliffColor => _themeOverrides.cliffColor ?? const CynefinTheme().cliffColor;

  /// The resolved domain label color after applying Mermaid theme precedence.
  Color get domainLabelColor => _themeOverrides.domainLabelColor ?? const CynefinTheme().labelColor;

  /// The resolved text color after applying Mermaid theme precedence.
  Color get textColor => _themeOverrides.textColor ?? const CynefinTheme().textColor;

  /// The resolved stroke color after applying Mermaid theme precedence.
  Color get strokeColor => _themeOverrides.strokeColor ?? const CynefinTheme().boundaryColor;

  /// Resolves renderer-specific values against the global [MermaidTheme].
  CynefinTheme resolveTheme(MermaidTheme theme) {
    final inherited = theme.cynefin;
    return CynefinTheme(
      domainFontSize: _themeOverrides.domainFontSize ?? inherited.domainFontSize,
      itemFontSize: _themeOverrides.itemFontSize ?? inherited.itemFontSize,
      boundaryColor: _themeOverrides.strokeColor ?? inherited.boundaryColor,
      boundaryWidth: _themeOverrides.boundaryWidth ?? inherited.boundaryWidth,
      cliffColor: _themeOverrides.cliffColor ?? inherited.cliffColor,
      cliffWidth: _themeOverrides.cliffWidth ?? inherited.cliffWidth,
      arrowColor: _themeOverrides.arrowColor ?? inherited.arrowColor,
      arrowWidth: _themeOverrides.arrowWidth ?? inherited.arrowWidth,
      complexBackground: _themeOverrides.complexColor ?? inherited.complexBackground,
      complicatedBackground: _themeOverrides.complicatedColor ?? inherited.complicatedBackground,
      chaoticBackground: _themeOverrides.chaoticColor ?? inherited.chaoticBackground,
      clearBackground: _themeOverrides.clearColor ?? inherited.clearBackground,
      confusionBackground: _themeOverrides.confusionColor ?? inherited.confusionBackground,
      textColor: _themeOverrides.textColor ?? inherited.textColor,
      labelColor: _themeOverrides.domainLabelColor ?? inherited.labelColor,
    );
  }
}

/// Typed rendering options for Mermaid info diagrams.
final class InfoRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [InfoRenderOptions].
  const InfoRenderOptions({this.version = '11.16.0'});

  /// The version.
  final String version;
}

/// Typed rendering options for Mermaid Kanban diagrams.
enum GanttDisplayMode {
  /// One row per task.
  normal,

  /// Reuse rows for non-overlapping tasks in each section.
  compact,
}

/// Typed rendering options for Mermaid Gantt diagrams.
final class GanttRenderOptions extends DiagramRenderOptions {
  /// Creates Mermaid-compatible Gantt options.
  const GanttRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.titleTopMargin = 25,
    this.barHeight = 20,
    this.barGap = 4,
    this.topPadding = 50,
    this.rightPadding = 75,
    this.leftPadding = 75,
    this.gridLineStartPadding = 35,
    this.fontSize = 11,
    this.sectionFontSize = 11,
    this.numberSectionStyles = 4,
    this.axisFormat = '%Y-%m-%d',
    this.tickInterval,
    this.topAxis = false,
    this.displayMode = GanttDisplayMode.normal,
    this.weekday = GanttWeekday.sunday,
    this.sectionBackground = const Color(102, 102, 255, 25),
    this.alternateSectionBackground = const Color(255, 255, 255, 51),
    this.sectionBackground2 = const Color(255, 244, 0, 51),
    this.excludeBackground = const Color(238, 238, 238),
    this.taskBackground = const Color(138, 144, 221),
    this.taskBorder = const Color(83, 79, 188),
    this.activeTaskBackground = const Color(191, 199, 255),
    this.activeTaskBorder = const Color(83, 79, 188),
    this.doneTaskBackground = const Color(211, 211, 211),
    this.doneTaskBorder = const Color(128, 128, 128),
    this.criticalTaskBackground = const Color(255, 0, 0),
    this.criticalTaskBorder = const Color(255, 136, 136),
    this.taskText = const Color(255, 255, 255),
    this.taskTextOutside = const Color(0, 0, 0),
    this.clickableTaskText = const Color(0, 49, 99),
    this.gridColor = const Color(211, 211, 211),
    this.todayLineColor = const Color(255, 0, 0),
    this.verticalLineColor = const Color(0, 0, 128),
    this.titleColor = const Color(51, 51, 51),
  });

  /// Title baseline offset.
  final double titleTopMargin;

  /// Task bar height.
  final double barHeight;

  /// Gap between task rows.
  final double barGap;

  /// Space above and below the task rows.
  final double topPadding;

  /// Space reserved on the right.
  final double rightPadding;

  /// Space reserved for section labels.
  final double leftPadding;

  /// Vertical grid-line start inset.
  final double gridLineStartPadding;

  /// Task label font size.
  final double fontSize;

  /// Section label font size.
  final double sectionFontSize;

  /// Number of alternating section styles.
  final int numberSectionStyles;

  /// Default D3-compatible axis format.
  final String axisFormat;

  /// Default axis interval when syntax does not override it.
  final GanttTickInterval? tickInterval;

  /// Whether the top axis is enabled by configuration.
  final bool topAxis;

  /// Task row allocation mode.
  final GanttDisplayMode displayMode;

  /// Weekday used for week interval ticks.
  final GanttWeekday weekday;

  /// Primary section-band paint, including Mermaid's section opacity.
  final Color sectionBackground;

  /// Alternating section-band paint.
  final Color alternateSectionBackground;

  /// Third section-band paint.
  final Color sectionBackground2;

  /// Excluded-date background paint.
  final Color excludeBackground;

  /// Planned task fill.
  final Color taskBackground;

  /// Planned task stroke.
  final Color taskBorder;

  /// Active task fill.
  final Color activeTaskBackground;

  /// Active task stroke.
  final Color activeTaskBorder;

  /// Completed task fill.
  final Color doneTaskBackground;

  /// Completed task stroke.
  final Color doneTaskBorder;

  /// Critical task fill.
  final Color criticalTaskBackground;

  /// Critical task stroke.
  final Color criticalTaskBorder;

  /// Text painted inside task bars.
  final Color taskText;

  /// Text painted beside narrow task bars.
  final Color taskTextOutside;

  /// Linked task text.
  final Color clickableTaskText;

  /// Grid stroke.
  final Color gridColor;

  /// Today marker stroke.
  final Color todayLineColor;

  /// Vertical marker paint.
  final Color verticalLineColor;

  /// Diagram and section title paint.
  final Color titleColor;
}

/// Typed rendering options for Mermaid Kanban diagrams.
final class KanbanRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [KanbanRenderOptions].
  const KanbanRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.padding = 8,
    this.sectionWidth = 200,
    this.ticketBaseUrl = '',
    this.sectionGap = 5,
    this.cardGap = 5,
  });

  /// Mermaid Kanban padding retained for configuration compatibility.
  ///
  /// Mermaid 11.16 reads the mindmap padding while laying out Kanban diagrams,
  /// so this setting does not currently alter the rendered viewport.
  final double padding;

  /// Width of each Kanban section in scene units.
  final double sectionWidth;

  /// Optional URL template where `#TICKET#` is replaced by the card ticket.
  final String ticketBaseUrl;

  /// Horizontal gap between sections.
  final double sectionGap;

  /// Vertical gap between cards.
  final double cardGap;
}

/// Typed rendering options for Mermaid event modeling diagrams.
final class EventModelingRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [EventModelingRenderOptions].
  const EventModelingRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.padding = 30,
    this.rowHeight = 32,
    this.swimlaneMinHeight = 70,
    this.swimlanePadding = 15,
    this.swimlaneGap = 10,
    this.boxPadding = 10,
    this.boxOverlap = 90,
    this.boxMinWidth = 80,
    this.boxMaxWidth = 450,
    this.boxMinHeight = 80,
    this.boxMaxHeight = 750,
    this.contentStartX = 250,
    this.textMaxWidth = 430,
  });

  /// Outer viewport padding passed to Mermaid's graph view-box setup.
  final double padding;

  /// Mermaid's public compatibility setting.
  ///
  /// Mermaid.js 11.16 exposes and defaults this value but its event-modeling
  /// renderer does not currently consult it during layout.
  final double rowHeight;

  /// The swimlane min height.
  final double swimlaneMinHeight;

  /// The swimlane padding.
  final double swimlanePadding;

  /// The swimlane gap.
  final double swimlaneGap;

  /// The box padding.
  final double boxPadding;

  /// The box overlap.
  final double boxOverlap;

  /// The box min width.
  final double boxMinWidth;

  /// The box max width.
  final double boxMaxWidth;

  /// The box min height.
  final double boxMinHeight;

  /// The box max height.
  final double boxMaxHeight;

  /// The content start x.
  final double contentStartX;

  /// The text max width.
  final double textMaxWidth;
}

/// Mermaid's legacy Git Graph node-label configuration.
///
/// Mermaid 11.16 retains this object in its public configuration but its Git
/// renderer does not currently consult it.
final class GitGraphNodeLabelOptions {
  /// Creates a typed [GitGraphNodeLabelOptions].
  const GitGraphNodeLabelOptions({
    this.width = defaultWidth,
    this.height = defaultHeight,
    this.x = defaultX,
    this.y = defaultY,
  });

  /// The default width behavior exposed by [GitGraphNodeLabelOptions].
  static const defaultWidth = 75.0;

  /// The default height behavior exposed by [GitGraphNodeLabelOptions].
  static const defaultHeight = 100.0;

  /// The default x behavior exposed by [GitGraphNodeLabelOptions].
  static const defaultX = -25.0;

  /// The default y behavior exposed by [GitGraphNodeLabelOptions].
  static const defaultY = 0.0;

  /// The width.
  final double width;

  /// The height.
  final double height;

  /// The x.
  final double x;

  /// The y.
  final double y;

  @override
  bool operator ==(Object other) =>
      other is GitGraphNodeLabelOptions &&
      width == other.width &&
      height == other.height &&
      x == other.x &&
      y == other.y;

  @override
  int get hashCode => Object.hash(width, height, x, y);
}

/// Typed rendering options for Mermaid git graph diagrams.
final class GitGraphRenderOptions extends DiagramRenderOptions {
  /// The default use max width behavior exposed by [GitGraphRenderOptions].
  static const defaultUseMaxWidth = true;

  /// The default title top margin behavior exposed by [GitGraphRenderOptions].
  static const defaultTitleTopMargin = 25.0;

  /// The default diagram padding behavior exposed by [GitGraphRenderOptions].
  static const defaultDiagramPadding = 8.0;

  /// The default main branch name behavior exposed by [GitGraphRenderOptions].
  static const defaultMainBranchName = 'main';

  /// The default main branch order behavior exposed by [GitGraphRenderOptions].
  static const defaultMainBranchOrder = 0.0;

  /// The default show commit label behavior exposed by [GitGraphRenderOptions].
  static const defaultShowCommitLabel = true;

  /// The default show branches behavior exposed by [GitGraphRenderOptions].
  static const defaultShowBranches = true;

  /// The default rotate commit label behavior exposed by [GitGraphRenderOptions].
  static const defaultRotateCommitLabel = true;

  /// The default parallel commits behavior exposed by [GitGraphRenderOptions].
  static const defaultParallelCommits = false;

  /// The default arrow marker absolute behavior exposed by [GitGraphRenderOptions].
  static const defaultArrowMarkerAbsolute = false;

  /// Mermaid's default-theme `git0` through `git7` colors after its standard
  /// light-theme darkening step.
  static const defaultBranchColors = [
    Color(0, 0, 236),
    Color(222, 222, 0),
    Color(157, 236, 0),
    Color(0, 118, 236),
    Color(0, 236, 236),
    Color(0, 236, 118),
    Color(236, 0, 236),
    Color(236, 0, 0),
  ];

  /// Mermaid's matching default foreground colors for branch labels.
  static const defaultBranchLabelColors = [
    Color(255, 255, 255),
    Color(0, 0, 0),
    Color(0, 0, 0),
    Color(255, 255, 255),
    Color(0, 0, 0),
    Color(0, 0, 0),
    Color(0, 0, 0),
    Color(0, 0, 0),
  ];

  /// Mermaid's default-theme `gitInv0` through `gitInv7` colors used by
  /// highlighted commits.
  static const defaultHighlightColors = [
    Color(19, 19, 0),
    Color(0, 0, 161),
    Color(49, 0, 147),
    Color(147, 73, 0),
    Color(147, 0, 0),
    Color(147, 0, 73),
    Color(0, 147, 0),
    Color(0, 147, 147),
  ];

  /// Creates a typed [GitGraphRenderOptions].
  const GitGraphRenderOptions({
    super.useWidth,
    super.useMaxWidth = defaultUseMaxWidth,
    this.titleTopMargin = defaultTitleTopMargin,
    this.diagramPadding = defaultDiagramPadding,
    this.nodeLabel = const GitGraphNodeLabelOptions(),
    this.mainBranchName = defaultMainBranchName,
    this.mainBranchOrder = defaultMainBranchOrder,
    this.showCommitLabel = defaultShowCommitLabel,
    this.showBranches = defaultShowBranches,
    this.rotateCommitLabel = defaultRotateCommitLabel,
    this.parallelCommits = defaultParallelCommits,
    this.arrowMarkerAbsolute = defaultArrowMarkerAbsolute,
    this.commitRadius = 10,
    this.branchSpacing = 50,
    this.commitSpacing = 50,
    List<Color>? branchColors,
    List<Color>? branchLabelColors,
    List<Color>? highlightColors,
    Color? branchLineColor,
    this.branchLineWidth = 1,
    this.branchLineDashes = const [2],
    this.commitStrokeWidth = 1,
    this.commitEdgeWidth = 8,
    this.commitEdgeCap = StrokeCap.round,
    Color? commitLabelColor,
    Color? commitLabelBackground,
    double? commitLabelFontSize,
    Color? specialCommitColor,
    Color? cherryPickColor,
    Color? tagLabelColor,
    Color? tagBackground,
    Color? tagBorder,
    double? tagLabelFontSize,
    Color? tagHoleColor,
    int? themeColorLimit,
    bool? useGradient,
    Color? gradientStart,
    Color? gradientStop,
    Color? filterColor,
    ThemeShadow? dropShadow,
  }) : _themeOverrides = (
         branchColors: branchColors,
         branchLabelColors: branchLabelColors,
         highlightColors: highlightColors,
         branchLineColor: branchLineColor,
         commitLabelColor: commitLabelColor,
         commitLabelBackground: commitLabelBackground,
         commitLabelFontSize: commitLabelFontSize,
         specialCommitColor: specialCommitColor,
         cherryPickColor: cherryPickColor,
         tagLabelColor: tagLabelColor,
         tagBackground: tagBackground,
         tagBorder: tagBorder,
         tagLabelFontSize: tagLabelFontSize,
         tagHoleColor: tagHoleColor,
         themeColorLimit: themeColorLimit,
         useGradient: useGradient,
         gradientStart: gradientStart,
         gradientStop: gradientStop,
         filterColor: filterColor,
         dropShadow: dropShadow,
       );

  /// The title top margin.
  final double titleTopMargin;

  /// The diagram padding.
  final double diagramPadding;

  /// Compatibility-only in Mermaid 11.16; see [GitGraphNodeLabelOptions].
  final GitGraphNodeLabelOptions nodeLabel;

  /// The main branch name.
  final String mainBranchName;

  /// The main branch order.
  final double mainBranchOrder;

  /// The show commit label.
  final bool showCommitLabel;

  /// The show branches.
  final bool showBranches;

  /// The rotate commit label.
  final bool rotateCommitLabel;

  /// The parallel commits.
  final bool parallelCommits;

  /// Compatibility-only in Mermaid 11.16's Git renderer.
  ///
  /// Git Graph draws typed paths directly and does not emit SVG arrow markers.
  final bool arrowMarkerAbsolute;

  /// The commit radius.
  final double commitRadius;

  /// The branch spacing.
  final double branchSpacing;

  /// The commit spacing.
  final double commitSpacing;

  /// The branch line width.
  final double branchLineWidth;

  /// The branch line dashes.
  final List<double> branchLineDashes;

  /// The commit stroke width.
  final double commitStrokeWidth;

  /// The commit edge width.
  final double commitEdgeWidth;

  /// The commit edge cap.
  final StrokeCap commitEdgeCap;
  final ({
    List<Color>? branchColors,
    List<Color>? branchLabelColors,
    List<Color>? highlightColors,
    Color? branchLineColor,
    Color? commitLabelColor,
    Color? commitLabelBackground,
    double? commitLabelFontSize,
    Color? specialCommitColor,
    Color? cherryPickColor,
    Color? tagLabelColor,
    Color? tagBackground,
    Color? tagBorder,
    double? tagLabelFontSize,
    Color? tagHoleColor,
    int? themeColorLimit,
    bool? useGradient,
    Color? gradientStart,
    Color? gradientStop,
    Color? filterColor,
    ThemeShadow? dropShadow,
  })
  _themeOverrides;

  /// The resolved branch colors after applying Mermaid theme precedence.
  List<Color> get branchColors => _themeOverrides.branchColors ?? defaultBranchColors;

  /// The resolved branch label colors after applying Mermaid theme precedence.
  List<Color> get branchLabelColors => _themeOverrides.branchLabelColors ?? defaultBranchLabelColors;

  /// The resolved highlight colors after applying Mermaid theme precedence.
  List<Color> get highlightColors => _themeOverrides.highlightColors ?? defaultHighlightColors;

  /// The resolved branch line color after applying Mermaid theme precedence.
  Color get branchLineColor => _themeOverrides.branchLineColor ?? const Color(51, 51, 51);

  /// The resolved commit label color after applying Mermaid theme precedence.
  Color get commitLabelColor => _themeOverrides.commitLabelColor ?? const Color(0, 0, 33);

  /// The resolved commit label background after applying Mermaid theme precedence.
  Color get commitLabelBackground => _themeOverrides.commitLabelBackground ?? const Color(255, 255, 222, 128);

  /// The resolved commit label font size after applying Mermaid theme precedence.
  double get commitLabelFontSize => _themeOverrides.commitLabelFontSize ?? 10;

  /// The resolved special commit color after applying Mermaid theme precedence.
  Color get specialCommitColor => _themeOverrides.specialCommitColor ?? const Color(236, 236, 255);

  /// The resolved cherry pick color after applying Mermaid theme precedence.
  Color get cherryPickColor => _themeOverrides.cherryPickColor ?? const Color(51, 51, 51);

  /// The resolved tag label color after applying Mermaid theme precedence.
  Color get tagLabelColor => _themeOverrides.tagLabelColor ?? const Color(19, 19, 0);

  /// The resolved tag background after applying Mermaid theme precedence.
  Color get tagBackground => _themeOverrides.tagBackground ?? const Color(236, 236, 255);

  /// The resolved tag border after applying Mermaid theme precedence.
  Color get tagBorder => _themeOverrides.tagBorder ?? const Color(199, 199, 241);

  /// The resolved tag label font size after applying Mermaid theme precedence.
  double get tagLabelFontSize => _themeOverrides.tagLabelFontSize ?? 10;

  /// The resolved tag hole color after applying Mermaid theme precedence.
  Color get tagHoleColor => _themeOverrides.tagHoleColor ?? const Color(51, 51, 51);

  /// The resolved theme color limit after applying Mermaid theme precedence.
  int get themeColorLimit => _themeOverrides.themeColorLimit ?? 12;

  /// The resolved use gradient after applying Mermaid theme precedence.
  bool get useGradient => _themeOverrides.useGradient ?? false;

  /// The resolved gradient start after applying Mermaid theme precedence.
  Color get gradientStart => _themeOverrides.gradientStart ?? const Color(147, 112, 219);

  /// The resolved gradient stop after applying Mermaid theme precedence.
  Color get gradientStop => _themeOverrides.gradientStop ?? const Color(170, 170, 51);

  /// The resolved filter color after applying Mermaid theme precedence.
  Color get filterColor => _themeOverrides.filterColor ?? const Color(255, 255, 255);

  /// The resolved drop shadow after applying Mermaid theme precedence.
  ThemeShadow get dropShadow => _themeOverrides.dropShadow ?? const ThemeShadow();

  /// Resolves Mermaid's precedence: diagram config, then global theme.
  GitGraphTheme resolveTheme(MermaidTheme theme) {
    final global = theme.gitGraph;
    return GitGraphTheme(
      branchColors: _themeOverrides.branchColors ?? global.branchColors,
      branchLabelColors: _themeOverrides.branchLabelColors ?? global.branchLabelColors,
      highlightColors: _themeOverrides.highlightColors ?? global.highlightColors,
      commitLineColor: _themeOverrides.branchLineColor ?? global.commitLineColor ?? theme.line,
      commitLabelColor: _themeOverrides.commitLabelColor ?? global.commitLabelColor,
      commitLabelBackground: _themeOverrides.commitLabelBackground ?? global.commitLabelBackground,
      commitLabelFontSize: _themeOverrides.commitLabelFontSize ?? global.commitLabelFontSize,
      specialColor: _themeOverrides.specialCommitColor ?? global.specialColor,
      primaryColor: _themeOverrides.cherryPickColor ?? global.primaryColor,
      tagLabelColor: _themeOverrides.tagLabelColor ?? global.tagLabelColor,
      tagLabelBackground: _themeOverrides.tagBackground ?? global.tagLabelBackground,
      tagLabelBorder: _themeOverrides.tagBorder ?? global.tagLabelBorder,
      tagLabelFontSize: _themeOverrides.tagLabelFontSize ?? global.tagLabelFontSize,
      tagHoleColor: _themeOverrides.tagHoleColor ?? global.tagHoleColor,
      themeColorLimit: _themeOverrides.themeColorLimit ?? global.themeColorLimit,
      useGradient: _themeOverrides.useGradient ?? global.useGradient,
      gradientStart: _themeOverrides.gradientStart ?? global.gradientStart,
      gradientStop: _themeOverrides.gradientStop ?? global.gradientStop,
      filterColor: _themeOverrides.filterColor ?? global.filterColor,
      dropShadow: _themeOverrides.dropShadow ?? global.dropShadow,
    );
  }
}

/// Typed rendering options for Mermaid tree view diagrams.
final class TreeViewRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [TreeViewRenderOptions].
  const TreeViewRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.rowIndent = 10,
    this.paddingX = 5,
    this.paddingY = 5,
    this.lineThickness = 1,
    this.showIcons = false,
    this.defaultIconPack = '',
    this.filenameIcons = const {},
    this.extensionIcons = const {},
    this.labelColor = defaultLabelColor,
    this.lineColor = defaultLineColor,
    this.iconColor = defaultIconColor,
    this.descriptionColor = defaultDescriptionColor,
    this.highlightBackground = defaultHighlightBackground,
    this.highlightStroke = defaultHighlightStroke,
    this.highlightStrokeWidth = 1,
  });

  /// The default label color behavior exposed by [TreeViewRenderOptions].
  static const defaultLabelColor = Color(0, 0, 0);

  /// The default line color behavior exposed by [TreeViewRenderOptions].
  static const defaultLineColor = Color(0, 0, 0);

  /// The default icon color behavior exposed by [TreeViewRenderOptions].
  static const defaultIconColor = Color(84, 110, 122);

  /// The default description color behavior exposed by [TreeViewRenderOptions].
  static const defaultDescriptionColor = Color(106, 153, 85);

  /// Namespace used by Mermaid's small built-in file and folder icon pack.
  static const builtInIconPack = 'mermaid-treeview';

  /// The built in file icon behavior exposed by [TreeViewRenderOptions].
  static const builtInFileIcon = '$builtInIconPack:file';

  /// The built in folder icon behavior exposed by [TreeViewRenderOptions].
  static const builtInFolderIcon = '$builtInIconPack:folder';

  /// Mermaid's 15%-opaque amber highlight background.
  static const defaultHighlightBackground = Color(255, 193, 7, 38);

  /// The default highlight stroke behavior exposed by [TreeViewRenderOptions].
  static const defaultHighlightStroke = Color(255, 193, 7);

  /// The row indent.
  final double rowIndent;

  /// The padding x.
  final double paddingX;

  /// The padding y.
  final double paddingY;

  /// The line thickness.
  final double lineThickness;

  /// Whether nodes without explicit `icon(...)` annotations receive icons.
  final bool showIcons;

  /// Pack used to qualify mapped or explicit unprefixed icon names.
  ///
  /// Empty values preserve Mermaid's behavior of selecting its built-in pack.
  final String defaultIconPack;

  /// Exact filename-to-icon overrides used when [showIcons] is enabled.
  final Map<String, String> filenameIcons;

  /// Case-insensitive extension-to-icon overrides used when [showIcons] is
  /// enabled. Keys may include or omit the leading period.
  final Map<String, String> extensionIcons;

  /// Primary node-label color.
  final Color labelColor;

  /// Connector-line color.
  final Color lineColor;

  /// Color applied to application-resolved and placeholder icon geometry.
  final Color iconColor;

  /// Mermaid's default secondary text color for node descriptions.
  final Color descriptionColor;

  /// Background and outline used by the built-in `highlight` class.
  final Color highlightBackground;

  /// The highlight stroke.
  final Color highlightStroke;

  /// The highlight stroke width.
  final double highlightStrokeWidth;
}

/// Defines the supported treemap value format values.
enum TreemapValueFormat {
  /// Selects the plain variant.
  plain,

  /// Selects the grouped variant.
  grouped,

  /// Selects the currency grouped variant.
  currencyGrouped,
}

// Mermaid 11.16 treemap configuration defaults.
const _treemapUseMaxWidth = true;
const _treemapPadding = 10.0;
const _treemapDiagramPadding = 8.0;
const _treemapShowValues = true;
const _treemapNodeWidth = 100.0;
const _treemapNodeHeight = 40.0;
const _treemapBorderWidth = 1.0;
const _treemapValueFontSize = 12.0;
const _treemapLabelFontSize = 14.0;

/// Typed rendering options for Mermaid treemap diagrams.
final class TreemapRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [TreemapRenderOptions].
  const TreemapRenderOptions({
    super.useWidth,
    super.useMaxWidth = _treemapUseMaxWidth,
    this.padding = _treemapPadding,
    this.diagramPadding = _treemapDiagramPadding,
    this.showValues = _treemapShowValues,
    this.nodeWidth = _treemapNodeWidth,
    this.nodeHeight = _treemapNodeHeight,
    this.borderWidth = _treemapBorderWidth,
    this.valueFontSize = _treemapValueFontSize,
    this.labelFontSize = _treemapLabelFontSize,
    this.valueFormat = TreemapValueFormat.grouped,
    this.sectionOpacity = .6,
    this.sectionStrokeOpacity = .4,
    this.leafOpacity = .3,
    List<Color>? sectionColors,
    List<Color>? sectionBorderColors,
    List<Color>? labelColors,
  }) : _palettes = (primary: sectionColors, peer: sectionBorderColors, label: labelColors);

  /// Padding between D3 treemap tiles.
  final double padding;

  /// The diagram padding.
  final double diagramPadding;

  /// The show values.
  final bool showValues;

  /// The node width.
  final double nodeWidth;

  /// The node height.
  final double nodeHeight;

  /// Mermaid configuration retained for parity with the current renderer.
  ///
  /// Mermaid 11.16 accepts this setting but still uses its fixed section and
  /// leaf stroke widths.
  final double borderWidth;

  /// Mermaid configuration retained for parity with the current renderer.
  ///
  /// Mermaid 11.16 accepts this setting but computes value sizes dynamically.
  final double valueFontSize;

  /// Mermaid configuration retained for parity with the current renderer.
  ///
  /// Mermaid 11.16 accepts this setting but computes label sizes dynamically.
  final double labelFontSize;

  /// The value format.
  final TreemapValueFormat valueFormat;

  /// The section opacity.
  final double sectionOpacity;

  /// The section stroke opacity.
  final double sectionStrokeOpacity;

  /// The leaf opacity.
  final double leafOpacity;
  final ({List<Color>? primary, List<Color>? peer, List<Color>? label}) _palettes;

  /// The resolved section colors after applying Mermaid theme precedence.
  List<Color> get sectionColors => _palettes.primary ?? _mermaidColorScale;

  /// The resolved section border colors after applying Mermaid theme precedence.
  List<Color> get sectionBorderColors => _palettes.peer ?? _mermaidColorScalePeers;

  /// The resolved label colors after applying Mermaid theme precedence.
  List<Color> get labelColors => _palettes.label ?? _mermaidColorScaleLabels;

  /// Resolves section colors using diagram, global theme, and default precedence.
  List<Color> resolveSectionColors(MermaidTheme theme) =>
      _resolveThemePalette(_palettes.primary, theme.categoricalColors, _mermaidColorScale);

  /// Resolves section border colors using diagram, global theme, and default precedence.
  List<Color> resolveSectionBorderColors(MermaidTheme theme) =>
      _resolveThemePalette(_palettes.peer, theme.categoricalPeerColors, _mermaidColorScalePeers);

  /// Resolves label colors using diagram, global theme, and default precedence.
  List<Color> resolveLabelColors(MermaidTheme theme) =>
      _resolveThemePalette(_palettes.label, theme.categoricalLabelColors, _mermaidColorScaleLabels);
}

/// Typed rendering options for Mermaid wardley diagrams.
final class WardleyRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [WardleyRenderOptions].
  const WardleyRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.width = 900,
    this.height = 600,
    this.padding = 48,
    this.nodeRadius = 6,
    this.nodeLabelOffset = 8,
    this.axisFontSize = 12,
    this.labelFontSize = 10,
    this.showGrid = false,
    Color? backgroundColor,
    Color? axisColor,
    Color? axisTextColor,
    this.stageBoundaryColor = const Color(0, 0, 0, 204),
    Color? gridColor,
    Color? componentFill,
    Color? componentStroke,
    Color? componentLabelColor,
    this.anchorLabelColor = const Color(0, 0, 0),
    this.buildStrategyStroke = const Color(0, 0, 0),
    Color? linkStroke,
    Color? evolutionStroke,
    Color? annotationStroke,
    Color? annotationTextColor,
    Color? annotationFill,
  }) : _themeOverrides = (
         backgroundColor: backgroundColor,
         axisColor: axisColor,
         axisTextColor: axisTextColor,
         gridColor: gridColor,
         componentFill: componentFill,
         componentStroke: componentStroke,
         componentLabelColor: componentLabelColor,
         linkStroke: linkStroke,
         evolutionStroke: evolutionStroke,
         annotationStroke: annotationStroke,
         annotationTextColor: annotationTextColor,
         annotationFill: annotationFill,
       );

  /// The width.
  final double width;

  /// The height.
  final double height;

  /// The padding.
  final double padding;

  /// The node radius.
  final double nodeRadius;

  /// The node label offset.
  final double nodeLabelOffset;

  /// The axis font size.
  final double axisFontSize;

  /// The label font size.
  final double labelFontSize;

  /// The show grid.
  final bool showGrid;
  final ({
    Color? backgroundColor,
    Color? axisColor,
    Color? axisTextColor,
    Color? gridColor,
    Color? componentFill,
    Color? componentStroke,
    Color? componentLabelColor,
    Color? linkStroke,
    Color? evolutionStroke,
    Color? annotationStroke,
    Color? annotationTextColor,
    Color? annotationFill,
  })
  _themeOverrides;

  /// The stage boundary color.
  final Color stageBoundaryColor;

  /// The anchor label color.
  final Color anchorLabelColor;

  /// The build strategy stroke.
  final Color buildStrategyStroke;

  /// The resolved background color after applying Mermaid theme precedence.
  Color get backgroundColor => _themeOverrides.backgroundColor ?? const WardleyTheme().backgroundColor;

  /// The resolved axis color after applying Mermaid theme precedence.
  Color get axisColor => _themeOverrides.axisColor ?? const Color(51, 51, 51);

  /// The resolved axis text color after applying Mermaid theme precedence.
  Color get axisTextColor => _themeOverrides.axisTextColor ?? const WardleyTheme().axisTextColor;

  /// The resolved grid color after applying Mermaid theme precedence.
  Color get gridColor => _themeOverrides.gridColor ?? const Color(211, 211, 211);

  /// The resolved component fill after applying Mermaid theme precedence.
  Color get componentFill => _themeOverrides.componentFill ?? const WardleyTheme().componentFill;

  /// The resolved component stroke after applying Mermaid theme precedence.
  Color get componentStroke => _themeOverrides.componentStroke ?? const Color(51, 51, 51);

  /// The resolved component label color after applying Mermaid theme precedence.
  Color get componentLabelColor => _themeOverrides.componentLabelColor ?? const WardleyTheme().componentLabelColor;

  /// The resolved link stroke after applying Mermaid theme precedence.
  Color get linkStroke => _themeOverrides.linkStroke ?? const Color(51, 51, 51);

  /// The resolved evolution stroke after applying Mermaid theme precedence.
  Color get evolutionStroke => _themeOverrides.evolutionStroke ?? const WardleyTheme().evolutionStroke;

  /// Resolves renderer-specific values against the global [MermaidTheme].
  WardleyTheme resolveTheme(MermaidTheme theme) {
    final inherited = theme.wardley;
    return WardleyTheme(
      backgroundColor: _themeOverrides.backgroundColor ?? inherited.backgroundColor,
      axisColor: _themeOverrides.axisColor ?? inherited.axisColor,
      axisTextColor: _themeOverrides.axisTextColor ?? inherited.axisTextColor,
      gridColor: _themeOverrides.gridColor ?? inherited.gridColor,
      componentFill: _themeOverrides.componentFill ?? inherited.componentFill,
      componentStroke: _themeOverrides.componentStroke ?? inherited.componentStroke,
      componentLabelColor: _themeOverrides.componentLabelColor ?? inherited.componentLabelColor,
      linkStroke: _themeOverrides.linkStroke ?? inherited.linkStroke,
      evolutionStroke: _themeOverrides.evolutionStroke ?? inherited.evolutionStroke,
      annotationStroke: _themeOverrides.annotationStroke ?? inherited.annotationStroke,
      annotationTextColor: _themeOverrides.annotationTextColor ?? inherited.annotationTextColor,
      annotationFill: _themeOverrides.annotationFill ?? inherited.annotationFill,
    );
  }
}

/// Typed rendering options for Mermaid railroad diagrams.
final class RailroadRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [RailroadRenderOptions].
  const RailroadRenderOptions({
    super.useWidth,
    super.useMaxWidth,
    this.compactMode = false,
    this.padding = 10,
    this.verticalSeparation = 8,
    this.horizontalSeparation = 10,
    this.arcRadius = 10,
    double? fontSize,
    String? fontFamily,
    double? strokeWidth,
    this.showMarkers = true,
    this.markerRadius = 5,
    Color? terminalFill,
    Color? terminalStroke,
    Color? terminalTextColor,
    Color? nonTerminalFill,
    Color? nonTerminalStroke,
    Color? nonTerminalTextColor,
    Color? lineColor,
    Color? markerFill,
    Color? commentFill,
    Color? commentStroke,
    Color? commentTextColor,
    Color? specialFill,
    Color? specialStroke,
    Color? ruleNameColor,
  }) : _themeOverrides = (
         fontSize: fontSize,
         fontFamily: fontFamily,
         strokeWidth: strokeWidth,
         terminalFill: terminalFill,
         terminalStroke: terminalStroke,
         terminalTextColor: terminalTextColor,
         nonTerminalFill: nonTerminalFill,
         nonTerminalStroke: nonTerminalStroke,
         nonTerminalTextColor: nonTerminalTextColor,
         lineColor: lineColor,
         markerFill: markerFill,
         commentFill: commentFill,
         commentStroke: commentStroke,
         commentTextColor: commentTextColor,
         specialFill: specialFill,
         specialStroke: specialStroke,
         ruleNameColor: ruleNameColor,
       );

  /// Mermaid currently accepts this option but does not alter its renderer.
  final bool compactMode;

  /// The padding.
  final double padding;

  /// The vertical separation.
  final double verticalSeparation;

  /// The horizontal separation.
  final double horizontalSeparation;

  /// The arc radius.
  final double arcRadius;

  /// The show markers.
  final bool showMarkers;

  /// The marker radius.
  final double markerRadius;
  final ({
    double? fontSize,
    String? fontFamily,
    double? strokeWidth,
    Color? terminalFill,
    Color? terminalStroke,
    Color? terminalTextColor,
    Color? nonTerminalFill,
    Color? nonTerminalStroke,
    Color? nonTerminalTextColor,
    Color? lineColor,
    Color? markerFill,
    Color? commentFill,
    Color? commentStroke,
    Color? commentTextColor,
    Color? specialFill,
    Color? specialStroke,
    Color? ruleNameColor,
  })
  _themeOverrides;

  RailroadTheme get _defaults => const RailroadTheme(
    terminalStroke: Color(238, 238, 188),
    nonTerminalStroke: Color(199, 199, 241),
    nonTerminalTextColor: Color(19, 19, 0),
    commentFill: Color(232, 232, 232),
    commentStroke: Color(136, 136, 136),
    commentTextColor: Color(102, 102, 102),
    specialFill: Color(236, 236, 255),
    specialStroke: Color(199, 199, 241),
  );

  /// The resolved font size after applying Mermaid theme precedence.
  double get fontSize => _themeOverrides.fontSize ?? _defaults.fontSize;

  /// The resolved font family after applying Mermaid theme precedence.
  String get fontFamily => _themeOverrides.fontFamily ?? _defaults.fontFamily;

  /// The resolved stroke width after applying Mermaid theme precedence.
  double get strokeWidth => _themeOverrides.strokeWidth ?? _defaults.strokeWidth;

  /// The resolved terminal fill after applying Mermaid theme precedence.
  Color get terminalFill => _themeOverrides.terminalFill ?? _defaults.terminalFill;

  /// The resolved terminal stroke after applying Mermaid theme precedence.
  Color get terminalStroke => _themeOverrides.terminalStroke ?? _defaults.terminalStroke;

  /// The resolved terminal text color after applying Mermaid theme precedence.
  Color get terminalTextColor => _themeOverrides.terminalTextColor ?? _defaults.terminalTextColor;

  /// The resolved non terminal fill after applying Mermaid theme precedence.
  Color get nonTerminalFill => _themeOverrides.nonTerminalFill ?? _defaults.nonTerminalFill;

  /// The resolved non terminal stroke after applying Mermaid theme precedence.
  Color get nonTerminalStroke => _themeOverrides.nonTerminalStroke ?? _defaults.nonTerminalStroke;

  /// The resolved non terminal text color after applying Mermaid theme precedence.
  Color get nonTerminalTextColor => _themeOverrides.nonTerminalTextColor ?? _defaults.nonTerminalTextColor;

  /// The resolved line color after applying Mermaid theme precedence.
  Color get lineColor => _themeOverrides.lineColor ?? _defaults.lineColor;

  /// The resolved marker fill after applying Mermaid theme precedence.
  Color get markerFill => _themeOverrides.markerFill ?? _defaults.markerFill;

  /// The resolved comment fill after applying Mermaid theme precedence.
  Color get commentFill => _themeOverrides.commentFill ?? _defaults.commentFill;

  /// The resolved comment stroke after applying Mermaid theme precedence.
  Color get commentStroke => _themeOverrides.commentStroke ?? _defaults.commentStroke;

  /// The resolved comment text color after applying Mermaid theme precedence.
  Color get commentTextColor => _themeOverrides.commentTextColor ?? _defaults.commentTextColor;

  /// The resolved special fill after applying Mermaid theme precedence.
  Color get specialFill => _themeOverrides.specialFill ?? _defaults.specialFill;

  /// The resolved special stroke after applying Mermaid theme precedence.
  Color get specialStroke => _themeOverrides.specialStroke ?? _defaults.specialStroke;

  /// The resolved rule name color after applying Mermaid theme precedence.
  Color get ruleNameColor => _themeOverrides.ruleNameColor ?? _defaults.ruleNameColor;

  /// Resolves explicit railroad styling over Mermaid's common theme variables.
  RailroadTheme resolveTheme(MermaidTheme theme) => RailroadTheme(
    fontSize: _themeOverrides.fontSize ?? theme.fontSize,
    fontFamily: _themeOverrides.fontFamily ?? theme.resolveFontFamily(fallback: _defaults.fontFamily),
    // Mermaid's railroad rules fix their strokes at 2px and override the
    // generic theme strokeWidth. Explicit typed diagram options remain useful
    // for backend-specific customization.
    strokeWidth: _themeOverrides.strokeWidth ?? _defaults.strokeWidth,
    terminalFill:
        _themeOverrides.terminalFill ?? theme._railroadCommonOverrides.secondBackground ?? _defaults.terminalFill,
    terminalStroke:
        _themeOverrides.terminalStroke ?? theme._railroadCommonOverrides.secondaryBorder ?? _defaults.terminalStroke,
    terminalTextColor:
        _themeOverrides.terminalTextColor ??
        theme._railroadCommonOverrides.secondaryText ??
        _defaults.terminalTextColor,
    nonTerminalFill:
        _themeOverrides.nonTerminalFill ?? theme._railroadCommonOverrides.mainBackground ?? _defaults.nonTerminalFill,
    nonTerminalStroke:
        _themeOverrides.nonTerminalStroke ??
        theme._railroadCommonOverrides.primaryBorder ??
        _defaults.nonTerminalStroke,
    nonTerminalTextColor:
        _themeOverrides.nonTerminalTextColor ??
        theme._railroadCommonOverrides.primaryText ??
        _defaults.nonTerminalTextColor,
    lineColor: _themeOverrides.lineColor ?? theme._railroadCommonOverrides.line ?? _defaults.lineColor,
    markerFill: _themeOverrides.markerFill ?? theme._railroadCommonOverrides.line ?? _defaults.markerFill,
    commentFill: _themeOverrides.commentFill ?? theme._railroadCommonOverrides.labelBackground ?? _defaults.commentFill,
    commentStroke:
        _themeOverrides.commentStroke ?? theme._railroadCommonOverrides.tertiaryBorder ?? _defaults.commentStroke,
    commentTextColor:
        _themeOverrides.commentTextColor ?? theme._railroadCommonOverrides.tertiaryText ?? _defaults.commentTextColor,
    specialFill: _themeOverrides.specialFill ?? theme._railroadCommonOverrides.tertiary ?? _defaults.specialFill,
    specialStroke:
        _themeOverrides.specialStroke ?? theme._railroadCommonOverrides.tertiaryBorder ?? _defaults.specialStroke,
    ruleNameColor: _themeOverrides.ruleNameColor ?? theme._railroadCommonOverrides.title ?? _defaults.ruleNameColor,
  );
}

/// Typed rendering options for Mermaid packet diagrams.
final class PacketRenderOptions extends DiagramRenderOptions {
  /// Mermaid's packet renderer uses black title text independently of the global theme.
  static const defaultTitleTextColor = Color(0, 0, 0);

  /// Creates a typed [PacketRenderOptions].
  const PacketRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.rowHeight = 32,
    this.bitWidth = 32,
    this.bitsPerRow = 32,
    this.showBits = true,
    this.paddingX = 5,
    this.paddingY = 5,
    this.titleText = defaultTitleTextColor,
  });

  /// The row height.
  final double rowHeight;

  /// The bit width.
  final double bitWidth;

  /// The bits per row.
  final int bitsPerRow;

  /// The show bits.
  final bool showBits;

  /// The padding x.
  final double paddingX;

  /// The padding y.
  final double paddingY;

  /// The title text.
  final Color titleText;
}

/// Defines the supported pie legend position values.
enum PieLegendPosition {
  /// Selects the top variant.
  top,

  /// Selects the bottom variant.
  bottom,

  /// Selects the left variant.
  left,

  /// Selects the right variant.
  right,

  /// Selects the center variant.
  center,
}

/// Typed rendering options for Mermaid pie diagrams.
final class PieRenderOptions extends DiagramRenderOptions {
  /// Mermaid's default light-theme color for pie chart titles.
  static const defaultTitleTextColor = Color(0, 0, 0);

  /// Creates a typed [PieRenderOptions].
  const PieRenderOptions({
    super.useWidth = 984,
    super.useMaxWidth = true,
    this.size = 450,
    this.margin = 40,
    this.radius,
    this.textPosition = .75,
    this.donutHole = 0,
    this.legendPosition = PieLegendPosition.right,
    this.highlightSlice,
    this.showLegend = true,
    double? sectionOpacity,
    Color? sectionStroke,
    Color? outerStroke,
    Color? legendText,
    Color? titleText,
    double? titleTextSize,
    Color? sectionText,
    double? sectionTextSize,
    double? legendTextSize,
    double? sectionStrokeWidth,
    double? outerStrokeWidth,
    List<Color>? sectionColors,
  }) : _themeOverrides = (
         colors: sectionColors,
         opacity: sectionOpacity,
         sectionStroke: sectionStroke,
         outerStroke: outerStroke,
         legendText: legendText,
         titleText: titleText,
         titleTextSize: titleTextSize,
         sectionText: sectionText,
         sectionTextSize: sectionTextSize,
         legendTextSize: legendTextSize,
         sectionStrokeWidth: sectionStrokeWidth,
         outerStrokeWidth: outerStrokeWidth,
       );

  /// The size.
  final double size;

  /// The margin.
  final double margin;

  /// The radius.
  final double? radius;

  /// The text position.
  final double textPosition;

  /// The donut hole.
  final double donutHole;

  /// The legend position.
  final PieLegendPosition legendPosition;

  /// The highlight slice.
  final String? highlightSlice;

  /// The show legend.
  final bool showLegend;
  final ({
    List<Color>? colors,
    double? opacity,
    Color? sectionStroke,
    Color? outerStroke,
    Color? legendText,
    Color? titleText,
    double? titleTextSize,
    Color? sectionText,
    double? sectionTextSize,
    double? legendTextSize,
    double? sectionStrokeWidth,
    double? outerStrokeWidth,
  })
  _themeOverrides;

  /// The resolved section opacity after applying Mermaid theme precedence.
  double get sectionOpacity => _themeOverrides.opacity ?? const PieTheme().opacity;

  /// The resolved section stroke after applying Mermaid theme precedence.
  Color get sectionStroke => _themeOverrides.sectionStroke ?? const PieTheme().strokeColor;

  /// The resolved outer stroke after applying Mermaid theme precedence.
  Color get outerStroke => _themeOverrides.outerStroke ?? const PieTheme().outerStrokeColor;

  /// The resolved legend text after applying Mermaid theme precedence.
  Color get legendText => _themeOverrides.legendText ?? const PieTheme().legendTextColor;

  /// The resolved title text after applying Mermaid theme precedence.
  Color get titleText => _themeOverrides.titleText ?? const PieTheme().titleTextColor;

  /// The resolved section colors after applying Mermaid theme precedence.
  List<Color> get sectionColors => _themeOverrides.colors ?? _mermaidPieColors;

  /// Resolves section colors using diagram, global theme, and default precedence.
  List<Color> resolveSectionColors(MermaidTheme theme) =>
      _resolveThemePalette(_themeOverrides.colors, theme.pieColors, _mermaidPieColors);

  /// Resolves renderer-specific values against the global [MermaidTheme].
  PieTheme resolveTheme(MermaidTheme theme) {
    final inherited = theme.pie;
    return PieTheme(
      titleTextSize: _themeOverrides.titleTextSize ?? inherited.titleTextSize,
      titleTextColor: _themeOverrides.titleText ?? inherited.titleTextColor,
      sectionTextSize: _themeOverrides.sectionTextSize ?? inherited.sectionTextSize,
      sectionTextColor: _themeOverrides.sectionText ?? inherited.sectionTextColor,
      legendTextSize: _themeOverrides.legendTextSize ?? inherited.legendTextSize,
      legendTextColor: _themeOverrides.legendText ?? inherited.legendTextColor,
      strokeColor: _themeOverrides.sectionStroke ?? inherited.strokeColor,
      strokeWidth: _themeOverrides.sectionStrokeWidth ?? inherited.strokeWidth,
      outerStrokeWidth: _themeOverrides.outerStrokeWidth ?? inherited.outerStrokeWidth,
      outerStrokeColor: _themeOverrides.outerStroke ?? inherited.outerStrokeColor,
      opacity: _themeOverrides.opacity ?? inherited.opacity,
    );
  }
}

/// Typed rendering options for Mermaid radar diagrams.
final class RadarRenderOptions extends DiagramRenderOptions {
  /// Creates a typed [RadarRenderOptions].
  const RadarRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.width = 600,
    this.height = 600,
    this.marginTop = 50,
    this.marginRight = 50,
    this.marginBottom = 50,
    this.marginLeft = 50,
    this.radius,
    this.axisScaleFactor = 1,
    this.axisLabelFactor = 1.05,
    this.curveTension = .17,
    Color? graticuleColor,
    double? graticuleOpacity,
    Color? axisColor,
    double? seriesOpacity,
    double? axisStrokeWidth,
    double? axisLabelFontSize,
    double? curveStrokeWidth,
    double? graticuleStrokeWidth,
    double? legendBoxSize,
    double? legendFontSize,
    List<Color>? seriesColors,
  }) : _themeOverrides = (
         colors: seriesColors,
         graticuleColor: graticuleColor,
         graticuleOpacity: graticuleOpacity,
         axisColor: axisColor,
         seriesOpacity: seriesOpacity,
         axisStrokeWidth: axisStrokeWidth,
         axisLabelFontSize: axisLabelFontSize,
         curveStrokeWidth: curveStrokeWidth,
         graticuleStrokeWidth: graticuleStrokeWidth,
         legendBoxSize: legendBoxSize,
         legendFontSize: legendFontSize,
       );

  /// The width.
  final double width;

  /// The height.
  final double height;

  /// The margin top.
  final double marginTop;

  /// The margin right.
  final double marginRight;

  /// The margin bottom.
  final double marginBottom;

  /// The margin left.
  final double marginLeft;

  /// The radius.
  final double? radius;

  /// The axis scale factor.
  final double axisScaleFactor;

  /// The axis label factor.
  final double axisLabelFactor;

  /// The curve tension.
  final double curveTension;
  final ({
    List<Color>? colors,
    Color? graticuleColor,
    double? graticuleOpacity,
    Color? axisColor,
    double? seriesOpacity,
    double? axisStrokeWidth,
    double? axisLabelFontSize,
    double? curveStrokeWidth,
    double? graticuleStrokeWidth,
    double? legendBoxSize,
    double? legendFontSize,
  })
  _themeOverrides;

  /// The resolved graticule color after applying Mermaid theme precedence.
  Color get graticuleColor => _themeOverrides.graticuleColor ?? const RadarTheme().graticuleColor;

  /// The resolved graticule opacity after applying Mermaid theme precedence.
  double get graticuleOpacity => _themeOverrides.graticuleOpacity ?? const RadarTheme().graticuleOpacity;

  /// The resolved axis color after applying Mermaid theme precedence.
  Color get axisColor => _themeOverrides.axisColor ?? const RadarTheme().axisColor;

  /// The resolved series opacity after applying Mermaid theme precedence.
  double get seriesOpacity => _themeOverrides.seriesOpacity ?? const RadarTheme().curveOpacity;

  /// The resolved series colors after applying Mermaid theme precedence.
  List<Color> get seriesColors => _themeOverrides.colors ?? _mermaidColorScale;

  /// Resolves series colors using diagram, global theme, and default precedence.
  List<Color> resolveSeriesColors(MermaidTheme theme) =>
      _resolveThemePalette(_themeOverrides.colors, theme.categoricalColors, _mermaidColorScale);

  /// Resolves renderer-specific values against the global [MermaidTheme].
  RadarTheme resolveTheme(MermaidTheme theme) {
    final inherited = theme.radar;
    return RadarTheme(
      axisColor: _themeOverrides.axisColor ?? inherited.axisColor,
      axisStrokeWidth: _themeOverrides.axisStrokeWidth ?? inherited.axisStrokeWidth,
      axisLabelFontSize: _themeOverrides.axisLabelFontSize ?? inherited.axisLabelFontSize,
      curveOpacity: _themeOverrides.seriesOpacity ?? inherited.curveOpacity,
      curveStrokeWidth: _themeOverrides.curveStrokeWidth ?? inherited.curveStrokeWidth,
      graticuleColor: _themeOverrides.graticuleColor ?? inherited.graticuleColor,
      graticuleStrokeWidth: _themeOverrides.graticuleStrokeWidth ?? inherited.graticuleStrokeWidth,
      graticuleOpacity: _themeOverrides.graticuleOpacity ?? inherited.graticuleOpacity,
      legendBoxSize: _themeOverrides.legendBoxSize ?? inherited.legendBoxSize,
      legendFontSize: _themeOverrides.legendFontSize ?? inherited.legendFontSize,
    );
  }
}

/// Typed rendering options for Mermaid flowcharts.
final class FlowchartRenderOptions extends GraphRenderOptions {
  /// Creates flowchart options with Mermaid-compatible spacing defaults.
  const FlowchartRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    super.nodeSpacing = 50,
    super.rankSpacing = 50,
    super.diagramPadding = 8,
    this.nodePadding = 15,
    super.edgeWidth = 1,
  });

  /// Horizontal and vertical padding around node labels.
  final double nodePadding;
}

/// Typed rendering options for Mermaid class diagrams.
final class ClassRenderOptions extends GraphRenderOptions {
  /// Creates class-diagram options with Mermaid-compatible spacing defaults.
  const ClassRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    super.nodeSpacing = 50,
    super.rankSpacing = 50,
    super.diagramPadding = 8,
    this.nodePadding = 12,
    this.compartmentPadding = 7,
    super.edgeWidth = 1,
  });

  /// Horizontal padding inside class boxes.
  final double nodePadding;

  /// Vertical padding around compartment rows.
  final double compartmentPadding;
}

/// Typed rendering options for Mermaid state diagrams.
final class StateRenderOptions extends GraphRenderOptions {
  /// Creates state-diagram options with Mermaid-compatible spacing defaults.
  const StateRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    super.nodeSpacing = 50,
    super.rankSpacing = 50,
    super.diagramPadding = 8,
    this.nodePadding = 15,
    this.noteMargin = 10,
    super.edgeWidth = 1,
  });

  /// Padding inside state boxes.
  final double nodePadding;

  /// Gap between a state and an attached note.
  final double noteMargin;
}

/// Typed rendering options for Mermaid entity-relationship diagrams.
final class ErRenderOptions extends GraphRenderOptions {
  /// Creates ER-diagram options with Mermaid-compatible spacing defaults.
  const ErRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    super.nodeSpacing = 50,
    super.rankSpacing = 80,
    super.diagramPadding = 8,
    this.cellPadding = 12.5,
    super.edgeWidth = 1,
  });

  /// Padding inside entity-table cells.
  final double cellPadding;
}

/// Typed Mermaid sequence-diagram layout configuration.
final class SequenceRenderOptions extends DiagramRenderOptions {
  /// Creates sequence options with Mermaid.js 11.16 spacing defaults.
  const SequenceRenderOptions({
    super.useWidth,
    super.useMaxWidth = true,
    this.activationWidth = 10,
    this.diagramMarginX = 50,
    this.diagramMarginY = 10,
    this.actorMargin = 50,
    this.actorWidth = 150,
    this.actorHeight = 65,
    this.boxMargin = 10,
    this.boxTextMargin = 5,
    this.noteMargin = 10,
    this.messageMargin = 35,
    this.mirrorActors = true,
    this.bottomMarginAdjustment = 1,
    this.showSequenceNumbers = false,
    this.actorFontSize = 16,
    this.noteFontSize = 16,
    this.messageFontSize = 16,
    this.wrapPadding = 10,
    this.labelBoxWidth = 50,
    this.labelBoxHeight = 20,
  });

  /// Width of activation rectangles.
  final double activationWidth;

  /// Horizontal outer margin.
  final double diagramMarginX;

  /// Vertical outer margin.
  final double diagramMarginY;

  /// Gap between adjacent participant boxes.
  final double actorMargin;

  /// Minimum participant width.
  final double actorWidth;

  /// Participant box height.
  final double actorHeight;

  /// Padding around grouping boxes and sequence frames.
  final double boxMargin;

  /// Padding around frame labels.
  final double boxTextMargin;

  /// Padding around notes.
  final double noteMargin;

  /// Minimum vertical distance allocated to messages.
  final double messageMargin;

  /// Whether participant boxes are repeated below the diagram.
  final bool mirrorActors;

  /// Additional lifeline length below the last statement.
  final double bottomMarginAdjustment;

  /// Whether messages are numbered without an `autonumber` statement.
  final bool showSequenceNumbers;

  /// Participant-label font size.
  final double actorFontSize;

  /// Note-label font size.
  final double noteFontSize;

  /// Message-label font size.
  final double messageFontSize;

  /// Horizontal padding used by wrapped labels.
  final double wrapPadding;

  /// Width of a frame's kind label.
  final double labelBoxWidth;

  /// Height of a frame's kind label.
  final double labelBoxHeight;
}

/// Typed Mermaid mindmap layout configuration.
final class MindmapRenderOptions extends DiagramRenderOptions {
  /// Creates mindmap options with Mermaid-compatible defaults.
  const MindmapRenderOptions({super.useWidth, super.useMaxWidth = true, this.padding = 10});

  /// Padding around the rendered diagram.
  final double padding;
}

/// Typed Mermaid timeline layout configuration.
final class TimelineRenderOptions extends DiagramRenderOptions {
  /// Creates timeline options with Mermaid-compatible defaults.
  const TimelineRenderOptions({super.useWidth, super.useMaxWidth = true, this.leftMargin = 150, this.padding = 50});

  /// Leading outer margin, matching Mermaid's `leftMargin`.
  final double leftMargin;

  /// Padding around the rendered diagram.
  final double padding;
}

/// Top-level configuration for layout and rendering.
///
/// [theme] supplies global Mermaid variables, while each diagram-specific
/// field contains typed renderer configuration. [padding] is applied after
/// diagram layout when the final scene viewport is constructed.
/// Geometry and presentation configuration for one XY chart axis.
final class XyChartAxisRenderOptions {
  const XyChartAxisRenderOptions({
    this.showLabel = true,
    this.labelFontSize = 14,
    this.labelPadding = 5,
    this.showTitle = true,
    this.titleFontSize = 16,
    this.titlePadding = 5,
    this.showTick = true,
    this.tickLength = 5,
    this.tickWidth = 2,
    this.showAxisLine = true,
    this.axisLineWidth = 2,
    this.labelRotation = 0,
  });

  final bool showLabel;
  final double labelFontSize;
  final double labelPadding;
  final bool showTitle;
  final double titleFontSize;
  final double titlePadding;
  final bool showTick;
  final double tickLength;
  final double tickWidth;
  final bool showAxisLine;
  final double axisLineWidth;
  final double labelRotation;
}

/// Geometry and presentation configuration for XY charts.
final class XyChartRenderOptions extends DiagramRenderOptions {
  const XyChartRenderOptions({
    this.width = 700,
    this.height = 500,
    this.titleFontSize = 20,
    this.titlePadding = 10,
    this.showTitle = true,
    this.showLegend = true,
    this.legendFontSize = 14,
    this.legendPadding = 10,
    this.showDataLabel = false,
    this.showDataLabelOutsideBar = false,
    this.xAxis = const XyChartAxisRenderOptions(),
    this.yAxis = const XyChartAxisRenderOptions(),
    this.plotReservedSpacePercent = 50,
    super.useWidth,
    super.useMaxWidth = true,
  });

  final double width;
  final double height;
  final double titleFontSize;
  final double titlePadding;
  final bool showTitle;
  final bool showLegend;
  final double legendFontSize;
  final double legendPadding;
  final bool showDataLabel;
  final bool showDataLabelOutsideBar;
  final XyChartAxisRenderOptions xAxis;
  final XyChartAxisRenderOptions yAxis;
  final double plotReservedSpacePercent;
}

/// Geometry and presentation configuration for quadrant charts.
final class QuadrantChartRenderOptions extends DiagramRenderOptions {
  const QuadrantChartRenderOptions({
    this.chartWidth = 500,
    this.chartHeight = 500,
    this.titlePadding = 10,
    this.titleFontSize = 20,
    this.quadrantPadding = 5,
    this.xAxisLabelPadding = 5,
    this.yAxisLabelPadding = 5,
    this.xAxisLabelFontSize = 16,
    this.yAxisLabelFontSize = 16,
    this.quadrantLabelFontSize = 16,
    this.quadrantTextTopPadding = 5,
    this.pointTextPadding = 5,
    this.pointLabelFontSize = 12,
    this.pointRadius = 5,
    this.xAxisPosition = QuadrantXAxisPosition.top,
    this.yAxisPosition = QuadrantYAxisPosition.left,
    this.internalBorderStrokeWidth = 1,
    this.externalBorderStrokeWidth = 2,
    super.useWidth,
    super.useMaxWidth = true,
  });

  final double chartWidth;
  final double chartHeight;
  final double titlePadding;
  final double titleFontSize;
  final double quadrantPadding;
  final double xAxisLabelPadding;
  final double yAxisLabelPadding;
  final double xAxisLabelFontSize;
  final double yAxisLabelFontSize;
  final double quadrantLabelFontSize;
  final double quadrantTextTopPadding;
  final double pointTextPadding;
  final double pointLabelFontSize;
  final double pointRadius;
  final QuadrantXAxisPosition xAxisPosition;
  final QuadrantYAxisPosition yAxisPosition;
  final double internalBorderStrokeWidth;
  final double externalBorderStrokeWidth;
}

enum QuadrantXAxisPosition { top, bottom }

enum QuadrantYAxisPosition { left, right }

final class RenderOptions {
  /// Creates rendering options with Mermaid-compatible defaults.
  const RenderOptions({
    this.theme = const MermaidTheme(),
    this.padding = 20,
    this.architecture = const ArchitectureRenderOptions(),
    this.cynefin = const CynefinRenderOptions(),
    this.eventModeling = const EventModelingRenderOptions(),
    this.classDiagram = const ClassRenderOptions(),
    this.entityRelationship = const ErRenderOptions(),
    this.flowchart = const FlowchartRenderOptions(),
    this.gantt = const GanttRenderOptions(),
    this.gitGraph = const GitGraphRenderOptions(),
    this.info = const InfoRenderOptions(),
    this.kanban = const KanbanRenderOptions(),
    this.mindmap = const MindmapRenderOptions(),
    this.packet = const PacketRenderOptions(),
    this.pie = const PieRenderOptions(),
    this.quadrantChart = const QuadrantChartRenderOptions(),
    this.radar = const RadarRenderOptions(),
    this.railroad = const RailroadRenderOptions(),
    this.sequence = const SequenceRenderOptions(),
    this.stateDiagram = const StateRenderOptions(),
    this.timeline = const TimelineRenderOptions(),
    this.treeView = const TreeViewRenderOptions(),
    this.treemap = const TreemapRenderOptions(),
    this.wardley = const WardleyRenderOptions(),
    this.xyChart = const XyChartRenderOptions(),
    this.diagram = const <Type, DiagramRenderOptions>{},
  });

  /// Global colors, typography, palettes, and renderer theme blocks.
  final MermaidTheme theme;

  /// Padding in scene units added around the computed content bounds.
  final double padding;

  /// Architecture renderer configuration.
  final ArchitectureRenderOptions architecture;

  /// Cynefin renderer configuration.
  final CynefinRenderOptions cynefin;

  /// Event Modeling renderer configuration.
  final EventModelingRenderOptions eventModeling;

  /// Class-diagram renderer configuration.
  final ClassRenderOptions classDiagram;

  /// Entity-relationship renderer configuration.
  final ErRenderOptions entityRelationship;

  /// Flowchart renderer configuration.
  final FlowchartRenderOptions flowchart;

  /// Gantt renderer configuration.
  final GanttRenderOptions gantt;

  /// Git Graph renderer configuration.
  final GitGraphRenderOptions gitGraph;

  /// Info renderer configuration.
  final InfoRenderOptions info;

  /// Kanban renderer configuration.
  final KanbanRenderOptions kanban;

  /// Mindmap renderer configuration.
  final MindmapRenderOptions mindmap;

  /// Packet renderer configuration.
  final PacketRenderOptions packet;

  /// Pie renderer configuration.
  final PieRenderOptions pie;

  /// Quadrant-chart renderer configuration.
  final QuadrantChartRenderOptions quadrantChart;

  /// Radar renderer configuration.
  final RadarRenderOptions radar;

  /// Shared railroad, ABNF, EBNF, and PEG renderer configuration.
  final RailroadRenderOptions railroad;

  /// Sequence renderer configuration.
  final SequenceRenderOptions sequence;

  /// State-diagram renderer configuration.
  final StateRenderOptions stateDiagram;

  /// Timeline renderer configuration.
  final TimelineRenderOptions timeline;

  /// Tree View renderer configuration.
  final TreeViewRenderOptions treeView;

  /// Treemap renderer configuration.
  final TreemapRenderOptions treemap;

  /// Wardley renderer configuration.
  final WardleyRenderOptions wardley;

  /// XY Chart renderer configuration.
  final XyChartRenderOptions xyChart;

  /// Additional typed options for renderer families added after this API.
  final Map<Type, DiagramRenderOptions> diagram;

  /// Returns the configured options matching the runtime type of [fallback].
  ///
  /// Entries in [diagram] take precedence over the corresponding named field.
  /// [fallback] also establishes the generic return type.
  T optionsFor<T extends DiagramRenderOptions>(T fallback) {
    final override = diagram[fallback.runtimeType];
    if (override != null) return override as T;
    return switch (fallback) {
          ArchitectureRenderOptions() => architecture,
          CynefinRenderOptions() => cynefin,
          EventModelingRenderOptions() => eventModeling,
          ClassRenderOptions() => classDiagram,
          ErRenderOptions() => entityRelationship,
          FlowchartRenderOptions() => flowchart,
          GanttRenderOptions() => gantt,
          GitGraphRenderOptions() => gitGraph,
          InfoRenderOptions() => info,
          KanbanRenderOptions() => kanban,
          MindmapRenderOptions() => mindmap,
          PacketRenderOptions() => packet,
          PieRenderOptions() => pie,
          QuadrantChartRenderOptions() => quadrantChart,
          RadarRenderOptions() => radar,
          RailroadRenderOptions() => railroad,
          SequenceRenderOptions() => sequence,
          StateRenderOptions() => stateDiagram,
          TimelineRenderOptions() => timeline,
          TreeViewRenderOptions() => treeView,
          TreemapRenderOptions() => treemap,
          WardleyRenderOptions() => wardley,
          XyChartRenderOptions() => xyChart,
        }
        as T;
  }
}

/// Controls how SVG root width attributes are derived from a scene.
enum SvgWidthMode {
  /// Use the backend-neutral sizing policy carried by [DiagramScene].
  scene,

  /// Emit the viewport's intrinsic numeric width and height.
  fixed,

  /// Fill the available width up to the viewport's intrinsic width.
  fitContainer,
}

/// Options that affect SVG serialization without changing scene geometry.
final class SvgRenderOptions {
  /// Creates SVG serialization options.
  const SvgRenderOptions({
    this.pretty = false,
    this.includeXmlDeclaration = false,
    this.rootId,
    this.widthMode = SvgWidthMode.scene,
  });

  /// Whether to indent the generated XML.
  final bool pretty;

  /// Whether to emit an XML declaration before the root element.
  final bool includeXmlDeclaration;

  /// Optional `id` assigned to the root `<svg>` element.
  final String? rootId;

  /// How root width and height attributes are emitted.
  final SvgWidthMode widthMode;
}
