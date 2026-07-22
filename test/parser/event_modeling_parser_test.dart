import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('eventmodeling parser', () {
    test('parses frame aliases into enum-backed semantic types', () {
      final ast =
          parse(DiagramType.eventModeling, '''eventmodeling
timeframe 01 command Cart.Update
tf 02 evt Cart.Updated ->> 01 `jsobj`{ a: b }
resetframe 003 readmodel Cart.Items ->> 02 [[CartData]]
rf 04 processor Refresh ->> 003
tf 05 ui CartPage ->> 003
''')
              as EventModelingAst;

      expect(ast.frames, [
        const EventModelTimeFrameAst(
          name: '01',
          entityType: EventModelEntityType.command,
          entityIdentifier: 'Cart.Update',
        ),
        const EventModelTimeFrameAst(
          name: '02',
          entityType: EventModelEntityType.event,
          entityIdentifier: 'Cart.Updated',
          sourceFrames: ['01'],
          dataType: EventModelDataType.javaScriptObject,
          dataInlineValue: '{ a: b }',
        ),
        const EventModelResetFrameAst(
          name: '003',
          entityType: EventModelEntityType.readModel,
          entityIdentifier: 'Cart.Items',
          sourceFrames: ['02'],
          dataReference: 'CartData',
        ),
        const EventModelResetFrameAst(
          name: '04',
          entityType: EventModelEntityType.processor,
          entityIdentifier: 'Refresh',
          sourceFrames: ['003'],
        ),
        const EventModelTimeFrameAst(
          name: '05',
          entityType: EventModelEntityType.ui,
          entityIdentifier: 'CartPage',
          sourceFrames: ['003'],
        ),
      ]);
    });

    test('parses model entities, data blocks, and notes', () {
      final ast =
          parse(DiagramType.eventModeling, '''eventmodeling
entity Cart.Item
data CartData `json` {
  { "quantity": 2 }
  "url": "https://example.com/cart"
  title remains payload
}
note 02 `md` {
  # Cart updated
}
''')
              as EventModelingAst;

      expect(ast.modelEntities, [const EventModelEntityAst(name: 'Cart.Item')]);
      expect(ast.dataEntities, [
        const EventModelDataEntityAst(
          name: 'CartData',
          dataType: EventModelDataType.json,
          value: '{\n  { "quantity": 2 }\n  "url": "https://example.com/cart"\n  title remains payload\n}',
        ),
      ]);
      expect(ast.notes, [
        const EventModelNoteAst(
          sourceFrame: '02',
          dataType: EventModelDataType.markdown,
          value: '{\n  # Cart updated\n}',
        ),
      ]);
    });

    test('parses given-when-then scenarios', () {
      final ast =
          parse(DiagramType.eventModeling, '''eventmodeling
gwt 03
given evt CartUpdated
when cmd RefreshCart
then rmo CartItems
ui CartPage
''')
              as EventModelingAst;

      expect(ast.scenarios, [
        const EventModelScenarioAst(
          sourceFrame: '03',
          given: [EventModelStatementAst(entityType: EventModelEntityType.event, entityIdentifier: 'CartUpdated')],
          when: [EventModelStatementAst(entityType: EventModelEntityType.command, entityIdentifier: 'RefreshCart')],
          then: [
            EventModelStatementAst(entityType: EventModelEntityType.readModel, entityIdentifier: 'CartItems'),
            EventModelStatementAst(entityType: EventModelEntityType.ui, entityIdentifier: 'CartPage'),
          ],
        ),
      ]);
    });

    test('parses metadata and ignores every Mermaid comment form', () {
      final ast =
          parse(DiagramType.eventModeling, '''eventmodeling
title Shopping flow
accTitle: Accessible flow
accDescr: Cart lifecycle
%% Mermaid comment
// line comment
/* block
comment */
tf 01 event Started
''')
              as EventModelingAst;

      expect(ast.title, 'Shopping flow');
      expect(ast.accessibilityTitle, 'Accessible flow');
      expect(ast.accessibilityDescription, 'Cart lifecycle');
      expect(ast.frames, hasLength(1));
    });

    test('stops inline data at its matching delimiter', () {
      final ast =
          parse(DiagramType.eventModeling, '''eventmodeling
tf 01 evt Quoted "a" // later "quote"
tf 02 evt Json {"nested": {"value": "}"}} // later }
''')
              as EventModelingAst;

      expect(ast.frames, [
        const EventModelTimeFrameAst(
          name: '01',
          entityType: EventModelEntityType.event,
          entityIdentifier: 'Quoted',
          dataInlineValue: '"a"',
        ),
        const EventModelTimeFrameAst(
          name: '02',
          entityType: EventModelEntityType.event,
          entityIdentifier: 'Json',
          dataInlineValue: '{"nested": {"value": "}"}}',
        ),
      ]);
    });

    test('rejects invalid frame identifiers and data types', () {
      expect(
        () => parse(DiagramType.eventModeling, 'eventmodeling\ntf 1234 evt Started\n'),
        throwsA(isA<MermaidParseException>()),
      );
      expect(
        () => parse(DiagramType.eventModeling, 'eventmodeling\ntf 01 evt Started `yaml`{a: b}\n'),
        throwsA(isA<MermaidParseException>()),
      );
    });
  });
}
