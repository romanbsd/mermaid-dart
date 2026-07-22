import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('cynefin parser', () {
    test('accepts bare and colon-terminated headers', () {
      for (final source in ['cynefin-beta', ' cynefin-beta: ', '\ncynefin-beta\n']) {
        final ast = parse('cynefin', source) as CynefinAst;
        expect(ast.domains, isEmpty);
        expect(ast.transitions, isEmpty);
      }
    });

    test('parses every domain and its items', () {
      final ast =
          parse('cynefin', '''cynefin-beta
complex
  "Probe"
  "Emergent practice"
complicated "Analyze"
clear
  "Best practice"
chaotic "Act"
confusion "Collect context"
''')
              as CynefinAst;

      expect(ast.domains, [
        const CynefinDomainAst(
          domain: CynefinDomain.complex,
          items: [
            CynefinItemAst(label: 'Probe'),
            CynefinItemAst(label: 'Emergent practice'),
          ],
        ),
        const CynefinDomainAst(
          domain: CynefinDomain.complicated,
          items: [CynefinItemAst(label: 'Analyze')],
        ),
        const CynefinDomainAst(
          domain: CynefinDomain.clear,
          items: [CynefinItemAst(label: 'Best practice')],
        ),
        const CynefinDomainAst(
          domain: CynefinDomain.chaotic,
          items: [CynefinItemAst(label: 'Act')],
        ),
        const CynefinDomainAst(
          domain: CynefinDomain.confusion,
          items: [CynefinItemAst(label: 'Collect context')],
        ),
      ]);
    });

    test('parses labeled and unlabeled transitions', () {
      final ast =
          parse('cynefin', '''cynefin-beta:
complex --> complicated: "Constrain"
chaotic --> clear
''')
              as CynefinAst;

      expect(ast.transitions, [
        const CynefinTransitionAst(from: CynefinDomain.complex, to: CynefinDomain.complicated, label: 'Constrain'),
        const CynefinTransitionAst(from: CynefinDomain.chaotic, to: CynefinDomain.clear),
      ]);
    });

    test('parses common metadata and ignores comments', () {
      final ast =
          parse('cynefin', '''cynefin-beta
title Decision context
accTitle: Cynefin framework
%% hidden
complex "Explore"
''')
              as CynefinAst;

      expect(ast.title, 'Decision context');
      expect(ast.accessibilityTitle, 'Cynefin framework');
      expect(ast.domains.single.items.single.label, 'Explore');
    });

    test('rejects unknown domains', () {
      expect(() => parse('cynefin', 'cynefin-beta\nsimple "Invalid"'), throwsA(isA<MermaidParseException>()));
    });
  });
}
