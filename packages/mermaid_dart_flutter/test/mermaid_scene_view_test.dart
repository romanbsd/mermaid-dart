import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;
import 'package:mermaid_dart_flutter/mermaid_dart_flutter.dart';

void main() {
  testWidgets('exposes scene accessibility metadata and intrinsic size', (
    tester,
  ) async {
    const scene = mermaid.DiagramScene(
      diagramType: mermaid.DiagramType.info,
      viewport: mermaid.Bounds(left: 0, top: 0, width: 120, height: 60),
      bounds: mermaid.Bounds(left: 0, top: 0, width: 120, height: 60),
      accessibilityTitle: 'Deployment flow',
      accessibilityDescription: 'Three deployment stages',
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: MermaidSceneView(scene: scene)),
      ),
    );

    expect(tester.getSize(find.byType(CustomPaint)), const Size(120, 60));
    expect(
      tester.getSemantics(find.byType(MermaidSceneView)),
      matchesSemantics(
        label: 'Deployment flow\nThree deployment stages',
        isImage: true,
      ),
    );
  });

  testWidgets('parses, lays out, and paints Mermaid source', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: MermaidDiagram(
            diagramType: mermaid.DiagramType.info,
            source: '''
info
accTitle: Runtime information
accDescr: Painted without SVG
''',
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('forwards an IconData resolver from source layout to painting', (
    tester,
  ) async {
    const resolver = FlutterIconDataResolver({'app:cache': IconData(0x41)});

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MermaidDiagram(
          diagramType: mermaid.DiagramType.architecture,
          source: '''
architecture-beta
service cache(app:cache)[Cache]
''',
          iconResolver: resolver,
        ),
      ),
    );

    final customPaint = tester.widget<CustomPaint>(find.byType(CustomPaint));
    expect(
      customPaint.painter,
      isA<MermaidScenePainter>().having(
        (painter) => painter.iconDataResolver,
        'iconDataResolver',
        same(resolver),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
