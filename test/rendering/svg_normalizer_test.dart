import 'package:mermaid_dart/src/rendering/svg_normalizer.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeSvg', () {
    test('sorts attributes and ignores formatting whitespace', () {
      expect(
        normalizeSvg('<svg b="2" a="1">\n  <text> Label </text>\n</svg>'),
        '<svg a="1" b="2"><text>Label</text></svg>',
      );
    });

    test('escapes quotes in normalized attribute values', () {
      expect(
        normalizeSvg('<svg font-family="&quot;Example Sans&quot;, sans-serif"/>'),
        '<svg font-family="&quot;Example Sans&quot;, sans-serif"></svg>',
      );
    });
  });

  group('canonicalizeSvgForComparison', () {
    test('canonicalizes generated IDs and all common references', () {
      const first = '''
        <svg aria-labelledby="title-a description-a">
          <title id="title-a">Chart</title>
          <desc id="description-a">Description</desc>
          <defs><clipPath id="clip-a"><rect width="1" height="1"/></clipPath></defs>
          <g clip-path="url(#clip-a)"><use href="#clip-a"/></g>
        </svg>
      ''';
      const second = '''
        <svg aria-labelledby="heading-91 details-42">
          <title id="heading-91">Chart</title>
          <desc id="details-42">Description</desc>
          <defs><clipPath id="mask-77"><rect height="1" width="1"/></clipPath></defs>
          <g clip-path="url(#mask-77)"><use href="#mask-77"/></g>
        </svg>
      ''';

      expect(canonicalizeSvgForComparison(first), canonicalizeSvgForComparison(second));
    });

    test('sorts class tokens and rounds numeric geometry', () {
      expect(
        canonicalizeSvgForComparison(
          '<svg viewBox="0 0 10.00004 20"><path class="edge active" '
          'd="M 1.23456 2.34567 L 9.99999 20" stroke-width="1.2000"/></svg>',
        ),
        '<svg viewBox="0 0 10 20"><path class="active edge" '
        'd="M 1.235 2.346 L 10 20" stroke-width="1.2"></path></svg>',
      );
    });

    test('does not rewrite numbers embedded in identifiers or colors', () {
      expect(
        canonicalizeSvgForComparison('<svg><path id="path12" fill="#123456" data-name="series2"/></svg>'),
        '<svg><path data-name="series2" fill="#123456" id="id0"></path></svg>',
      );
    });
  });
}
