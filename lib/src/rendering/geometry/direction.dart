import 'dart:math' as math;

import '../scene.dart';

/// A unit direction between two scene points, with its perpendicular.
///
/// Edge markers, arrowheads, and cardinality labels are all placed by stepping
/// a fixed amount along an edge and a fixed amount across it, so they share this
/// one measurement instead of recomputing the vector per diagram family.
final class Direction {
  const Direction._(this.x, this.y, this.distance);

  /// Measures the direction from [from] toward [to].
  ///
  /// Coincident points report the positive x axis so markers stay deterministic
  /// for zero-length edges, matching Mermaid.
  factory Direction.between(Point from, Point to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    return distance == 0 ? const Direction._(1, 0, 0) : Direction._(dx / distance, dy / distance, distance);
  }

  /// Horizontal component of the unit direction.
  final double x;

  /// Vertical component of the unit direction.
  final double y;

  /// Length of the measured segment, or `0` for coincident points.
  final double distance;

  /// Horizontal component of the direction rotated a quarter turn clockwise.
  double get perpendicularX => -y;

  /// Vertical component of the direction rotated a quarter turn clockwise.
  double get perpendicularY => x;

  /// The point [along] units from [origin], shifted [across] units sideways.
  ///
  /// Positive [across] moves along the perpendicular; negative moves opposite.
  Point from(Point origin, double along, [double across = 0]) =>
      Point(origin.x + x * along + perpendicularX * across, origin.y + y * along + perpendicularY * across);
}

/// The point [distance] units from [start] toward [end].
///
/// Returns [start] unchanged when the two points coincide, since no direction
/// can be derived from a zero-length segment.
Point pointToward(Point start, Point end, double distance) {
  final direction = Direction.between(start, end);
  return direction.distance == 0 ? start : direction.from(start, distance);
}
