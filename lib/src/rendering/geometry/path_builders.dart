import '../scene.dart';
import 'polar.dart';

/// Numeric tolerance used to recognize a complete revolution.
///
/// SVG arcs with coincident endpoints are invisible, so full circles must be
/// emitted as two half arcs.
const defaultArcFullCircleTolerance = 1e-9;

/// Builds a closed pie wedge or annular sector from typed path commands.
List<PathCommand> annularSectorPath({
  required Point center,
  required double outerRadius,
  required double innerRadius,
  required double startAngle,
  required double endAngle,
  double fullCircleTolerance = defaultArcFullCircleTolerance,
}) {
  final sweep = endAngle - startAngle;
  final isFullCircle = sweep >= fullTurnRadians - fullCircleTolerance;
  final commands = <PathCommand>[MoveTo(polarPoint(center, outerRadius, startAngle))];
  if (isFullCircle) {
    _addHalfCircleArcs(
      commands,
      center: center,
      radius: outerRadius,
      middleAngle: startAngle + halfTurnRadians,
      endAngle: endAngle,
      clockwise: true,
    );
  } else {
    commands.add(
      ArcTo(
        radiusX: outerRadius,
        radiusY: outerRadius,
        largeArc: sweep > halfTurnRadians,
        end: polarPoint(center, outerRadius, endAngle),
      ),
    );
  }
  if (innerRadius == 0) {
    commands.add(LineTo(center));
  } else {
    commands.add(LineTo(polarPoint(center, innerRadius, endAngle)));
    if (isFullCircle) {
      _addHalfCircleArcs(
        commands,
        center: center,
        radius: innerRadius,
        middleAngle: startAngle + halfTurnRadians,
        endAngle: startAngle,
        clockwise: false,
      );
    } else {
      commands.add(
        ArcTo(
          radiusX: innerRadius,
          radiusY: innerRadius,
          largeArc: sweep > halfTurnRadians,
          clockwise: false,
          end: polarPoint(center, innerRadius, startAngle),
        ),
      );
    }
  }
  commands.add(const ClosePath());
  return commands;
}

void _addHalfCircleArcs(
  List<PathCommand> commands, {
  required Point center,
  required double radius,
  required double middleAngle,
  required double endAngle,
  required bool clockwise,
}) {
  commands
    ..add(ArcTo(radiusX: radius, radiusY: radius, clockwise: clockwise, end: polarPoint(center, radius, middleAngle)))
    ..add(ArcTo(radiusX: radius, radiusY: radius, clockwise: clockwise, end: polarPoint(center, radius, endAngle)));
}

/// Interpolates [points] into Mermaid's closed cubic curve representation.
List<PathCommand> closedCubicSplinePath(List<Point> points, {required double tension}) {
  if (points.isEmpty) return const [];
  final count = points.length;
  final commands = <PathCommand>[MoveTo(points.first)];
  for (var i = 0; i < count; i++) {
    final previous = points[(i - 1 + count) % count];
    final current = points[i];
    final next = points[(i + 1) % count];
    final afterNext = points[(i + 2) % count];
    commands.add(
      CubicTo(
        Point(current.x + (next.x - previous.x) * tension, current.y + (next.y - previous.y) * tension),
        Point(next.x - (afterNext.x - current.x) * tension, next.y - (afterNext.y - current.y) * tension),
        next,
      ),
    );
  }
  commands.add(const ClosePath());
  return commands;
}
