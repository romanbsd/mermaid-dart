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
}
