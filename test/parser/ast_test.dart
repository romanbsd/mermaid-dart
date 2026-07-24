import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('common metadata is available through DiagramAst', () {
    const DiagramAst ast = InfoAst(
      title: 'Title',
      accessibilityTitle: 'Accessible title',
      accessibilityDescription: 'Description',
    );

    expect(ast.title, 'Title');
    expect(ast.accessibilityTitle, 'Accessible title');
    expect(ast.accessibilityDescription, 'Description');
  });

  test('all diagram ASTs use deep value equality and matching hash codes', () {
    final pairs = <(DiagramAst, DiagramAst)>[
      (
        WardleyAst(size: const WardleySizeAst(width: 1, height: 2), title: 'Map'),
        WardleyAst(size: const WardleySizeAst(width: 1, height: 2), title: 'Map'),
      ),
      (
        TreemapAst(
          rows: const [TreemapNodeRowAst(indent: 0, item: TreemapSectionAst(name: 'Root'))],
        ),
        TreemapAst(
          rows: const [TreemapNodeRowAst(indent: 0, item: TreemapSectionAst(name: 'Root'))],
        ),
      ),
      (
        RailroadAst(
          rules: const [RailroadRuleAst(name: 'rule', definition: RailroadTerminalAst('value'))],
        ),
        RailroadAst(
          rules: const [RailroadRuleAst(name: 'rule', definition: RailroadTerminalAst('value'))],
        ),
      ),
      (InfoAst(title: 'Info'), InfoAst(title: 'Info')),
      (
        PieAst(sections: const [PieSectionAst(label: 'A', value: 1)]),
        PieAst(sections: const [PieSectionAst(label: 'A', value: 1)]),
      ),
      (
        PacketAst(blocks: const [PacketSingleBitBlockAst(bit: 0, label: 'A')]),
        PacketAst(blocks: const [PacketSingleBitBlockAst(bit: 0, label: 'A')]),
      ),
      (RadarAst(axes: const [RadarAxisAst(name: 'cost')]), RadarAst(axes: const [RadarAxisAst(name: 'cost')])),
      (
        CynefinAst(domains: const [CynefinDomainAst(domain: CynefinDomain.clear)]),
        CynefinAst(domains: const [CynefinDomainAst(domain: CynefinDomain.clear)]),
      ),
      (
        GitGraphAst(statements: const [GitGraphCommitAst(id: '1')]),
        GitGraphAst(statements: const [GitGraphCommitAst(id: '1')]),
      ),
      (
        ArchitectureAst(groups: const [ArchitectureGroupAst(id: 'api')]),
        ArchitectureAst(groups: const [ArchitectureGroupAst(id: 'api')]),
      ),
      (
        TreeViewAst(nodes: const [TreeViewNodeAst(name: 'root')]),
        TreeViewAst(nodes: const [TreeViewNodeAst(name: 'root')]),
      ),
      (
        EventModelingAst(modelEntities: const [EventModelEntityAst(name: 'Order')]),
        EventModelingAst(modelEntities: const [EventModelEntityAst(name: 'Order')]),
      ),
      (
        FlowchartAst(
          nodes: const [FlowchartNodeAst(id: 'A', label: 'Start')],
          edges: const [FlowchartEdgeAst(from: 'A', to: 'B')],
        ),
        FlowchartAst(
          nodes: const [FlowchartNodeAst(id: 'A', label: 'Start')],
          edges: const [FlowchartEdgeAst(from: 'A', to: 'B')],
        ),
      ),
      (
        SequenceAst(
          participants: const [SequenceParticipantAst(id: 'A', label: 'Actor A')],
          statements: const [SequenceMessageAst(from: 'A', to: 'B', text: 'Hello')],
        ),
        SequenceAst(
          participants: const [SequenceParticipantAst(id: 'A', label: 'Actor A')],
          statements: const [SequenceMessageAst(from: 'A', to: 'B', text: 'Hello')],
        ),
      ),
      (
        ClassDiagramAst(
          classes: const [ClassAst(id: 'A', label: 'A')],
        ),
        ClassDiagramAst(
          classes: const [ClassAst(id: 'A', label: 'A')],
        ),
      ),
      (
        StateDiagramAst(
          states: const [StateAst(id: 'A', label: 'A')],
        ),
        StateDiagramAst(
          states: const [StateAst(id: 'A', label: 'A')],
        ),
      ),
      (
        ErDiagramAst(
          entities: const [ErEntityAst(id: 'A', label: 'A')],
        ),
        ErDiagramAst(
          entities: const [ErEntityAst(id: 'A', label: 'A')],
        ),
      ),
    ];

    for (final (left, right) in pairs) {
      expect(left, right);
      expect(left.hashCode, right.hashCode);
    }
  });

  test('value equality observes nested changes and concrete runtime types', () {
    expect(
      const PieAst(sections: [PieSectionAst(label: 'A', value: 1)]),
      isNot(const PieAst(sections: [PieSectionAst(label: 'A', value: 2)])),
    );
    expect(
      const WardleyAcceleratorAst(name: 'market', position: WardleyPositionAst(x: 1, y: 2)),
      isNot(const WardleyDeacceleratorAst(name: 'market', position: WardleyPositionAst(x: 1, y: 2))),
    );
    expect(
      const EventModelTimeFrameAst(name: '1', entityType: EventModelEntityType.event, entityIdentifier: 'Created'),
      isNot(
        const EventModelResetFrameAst(name: '1', entityType: EventModelEntityType.event, entityIdentifier: 'Created'),
      ),
    );
  });
}
