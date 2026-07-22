import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common_syntax.dart';

final class _Header {
  const _Header(this.direction);
  final GitGraphDirection? direction;
}

final class _Property {
  const _Property(this.name, this.value);
  final String name;
  final Object value;
}

final Parser<String> _quotedValue = quotedStringParser.flatten().map(decodeQuotedString);

final Parser<String> _reference = pattern(
  '0-9A-Za-z_',
).seq(pattern('0-9A-Za-z_./-').star()).flatten().where((value) => RegExp(r'[0-9A-Za-z_]$').hasMatch(value));

final Parser<String> _name = (_quotedValue | _reference).cast<String>();

final Parser<GitGraphCommitType> _commitType = (string('NORMAL') | string('REVERSE') | string('HIGHLIGHT')).map(
  (value) => switch (value) {
    'NORMAL' => GitGraphCommitType.normal,
    'REVERSE' => GitGraphCommitType.reverse,
    'HIGHLIGHT' => GitGraphCommitType.highlight,
    _ => throw StateError('unreachable commit type'),
  },
);

Parser<_Property> _quotedProperty(String name) =>
    (string('$name:') & horizontalSpaceParser & _quotedValue).map((value) => _Property(name, value[2] as String));

final Parser<_Property> _typeProperty = (string('type:') & horizontalSpaceParser & _commitType).map(
  (value) => _Property('type', value[2] as GitGraphCommitType),
);

final Parser<_Property> _messageProperty = ((string('msg:') & horizontalSpaceParser).optional() & _quotedValue).map(
  (value) => _Property('message', value[1] as String),
);

final Parser<GitGraphCommitAst> _commit =
    (string('commit') &
            (pattern(' \t').plus() &
                    (_quotedProperty('id') | _messageProperty | _quotedProperty('tag') | _typeProperty))
                .star() &
            horizontalSpaceParser &
            lineEndParser)
        .map((value) {
          String? id;
          String? message;
          GitGraphCommitType? type;
          final tags = <String>[];
          for (final property in _properties(value)) {
            switch (property.name) {
              case 'id':
                id = property.value as String;
              case 'message':
                message = property.value as String;
              case 'tag':
                tags.add(property.value as String);
              case 'type':
                type = property.value as GitGraphCommitType;
            }
          }
          return GitGraphCommitAst(id: id, message: message, tags: List.unmodifiable(tags), type: type);
        });

final Parser<GitGraphBranchAst> _branch =
    (string('branch') &
            pattern(' \t').plus() &
            _name &
            (pattern(' \t').plus() & string('order:') & horizontalSpaceParser & digit().plus().flatten().map(int.parse))
                .optional() &
            horizontalSpaceParser &
            lineEndParser)
        .map((value) {
          final integers = _values<int>(value);
          return GitGraphBranchAst(name: value[2] as String, order: integers.firstOrNull);
        });

final Parser<GitGraphMergeAst> _merge =
    (string('merge') &
            pattern(' \t').plus() &
            _name &
            (pattern(' \t').plus() & (_quotedProperty('id') | _quotedProperty('tag') | _typeProperty)).star() &
            horizontalSpaceParser &
            lineEndParser)
        .map((value) {
          String? id;
          GitGraphCommitType? type;
          final tags = <String>[];
          for (final property in _properties(value)) {
            switch (property.name) {
              case 'id':
                id = property.value as String;
              case 'tag':
                tags.add(property.value as String);
              case 'type':
                type = property.value as GitGraphCommitType;
            }
          }
          return GitGraphMergeAst(branch: value[2] as String, id: id, tags: List.unmodifiable(tags), type: type);
        });

final Parser<GitGraphCheckoutAst> _checkout =
    ((string('checkout') | string('switch')) & pattern(' \t').plus() & _name & horizontalSpaceParser & lineEndParser)
        .map((value) {
          return GitGraphCheckoutAst(branch: value[2] as String);
        });

final Parser<GitGraphCherryPickAst> _cherryPick =
    (string('cherry-pick') &
            (pattern(' \t').plus() & (_quotedProperty('id') | _quotedProperty('tag') | _quotedProperty('parent')))
                .star() &
            horizontalSpaceParser &
            lineEndParser)
        .map((value) {
          String? id;
          String? parent;
          final tags = <String>[];
          for (final property in _properties(value)) {
            switch (property.name) {
              case 'id':
                id = property.value as String;
              case 'parent':
                parent = property.value as String;
              case 'tag':
                tags.add(property.value as String);
            }
          }
          return GitGraphCherryPickAst(id: id, parent: parent, tags: List.unmodifiable(tags));
        });

final Parser<_Header> _header =
    (string('gitGraph') &
            horizontalSpaceParser &
            (((string('LR') | string('TB') | string('BT')) & horizontalSpaceParser & char(':')) | char(':')).optional())
        .map((value) {
          final direction = _values<String>(value).where((part) => part == 'LR' || part == 'TB' || part == 'BT');
          return _Header(
            direction.isEmpty
                ? null
                : switch (direction.single) {
                    'LR' => GitGraphDirection.leftToRight,
                    'TB' => GitGraphDirection.topToBottom,
                    'BT' => GitGraphDirection.bottomToTop,
                    _ => throw StateError('unreachable direction'),
                  },
          );
        });

final Parser<Object?> _gitGraphGrammar =
    (whitespaceParser &
            _header &
            (whitespaceParser & (commonMetadataParser | _commit | _branch | _merge | _checkout | _cherryPick)).star() &
            whitespaceParser)
        .end();

GitGraphAst parseGitGraph(String source) {
  final visibleSource = hideIgnoredSyntax(source);
  final result = _gitGraphGrammar.parse(visibleSource);
  if (result is Failure) throwParseFailure(source, result);

  _Header? header;
  final statements = <GitGraphStatementAst>[];
  void collect(Object? value) {
    switch (value) {
      case _Header():
        header = value;
      case GitGraphStatementAst():
        statements.add(value);
      case Iterable<Object?>():
        value.forEach(collect);
    }
  }

  collect(result.value);
  final metadata = readCommonMetadata(visibleSource);
  return GitGraphAst(
    direction: header?.direction,
    statements: List.unmodifiable(statements),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}

List<_Property> _properties(Object? value) => _values<_Property>(value);

List<T> _values<T>(Object? value) {
  final values = <T>[];
  void collect(Object? part) {
    switch (part) {
      case T():
        values.add(part);
      case Iterable<Object?>():
        part.forEach(collect);
    }
  }

  collect(value);
  return values;
}
