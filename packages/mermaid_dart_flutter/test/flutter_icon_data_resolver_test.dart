import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';

void main() {
  const icon = IconData(0x41);
  const fallbackGeometry = mermaid.IconGeometry(
    bounds: mermaid.Bounds(left: 0, top: 0, width: 12, height: 6),
  );
  const resolver = FlutterIconDataResolver({'app:cache': icon}, size: 24);

  test('reserves square geometry for IconData references', () {
    expect(resolver.resolveIconData('app:cache'), icon);
    expect(
      resolver.resolve('app:cache'),
      const mermaid.IconGeometry(
        bounds: mermaid.Bounds(left: 0, top: 0, width: 24, height: 24),
      ),
    );
  });

  test('delegates unknown references to the vector fallback', () {
    const withFallback = FlutterIconDataResolver({
      'app:cache': icon,
    }, fallback: _FallbackResolver(fallbackGeometry));

    expect(withFallback.resolveIconData('app:unknown'), isNull);
    expect(withFallback.resolve('app:unknown'), fallbackGeometry);
    expect(withFallback.resolve('app:cache'), fallbackGeometry);
  });
}

final class _FallbackResolver implements mermaid.IconResolver {
  const _FallbackResolver(this.geometry);

  final mermaid.IconGeometry geometry;

  @override
  mermaid.IconGeometry? resolve(String reference) => geometry;
}
