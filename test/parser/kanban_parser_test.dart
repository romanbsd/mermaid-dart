import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('kanban parser', () {
    test('accepts the case-insensitive upstream header and an empty board', () {
      expect(parse(DiagramType.kanban, '\nKanBan\n'), const KanbanAst());
    });

    test('parses sections and flattens deeper cards into the current section', () {
      final ast =
          parse(DiagramType.kanban, '''
kanban
  backlog[Backlog]
    write[Write parser]
      test[Port upstream tests]
  done[Done]
    ship[Ship it]
''')
              as KanbanAst;

      expect(ast.sections, const [
        KanbanSectionAst(
          id: 'backlog',
          label: 'Backlog',
          cards: [
            KanbanCardAst(id: 'write', label: 'Write parser'),
            KanbanCardAst(id: 'test', label: 'Port upstream tests'),
          ],
        ),
        KanbanSectionAst(
          id: 'done',
          label: 'Done',
          cards: [KanbanCardAst(id: 'ship', label: 'Ship it')],
        ),
      ]);
    });

    test('parses decorations, comments, quoted labels, and card metadata', () {
      final ast =
          parse(DiagramType.kanban, '''
%% before the declaration
kanban
  todo["To do []"]
  :::featured urgent
  ::icon(material-symbols:view-kanban)
    task["Implement ()"]@{
      ticket: MC-1234
      assigned: Roman
      priority: high
      icon: material-symbols:code
    }
    review@{ label: "Review %% output", priority: very low } %% hidden
''')
              as KanbanAst;

      expect(
        ast.sections.single,
        const KanbanSectionAst(
          id: 'todo',
          label: 'To do []',
          cssClasses: ['featured', 'urgent'],
          icon: 'material-symbols:view-kanban',
          cards: [
            KanbanCardAst(
              id: 'task',
              label: 'Implement ()',
              ticket: 'MC-1234',
              assigned: 'Roman',
              priority: KanbanPriority.high,
              icon: 'material-symbols:code',
            ),
            KanbanCardAst(id: 'review', label: 'Review %% output', priority: KanbanPriority.veryLow),
          ],
        ),
      );
    });

    test('preserves common metadata and supports generated ids', () {
      final ast =
          parse(DiagramType.kanban, '''
kanban
title Delivery board
accTitle: Accessible board
accDescr: Work grouped by state
  (To do)
    (Unidentified card)
''')
              as KanbanAst;

      expect(ast.title, 'Delivery board');
      expect(ast.accessibilityTitle, 'Accessible board');
      expect(ast.accessibilityDescription, 'Work grouped by state');
      expect(ast.sections.single.id, 'To do');
      expect(ast.sections.single.cards.single.id, 'Unidentified card');
    });

    test('does not restore metadata-looking text inside comments', () {
      final ast =
          parse(
                DiagramType.kanban,
                'kanban\n'
                '  todo\n'
                '    task\n'
                '    %% ignored @{ priority: urgent }\n'
                '    next %% ignored @{ assigned: nobody }\n',
              )
              as KanbanAst;

      expect(ast.sections.single.cards.map((card) => card.id), ['task', 'next']);
    });

    test('rejects items that precede the section indentation level', () {
      expect(
        () => parse(
          DiagramType.kanban,
          'kanban\n'
          '      root\n'
          '    fakeRoot\n'
          'realRootWrongPlace\n',
        ),
        throwsA(
          isA<MermaidParseException>().having(
            (error) => error.message,
            'message',
            contains('Items without section detected'),
          ),
        ),
      );
    });

    test('rejects decorations without a preceding node and invalid priorities', () {
      for (final source in ['kanban\n  ::icon(star)', 'kanban\n  todo@{ priority: urgent }']) {
        expect(() => parse(DiagramType.kanban, source), throwsA(isA<MermaidParseException>()));
      }
    });
  });
}
