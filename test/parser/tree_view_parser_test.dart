import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('treeView parser', () {
    test('accepts empty diagrams and parses common metadata', () {
      final empty = parse('treeView', 'treeView-beta') as TreeViewAst;
      expect(empty.nodes, isEmpty);

      final ast =
          parse('treeView', '''treeView-beta
title Project files
accTitle: Accessible files
accDescr: Source tree
%% ignored
"Root"
''')
              as TreeViewAst;
      expect(ast.title, 'Project files');
      expect(ast.accessibilityTitle, 'Accessible files');
      expect(ast.accessibilityDescription, 'Source tree');
      expect(ast.nodes, [const TreeViewNodeAst(name: 'Root')]);
    });

    test('preserves indentation and quoted or bare names', () {
      final ast =
          parse('treeView', '''treeView-beta
src/
    index.js
    "Multi  Word File.ts"
\tBut  _  _ton💓.tsx
''')
              as TreeViewAst;

      expect(ast.nodes, [
        const TreeViewNodeAst(name: 'src/'),
        const TreeViewNodeAst(indent: 4, name: 'index.js'),
        const TreeViewNodeAst(indent: 4, name: 'Multi  Word File.ts'),
        const TreeViewNodeAst(indent: 1, name: 'But  _  _ton💓.tsx'),
      ]);
    });

    test('parses open-ended annotations in any order', () {
      final ast =
          parse('treeView', '''treeView-beta
app.ts icon(logos:react) :::my-class ## entry point
data.bin ## binary data
empty icon()
''')
              as TreeViewAst;

      expect(ast.nodes, [
        const TreeViewNodeAst(name: 'app.ts', cssClass: 'my-class', icon: 'logos:react', description: 'entry point'),
        const TreeViewNodeAst(name: 'data.bin', description: 'binary data'),
        const TreeViewNodeAst(name: 'empty', icon: ''),
      ]);
    });

    test('keeps spaces in bare names but excludes annotation spacing', () {
      final ast = parse('treeView', 'treeView-beta\nMy Documents/   :::highlight\nindex.js  ') as TreeViewAst;

      expect(ast.nodes, [
        const TreeViewNodeAst(name: 'My Documents/', cssClass: 'highlight'),
        const TreeViewNodeAst(name: 'index.js'),
      ]);
    });

    test('rejects malformed quoted nodes and annotations', () {
      expect(() => parse('treeView', 'treeView-beta\n"unterminated\n'), throwsA(isA<MermaidParseException>()));
      expect(
        () => parse('treeView', 'treeView-beta\n"file" icon(bad:name:extra)\n'),
        throwsA(isA<MermaidParseException>()),
      );
      for (final name in [':::class', 'icon(folder)', '## description']) {
        expect(() => parse('treeView', 'treeView-beta\n$name\n'), throwsA(isA<MermaidParseException>()));
      }
    });
  });
}
