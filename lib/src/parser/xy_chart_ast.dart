part of 'ast.dart';

/// Direction in which an XY chart's independent axis runs.
enum XyChartOrientation { vertical, horizontal }

/// Plot primitive supported by Mermaid XY charts.
enum XyChartPlotType { bar, line }

/// A typed XY chart.
final class XyChartAst extends DiagramAst {
  const XyChartAst({
    this.orientation = XyChartOrientation.vertical,
    required this.xAxis,
    required this.yAxis,
    this.plots = const [],
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.xyChart;

  final XyChartOrientation orientation;
  final XyChartAxisAst xAxis;
  final XyChartLinearAxisAst yAxis;
  final List<XyChartPlotAst> plots;

  @override
  List<Object?> get diagramFields => [orientation, xAxis, yAxis, plots];
}

sealed class XyChartAxisAst with _AstValueEquality {
  const XyChartAxisAst({this.title = ''});
  final String title;
}

final class XyChartBandAxisAst extends XyChartAxisAst {
  const XyChartBandAxisAst({super.title, this.categories = const []});
  final List<String> categories;
  @override
  List<Object?> get equalityFields => [title, categories];
}

final class XyChartLinearAxisAst extends XyChartAxisAst {
  const XyChartLinearAxisAst({super.title, required this.min, required this.max});
  final double min;
  final double max;
  @override
  List<Object?> get equalityFields => [title, min, max];
}

final class XyChartPlotAst with _AstValueEquality {
  const XyChartPlotAst({required this.type, this.title = '', this.points = const [], this.pointLabels = const []});
  final XyChartPlotType type;
  final String title;
  final List<double> points;
  final List<String> pointLabels;
  @override
  List<Object?> get equalityFields => [type, title, points, pointLabels];
}
