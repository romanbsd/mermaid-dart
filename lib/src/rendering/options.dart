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

final class InfoRenderOptions extends DiagramRenderOptions {
  const InfoRenderOptions({this.version = '1.0.0'});

  final String version;
}

final class TreeViewRenderOptions extends DiagramRenderOptions {
  const TreeViewRenderOptions({this.rowIndent = 10, this.paddingX = 5, this.paddingY = 5, this.lineThickness = 1});

  final double rowIndent;
  final double paddingX;
  final double paddingY;
  final double lineThickness;
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
    this.info = const InfoRenderOptions(),
    this.packet = const PacketRenderOptions(),
    this.pie = const PieRenderOptions(),
    this.radar = const RadarRenderOptions(),
    this.railroad = const RailroadRenderOptions(),
    this.treeView = const TreeViewRenderOptions(),
    this.diagram = const <Type, DiagramRenderOptions>{},
  });

  final MermaidTheme theme;
  final double padding;
  final InfoRenderOptions info;
  final PacketRenderOptions packet;
  final PieRenderOptions pie;
  final RadarRenderOptions radar;
  final RailroadRenderOptions railroad;
  final TreeViewRenderOptions treeView;

  /// Additional typed options for renderer families added after this API.
  final Map<Type, DiagramRenderOptions> diagram;

  T optionsFor<T extends DiagramRenderOptions>(T fallback) {
    final override = diagram[fallback.runtimeType];
    if (override != null) return override as T;
    return switch (fallback) {
          InfoRenderOptions() => info,
          PacketRenderOptions() => packet,
          PieRenderOptions() => pie,
          RadarRenderOptions() => radar,
          RailroadRenderOptions() => railroad,
          TreeViewRenderOptions() => treeView,
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
