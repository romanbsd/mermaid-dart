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

    final row = items.sublist(start, end);
    if (dx < dy) {
      final rowBottom = remaining == 0 ? y1 : y0 + dy * sum / remaining;
      _dice(row, x0, y0, x1, rowBottom, innerPadding, round, result);
      y0 = rowBottom;
    } else {
      final rowRight = remaining == 0 ? x1 : x0 + dx * sum / remaining;
      _slice(row, x0, y0, rowRight, y1, innerPadding, round, result);
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
  List<TreemapItem<T>> row,
  double x0,
  double y0,
  double x1,
  double y1,
  double padding,
  bool round,
  List<TreemapTile<T>> output,
) {
  final total = row.fold<double>(0, (sum, item) => sum + item.value);
  var x = x0;
  for (var i = 0; i < row.length; i++) {
    final next = i == row.length - 1 ? x1 : x + (x1 - x0) * row[i].value / total;
    output.add(TreemapTile(row[i].data, _tileBounds(x, y0, next, y1, padding, round)));
    x = next;
  }
}

void _slice<T>(
  List<TreemapItem<T>> row,
  double x0,
  double y0,
  double x1,
  double y1,
  double padding,
  bool round,
  List<TreemapTile<T>> output,
) {
  final total = row.fold<double>(0, (sum, item) => sum + item.value);
  var y = y0;
  for (var i = 0; i < row.length; i++) {
    final next = i == row.length - 1 ? y1 : y + (y1 - y0) * row[i].value / total;
    output.add(TreemapTile(row[i].data, _tileBounds(x0, y, x1, next, padding, round)));
    y = next;
  }
}

Bounds _tileBounds(double x0, double y0, double x1, double y1, double padding, bool round) {
  final half = padding / 2;
  final left = x0 + half;
  final top = y0 + half;
  final right = x1 - half;
  final bottom = y1 - half;
  return Bounds(
    left: round ? left.roundToDouble() : left,
    top: round ? top.roundToDouble() : top,
    width: (round ? right.roundToDouble() : right) - (round ? left.roundToDouble() : left),
    height: (round ? bottom.roundToDouble() : bottom) - (round ? top.roundToDouble() : top),
  );
}
