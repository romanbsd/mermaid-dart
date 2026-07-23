import 'dart:math' as math;

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

    test('preserves first-match resolution when labels are duplicated', () {
      final model = buildWardleyModel(
        const WardleyAst(
          components: [
            WardleyComponentAst(name: 'First', position: WardleyPositionAst(x: 10, y: 20)),
            WardleyComponentAst(name: 'Second', position: WardleyPositionAst(x: 30, y: 40)),
          ],
          pipelines: [
            WardleyPipelineAst(
              parent: 'First',
              components: [WardleyPipelineComponentAst(name: 'Shared', evolution: 50)],
            ),
            WardleyPipelineAst(
              parent: 'Second',
              components: [WardleyPipelineComponentAst(name: 'Shared', evolution: 60)],
            ),
          ],
          links: [WardleyLinkAst(from: 'Shared', to: 'Second', style: WardleyLinkStyle.solid)],
        ),
      );

      expect(model.links.single.sourceId, 'First_Shared');
    });
  });

  group('Wardley geometry', () {
    test('projects and clamps map coordinates inside the padded viewport', () {
      expect(projectWardleyPoint(x: 50, y: 25, width: 200, height: 120, padding: 10), const Point(100, 85));
      expect(projectWardleyPoint(x: -10, y: 120, width: 200, height: 120, padding: 10), const Point(10, 10));
    });

    test('builds symmetric market triangle vertices', () {
      final triangle = wardleyMarketTriangle(center: const Point(50, 50), radius: 12, angle: math.pi / 6);

      expect(triangle.top, const Point(50, 38));
      expect(triangle.left.x, closeTo(39.607695, 0.000001));
      expect(triangle.right.x, closeTo(60.392305, 0.000001));
      expect(triangle.left.y, closeTo(56, 0.000001));
      expect(triangle.right.y, closeTo(56, 0.000001));
    });

    test('mirrors typed marker paths without changing command structure', () {
      final right = wardleyMarkerCommands(
        const Point(10, 20),
        right: true,
        width: 60,
        height: 30,
        headWidth: 20,
        notchDepth: 8,
      );
      final left = wardleyMarkerCommands(
        const Point(10, 20),
        right: false,
        width: 60,
        height: 30,
        headWidth: 20,
        notchDepth: 8,
      );

      expect(right, hasLength(8));
      expect(left, hasLength(8));
      expect(right.first, const MoveTo(Point(10, 5)));
      expect(left.first, const MoveTo(Point(70, 5)));
      expect((right[3] as LineTo).point, const Point(70, 20));
      expect((left[3] as LineTo).point, const Point(10, 20));
      expect(right.last, const ClosePath());
      expect(left.last, const ClosePath());
    });
  });
}
