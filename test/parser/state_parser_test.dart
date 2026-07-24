import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('state diagram parser', () {
    test('parses aliases, descriptions, transitions, notes, and special states', () {
      final ast =
          parse(DiagramType.stateDiagram, '''
stateDiagram-v2
title Checkout
direction LR
[*] --> Idle
state "Awaiting payment" as Pending
Idle --> Pending : begin
Pending : entry / reserve
state choice <<choice>>
Pending --> choice
choice --> Complete : paid
Complete --> [*]
note right of Pending : Expires after 15m
''')
              as StateDiagramAst;

      expect(ast.title, 'Checkout');
      expect(ast.direction, GraphDirection.leftRight);
      expect(ast.states.where((state) => state.type == StateType.start), hasLength(1));
      expect(ast.states.where((state) => state.type == StateType.end), hasLength(1));
      expect(
        ast.states.firstWhere((state) => state.id == 'Pending'),
        const StateAst(
          id: 'Pending',
          label: 'Awaiting payment',
          descriptions: ['entry / reserve'],
          note: StateNoteAst(text: 'Expires after 15m', position: StateNotePosition.right),
        ),
      );
      expect(ast.states.firstWhere((state) => state.id == 'choice').type, StateType.choice);
      expect(
        ast.transitions.where((transition) => transition.label == 'begin').single,
        const StateTransitionAst(from: 'Idle', to: 'Pending', label: 'begin'),
      );
    });

    test('parses composite states, concurrency, classes, and nested direction', () {
      final ast =
          parse(DiagramType.stateDiagram, '''
stateDiagram
state Active {
  direction TB
  [*] --> First
  First --> Second
  --
  [*] --> Audit
}
classDef emphasis fill:#fee,stroke:#933
class Active emphasis
''')
              as StateDiagramAst;

      final active = ast.states.singleWhere((state) => state.id == 'Active');
      expect(active.children, isNotEmpty);
      expect(active.transitions, hasLength(3));
      expect(active.children.where((state) => state.type == StateType.divider), hasLength(1));
      expect(active.direction, GraphDirection.topDown);
      expect(active.cssClasses, ['emphasis']);
      expect(ast.classDefinitions['emphasis'], {'fill': '#fee', 'stroke': '#933'});
    });

    test('normalizes multiline notes from the upstream grammar', () {
      final ast =
          parse(DiagramType.stateDiagram, '''
stateDiagram-v2
State1
note left of State1
Line1<br/>Line2
Line3
end note
''')
              as StateDiagramAst;

      expect(
        ast.states.single.note,
        const StateNoteAst(text: 'Line1<br>Line2<br>Line3', position: StateNotePosition.left),
      );
    });

    test('parses composites, forks, joins, concurrency, notes, and styling', () {
      final ast =
          parse(DiagramType.stateDiagram, '''
stateDiagram-v2
state Workflow {
  direction LR
  [*] --> Fork
  state Fork <<fork>>
  Fork --> First
  Fork --> Second
  --
  state Join <<join>>
  First --> Join
  Second --> Join
  Join --> [*]
}
note left of Workflow
Concurrent processing
with a synchronized join
end note
classDef active fill:#eef,stroke:#446,color:#113
class Workflow,First,Second active
''')
              as StateDiagramAst;

      final workflow = ast.states.singleWhere((state) => state.id == 'Workflow');
      expect(workflow.direction, GraphDirection.leftRight);
      expect(
        workflow.children.map((state) => state.type),
        containsAll([StateType.start, StateType.fork, StateType.divider, StateType.join, StateType.end]),
      );
      expect(workflow.note?.position, StateNotePosition.left);
      expect(workflow.note?.text, 'Concurrent processing<br>with a synchronized join');
      expect(workflow.cssClasses, ['active']);
      expect(
        workflow.children
            .where((state) => state.id == 'First' || state.id == 'Second')
            .every((state) => state.cssClasses.contains('active')),
        isTrue,
      );
      expect(ast.classDefinitions['active'], {'fill': '#eef', 'stroke': '#446', 'color': '#113'});
    });

    test('reports an unterminated composite state at its declaration', () {
      expect(
        () => parse(DiagramType.stateDiagram, 'stateDiagram-v2\nstate Open {\n  [*] --> A\n'),
        throwsA(
          isA<MermaidParseException>()
              .having((error) => error.line, 'line', 2)
              .having((error) => error.column, 'column', 1),
        ),
      );
    });
  });
}
