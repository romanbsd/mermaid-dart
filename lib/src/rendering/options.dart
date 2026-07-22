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
}

final class InfoRenderOptions extends DiagramRenderOptions {
  const InfoRenderOptions({this.version = '1.0.0'});

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
    this.branchColors = const [
      Color(87, 103, 198),
      Color(241, 156, 74),
      Color(76, 175, 130),
      Color(218, 91, 91),
      Color(151, 104, 190),
      Color(72, 169, 197),
      Color(222, 190, 73),
      Color(100, 100, 100),
    ],
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
}

final class TreeViewRenderOptions extends DiagramRenderOptions {
  const TreeViewRenderOptions({this.rowIndent = 10, this.paddingX = 5, this.paddingY = 5, this.lineThickness = 1});

  final double rowIndent;
  final double paddingX;
  final double paddingY;
  final double lineThickness;
}

enum TreemapValueFormat { plain, grouped, currencyGrouped }

final class TreemapRenderOptions extends DiagramRenderOptions {
  const TreemapRenderOptions({
    this.width = 960,
    this.height = 500,
    this.innerPadding = 10,
    this.sectionPadding = 10,
    this.sectionHeaderHeight = 25,
    this.showValues = true,
    this.valueFormat = TreemapValueFormat.grouped,
  });

  final double width;
  final double height;
  final double innerPadding;
  final double sectionPadding;
  final double sectionHeaderHeight;
  final bool showValues;
  final TreemapValueFormat valueFormat;
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
    this.axisColor = const Color(0, 0, 0),
    this.axisTextColor = const Color(34, 34, 34),
    this.gridColor = const Color(100, 100, 100, 51),
    this.componentFill = const Color(255, 255, 255),
    this.componentStroke = const Color(0, 0, 0),
    this.componentLabelColor = const Color(34, 34, 34),
    this.linkStroke = const Color(0, 0, 0),
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
  final Color gridColor;
  final Color componentFill;
  final Color componentStroke;
  final Color componentLabelColor;
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
    this.fontSize = 14,
    this.fontFamily = 'monospace',
    this.strokeWidth = 2,
    this.showMarkers = true,
    this.markerRadius = 5,
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
}

final class PacketRenderOptions extends DiagramRenderOptions {
  const PacketRenderOptions({
    this.rowHeight = 32,
    this.bitWidth = 32,
    this.bitsPerRow = 32,
    this.showBits = true,
    this.paddingX = 5,
    this.paddingY = 5,
  });

  final double rowHeight;
  final double bitWidth;
  final int bitsPerRow;
  final bool showBits;
  final double paddingX;
  final double paddingY;
}

enum PieLegendPosition { top, bottom, left, right, center }

final class PieRenderOptions extends DiagramRenderOptions {
  const PieRenderOptions({
    this.size = 450,
    this.margin = 40,
    this.radius,
    this.textPosition = .75,
    this.donutHole = 0,
    this.legendPosition = PieLegendPosition.right,
    this.highlightSlice,
    this.showLegend = true,
  });

  final double size;
  final double margin;
  final double? radius;
  final double textPosition;
  final double donutHole;
  final PieLegendPosition legendPosition;
  final String? highlightSlice;
  final bool showLegend;
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
}

final class RenderOptions {
  const RenderOptions({
    this.theme = const MermaidTheme(),
    this.padding = 20,
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
