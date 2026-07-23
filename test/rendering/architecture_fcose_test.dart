import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart/src/rendering/geometry/architecture_fcose.dart';
import 'package:test/test.dart';

void main() {
  group('architecture fCoSE', () {
    test('uses AST directions to build a directional grid', () {
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

      final positions = layoutArchitectureWithFcose(ast, const ArchitectureRenderOptions());

      expect(positions['b']!.x - positions['a']!.x, closeTo(200.9256326281156, 1e-9));
      expect(positions['c']!.y - positions['a']!.y, closeTo(200.9256326281156, 1e-9));
      expect(positions['d']!.x - positions['c']!.x, closeTo(200.9256326281156, 1e-9));
      expect(positions['d']!.y - positions['b']!.y, closeTo(200.9256326281156, 1e-9));
    });

    test('uses AST alignment declarations directly', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'service a(server)[A]\n'
                'service b(server)[B]\n'
                'service c(server)[C]\n'
                'align row a b c\n',
              )
              as ArchitectureAst;

      final positions = layoutArchitectureWithFcose(ast, const ArchitectureRenderOptions());

      expect(positions.values.map((position) => position.y), everyElement(closeTo(positions['a']!.y, 1e-9)));
    });

    test('rejects edges with matching port directions', () {
      final ast =
          parse(
                DiagramType.architecture,
                'architecture-beta\n'
                'service a(server)[A]\n'
                'service b(server)[B]\n'
                'a:R -- R:b\n',
              )
              as ArchitectureAst;

      expect(() => layoutArchitectureWithFcose(ast, const ArchitectureRenderOptions()), throwsArgumentError);
    });
  });
}
