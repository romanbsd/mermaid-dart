import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('timeline parser', () {
    test('parses direction, sections, periods, and continued events', () {
      final ast =
          parse(DiagramType.timeline, '''
timeline TD
  section Foundation
    Research : Interviews : Prototype
             : Validation
  section Launch
    Release
''')
              as TimelineAst;

      expect(ast.direction, TimelineDirection.topDown);
      expect(ast.sections, hasLength(2));
      expect(ast.sections.first.name, 'Foundation');
      expect(ast.sections.first.periods.single.label, 'Research');
      expect(ast.sections.first.periods.single.events, ['Interviews', 'Prototype', 'Validation']);
      expect(ast.sections.last.periods.single.label, 'Release');
    });

    test('defaults to LR and supports periods without sections', () {
      final ast = parse(DiagramType.timeline, 'timeline\nIdea\nBuild : Ship\n') as TimelineAst;

      expect(ast.direction, TimelineDirection.leftRight);
      expect(ast.sections.single.name, isEmpty);
      expect(ast.sections.single.periods.map((period) => period.label), ['Idea', 'Build']);
      expect(ast.sections.single.periods.last.events, ['Ship']);
    });

    test('preserves metadata, markdown links, semicolons, and hashes', () {
      final ast =
          parse(DiagramType.timeline, '''
timeline LR
title ;my;title;
accTitle: Release history
accDescr: Product milestones
section #a#bc-123#
;ta;sk1; : [event](https://example.com) : #ev#ent2#
''')
              as TimelineAst;

      expect(ast.title, ';my;title;');
      expect(ast.accessibilityTitle, 'Release history');
      expect(ast.accessibilityDescription, 'Product milestones');
      expect(ast.sections.single.name, '#a#bc-123#');
      expect(ast.sections.single.periods.single.label, ';ta;sk1;');
      expect(ast.sections.single.periods.single.events, ['[event](https://example.com)', '#ev#ent2#']);
    });

    test('rejects an event before its period', () {
      expect(
        () => parse(DiagramType.timeline, 'timeline\n  : orphan\n'),
        throwsA(isA<MermaidParseException>().having((error) => error.line, 'line', 2)),
      );
    });

    test('accepts a case-insensitive diagram header and direction', () {
      final ast = parse(DiagramType.timeline, 'TIMELINE td\n  Event\n') as TimelineAst;

      expect(ast.direction, TimelineDirection.topDown);
      expect(ast.sections.single.periods.single.label, 'Event');
    });
  });
}
