import 'dart:math' as math;

import '../scene.dart';

/// Radians in one complete revolution.
const fullTurnRadians = math.pi * 2;

/// Radians in one half revolution.
const halfTurnRadians = math.pi;

/// The twelve-o'clock angle in SVG's clockwise, downward-positive coordinates.
const topAngleRadians = -math.pi / 2;

/// Returns the angle at [index] among [count] evenly spaced positions.
double evenlySpacedAngle(int index, int count, {double startAngle = topAngleRadians}) {
  if (count <= 0) {
    throw ArgumentError.value(count, 'count', 'must be positive');
  }
  return startAngle + fullTurnRadians * index / count;
}

/// Projects a polar coordinate around [center] into scene coordinates.
Point polarPoint(Point center, double radius, double angle) =>
    Point(center.x + radius * math.cos(angle), center.y + radius * math.sin(angle));
