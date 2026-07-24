part of 'ast.dart';

/// Mermaid quadrant positions in reading order.
enum Quadrant { topRight, topLeft, bottomLeft, bottomRight }

/// The two labels attached to one quadrant-chart axis.
final class QuadrantAxisAst with _AstValueEquality {
  const QuadrantAxisAst({required this.start, this.end});

  /// The left x-axis label or bottom y-axis label.
  final String start;

  /// The right x-axis label or top y-axis label.
  final String? end;

  @override
  List<Object?> get equalityFields => [start, end];
}

/// Styles supported by Mermaid quadrant points and `classDef` declarations.
final class QuadrantPointStyleAst with _AstValueEquality {
  const QuadrantPointStyleAst({this.radius, this.color, this.strokeColor, this.strokeWidth});

  final double? radius;
  final String? color;
  final String? strokeColor;
  final double? strokeWidth;

  /// Returns class styles with directly declared point styles taking priority.
  QuadrantPointStyleAst overlay(QuadrantPointStyleAst direct) => QuadrantPointStyleAst(
    radius: direct.radius ?? radius,
    color: direct.color ?? color,
    strokeColor: direct.strokeColor ?? strokeColor,
    strokeWidth: direct.strokeWidth ?? strokeWidth,
  );

  @override
  List<Object?> get equalityFields => [radius, color, strokeColor, strokeWidth];
}

/// A normalized point in a quadrant chart.
final class QuadrantPointAst with _AstValueEquality {
  const QuadrantPointAst({
    required this.label,
    required this.x,
    required this.y,
    this.className,
    this.style = const QuadrantPointStyleAst(),
  });

  final String label;
  final double x;
  final double y;
  final String? className;
  final QuadrantPointStyleAst style;

  @override
  List<Object?> get equalityFields => [label, x, y, className, style];
}

/// A typed Mermaid quadrant chart.
final class QuadrantChartAst extends DiagramAst {
  const QuadrantChartAst({
    this.xAxis,
    this.yAxis,
    this.quadrants = const {},
    this.points = const [],
    this.classDefinitions = const {},
    super.title,
    super.accessibilityTitle,
    super.accessibilityDescription,
  });

  @override
  DiagramType get type => DiagramType.quadrantChart;

  final QuadrantAxisAst? xAxis;
  final QuadrantAxisAst? yAxis;
  final Map<Quadrant, String> quadrants;
  final List<QuadrantPointAst> points;
  final Map<String, QuadrantPointStyleAst> classDefinitions;

  @override
  List<Object?> get diagramFields => [xAxis, yAxis, quadrants, points, classDefinitions];
}
