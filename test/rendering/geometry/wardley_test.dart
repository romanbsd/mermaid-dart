import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart/src/rendering/geometry/wardley.dart';
import 'package:test/test.dart';

void main() {
  group('buildWardleyModel', () {
    test('builds typed nodes and synthetic pipeline component IDs', () {
      final model = buildWardleyModel(
        const WardleyAst(
          anchors: [WardleyAnchorAst(name: 'User', position: WardleyPositionAst(x: 10, y: 90))],
          components: [WardleyComponentAst(name: 'Platform', position: WardleyPositionAst(x: 50, y: 50))],
          pipelines: [
            WardleyPipelineAst(
              parent: 'Platform',
              components: [WardleyPipelineComponentAst(name: 'Queue', evolution: 30)],
            ),
          ],
        ),
      );

      expect(model.nodes.map((node) => node.kind), [
        WardleyNodeKind.anchor,
        WardleyNodeKind.component,
        WardleyNodeKind.pipelineComponent,
      ]);
      expect(model.nodes.singleWhere((node) => node.id == 'Platform').isPipelineParent, isTrue);
      expect(model.nodes.last.id, 'Platform_Queue');
      expect(model.nodes.last.label, 'Queue');
      expect(model.nodes.last.y, 50);
      expect(model.pipelines.single.componentIds, ['Platform_Queue']);
    });

    test('resolves link labels to pipeline IDs and preserves trend coordinates', () {
      final model = buildWardleyModel(
        const WardleyAst(
          components: [WardleyComponentAst(name: 'Platform', position: WardleyPositionAst(x: 50, y: 60))],
          pipelines: [
            WardleyPipelineAst(
              parent: 'Platform',
              components: [WardleyPipelineComponentAst(name: 'Queue', evolution: 30)],
            ),
          ],
          links: [WardleyLinkAst(from: 'Queue', to: 'Platform', style: WardleyLinkStyle.dashed)],
          evolves: [WardleyEvolveAst(component: 'Platform', target: 80)],
        ),
      );

      expect(model.links.single.sourceId, 'Platform_Queue');
      expect(model.links.single.targetId, 'Platform');
      expect(model.trends.single.nodeId, 'Platform');
      expect(model.trends.single.targetX, 80);
      expect(model.trends.single.targetY, 60);
    });
  });
}
