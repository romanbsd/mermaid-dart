import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common_syntax.dart';

const _reservedIdentifiers = {
  'architecture-beta',
  'group',
  'service',
  'junction',
  'in',
  'align',
  'row',
  'column',
  'title',
  'accTitle',
  'accDescr',
};

Parser<T> _token<T>(Parser<T> parser) => parser.trim(pattern(' \t'));

final Parser<String> _identifier = pattern('0-9A-Za-z_')
    .seq(pattern('0-9A-Za-z_-').star())
    .flatten()
    .where((value) => RegExp(r'[0-9A-Za-z_]$').hasMatch(value) && !_reservedIdentifiers.contains(value));

final Parser<String> _icon = (char('(') & pattern('0-9A-Za-z_:-').plus() & char(')')).flatten().map(
  (value) => value.substring(1, value.length - 1).trim(),
);

final Parser<String> _architectureTitle =
    (char('[') & (quotedStringParser.flatten() | pattern('0-9A-Za-z_ ').plus().flatten()) & char(']')).map((value) {
      final inner = (value[1] as String).trim();
      return inner.startsWith('"') || inner.startsWith("'") ? decodeQuotedString(inner).trim() : inner;
    });

final class _IconValue {
  const _IconValue(this.value);
  final String value;
}

final class _IconTextValue {
  const _IconTextValue(this.value);
  final String value;
}

final Parser<_IconValue> _iconValue = _icon.map(_IconValue.new);
final Parser<_IconTextValue> _iconTextValue = quotedStringParser
    .flatten()
    .map(decodeQuotedString)
    .map(_IconTextValue.new);

final Parser<String> _parent = (_token(string('in')) & _token(_identifier)).map((value) => value[1] as String);

final Parser<ArchitectureGroupAst> _group =
    (_token(string('group')) &
            _token(_identifier) &
            _token(_icon).optional() &
            _token(_architectureTitle).optional() &
            _parent.optional() &
            lineEndParser)
        .map(
          (value) => ArchitectureGroupAst(
            id: value[1] as String,
            icon: value[2] as String?,
            title: value[3] as String?,
            parent: value[4] as String?,
          ),
        );

final Parser<ArchitectureServiceAst> _service =
    (_token(string('service')) &
            _token(_identifier) &
            _token((_iconTextValue | _iconValue).cast<Object>()).optional() &
            _token(_architectureTitle).optional() &
            _parent.optional() &
            lineEndParser)
        .map((value) {
          final icon = value[2];
          return ArchitectureServiceAst(
            id: value[1] as String,
            icon: icon is _IconValue ? icon.value : null,
            iconText: icon is _IconTextValue ? icon.value : null,
            title: value[3] as String?,
            parent: value[4] as String?,
          );
        });

final Parser<ArchitectureJunctionAst> _junction =
    (_token(string('junction')) & _token(_identifier) & _parent.optional() & lineEndParser).map(
      (value) => ArchitectureJunctionAst(id: value[1] as String, parent: value[2] as String?),
    );

final Parser<ArchitectureDirection> _direction = (char('L') | char('R') | char('T') | char('B')).map(
  (value) => switch (value) {
    'L' => ArchitectureDirection.left,
    'R' => ArchitectureDirection.right,
    'T' => ArchitectureDirection.top,
    'B' => ArchitectureDirection.bottom,
    _ => throw StateError('unreachable architecture direction'),
  },
);

final class _Arrow {
  const _Arrow({required this.leftArrow, required this.rightArrow, this.title});
  final bool leftArrow;
  final bool rightArrow;
  final String? title;
}

final Parser<_Arrow> _arrow =
    (_token((char('<') | char('>')).optional()) &
            _token(
              string('--').map((_) => null) |
                  (char('-') & _token(_architectureTitle) & char('-')).map((value) => value[1] as String),
            ) &
            _token((char('<') | char('>')).optional()))
        .map((value) => _Arrow(leftArrow: value[0] != null, title: value[1] as String?, rightArrow: value[2] != null));

final Parser<ArchitectureEdgeAst> _edge =
    (_token(_identifier) &
            _token(string('{group}').optional()) &
            _token(char(':')) &
            _token(_direction) &
            _arrow &
            _token(_direction) &
            _token(char(':')) &
            _token(_identifier) &
            _token(string('{group}').optional()) &
            lineEndParser)
        .map((value) {
          final arrow = value[4] as _Arrow;
          return ArchitectureEdgeAst(
            leftId: value[0] as String,
            leftGroup: value[1] != null,
            leftDirection: value[3] as ArchitectureDirection,
            leftArrow: arrow.leftArrow,
            rightId: value[7] as String,
            rightGroup: value[8] != null,
            rightDirection: value[5] as ArchitectureDirection,
            rightArrow: arrow.rightArrow,
            title: arrow.title,
          );
        });

final Parser<ArchitectureAlignmentAst> _alignment =
    (_token(string('align')) &
            _token((string('row') | string('column')).cast<String>()) &
            _token(_identifier) &
            _token(_identifier) &
            _token(_identifier).star() &
            lineEndParser)
        .map((value) {
          final members = <String>[value[2] as String, value[3] as String, ...(value[4] as List<String>)];
          return ArchitectureAlignmentAst(
            direction: value[1] == 'row' ? ArchitectureAlignmentDirection.row : ArchitectureAlignmentDirection.column,
            members: List.unmodifiable(members),
          );
        });

final Parser<Object?> _architectureGrammar =
    (whitespaceParser &
            string('architecture-beta') &
            (whitespaceParser & (commonMetadataParser | _group | _service | _junction | _edge | _alignment)).star() &
            whitespaceParser)
        .end();

ArchitectureAst parseArchitecture(String source) {
  final visibleSource = hideIgnoredSyntax(source);
  final result = _architectureGrammar.parse(visibleSource);
  if (result is Failure) throwParseFailure(source, result);

  final groups = <ArchitectureGroupAst>[];
  final services = <ArchitectureServiceAst>[];
  final junctions = <ArchitectureJunctionAst>[];
  final edges = <ArchitectureEdgeAst>[];
  final alignments = <ArchitectureAlignmentAst>[];
  void collect(Object? value) {
    switch (value) {
      case ArchitectureGroupAst():
        groups.add(value);
      case ArchitectureServiceAst():
        services.add(value);
      case ArchitectureJunctionAst():
        junctions.add(value);
      case ArchitectureEdgeAst():
        edges.add(value);
      case ArchitectureAlignmentAst():
        alignments.add(value);
      case Iterable<Object?>():
        value.forEach(collect);
    }
  }

  collect(result.value);
  final metadata = readCommonMetadata(visibleSource);
  return ArchitectureAst(
    groups: List.unmodifiable(groups),
    services: List.unmodifiable(services),
    junctions: List.unmodifiable(junctions),
    edges: List.unmodifiable(edges),
    alignments: List.unmodifiable(alignments),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}
