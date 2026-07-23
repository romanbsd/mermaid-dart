import '../scene.dart';

/// Builds the upper route that skips an optional railroad item.
///
/// Mermaid uses the same route for an optional node and for a repetition whose
/// minimum count is zero.
List<PathCommand> railroadBypassCommands({required double width, required double baselineY, required double radius}) =>
    [
      MoveTo(Point(0, baselineY)),
      ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(radius, baselineY - radius)),
      LineTo(Point(radius, radius)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2, 0)),
      LineTo(Point(width - radius * 2, 0)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(width - radius, radius)),
      LineTo(Point(width - radius, baselineY - radius)),
      ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(width, baselineY)),
    ];

/// Builds the left and right routes connecting one railroad choice item.
({List<PathCommand> left, List<PathCommand> right}) railroadChoiceBranchCommands({
  required double width,
  required double itemX,
  required double itemWidth,
  required double itemCenterY,
  required double centerY,
  required double radius,
}) {
  final left = <PathCommand>[MoveTo(Point(0, centerY))];
  final rightStart = itemX + itemWidth;
  final right = <PathCommand>[MoveTo(Point(rightStart, itemCenterY))];

  if (itemCenterY == centerY) {
    left.add(LineTo(Point(itemX, itemCenterY)));
    right.add(LineTo(Point(width, centerY)));
    return (left: left, right: right);
  }

  final below = itemCenterY > centerY;
  left
    ..add(
      ArcTo(
        radiusX: radius,
        radiusY: radius,
        clockwise: below,
        end: Point(radius, centerY + (below ? radius : -radius)),
      ),
    )
    ..add(LineTo(Point(radius, itemCenterY - (below ? radius : -radius))))
    ..add(ArcTo(radiusX: radius, radiusY: radius, clockwise: !below, end: Point(radius * 2, itemCenterY)))
    ..add(LineTo(Point(itemX, itemCenterY)));
  right
    ..add(LineTo(Point(width - radius * 2, itemCenterY)))
    ..add(
      ArcTo(
        radiusX: radius,
        radiusY: radius,
        clockwise: !below,
        end: Point(width - radius, itemCenterY + (below ? -radius : radius)),
      ),
    )
    ..add(LineTo(Point(width - radius, centerY + (below ? radius : -radius))))
    ..add(ArcTo(radiusX: radius, radiusY: radius, clockwise: below, end: Point(width, centerY)));
  return (left: left, right: right);
}

/// Builds the lower route that loops a railroad repetition back to its item.
List<PathCommand> railroadRepetitionLoopCommands({
  required double itemWidth,
  required double baselineY,
  required double loopY,
  required double radius,
}) => [
  MoveTo(Point(radius * 2 + itemWidth, baselineY)),
  ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 3 + itemWidth, baselineY + radius)),
  LineTo(Point(radius * 3 + itemWidth, loopY)),
  ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2 + itemWidth, loopY + radius)),
  LineTo(Point(radius * 2, loopY + radius)),
  ArcTo(radiusX: radius, radiusY: radius, end: Point(radius, loopY)),
  LineTo(Point(radius, baselineY + radius)),
  ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2, baselineY)),
];
