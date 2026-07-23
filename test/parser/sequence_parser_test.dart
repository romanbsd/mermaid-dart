import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('sequence parser', () {
    test('parses participants, aliases, messages, metadata, and autonumber', () {
      final ast =
          parse(DiagramType.sequence, '''
sequenceDiagram
title Request lifecycle
accTitle: Accessible request lifecycle
accDescr: Client calls the API
autonumber 3 2
actor C as Client
participant A as API
C->>+A: Request
A-->>-C: Response
''')
              as SequenceAst;

      expect(ast.title, 'Request lifecycle');
      expect(ast.accessibilityTitle, 'Accessible request lifecycle');
      expect(ast.accessibilityDescription, 'Client calls the API');
      expect(ast.participants, const [
        SequenceParticipantAst(id: 'C', label: 'Client', kind: SequenceParticipantKind.actor),
        SequenceParticipantAst(id: 'A', label: 'API'),
      ]);
      expect(ast.autoNumber, const SequenceAutoNumberAst(start: 3, step: 2));
      expect(ast.statements, const [
        SequenceMessageAst(from: 'C', to: 'A', text: 'Request', arrow: SequenceArrow.solid, activateTarget: true),
        SequenceMessageAst(from: 'A', to: 'C', text: 'Response', arrow: SequenceArrow.dotted, deactivateSource: true),
      ]);
    });

    test('parses notes, activations, boxes, and nested control blocks', () {
      final ast =
          parse(DiagramType.sequence, '''
sequenceDiagram
box rgba(120, 140, 255, .15) Services
participant API
participant DB
end
participant Client
Client->>API: Call
activate API
alt cached
  API-->>Client: Result
else miss
  loop retry
    API->>DB: Query
    DB-->>API: Row
  end
end
Note over API,DB: Internal work
deactivate API
''')
              as SequenceAst;

      expect(ast.boxes, const [
        SequenceBoxAst(label: 'Services', color: 'rgba(120, 140, 255, .15)', participantIds: ['API', 'DB']),
      ]);
      expect(ast.statements[1], const SequenceActivationAst(participantId: 'API', active: true));
      expect(
        ast.statements[2],
        const SequenceBlockAst(
          kind: SequenceBlockKind.alt,
          sections: [
            SequenceBlockSectionAst(
              label: 'cached',
              statements: [SequenceMessageAst(from: 'API', to: 'Client', text: 'Result', arrow: SequenceArrow.dotted)],
            ),
            SequenceBlockSectionAst(
              label: 'miss',
              statements: [
                SequenceBlockAst(
                  kind: SequenceBlockKind.loop,
                  sections: [
                    SequenceBlockSectionAst(
                      label: 'retry',
                      statements: [
                        SequenceMessageAst(from: 'API', to: 'DB', text: 'Query'),
                        SequenceMessageAst(from: 'DB', to: 'API', text: 'Row', arrow: SequenceArrow.dotted),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      expect(
        ast.statements[3],
        const SequenceNoteAst(
          participantIds: ['API', 'DB'],
          text: 'Internal work',
          placement: SequenceNotePlacement.over,
        ),
      );
      expect(ast.statements[4], const SequenceActivationAst(participantId: 'API', active: false));
    });

    test('tracks create and destroy against their associated messages', () {
      final ast =
          parse(DiagramType.sequence, '''
sequenceDiagram
participant A
create participant B
A->>B: Create
destroy B
B--xA: Done
''')
              as SequenceAst;

      expect(ast.participants.last, const SequenceParticipantAst(id: 'B', label: 'B', createdAt: 0, destroyedAt: 1));
      expect(ast.statements, const [
        SequenceMessageAst(from: 'A', to: 'B', text: 'Create'),
        SequenceMessageAst(from: 'B', to: 'A', text: 'Done', arrow: SequenceArrow.dottedCross),
      ]);
    });

    test('supports semicolon-separated statements and sequence hash comments', () {
      final ast =
          parse(
                DiagramType.sequence,
                'sequenceDiagram; participant A; participant B # internal\n'
                'A->B: open; B-->>A: dotted\n',
              )
              as SequenceAst;

      expect(ast.participants.map((participant) => participant.id), ['A', 'B']);
      expect(ast.statements, const [
        SequenceMessageAst(from: 'A', to: 'B', text: 'open', arrow: SequenceArrow.solidOpen),
        SequenceMessageAst(from: 'B', to: 'A', text: 'dotted', arrow: SequenceArrow.dotted),
      ]);
    });

    test('reports unterminated blocks with a source location', () {
      expect(
        () => parse(DiagramType.sequence, 'sequenceDiagram\nloop forever\nA->>B: ping\n'),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.line, 'line', 2)
              .having((error) => error.column, 'column', 1),
        ),
      );
    });
  });
}
