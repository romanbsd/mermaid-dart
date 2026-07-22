import 'ast.dart';
import 'common_syntax.dart';

final RegExp _eventModelHeader = RegExp(r'^[\t \r\n]*eventmodeling(?![\w])');
final RegExp _identifierPattern = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');
final RegExp _frameIdentifierPattern = RegExp(r'\d{1,3}(?!\d)');

const _entityTypes = {
  'rmo': EventModelEntityType.readModel,
  'readmodel': EventModelEntityType.readModel,
  'ui': EventModelEntityType.ui,
  'cmd': EventModelEntityType.command,
  'command': EventModelEntityType.command,
  'evt': EventModelEntityType.event,
  'event': EventModelEntityType.event,
  'pcr': EventModelEntityType.processor,
  'processor': EventModelEntityType.processor,
};

const _dataTypes = {
  'json': EventModelDataType.json,
  'jsobj': EventModelDataType.javaScriptObject,
  'figma': EventModelDataType.figma,
  'salt': EventModelDataType.salt,
  'uri': EventModelDataType.uri,
  'md': EventModelDataType.markdown,
  'html': EventModelDataType.html,
  'text': EventModelDataType.text,
};

EventModelingAst parseEventModeling(String source) {
  final visibleSource = hideIgnoredSyntax(source);
  final commentHiddenSource = _hideEventModelComments(visibleSource);
  final metadataSource = _hideEventModelDataBlocks(commentHiddenSource);

  final header = _eventModelHeader.firstMatch(commentHiddenSource);
  if (header == null) {
    final offset = RegExp(r'\S').firstMatch(visibleSource)?.start ?? 0;
    throwParseError(source, 'Expected "eventmodeling"', offset);
  }

  final metadata = readCommonMetadata(metadataSource);
  final hiddenMetadataSource = hideCommonMetadata(metadataSource);
  final syntaxSource = String.fromCharCodes([
    for (var offset = 0; offset < visibleSource.length; offset++)
      metadataSource.codeUnitAt(offset) == hiddenMetadataSource.codeUnitAt(offset)
          ? visibleSource.codeUnitAt(offset)
          : hiddenMetadataSource.codeUnitAt(offset),
  ]);
  final scanner = _EventModelScanner(syntaxSource, source, header.end);
  final modelEntities = <EventModelEntityAst>[];
  final frames = <EventModelFrameAst>[];
  final dataEntities = <EventModelDataEntityAst>[];
  final notes = <EventModelNoteAst>[];
  final scenarios = <EventModelScenarioAst>[];

  while (!scanner.isAtEnd) {
    switch (scanner.peekWord()) {
      case 'tf' || 'timeframe':
        frames.add(scanner.parseFrame(reset: false));
      case 'rf' || 'resetframe':
        frames.add(scanner.parseFrame(reset: true));
      case 'entity':
        scanner.takeWord('entity');
        modelEntities.add(EventModelEntityAst(name: scanner.takeQualifiedName()));
      case 'data':
        scanner.takeWord('data');
        final name = scanner.takeIdentifier();
        final dataType = scanner.takeOptionalDataType();
        dataEntities.add(EventModelDataEntityAst(name: name, dataType: dataType, value: scanner.takeDataBlock()));
      case 'note':
        scanner.takeWord('note');
        final sourceFrame = scanner.takeFrameIdentifier();
        final dataType = scanner.takeOptionalDataType();
        notes.add(EventModelNoteAst(sourceFrame: sourceFrame, dataType: dataType, value: scanner.takeDataBlock()));
      case 'gwt':
        scenarios.add(scanner.parseScenario());
      case final token:
        scanner.fail('Unexpected event model token${token == null ? '' : ' "$token"'}');
    }
  }

  return EventModelingAst(
    modelEntities: List.unmodifiable(modelEntities),
    frames: List.unmodifiable(frames),
    dataEntities: List.unmodifiable(dataEntities),
    notes: List.unmodifiable(notes),
    scenarios: List.unmodifiable(scenarios),
    title: metadata.title,
    accessibilityTitle: metadata.accessibilityTitle,
    accessibilityDescription: metadata.accessibilityDescription,
  );
}

String _hideEventModelComments(String source) {
  var result = source;
  for (final expression in [RegExp(r'/\*[\s\S]*?\*/'), RegExp(r'//[^\n\r]*')]) {
    result = result.replaceAllMapped(expression, (match) {
      return match.group(0)!.replaceAll(RegExp(r'[^\r\n]'), ' ');
    });
  }
  return result;
}

String _hideEventModelDataBlocks(String source) => source.replaceAllMapped(
  RegExp(r'\{[\t ]*\r?\n(?:[\s\S]*?\r?\n)?\}'),
  (match) => match.group(0)!.replaceAll(RegExp(r'[^\r\n]'), ' '),
);

final class _EventModelScanner {
  _EventModelScanner(this.text, this.originalSource, this.index);

  final String text;
  final String originalSource;
  int index;

  bool get isAtEnd {
    skipWhitespace();
    return index >= text.length;
  }

  void skipWhitespace() {
    while (index < text.length) {
      if (RegExp(r'\s').hasMatch(text[index])) {
        index++;
        continue;
      }
      if (text.startsWith('//', index)) {
        final newline = text.indexOf('\n', index + 2);
        index = newline < 0 ? text.length : newline + 1;
        continue;
      }
      if (text.startsWith('/*', index)) {
        final closing = text.indexOf('*/', index + 2);
        if (closing < 0) fail('Unterminated block comment');
        index = closing + 2;
        continue;
      }
      break;
    }
  }

  String? peekWord() {
    skipWhitespace();
    return _identifierPattern.matchAsPrefix(text, index)?.group(0);
  }

  String takeWord([String? expected]) {
    skipWhitespace();
    final match = _identifierPattern.matchAsPrefix(text, index);
    if (match == null || expected != null && match.group(0) != expected) {
      fail(expected == null ? 'Expected identifier' : 'Expected "$expected"');
    }
    index = match.end;
    return match.group(0)!;
  }

  String takeIdentifier() => takeWord();

  String takeQualifiedName() {
    final result = StringBuffer(takeIdentifier());
    while (true) {
      skipWhitespace();
      if (!_consume('.')) break;
      result
        ..write('.')
        ..write(takeIdentifier());
    }
    return result.toString();
  }

  String takeFrameIdentifier() {
    skipWhitespace();
    final match = _frameIdentifierPattern.matchAsPrefix(text, index);
    if (match == null) fail('Expected a one-to-three digit frame identifier');
    index = match.end;
    return match.group(0)!;
  }

  EventModelEntityType takeEntityType() {
    final lexeme = takeWord();
    return _entityTypes[lexeme] ?? (fail('Unknown model entity type "$lexeme"'));
  }

  EventModelDataType? takeOptionalDataType() {
    skipWhitespace();
    if (!_consume('`')) return null;
    final lexeme = takeWord();
    if (!_consume('`')) fail('Expected closing data type backtick');
    return _dataTypes[lexeme] ?? (fail('Unknown data type "$lexeme"'));
  }

  EventModelFrameAst parseFrame({required bool reset}) {
    final keyword = takeWord();
    final validKeyword = reset ? keyword == 'rf' || keyword == 'resetframe' : keyword == 'tf' || keyword == 'timeframe';
    if (!validKeyword) fail('Unexpected frame keyword "$keyword"');
    final name = takeFrameIdentifier();
    final entityType = takeEntityType();
    final entityIdentifier = takeQualifiedName();
    final sourceFrames = <String>[];
    while (true) {
      skipWhitespace();
      if (!_consume('->>')) break;
      sourceFrames.add(takeFrameIdentifier());
    }

    skipWhitespace();
    String? dataReference;
    if (_consume('[[')) {
      dataReference = takeIdentifier();
      skipWhitespace();
      if (!_consume(']]')) fail('Expected closing data reference brackets');
    }

    final dataType = takeOptionalDataType();
    final dataInlineValue = _takeOptionalInlineData();
    if (dataType != null && dataInlineValue == null) {
      fail('Expected inline data after data type');
    }
    final immutableSources = List<String>.unmodifiable(sourceFrames);
    return reset
        ? EventModelResetFrameAst(
            name: name,
            entityType: entityType,
            entityIdentifier: entityIdentifier,
            sourceFrames: immutableSources,
            dataReference: dataReference,
            dataType: dataType,
            dataInlineValue: dataInlineValue,
          )
        : EventModelTimeFrameAst(
            name: name,
            entityType: entityType,
            entityIdentifier: entityIdentifier,
            sourceFrames: immutableSources,
            dataReference: dataReference,
            dataType: dataType,
            dataInlineValue: dataInlineValue,
          );
  }

  String? _takeOptionalInlineData() {
    skipWhitespace();
    if (index >= text.length) return null;
    final delimiter = text[index];
    if (delimiter != '{' && delimiter != '"' && delimiter != "'") return null;
    final newline = text.indexOf('\n', index);
    final lineEnd = newline < 0 ? text.length : newline;
    final closing = delimiter == '{' ? _findMatchingBrace(lineEnd) : _findMatchingQuote(delimiter, lineEnd);
    if (closing < 0) fail('Unterminated inline data');
    final value = text.substring(index, closing + 1);
    index = closing + 1;
    return value;
  }

  int _findMatchingQuote(String delimiter, int lineEnd) {
    for (var cursor = index + 1; cursor < lineEnd; cursor++) {
      if (text[cursor] == '\\') {
        cursor++;
      } else if (text[cursor] == delimiter) {
        return cursor;
      }
    }
    return -1;
  }

  int _findMatchingBrace(int lineEnd) {
    var depth = 0;
    String? quote;
    for (var cursor = index; cursor < lineEnd; cursor++) {
      final character = text[cursor];
      if (quote case final delimiter?) {
        if (character == '\\') {
          cursor++;
        } else if (character == delimiter) {
          quote = null;
        }
      } else if (character == '"' || character == "'") {
        quote = character;
      } else if (character == '{') {
        depth++;
      } else if (character == '}' && --depth == 0) {
        return cursor;
      }
    }
    return -1;
  }

  String takeDataBlock() {
    skipWhitespace();
    final match = RegExp(r'\{[\t ]*\r?\n(?:[\s\S]*?\r?\n)?\}').matchAsPrefix(text, index);
    if (match == null) fail('Expected multiline data block');
    index = match.end;
    return match.group(0)!;
  }

  EventModelScenarioAst parseScenario() {
    takeWord('gwt');
    final sourceFrame = takeFrameIdentifier();
    takeWord('given');
    final given = _takeStatementsUntil({'when', 'then'});
    if (given.isEmpty) fail('Expected at least one given statement');

    final when = <EventModelStatementAst>[];
    if (peekWord() == 'when') {
      takeWord('when');
      when.addAll(_takeStatementsUntil({'then'}));
      if (when.isEmpty) fail('Expected at least one when statement');
    }
    takeWord('then');
    final then = _takeStatementsUntil(const {});
    if (then.isEmpty) fail('Expected at least one then statement');
    return EventModelScenarioAst(
      sourceFrame: sourceFrame,
      given: List.unmodifiable(given),
      when: List.unmodifiable(when),
      then: List.unmodifiable(then),
    );
  }

  List<EventModelStatementAst> _takeStatementsUntil(Set<String> terminators) {
    final statements = <EventModelStatementAst>[];
    while (true) {
      final word = peekWord();
      if (word == null || terminators.contains(word) || !_entityTypes.containsKey(word)) break;
      statements.add(EventModelStatementAst(entityType: takeEntityType(), entityIdentifier: takeIdentifier()));
    }
    return statements;
  }

  bool _consume(String value) {
    if (!text.startsWith(value, index)) return false;
    index += value.length;
    return true;
  }

  Never fail(String message) => throwParseError(originalSource, message, index);
}
