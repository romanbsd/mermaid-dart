import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('gitGraph parser', () {
    test('accepts every header form and enum-backed direction', () {
      expect((parse('gitGraph', 'gitGraph') as GitGraphAst).direction, isNull);
      expect((parse('gitGraph', 'gitGraph:') as GitGraphAst).direction, isNull);
      expect((parse('gitGraph', 'gitGraph LR:') as GitGraphAst).direction, GitGraphDirection.leftToRight);
      expect((parse('gitGraph', 'gitGraph TB:') as GitGraphAst).direction, GitGraphDirection.topToBottom);
      expect((parse('gitGraph', 'gitGraph BT:') as GitGraphAst).direction, GitGraphDirection.bottomToTop);
    });

    test('parses commits and all commit properties', () {
      final ast =
          parse('gitGraph', '''gitGraph
commit
commit id:"1" msg:"Fix issue #123: Handle errors" tag:"v1.2" tag:'stable' type:HIGHLIGHT
''')
              as GitGraphAst;

      expect(ast.statements, [
        const GitGraphCommitAst(),
        const GitGraphCommitAst(
          id: '1',
          message: 'Fix issue #123: Handle errors',
          tags: ['v1.2', 'stable'],
          type: GitGraphCommitType.highlight,
        ),
      ]);
    });

    test('parses branch, checkout, and switch statements', () {
      final ast =
          parse('gitGraph', '''gitGraph
branch 1.0.1 order:2
branch "feature branch"
checkout feature/test-branch
switch my-feature_branch
''')
              as GitGraphAst;

      expect(ast.statements, [
        const GitGraphBranchAst(name: '1.0.1', order: 2),
        const GitGraphBranchAst(name: 'feature branch'),
        const GitGraphCheckoutAst(branch: 'feature/test-branch'),
        const GitGraphCheckoutAst(branch: 'my-feature_branch'),
      ]);
    });

    test('parses merge and cherry-pick properties', () {
      final ast =
          parse('gitGraph', '''gitGraph
merge feature id:"m1" tag:"release" type:REVERSE
cherry-pick id:"123" tag:"urgent" parent:"100"
''')
              as GitGraphAst;

      expect(ast.statements, [
        const GitGraphMergeAst(branch: 'feature', id: 'm1', tags: ['release'], type: GitGraphCommitType.reverse),
        const GitGraphCherryPickAst(id: '123', tags: ['urgent'], parent: '100'),
      ]);
    });

    test('preserves common metadata and ignores comments', () {
      final ast =
          parse('gitGraph', '''gitGraph TB:
title Release history
accTitle: Accessible history
accDescr {
  First line
  Second line
}
%% ignored
commit msg:"Initial release"
''')
              as GitGraphAst;

      expect(ast.title, 'Release history');
      expect(ast.accessibilityTitle, 'Accessible history');
      expect(ast.accessibilityDescription, 'First line\nSecond line');
      expect(ast.statements, [const GitGraphCommitAst(message: 'Initial release')]);
    });

    test('rejects malformed properties and invalid branch order', () {
      expect(() => parse('gitGraph', 'gitGraph\ncommit unknown:"oops"\n'), throwsA(isA<MermaidParseException>()));
      expect(() => parse('gitGraph', 'gitGraph\nbranch feature order:xyz\n'), throwsA(isA<MermaidParseException>()));
    });
  });
}
