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
  const ArchitectureTheme({
    this.edgeColor = const Color(51, 51, 51),
    this.edgeArrowColor = const Color(51, 51, 51),
    this.edgeWidth = 3,
    this.groupBorderColor = const Color(199, 199, 241),
    this.groupBorderWidth = 2,
  });

  final Color edgeColor;
  final Color edgeArrowColor;
  final double edgeWidth;
  final Color groupBorderColor;
  final double groupBorderWidth;
}

/// Typed Mermaid Cynefin theme block.
final class CynefinTheme {
  const CynefinTheme({
    this.domainFontSize = 16,
    this.itemFontSize = 12,
    this.boundaryColor = const Color(51, 51, 51),
    this.boundaryWidth = 2,
    this.cliffColor = const Color(139, 0, 0),
    this.cliffWidth = 4,
    this.arrowColor = const Color(51, 51, 51),
    this.arrowWidth = 2,
    this.complexBackground = const Color(232, 245, 233, 102),
    this.complicatedBackground = const Color(227, 242, 253, 102),
    this.chaoticBackground = const Color(251, 233, 231, 102),
    this.clearBackground = const Color(255, 248, 225, 102),
    this.confusionBackground = const Color(243, 229, 245, 128),
    this.textColor = const Color(51, 51, 51),
    this.labelColor = const Color(19, 19, 0),
  });

  final double domainFontSize;
  final double itemFontSize;
  final Color boundaryColor;
  final double boundaryWidth;
  final Color cliffColor;
  final double cliffWidth;
  final Color arrowColor;
  final double arrowWidth;
  final Color complexBackground;
  final Color complicatedBackground;
  final Color chaoticBackground;
  final Color clearBackground;
  final Color confusionBackground;
  final Color textColor;
  final Color labelColor;
}

/// Typed Mermaid Event Modeling theme variables.
final class EventModelingTheme {
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

  final Color uiFill;
  final Color uiStroke;
  final Color processorFill;
  final Color processorStroke;
  final Color readModelFill;
  final Color readModelStroke;
  final Color commandFill;
  final Color commandStroke;
  final Color eventFill;
  final Color eventStroke;
  final Color swimlaneBackgroundOdd;
  final Color swimlaneBackgroundStroke;
  final Color arrowhead;
  final Color relationStroke;
}

/// Backend-neutral representation of Mermaid's Git Graph shadow variable.
final class ThemeShadow {
  const ThemeShadow({this.color = const Color(185, 185, 185), this.offsetX = 1, this.offsetY = 2, this.blurRadius = 2});

  final Color color;
  final double offsetX;
  final double offsetY;
  final double blurRadius;
}

/// Typed Mermaid Git Graph theme variables.
final class GitGraphTheme {
  const GitGraphTheme({
    this.branchColors = GitGraphRenderOptions.defaultBranchColors,
    this.highlightColors = GitGraphRenderOptions.defaultHighlightColors,
    this.branchLabelColors = GitGraphRenderOptions.defaultBranchLabelColors,
    this.tagLabelColor = const Color(19, 19, 0),
    this.tagLabelBackground = const Color(236, 236, 255),
    this.tagLabelBorder = const Color(199, 199, 241),
    this.tagLabelFontSize = 10,
    this.commitLabelColor = const Color(0, 0, 33),
    this.commitLabelBackground = const Color(255, 255, 222, 128),
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

  final List<Color> branchColors;
  final List<Color> highlightColors;
  final List<Color> branchLabelColors;
  final Color tagLabelColor;
  final Color tagLabelBackground;
  final Color tagLabelBorder;
  final double tagLabelFontSize;
  final Color commitLabelColor;
  final Color commitLabelBackground;
  final double commitLabelFontSize;
  final Color? commitLineColor;
  final Color tagHoleColor;
  final Color primaryColor;
  final Color specialColor;
  final int themeColorLimit;
  final bool useGradient;
  final Color gradientStart;
  final Color gradientStop;
  final Color filterColor;
  final ThemeShadow dropShadow;
}

/// Typed Mermaid Pie theme variables other than the slice palette.
final class PieTheme {
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

  final double titleTextSize;
  final Color titleTextColor;
  final double sectionTextSize;
  final Color sectionTextColor;
  final double legendTextSize;
  final Color legendTextColor;
  final Color strokeColor;
  final double strokeWidth;
  final double outerStrokeWidth;
  final Color outerStrokeColor;
  final double opacity;
}

/// Typed Mermaid Radar theme block.
final class RadarTheme {
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

  final Color axisColor;
  final double axisStrokeWidth;
  final double axisLabelFontSize;
  final double curveOpacity;
  final double curveStrokeWidth;
  final Color graticuleColor;
  final double graticuleStrokeWidth;
  final double graticuleOpacity;
  final double legendBoxSize;
  final double legendFontSize;
}

/// Resolved Mermaid theme values shared by the four railroad frontends.
final class RailroadTheme {
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

  final double fontSize;
  final String fontFamily;
  final double strokeWidth;
  final Color terminalFill;
  final Color terminalStroke;
  final Color terminalTextColor;
  final Color nonTerminalFill;
  final Color nonTerminalStroke;
  final Color nonTerminalTextColor;
  final Color lineColor;
  final Color markerFill;
  final Color commentFill;
  final Color commentStroke;
  final Color commentTextColor;
  final Color specialFill;
  final Color specialStroke;
  final Color ruleNameColor;
}

/// Typed Mermaid Wardley theme block.
final class WardleyTheme {
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

  final Color backgroundColor;
  final Color axisColor;
  final Color axisTextColor;
  final Color gridColor;
  final Color componentFill;
  final Color componentStroke;
  final Color componentLabelColor;
  final Color linkStroke;
  final Color evolutionStroke;
  final Color annotationStroke;
  final Color annotationTextColor;
  final Color annotationFill;
}

final class MermaidTheme {
  const MermaidTheme({
    this.background = const Color(255, 255, 255, 0),
    this.primary = const Color(236, 236, 255),
    this.primaryBorder = const Color(147, 112, 219),
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
    this.radar = const RadarTheme(),
    this.wardley = const WardleyTheme(),
  }) : _fontFamilyOverride = fontFamily,
       _railroadCommonOverrides = (
         primaryText: primaryText,
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

  final Color background;
  final Color primary;
  final Color primaryBorder;
  final Color secondary;
  final Color text;
  final ({
    Color? primaryText,
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
  Color get primaryText => _railroadCommonOverrides.primaryText ?? const Color(51, 51, 51);
  Color get line => _railroadCommonOverrides.line ?? const Color(51, 51, 51);
  Color get tertiary => _railroadCommonOverrides.tertiary ?? const Color(238, 238, 238);
  Color get secondaryBorder => _railroadCommonOverrides.secondaryBorder ?? const Color(170, 170, 51);
  Color get tertiaryBorder => _railroadCommonOverrides.tertiaryBorder ?? const Color(211, 211, 211);
  Color get secondaryText => _railroadCommonOverrides.secondaryText ?? const Color(0, 0, 33);
  Color get tertiaryText => _railroadCommonOverrides.tertiaryText ?? const Color(51, 51, 51);
  Color get title => _railroadCommonOverrides.title ?? const Color(51, 51, 51);
  Color get mainBackground => _railroadCommonOverrides.mainBackground ?? const Color(236, 236, 255);
  Color get secondBackground => _railroadCommonOverrides.secondBackground ?? const Color(255, 255, 222);
  Color get labelBackground => _railroadCommonOverrides.labelBackground ?? const Color(232, 232, 232, 204);
  Color get nodeBorder => _railroadCommonOverrides.nodeBorder ?? const Color(147, 112, 219);
  double get strokeWidth => _railroadCommonOverrides.strokeWidth ?? 1;
  final String? _fontFamilyOverride;
  String get fontFamily => _fontFamilyOverride ?? 'Arial, sans-serif';

  /// Uses a renderer-specific Mermaid default unless the caller explicitly
  /// supplied the global `fontFamily` theme variable.
  String resolveFontFamily({required String fallback}) => _fontFamilyOverride ?? fallback;
  final double fontSize;

  /// Mermaid's `cScale0` through `cScale11` categorical colors.
  final List<Color> categoricalColors;

  /// Mermaid's `cScalePeer0` through `cScalePeer11` border colors.
  final List<Color> categoricalPeerColors;

  /// Mermaid's `cScaleLabel0` through `cScaleLabel11` text colors.
  final List<Color> categoricalLabelColors;

  /// Mermaid's `pie1` through `pie12` slice colors.
  final List<Color> pieColors;

  final ArchitectureTheme architecture;
  final CynefinTheme cynefin;
  final EventModelingTheme eventModeling;
  final GitGraphTheme gitGraph;
  final PieTheme pie;
  final RadarTheme radar;
  final WardleyTheme wardley;
}

enum DiagramDirection { leftToRight, topToBottom }

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

final class ArchitectureRenderOptions extends DiagramRenderOptions {
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

  final double padding;
  final double iconSize;

  /// Font size used by Mermaid's architecture graph layout.
  ///
  /// Mermaid's SVG drawing layer renders labels with the global theme font
  /// size, while fCoSE still uses this value when sizing positioned nodes.
  final double fontSize;

  /// Whether fCoSE-compatible layouts randomize their initial node positions.
  final bool randomize;

  final double nodeSeparation;
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

  Color get groupBorderColor => _themeOverrides.groupBorderColor ?? const Color(199, 199, 241);
  Color get edgeColor => _themeOverrides.edgeColor ?? const Color(51, 51, 51);
  Color get edgeArrowColor => _themeOverrides.edgeArrowColor ?? const Color(51, 51, 51);
  double get edgeWidth => _themeOverrides.edgeWidth ?? 3;
  double get groupBorderWidth => _themeOverrides.groupBorderWidth ?? 2;

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

final class CynefinRenderOptions extends DiagramRenderOptions {
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

  final double width;
  final double height;
  final double padding;
  final bool showDomainDescriptions;
  final double boundaryAmplitude;
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
  final List<double> boundaryDashes;
  final List<double> confusionDashes;

  Color get complexColor => _themeOverrides.complexColor ?? const CynefinTheme().complexBackground;
  Color get complicatedColor => _themeOverrides.complicatedColor ?? const CynefinTheme().complicatedBackground;
  Color get chaoticColor => _themeOverrides.chaoticColor ?? const CynefinTheme().chaoticBackground;
  Color get clearColor => _themeOverrides.clearColor ?? const CynefinTheme().clearBackground;
  Color get confusionColor => _themeOverrides.confusionColor ?? const CynefinTheme().confusionBackground;
  Color get cliffColor => _themeOverrides.cliffColor ?? const CynefinTheme().cliffColor;
  Color get domainLabelColor => _themeOverrides.domainLabelColor ?? const CynefinTheme().labelColor;
  Color get textColor => _themeOverrides.textColor ?? const CynefinTheme().textColor;
  Color get strokeColor => _themeOverrides.strokeColor ?? const CynefinTheme().boundaryColor;

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

final class InfoRenderOptions extends DiagramRenderOptions {
  const InfoRenderOptions({this.version = '11.16.0'});

  final String version;
}

final class EventModelingRenderOptions extends DiagramRenderOptions {
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

  final double swimlaneMinHeight;
  final double swimlanePadding;
  final double swimlaneGap;
  final double boxPadding;
  final double boxOverlap;
  final double boxMinWidth;
  final double boxMaxWidth;
  final double boxMinHeight;
  final double boxMaxHeight;
  final double contentStartX;
  final double textMaxWidth;
}

/// Mermaid's legacy Git Graph node-label configuration.
///
/// Mermaid 11.16 retains this object in its public configuration but its Git
/// renderer does not currently consult it.
final class GitGraphNodeLabelOptions {
  const GitGraphNodeLabelOptions({
    this.width = defaultWidth,
    this.height = defaultHeight,
    this.x = defaultX,
    this.y = defaultY,
  });

  static const defaultWidth = 75.0;
  static const defaultHeight = 100.0;
  static const defaultX = -25.0;
  static const defaultY = 0.0;

  final double width;
  final double height;
  final double x;
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

final class GitGraphRenderOptions extends DiagramRenderOptions {
  static const defaultUseMaxWidth = true;
  static const defaultTitleTopMargin = 25.0;
  static const defaultDiagramPadding = 8.0;
  static const defaultMainBranchName = 'main';
  static const defaultMainBranchOrder = 0.0;
  static const defaultShowCommitLabel = true;
  static const defaultShowBranches = true;
  static const defaultRotateCommitLabel = true;
  static const defaultParallelCommits = false;
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

  final double titleTopMargin;
  final double diagramPadding;

  /// Compatibility-only in Mermaid 11.16; see [GitGraphNodeLabelOptions].
  final GitGraphNodeLabelOptions nodeLabel;

  final String mainBranchName;
  final double mainBranchOrder;
  final bool showCommitLabel;
  final bool showBranches;
  final bool rotateCommitLabel;
  final bool parallelCommits;

  /// Compatibility-only in Mermaid 11.16's Git renderer.
  ///
  /// Git Graph draws typed paths directly and does not emit SVG arrow markers.
  final bool arrowMarkerAbsolute;

  final double commitRadius;
  final double branchSpacing;
  final double commitSpacing;
  final double branchLineWidth;
  final List<double> branchLineDashes;
  final double commitStrokeWidth;
  final double commitEdgeWidth;
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

  List<Color> get branchColors => _themeOverrides.branchColors ?? defaultBranchColors;
  List<Color> get branchLabelColors => _themeOverrides.branchLabelColors ?? defaultBranchLabelColors;
  List<Color> get highlightColors => _themeOverrides.highlightColors ?? defaultHighlightColors;
  Color get branchLineColor => _themeOverrides.branchLineColor ?? const Color(51, 51, 51);
  Color get commitLabelColor => _themeOverrides.commitLabelColor ?? const Color(0, 0, 33);
  Color get commitLabelBackground => _themeOverrides.commitLabelBackground ?? const Color(255, 255, 222, 128);
  double get commitLabelFontSize => _themeOverrides.commitLabelFontSize ?? 10;
  Color get specialCommitColor => _themeOverrides.specialCommitColor ?? const Color(236, 236, 255);
  Color get cherryPickColor => _themeOverrides.cherryPickColor ?? const Color(51, 51, 51);
  Color get tagLabelColor => _themeOverrides.tagLabelColor ?? const Color(19, 19, 0);
  Color get tagBackground => _themeOverrides.tagBackground ?? const Color(236, 236, 255);
  Color get tagBorder => _themeOverrides.tagBorder ?? const Color(199, 199, 241);
  double get tagLabelFontSize => _themeOverrides.tagLabelFontSize ?? 10;
  Color get tagHoleColor => _themeOverrides.tagHoleColor ?? const Color(51, 51, 51);
  int get themeColorLimit => _themeOverrides.themeColorLimit ?? 12;
  bool get useGradient => _themeOverrides.useGradient ?? false;
  Color get gradientStart => _themeOverrides.gradientStart ?? const Color(147, 112, 219);
  Color get gradientStop => _themeOverrides.gradientStop ?? const Color(170, 170, 51);
  Color get filterColor => _themeOverrides.filterColor ?? const Color(255, 255, 255);
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

final class TreeViewRenderOptions extends DiagramRenderOptions {
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

  static const defaultLabelColor = Color(0, 0, 0);
  static const defaultLineColor = Color(0, 0, 0);
  static const defaultIconColor = Color(84, 110, 122);
  static const defaultDescriptionColor = Color(106, 153, 85);

  /// Namespace used by Mermaid's small built-in file and folder icon pack.
  static const builtInIconPack = 'mermaid-treeview';
  static const builtInFileIcon = '$builtInIconPack:file';
  static const builtInFolderIcon = '$builtInIconPack:folder';

  /// Mermaid's 15%-opaque amber highlight background.
  static const defaultHighlightBackground = Color(255, 193, 7, 38);

  static const defaultHighlightStroke = Color(255, 193, 7);

  final double rowIndent;
  final double paddingX;
  final double paddingY;
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
  final Color highlightStroke;
  final double highlightStrokeWidth;
}

enum TreemapValueFormat { plain, grouped, currencyGrouped }

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

final class TreemapRenderOptions extends DiagramRenderOptions {
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

  final double diagramPadding;
  final bool showValues;
  final double nodeWidth;
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

  final TreemapValueFormat valueFormat;
  final double sectionOpacity;
  final double sectionStrokeOpacity;
  final double leafOpacity;
  final ({List<Color>? primary, List<Color>? peer, List<Color>? label}) _palettes;

  List<Color> get sectionColors => _palettes.primary ?? _mermaidColorScale;
  List<Color> get sectionBorderColors => _palettes.peer ?? _mermaidColorScalePeers;
  List<Color> get labelColors => _palettes.label ?? _mermaidColorScaleLabels;

  List<Color> resolveSectionColors(MermaidTheme theme) =>
      _resolveThemePalette(_palettes.primary, theme.categoricalColors, _mermaidColorScale);

  List<Color> resolveSectionBorderColors(MermaidTheme theme) =>
      _resolveThemePalette(_palettes.peer, theme.categoricalPeerColors, _mermaidColorScalePeers);

  List<Color> resolveLabelColors(MermaidTheme theme) =>
      _resolveThemePalette(_palettes.label, theme.categoricalLabelColors, _mermaidColorScaleLabels);
}

final class WardleyRenderOptions extends DiagramRenderOptions {
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

  final double width;
  final double height;
  final double padding;
  final double nodeRadius;
  final double nodeLabelOffset;
  final double axisFontSize;
  final double labelFontSize;
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
  final Color stageBoundaryColor;
  final Color anchorLabelColor;
  final Color buildStrategyStroke;

  Color get backgroundColor => _themeOverrides.backgroundColor ?? const WardleyTheme().backgroundColor;
  Color get axisColor => _themeOverrides.axisColor ?? const Color(51, 51, 51);
  Color get axisTextColor => _themeOverrides.axisTextColor ?? const WardleyTheme().axisTextColor;
  Color get gridColor => _themeOverrides.gridColor ?? const Color(211, 211, 211);
  Color get componentFill => _themeOverrides.componentFill ?? const WardleyTheme().componentFill;
  Color get componentStroke => _themeOverrides.componentStroke ?? const Color(51, 51, 51);
  Color get componentLabelColor => _themeOverrides.componentLabelColor ?? const WardleyTheme().componentLabelColor;
  Color get linkStroke => _themeOverrides.linkStroke ?? const Color(51, 51, 51);
  Color get evolutionStroke => _themeOverrides.evolutionStroke ?? const WardleyTheme().evolutionStroke;

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

final class RailroadRenderOptions extends DiagramRenderOptions {
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
  final double padding;
  final double verticalSeparation;
  final double horizontalSeparation;
  final double arcRadius;
  final bool showMarkers;
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

  double get fontSize => _themeOverrides.fontSize ?? _defaults.fontSize;
  String get fontFamily => _themeOverrides.fontFamily ?? _defaults.fontFamily;
  double get strokeWidth => _themeOverrides.strokeWidth ?? _defaults.strokeWidth;
  Color get terminalFill => _themeOverrides.terminalFill ?? _defaults.terminalFill;
  Color get terminalStroke => _themeOverrides.terminalStroke ?? _defaults.terminalStroke;
  Color get terminalTextColor => _themeOverrides.terminalTextColor ?? _defaults.terminalTextColor;
  Color get nonTerminalFill => _themeOverrides.nonTerminalFill ?? _defaults.nonTerminalFill;
  Color get nonTerminalStroke => _themeOverrides.nonTerminalStroke ?? _defaults.nonTerminalStroke;
  Color get nonTerminalTextColor => _themeOverrides.nonTerminalTextColor ?? _defaults.nonTerminalTextColor;
  Color get lineColor => _themeOverrides.lineColor ?? _defaults.lineColor;
  Color get markerFill => _themeOverrides.markerFill ?? _defaults.markerFill;
  Color get commentFill => _themeOverrides.commentFill ?? _defaults.commentFill;
  Color get commentStroke => _themeOverrides.commentStroke ?? _defaults.commentStroke;
  Color get commentTextColor => _themeOverrides.commentTextColor ?? _defaults.commentTextColor;
  Color get specialFill => _themeOverrides.specialFill ?? _defaults.specialFill;
  Color get specialStroke => _themeOverrides.specialStroke ?? _defaults.specialStroke;
  Color get ruleNameColor => _themeOverrides.ruleNameColor ?? _defaults.ruleNameColor;

  /// Resolves explicit railroad styling over Mermaid's common theme variables.
  RailroadTheme resolveTheme(MermaidTheme theme) => RailroadTheme(
    fontSize: _themeOverrides.fontSize ?? theme.fontSize,
    fontFamily: _themeOverrides.fontFamily ?? theme.resolveFontFamily(fallback: _defaults.fontFamily),
    strokeWidth: _themeOverrides.strokeWidth ?? theme._railroadCommonOverrides.strokeWidth ?? _defaults.strokeWidth,
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
        _themeOverrides.nonTerminalStroke ?? theme._railroadCommonOverrides.nodeBorder ?? _defaults.nonTerminalStroke,
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

final class PacketRenderOptions extends DiagramRenderOptions {
  /// Mermaid's packet renderer uses black title text independently of the global theme.
  static const defaultTitleTextColor = Color(0, 0, 0);

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

  final double rowHeight;
  final double bitWidth;
  final int bitsPerRow;
  final bool showBits;
  final double paddingX;
  final double paddingY;
  final Color titleText;
}

enum PieLegendPosition { top, bottom, left, right, center }

final class PieRenderOptions extends DiagramRenderOptions {
  /// Mermaid's default light-theme color for pie chart titles.
  static const defaultTitleTextColor = Color(0, 0, 0);

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

  final double size;
  final double margin;
  final double? radius;
  final double textPosition;
  final double donutHole;
  final PieLegendPosition legendPosition;
  final String? highlightSlice;
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

  double get sectionOpacity => _themeOverrides.opacity ?? const PieTheme().opacity;
  Color get sectionStroke => _themeOverrides.sectionStroke ?? const PieTheme().strokeColor;
  Color get outerStroke => _themeOverrides.outerStroke ?? const PieTheme().outerStrokeColor;
  Color get legendText => _themeOverrides.legendText ?? const PieTheme().legendTextColor;
  Color get titleText => _themeOverrides.titleText ?? const PieTheme().titleTextColor;
  List<Color> get sectionColors => _themeOverrides.colors ?? _mermaidPieColors;

  List<Color> resolveSectionColors(MermaidTheme theme) =>
      _resolveThemePalette(_themeOverrides.colors, theme.pieColors, _mermaidPieColors);

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

final class RadarRenderOptions extends DiagramRenderOptions {
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

  final double width;
  final double height;
  final double marginTop;
  final double marginRight;
  final double marginBottom;
  final double marginLeft;
  final double? radius;
  final double axisScaleFactor;
  final double axisLabelFactor;
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

  Color get graticuleColor => _themeOverrides.graticuleColor ?? const RadarTheme().graticuleColor;
  double get graticuleOpacity => _themeOverrides.graticuleOpacity ?? const RadarTheme().graticuleOpacity;
  Color get axisColor => _themeOverrides.axisColor ?? const RadarTheme().axisColor;
  double get seriesOpacity => _themeOverrides.seriesOpacity ?? const RadarTheme().curveOpacity;
  List<Color> get seriesColors => _themeOverrides.colors ?? _mermaidColorScale;

  List<Color> resolveSeriesColors(MermaidTheme theme) =>
      _resolveThemePalette(_themeOverrides.colors, theme.categoricalColors, _mermaidColorScale);

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

final class RenderOptions {
  const RenderOptions({
    this.theme = const MermaidTheme(),
    this.padding = 20,
    this.architecture = const ArchitectureRenderOptions(),
    this.cynefin = const CynefinRenderOptions(),
    this.eventModeling = const EventModelingRenderOptions(),
    this.gitGraph = const GitGraphRenderOptions(),
    this.info = const InfoRenderOptions(),
    this.packet = const PacketRenderOptions(),
    this.pie = const PieRenderOptions(),
    this.radar = const RadarRenderOptions(),
    this.railroad = const RailroadRenderOptions(),
    this.treeView = const TreeViewRenderOptions(),
    this.treemap = const TreemapRenderOptions(),
    this.wardley = const WardleyRenderOptions(),
    this.diagram = const <Type, DiagramRenderOptions>{},
  });

  final MermaidTheme theme;
  final double padding;
  final ArchitectureRenderOptions architecture;
  final CynefinRenderOptions cynefin;
  final EventModelingRenderOptions eventModeling;
  final GitGraphRenderOptions gitGraph;
  final InfoRenderOptions info;
  final PacketRenderOptions packet;
  final PieRenderOptions pie;
  final RadarRenderOptions radar;
  final RailroadRenderOptions railroad;
  final TreeViewRenderOptions treeView;
  final TreemapRenderOptions treemap;
  final WardleyRenderOptions wardley;

  /// Additional typed options for renderer families added after this API.
  final Map<Type, DiagramRenderOptions> diagram;

  T optionsFor<T extends DiagramRenderOptions>(T fallback) {
    final override = diagram[fallback.runtimeType];
    if (override != null) return override as T;
    return switch (fallback) {
          ArchitectureRenderOptions() => architecture,
          CynefinRenderOptions() => cynefin,
          EventModelingRenderOptions() => eventModeling,
          GitGraphRenderOptions() => gitGraph,
          InfoRenderOptions() => info,
          PacketRenderOptions() => packet,
          PieRenderOptions() => pie,
          RadarRenderOptions() => radar,
          RailroadRenderOptions() => railroad,
          TreeViewRenderOptions() => treeView,
          TreemapRenderOptions() => treemap,
          WardleyRenderOptions() => wardley,
        }
        as T;
  }
}

enum SvgWidthMode {
  /// Use the backend-neutral sizing policy carried by [DiagramScene].
  scene,

  /// Emit the viewport's intrinsic numeric width and height.
  fixed,

  /// Fill the available width up to the viewport's intrinsic width.
  fitContainer,
}

final class SvgRenderOptions {
  const SvgRenderOptions({
    this.pretty = false,
    this.includeXmlDeclaration = false,
    this.rootId,
    this.widthMode = SvgWidthMode.scene,
  });
  final bool pretty;
  final bool includeXmlDeclaration;
  final String? rootId;
  final SvgWidthMode widthMode;
}
