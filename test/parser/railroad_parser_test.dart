import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

void main() {
  group('railroad parser frontends', () {
    test('lower equivalent syntax into one shared sealed AST', () {
      final diagrams = <RailroadAst>[
        parse(DiagramType.railroad, '''railroad-beta
rule = sequence(terminal("a"), optional(nonterminal("b"))) ;
''')
            as RailroadAst,
        parse(DiagramType.railroadEbnf, '''railroad-ebnf-beta
rule = "a" b? ;
''')
            as RailroadAst,
        parse(DiagramType.railroadAbnf, '''railroad-abnf-beta
rule = "a" [b] ;
''')
            as RailroadAst,
        parse(DiagramType.railroadPeg, '''railroad-peg-beta
rule <- "a" b? ;
''')
            as RailroadAst,
      ];

      const expected = RailroadAst(
        rules: [
          RailroadRuleAst(
            name: 'rule',
            definition: RailroadSequenceAst([
              RailroadTerminalAst('a'),
              RailroadOptionalAst(RailroadNonTerminalAst('b')),
            ]),
          ),
        ],
      );
      expect(diagrams, everyElement(expected));
      expect(expected.rules.single.definition, isA<RailroadNodeAst>());
    });

    test('classic frontend parses every IR expression and metadata', () {
      final ast =
          parse(DiagramType.railroad, '''railroad-beta
title "Example Grammar"
accTitle: Accessible railroad
accDescr: Shared renderer input
rule = choice(
  terminal("a\\n"),
  nonterminal('other'),
  special("any character"),
  oneOrMore(terminal("b")),
  zeroOrMore(terminal("c"))
) ;
''')
              as RailroadAst;

      expect(ast.title, 'Example Grammar');
      expect(ast.accessibilityTitle, 'Accessible railroad');
      expect(ast.accessibilityDescription, 'Shared renderer input');
      final choice = ast.rules.single.definition as RailroadChoiceAst;
      expect(choice.alternatives, [
        const RailroadTerminalAst('a\n'),
        const RailroadNonTerminalAst('other'),
        const RailroadSpecialAst('any character'),
        const RailroadRepetitionAst(RailroadTerminalAst('b'), min: 1, max: double.infinity),
        const RailroadRepetitionAst(RailroadTerminalAst('c'), min: 0, max: double.infinity),
      ]);
    });

    test('EBNF frontend handles ISO forms, postfixes, exception, and comments', () {
      final ast =
          parse(DiagramType.railroadEbnf, '''railroad-ebnf-beta
(* ISO comment *)
rule = [ "a" ], { other }, ? special ?, "x" - "y" ;
''')
              as RailroadAst;

      expect(
        ast.rules.single.definition,
        const RailroadSequenceAst([
          RailroadOptionalAst(RailroadTerminalAst('a')),
          RailroadRepetitionAst(RailroadNonTerminalAst('other'), min: 0, max: double.infinity),
          RailroadSpecialAst('special'),
          RailroadSequenceAst([RailroadTerminalAst('x'), RailroadTerminalAst('-'), RailroadTerminalAst('y')]),
        ]),
      );
    });

    test('ABNF frontend handles alternation, numeric values, and repeat ranges', () {
      final ast =
          parse(DiagramType.railroadAbnf, '''railroad-abnf-beta
rule = 2"a" / *3%x30 / 1*other / 4token ;
''')
              as RailroadAst;

      expect(
        ast.rules.single.definition,
        const RailroadChoiceAst([
          RailroadRepetitionAst(RailroadTerminalAst('a'), min: 2, max: 2),
          RailroadRepetitionAst(RailroadTerminalAst('%x30'), min: 0, max: 3),
          RailroadRepetitionAst(RailroadNonTerminalAst('other'), min: 1, max: double.infinity),
          RailroadRepetitionAst(RailroadNonTerminalAst('token'), min: 4, max: 4),
        ]),
      );
    });

    test('PEG frontend handles ordered choice, suffixes, lookahead, and any', () {
      final ast =
          parse(DiagramType.railroadPeg, '''railroad-peg-beta
rule <- &"a" !other .+ / ("b" other)* ;
''')
              as RailroadAst;

      expect(
        ast.rules.single.definition,
        const RailroadChoiceAst([
          RailroadSequenceAst([
            RailroadSpecialAst('&"a"'),
            RailroadSpecialAst('!other'),
            RailroadRepetitionAst(RailroadSpecialAst('.'), min: 1, max: double.infinity),
          ]),
          RailroadRepetitionAst(
            RailroadSequenceAst([RailroadTerminalAst('b'), RailroadNonTerminalAst('other')]),
            min: 0,
            max: double.infinity,
          ),
        ]),
      );
    });

    test('parses upstream real-world expression and URI examples', () {
      final ebnf =
          parse(DiagramType.railroadEbnf, '''railroad-ebnf-beta
expression = term ( "+" term | "-" term )* ;
term = factor ( "*" factor | "/" factor )* ;
factor = number | "(" expression ")" ;
number = digit+ ;
digit = "0" | "1" | "2" ;
''')
              as RailroadAst;
      final abnf =
          parse(DiagramType.railroadAbnf, '''railroad-abnf-beta
URI = scheme ":" hier-part ;
scheme = ALPHA *( ALPHA / DIGIT / "+" / "-" / "." ) ;
hier-part = "//" authority path-abempty ;
''')
              as RailroadAst;
      final peg =
          parse(DiagramType.railroadPeg, '''railroad-peg-beta
Expression <- Term (("+" / "-") Term)* ;
Term <- Factor (("*" / "/") Factor)* ;
Factor <- Number / "(" Expression ")" ;
Number <- Digit+ ;
Digit <- "0" / "1" / "2" ;
''')
              as RailroadAst;

      expect(ebnf.rules, hasLength(5));
      expect(abnf.rules, hasLength(3));
      expect(peg.rules, hasLength(5));
    });

    test('all frontends reject malformed or mismatched syntax', () {
      for (final entry in <DiagramType, String>{
        DiagramType.railroad: 'railroad-beta\nrule = terminal("a")',
        DiagramType.railroadEbnf: 'railroad-ebnf-beta\nrule = "a"',
        DiagramType.railroadAbnf: 'railroad-abnf-beta\nrule = "a"',
        DiagramType.railroadPeg: 'railroad-peg-beta\nrule <- "a"',
      }.entries) {
        expect(() => parse(entry.key, entry.value), throwsA(isA<MermaidParseException>()));
      }
    });
  });
}
