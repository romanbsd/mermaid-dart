import '../scene.dart';

/// A weighted item consumed by the deterministic squarify layout.
final class TreemapItem<T> {
  const TreemapItem(this.value, this.data);

  final double value;
  final T data;
}

/// Positioned output from [squarifyTreemap].
final class TreemapTile<T> {
  const TreemapTile(this.data, this.bounds);

  final T data;
  final Bounds bounds;
}

/// Pure-Dart port of D3's golden-ratio squarify tiler.
List<TreemapTile<T>> squarifyTreemap<T>(
  List<TreemapItem<T>> source,
  Bounds bounds, {
  double innerPadding = 0,
  bool round = true,
}) {
  if (source.isEmpty) return const [];
  final positiveTotal = source.fold<double>(0, (sum, item) => sum + item.value.clamp(0, double.infinity));
  final items = positiveTotal == 0
      ? [for (final item in source) TreemapItem(1.0, item.data)]
      : [for (final item in source) TreemapItem(item.value.clamp(0, double.infinity), item.data)];
  final result = <TreemapTile<T>>[];
  var x0 = bounds.left - innerPadding / 2;
  var y0 = bounds.top - innerPadding / 2;
  var x1 = bounds.right + innerPadding / 2;
  var y1 = bounds.bottom + innerPadding / 2;
  var remaining = items.fold<double>(0, (sum, item) => sum + item.value);
  var start = 0;
  const ratio = 1.618033988749895;

  while (start < items.length) {
    final dx = x1 - x0;
    final dy = y1 - y0;
    var end = start + 1;
    var sum = items[start].value;
    var minValue = sum;
    var maxValue = sum;
    final alpha = (dy / dx).abs().clamp(0, double.infinity).compareTo((dx / dy).abs()) > 0
        ? (dy / dx).abs() / (remaining * ratio)
        : (dx / dy).abs() / (remaining * ratio);
    var beta = sum * sum * alpha;
    var minimumRatio = _worstRatio(minValue, maxValue, beta);

    while (end < items.length) {
      final value = items[end].value;
      final nextSum = sum + value;
      final nextMin = value < minValue ? value : minValue;
      final nextMax = value > maxValue ? value : maxValue;
      final nextBeta = nextSum * nextSum * alpha;
      final nextRatio = _worstRatio(nextMin, nextMax, nextBeta);
      if (nextRatio > minimumRatio) break;
      sum = nextSum;
      minValue = nextMin;
      maxValue = nextMax;
      beta = nextBeta;
      minimumRatio = nextRatio;
      end++;
    }

    if (dx < dy) {
      final rowBottom = remaining == 0 ? y1 : y0 + dy * sum / remaining;
      _dice(items, start, end, sum, x0, y0, x1, rowBottom, innerPadding, round, result);
      y0 = rowBottom;
    } else {
      final rowRight = remaining == 0 ? x1 : x0 + dx * sum / remaining;
      _slice(items, start, end, sum, x0, y0, rowRight, y1, innerPadding, round, result);
      x0 = rowRight;
    }
    remaining -= sum;
    start = end;
  }
  return result;
}

double _worstRatio(double minimum, double maximum, double beta) {
  if (minimum <= 0 || beta <= 0) return double.infinity;
  final first = maximum / beta;
  final second = beta / minimum;
  return first > second ? first : second;
}

void _dice<T>(
  List<TreemapItem<T>> items,
  int start,
  int end,
  double total,
  double x0,
  double y0,
  double x1,
  double y1,
  double padding,
  bool round,
  List<TreemapTile<T>> output,
) {
  var x = x0;
  for (var index = start; index < end; index++) {
    final item = items[index];
    final next = index == end - 1 ? x1 : x + (x1 - x0) * item.value / total;
    output.add(TreemapTile(item.data, _tileBounds(x, y0, next, y1, padding, round)));
    x = next;
  }
}

void _slice<T>(
  List<TreemapItem<T>> items,
  int start,
  int end,
  double total,
  double x0,
  double y0,
  double x1,
  double y1,
  double padding,
  bool round,
  List<TreemapTile<T>> output,
) {
  var y = y0;
  for (var index = start; index < end; index++) {
    final item = items[index];
    final next = index == end - 1 ? y1 : y + (y1 - y0) * item.value / total;
    output.add(TreemapTile(item.data, _tileBounds(x0, y, x1, next, padding, round)));
    y = next;
  }
}

Bounds _tileBounds(double x0, double y0, double x1, double y1, double padding, bool round) {
  final half = padding / 2;
  double snap(double value) => round ? value.roundToDouble() : value;
  final left = snap(x0 + half);
  final top = snap(y0 + half);
  final right = snap(x1 - half);
  final bottom = snap(y1 - half);
  return Bounds(left: left, top: top, width: right - left, height: bottom - top);
}
