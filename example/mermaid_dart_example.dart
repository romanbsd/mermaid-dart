import 'package:mermaid_dart/mermaid_dart.dart';

void main() {
  final ast = parse(DiagramType.info, 'info showInfo\ntitle Mermaid in Dart\naccDescr: Parser example');
  print(ast);
}
