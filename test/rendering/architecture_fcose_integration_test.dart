import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  test('architecture uses Mermaid fCoSE geometry for a directional grid', () {
    final ast =
        parse(
              DiagramType.architecture,
              'architecture-beta\n'
              'service a(server)[A]\n'
              'service b(server)[B]\n'
              'service c(server)[C]\n'
              'service d(server)[D]\n'
              'a:R -- L:b\n'
              'a:B -- T:c\n'
              'b:B -- T:d\n'
              'c:R -- L:d\n',
            )
            as ArchitectureAst;

    final scene = layoutDiagram(ast, options: const RenderOptions(padding: 0));
    final positions = {
      for (final service in _flatten(
        scene.elements,
      ).whereType<SceneGroup>().where((element) => element.cssClasses.contains('architecture-service')))
        service.label!: service.transforms.single as Translate,
    };

    expect(positions['B']!.x - positions['A']!.x, closeTo(200.9256326281156, 1e-9));
    expect(positions['C']!.y - positions['A']!.y, closeTo(200.9256326281156, 1e-9));
    expect(positions['D']!.x - positions['C']!.x, closeTo(200.9256326281156, 1e-9));
    expect(positions['D']!.y - positions['B']!.y, closeTo(200.9256326281156, 1e-9));
  });

  test('architecture group bounds contain measured service labels', () {
    const label = 'A service label much wider than its icon';
    final ast =
        parse(
              DiagramType.architecture,
              'architecture-beta\n'
              'group cloud[Cloud]\n'
              'service api(server)[$label] in cloud\n',
            )
            as ArchitectureAst;

    final scene = layoutDiagram(ast, options: const RenderOptions(padding: 0));
    final elements = _flatten(scene.elements).toList();
    final group = elements.whereType<SceneRect>().singleWhere(
      (element) => element.cssClasses.contains('architecture-group'),
    );
    final service = elements.whereType<SceneGroup>().singleWhere(
      (element) => element.cssClasses.contains('architecture-service'),
    );
    final center = service.transforms.single as Translate;
    final labelWidth = const DeterministicTextMeasurer().measure(label, const SceneTextStyle(fontSize: 16)).width;

    expect(group.bounds.left, lessThanOrEqualTo(center.x - labelWidth / 2));
    expect(group.bounds.right, greaterThanOrEqualTo(center.x + labelWidth / 2));
  });

  test('architecture group bounds contain measured group headers', () {
    const label = 'A group header much wider than its service';
    final ast =
        parse(
              DiagramType.architecture,
              'architecture-beta\n'
              'group cloud[$label]\n'
              'service api(server)[API] in cloud\n',
            )
            as ArchitectureAst;

    final scene = layoutDiagram(ast, options: const RenderOptions(padding: 0));
    final group = _flatten(
      scene.elements,
    ).whereType<SceneRect>().singleWhere((element) => element.cssClasses.contains('architecture-group'));
    final labelWidth = const DeterministicTextMeasurer().measure(label, const SceneTextStyle(fontSize: 16)).width;

    expect(group.bounds.width, greaterThan(labelWidth));
  });
}

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element case SceneGroup(:final children)) {
      yield* _flatten(children);
    }
  }
}
