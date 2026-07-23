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

final class ArchitectureRenderOptions extends DiagramRenderOptions {
  const ArchitectureRenderOptions({
    this.padding = 40,
    this.iconSize = 80,
    this.fontSize = 16,
    this.randomize = false,
    this.nodeSeparation = 75,
    this.idealEdgeLengthMultiplier = 1.5,
    this.edgeElasticity = 0.45,
    this.numIter = 2500,
    this.seed = 1,
    this.groupBorderColor = const Color(199, 199, 241),
    this.edgeColor = const Color(51, 51, 51),
  });

  final double padding;
  final double iconSize;
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

  final Color groupBorderColor;
  final Color edgeColor;
}

final class CynefinRenderOptions extends DiagramRenderOptions {
  const CynefinRenderOptions({
    this.width = 800,
    this.height = 600,
    this.padding = 40,
    this.showDomainDescriptions = true,
    this.boundaryAmplitude = 8,
    this.seed = 0,
    this.complexColor = const Color(232, 245, 233, 102),
    this.complicatedColor = const Color(227, 242, 253, 102),
    this.chaoticColor = const Color(251, 233, 231, 102),
    this.clearColor = const Color(255, 248, 225, 102),
    this.confusionColor = const Color(243, 229, 245, 128),
    this.cliffColor = const Color(139, 0, 0),
    this.domainLabelColor = const Color(19, 19, 0),
    this.textColor = const Color(51, 51, 51),
    this.strokeColor = const Color(51, 51, 51),
    this.boundaryDashes = const [6, 3],
    this.confusionDashes = const [4, 2],
  });

  final double width;
  final double height;
  final double padding;
  final bool showDomainDescriptions;
  final double boundaryAmplitude;
  final int seed;
  final Color complexColor;
  final Color complicatedColor;
  final Color chaoticColor;
  final Color clearColor;
  final Color confusionColor;
  final Color cliffColor;
  final Color domainLabelColor;
  final Color textColor;
  final Color strokeColor;
  final List<double> boundaryDashes;
  final List<double> confusionDashes;
}

final class InfoRenderOptions extends DiagramRenderOptions {
  const InfoRenderOptions({this.version = '11.16.0'});

  final String version;
}

final class EventModelingRenderOptions extends DiagramRenderOptions {
  const EventModelingRenderOptions({
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

final class GitGraphRenderOptions extends DiagramRenderOptions {
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
    this.titleTopMargin = 25,
    this.diagramPadding = 8,
    this.mainBranchName = 'main',
    this.mainBranchOrder = 0,
    this.showCommitLabel = true,
    this.showBranches = true,
    this.rotateCommitLabel = true,
    this.parallelCommits = false,
    this.commitRadius = 10,
    this.branchSpacing = 50,
    this.commitSpacing = 50,
    this.branchColors = defaultBranchColors,
    this.branchLabelColors = defaultBranchLabelColors,
    this.highlightColors = defaultHighlightColors,
    this.branchLineColor = const Color(51, 51, 51),
    this.branchLineWidth = 1,
    this.branchLineDashes = const [2],
    this.commitStrokeWidth = 1,
    this.commitEdgeWidth = 8,
    this.commitEdgeCap = StrokeCap.round,
    this.commitLabelColor = const Color(0, 0, 33),
    this.commitLabelBackground = const Color(255, 255, 222, 128),
    this.specialCommitColor = const Color(236, 236, 255),
    this.cherryPickColor = const Color(51, 51, 51),
    this.tagLabelColor = const Color(19, 19, 0),
    this.tagBackground = const Color(236, 236, 255),
    this.tagBorder = const Color(199, 199, 241),
    this.tagHoleColor = const Color(51, 51, 51),
  });

  final double titleTopMargin;
  final double diagramPadding;
  final String mainBranchName;
  final double mainBranchOrder;
  final bool showCommitLabel;
  final bool showBranches;
  final bool rotateCommitLabel;
  final bool parallelCommits;
  final double commitRadius;
  final double branchSpacing;
  final double commitSpacing;
  final List<Color> branchColors;
  final List<Color> branchLabelColors;
  final List<Color> highlightColors;
  final Color branchLineColor;
  final double branchLineWidth;
  final List<double> branchLineDashes;
  final double commitStrokeWidth;
  final double commitEdgeWidth;
  final StrokeCap commitEdgeCap;
  final Color commitLabelColor;
  final Color commitLabelBackground;
  final Color specialCommitColor;
  final Color cherryPickColor;
  final Color tagLabelColor;
  final Color tagBackground;
  final Color tagBorder;
  final Color tagHoleColor;
}

final class TreeViewRenderOptions extends DiagramRenderOptions {
  const TreeViewRenderOptions({
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

final class TreemapRenderOptions extends DiagramRenderOptions {
  const TreemapRenderOptions({
    this.width = 1000,
    this.height = 400,
    this.innerPadding = 10,
    this.sectionPadding = 10,
    this.sectionHeaderHeight = 25,
    this.diagramPadding = 8,
    this.showValues = true,
    this.valueFormat = TreemapValueFormat.grouped,
    this.sectionOpacity = .6,
    this.sectionStrokeOpacity = .4,
    this.leafOpacity = .3,
    this.sectionColors = _mermaidColorScale,
    this.sectionBorderColors = _mermaidColorScalePeers,
    this.labelColors = _mermaidColorScaleLabels,
  });

  final double width;
  final double height;
  final double innerPadding;
  final double sectionPadding;
  final double sectionHeaderHeight;
  final double diagramPadding;
  final bool showValues;
  final TreemapValueFormat valueFormat;
  final double sectionOpacity;
  final double sectionStrokeOpacity;
  final double leafOpacity;
  final List<Color> sectionColors;
  final List<Color> sectionBorderColors;
  final List<Color> labelColors;
}

final class WardleyRenderOptions extends DiagramRenderOptions {
  const WardleyRenderOptions({
    this.width = 900,
    this.height = 600,
    this.padding = 48,
    this.nodeRadius = 6,
    this.nodeLabelOffset = 8,
    this.axisFontSize = 12,
    this.labelFontSize = 10,
    this.showGrid = false,
    this.backgroundColor = const Color(255, 255, 255),
    this.axisColor = const Color(51, 51, 51),
    this.axisTextColor = const Color(19, 19, 0),
    this.stageBoundaryColor = const Color(0, 0, 0, 204),
    this.gridColor = const Color(100, 100, 100, 51),
    this.componentFill = const Color(255, 255, 255),
    this.componentStroke = const Color(51, 51, 51),
    this.componentLabelColor = const Color(19, 19, 0),
    this.anchorLabelColor = const Color(0, 0, 0),
    this.buildStrategyStroke = const Color(0, 0, 0),
    this.linkStroke = const Color(51, 51, 51),
    this.evolutionStroke = const Color(220, 53, 69),
  });

  final double width;
  final double height;
  final double padding;
  final double nodeRadius;
  final double nodeLabelOffset;
  final double axisFontSize;
  final double labelFontSize;
  final bool showGrid;
  final Color backgroundColor;
  final Color axisColor;
  final Color axisTextColor;
  final Color stageBoundaryColor;
  final Color gridColor;
  final Color componentFill;
  final Color componentStroke;
  final Color componentLabelColor;
  final Color anchorLabelColor;
  final Color buildStrategyStroke;
  final Color linkStroke;
  final Color evolutionStroke;
}

final class RailroadRenderOptions extends DiagramRenderOptions {
  const RailroadRenderOptions({
    this.compactMode = false,
    this.padding = 10,
    this.verticalSeparation = 8,
    this.horizontalSeparation = 10,
    this.arcRadius = 10,
    this.fontSize = 16,
    this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif',
    this.strokeWidth = 2,
    this.showMarkers = true,
    this.markerRadius = 5,
    this.terminalFill = const Color(255, 255, 222),
    this.terminalBorder = const Color(238, 238, 188),
    this.terminalText = const Color(0, 0, 33),
    this.nonTerminalFill = const Color(236, 236, 255),
    this.nonTerminalBorder = const Color(199, 199, 241),
    this.nonTerminalText = const Color(19, 19, 0),
  });

  final bool compactMode;
  final double padding;
  final double verticalSeparation;
  final double horizontalSeparation;
  final double arcRadius;
  final double fontSize;
  final String fontFamily;
  final double strokeWidth;
  final bool showMarkers;
  final double markerRadius;
  final Color terminalFill;
  final Color terminalBorder;
  final Color terminalText;
  final Color nonTerminalFill;
  final Color nonTerminalBorder;
  final Color nonTerminalText;
}

final class PacketRenderOptions extends DiagramRenderOptions {
  /// Mermaid's packet renderer uses black title text independently of the global theme.
  static const defaultTitleTextColor = Color(0, 0, 0);

  const PacketRenderOptions({
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
    this.size = 450,
    this.margin = 40,
    this.radius,
    this.textPosition = .75,
    this.donutHole = 0,
    this.legendPosition = PieLegendPosition.right,
    this.highlightSlice,
    this.showLegend = true,
    this.sectionOpacity = .7,
    this.sectionStroke = const Color(0, 0, 0),
    this.outerStroke = const Color(0, 0, 0),
    this.legendText = const Color(0, 0, 0),
    this.titleText = defaultTitleTextColor,
    this.sectionColors = const [
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
    ],
  });

  final double size;
  final double margin;
  final double? radius;
  final double textPosition;
  final double donutHole;
  final PieLegendPosition legendPosition;
  final String? highlightSlice;
  final bool showLegend;
  final double sectionOpacity;
  final Color sectionStroke;
  final Color outerStroke;
  final Color legendText;
  final Color titleText;
  final List<Color> sectionColors;
}

final class RadarRenderOptions extends DiagramRenderOptions {
  const RadarRenderOptions({
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
    this.graticuleColor = const Color(222, 222, 222),
    this.graticuleOpacity = .3,
    this.axisColor = const Color(51, 51, 51),
    this.seriesOpacity = .5,
    this.seriesColors = _mermaidColorScale,
  });

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
  final Color graticuleColor;
  final double graticuleOpacity;
  final Color axisColor;
  final double seriesOpacity;
  final List<Color> seriesColors;
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

final class SvgRenderOptions {
  const SvgRenderOptions({this.pretty = false, this.includeXmlDeclaration = false, this.rootId});
  final bool pretty;
  final bool includeXmlDeclaration;
  final String? rootId;
}
