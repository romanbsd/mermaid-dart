import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

void main() {
  group('SVG link security', () {
    test('emits only allowlisted destinations with isolated blank targets', () {
      const safeLinks = [
        'https://example.test/path',
        'http://example.test/path',
        'mailto:user@example.test',
        '/absolute/path',
        './relative/path',
        '../parent/path',
        'relative/path',
        '?query=value',
        '#fragment',
      ];

      for (final link in safeLinks) {
        final anchor = _renderLink(link).findAllElements('a').single;
        expect(anchor.getAttribute('href'), link, reason: link);
        expect(anchor.getAttribute('target'), '_blank', reason: link);
        expect(anchor.getAttribute('rel'), 'noopener noreferrer', reason: link);
      }

      expect(
        _renderLink('  https://example.test/trimmed  ').findAllElements('a').single.getAttribute('href'),
        'https://example.test/trimmed',
      );
    });

    test('renders unsafe, ambiguous, and malformed destinations as plain text', () {
      const unsafeLinks = [
        'javascript:alert(document.cookie)',
        'JaVaScRiPt:alert(1)',
        'data:text/html,<script>alert(1)</script>',
        'vbscript:msgbox(1)',
        'file:///etc/passwd',
        'notes://local/item',
        '//example.test/path',
        r'\\example.test\path',
        'java\nscript:alert(1)',
        'java\u0085script:alert(1)',
        'java\u200bscript:alert(1)',
        r'java\nscript:alert(1)',
        'https://',
        '',
      ];

      for (final link in unsafeLinks) {
        final document = _renderLink(link);
        expect(document.findAllElements('a'), isEmpty, reason: link);
        expect(document.findAllElements('text').single.innerText, 'Label', reason: link);
      }
    });

    test('blocks source-controlled Gantt and Sequence script links', () {
      final gantt = renderDiagramSvg(DiagramType.gantt, '''
gantt
dateFormat YYYY-MM-DD
Task :task, 2025-01-01, 1d
click task href "javascript:alert(document.cookie)"
''');
      final sequence = renderDiagramSvg(DiagramType.sequence, '''
sequenceDiagram
participant A
link A: Docs @ javascript:alert(document.cookie)
''');

      for (final svg in [gantt, sequence]) {
        final document = XmlDocument.parse(svg);
        expect(document.findAllElements('a'), isEmpty);
        expect(svg, isNot(contains('javascript:')));
      }
    });
  });
}

XmlDocument _renderLink(String link) => XmlDocument.parse(
  renderSvg(
    DiagramScene(
      diagramType: DiagramType.info,
      viewport: const Bounds(left: 0, top: 0, width: 100, height: 30),
      bounds: const Bounds(left: 0, top: 0, width: 100, height: 30),
      elements: [
        SceneText(
          id: 'label',
          position: const Point(0, 15),
          text: 'Label',
          bounds: const Bounds(left: 0, top: 0, width: 40, height: 20),
          link: link,
        ),
      ],
    ),
  ),
);
