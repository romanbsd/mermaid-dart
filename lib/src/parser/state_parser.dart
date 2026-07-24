import 'ast.dart';
import 'common_syntax.dart';
import 'graph_syntax.dart';

/// Parses Mermaid `stateDiagram` and `stateDiagram-v2` source.
StateDiagramAst parseStateDiagram(String source) {
  final prepared = prepareDiagramSource(source, headers: const ['stateDiagram-v2', 'stateDiagram']);
  return _StateParser(source, sourceLines(prepared.syntax), prepared.metadata).parse();
}

final class _StateParser {
  _StateParser(this.source, this.lines, this.metadata);

  final String source;
  final List<SourceLine> lines;
  final CommonMetadata metadata;
  final Map<String, Map<String, String>> classDefinitions = {};
  var index = 0;
  var specialCounter = 0;
  var hideEmptyDescriptions = false;

  StateDiagramAst parse() {
    final scope = _parseScope();
    return StateDiagramAst(
      direction: scope.direction ?? GraphDirection.topDown,
      states: scope.states.values.map((state) => state.freeze()).toList(growable: false),
      transitions: List.unmodifiable(scope.transitions),
      hideEmptyDescriptions: hideEmptyDescriptions,
      classDefinitions: freezeGraphClassDefinitions(classDefinitions),
      title: metadata.title,
      accessibilityTitle: metadata.accessibilityTitle,
      accessibilityDescription: metadata.accessibilityDescription,
    );
  }

  _StateScope _parseScope({int? openingOffset}) {
    final scope = _StateScope();
    while (index < lines.length) {
      final line = lines[index];
      final text = line.text.trim();
      index++;
      if (text.isEmpty) continue;
      if (text == '}') {
        if (openingOffset == null) throwGraphLineError(source, line, 'Unexpected closing brace');
        return scope;
      }
      if (parseGraphDirectionStatement(text) case final direction?) {
        scope.direction = direction;
        continue;
      }
      if (text.toLowerCase() == 'hide empty description') {
        hideEmptyDescriptions = true;
        continue;
      }
      final classDef = parseGraphClassDefinition(text);
      if (classDef != null) {
        for (final name in classDef.names) {
          classDefinitions[name] = classDef.styles;
        }
        continue;
      }
      final classAssignment = parseGraphClassAssignment(text);
      if (classAssignment != null) {
        for (final id in classAssignment.ids) {
          mergeCssClasses(_state(scope, id).cssClasses, classAssignment.cssClasses);
        }
        continue;
      }
      final style = parseGraphStyleAssignment(text);
      if (style != null) {
        for (final id in style.ids) {
          _state(scope, id).styles.addAll(style.styles);
        }
        continue;
      }
      final note = RegExp(r'^note\s+(left|right)\s+of\s+([^\s:]+)\s*:\s*(.+)$', caseSensitive: false).firstMatch(text);
      if (note != null) {
        _state(scope, note.group(2)!).note = StateNoteAst(
          text: note.group(3)!.trim(),
          position: note.group(1)!.toLowerCase() == 'left' ? StateNotePosition.left : StateNotePosition.right,
        );
        continue;
      }
      final noteBlock = RegExp(r'^note\s+(left|right)\s+of\s+([^\s:]+)$', caseSensitive: false).firstMatch(text);
      if (noteBlock != null) {
        final noteLines = <String>[];
        var terminated = false;
        while (index < lines.length) {
          final noteLine = lines[index++];
          if (noteLine.text.trim().toLowerCase() == 'end note') {
            terminated = true;
            break;
          }
          noteLines.add(noteLine.text.trim());
        }
        if (!terminated) throwParseError(source, 'Unterminated note', line.offset + line.text.indexOf('note'));
        _state(scope, noteBlock.group(2)!).note = StateNoteAst(
          text: noteLines.join('<br>').replaceAll(RegExp(r'<br\s*/?\s*>', caseSensitive: false), '<br>'),
          position: noteBlock.group(1)!.toLowerCase() == 'left' ? StateNotePosition.left : StateNotePosition.right,
        );
        continue;
      }
      final composite = RegExp(r'^state\s+(.+?)\s*\{$', caseSensitive: false).firstMatch(text);
      if (composite != null) {
        final declaration = _parseStateDeclaration(composite.group(1)!);
        final state = _state(scope, declaration.id, label: declaration.label, type: declaration.type);
        final nested = _parseScope(openingOffset: line.offset + line.text.indexOf('state'));
        state.children
          ..clear()
          ..addAll(nested.states.values);
        state.transitions
          ..clear()
          ..addAll(nested.transitions);
        state.direction = nested.direction;
        continue;
      }
      final stateDeclaration = RegExp(r'^state\s+(.+)$', caseSensitive: false).firstMatch(text);
      if (stateDeclaration != null) {
        final declaration = _parseStateDeclaration(stateDeclaration.group(1)!);
        _state(scope, declaration.id, label: declaration.label, type: declaration.type);
        continue;
      }
      if (text == '--') {
        final id = '__divider_${specialCounter++}';
        _state(scope, id, label: '', type: StateType.divider);
        continue;
      }
      final transition = RegExp(r'^(.+?)\s*-->\s*(.+?)(?:\s*:\s*(.*))?$').firstMatch(text);
      if (transition != null) {
        final from = _transitionState(scope, transition.group(1)!, sourceEndpoint: true);
        final to = _transitionState(scope, transition.group(2)!, sourceEndpoint: false);
        scope.transitions.add(
          StateTransitionAst(
            from: from.id,
            to: to.id,
            label: switch (transition.group(3)?.trim()) {
              final value? when value.isNotEmpty => value,
              _ => null,
            },
          ),
        );
        continue;
      }
      final description = RegExp(r'^([^:]+?)\s*:\s*(.+)$').firstMatch(text);
      if (description != null) {
        _state(scope, description.group(1)!).descriptions.add(description.group(2)!.trim());
        continue;
      }
      final simple = RegExp(r'^([^\s]+)(?:\s*:::\s*([^\s]+))?$').firstMatch(text);
      if (simple != null) {
        final state = _state(scope, simple.group(1)!);
        if (simple.group(2) case final cssClass?) mergeCssClasses(state.cssClasses, parseCssClasses(cssClass));
        continue;
      }
      throwGraphLineError(source, line, 'Unexpected state diagram statement');
    }
    if (openingOffset != null) throwParseError(source, 'Unterminated composite state', openingOffset);
    return scope;
  }

  _MutableState _transitionState(_StateScope scope, String value, {required bool sourceEndpoint}) {
    final id = value.trim();
    if (id != '[*]') return _state(scope, id);
    final type = sourceEndpoint ? StateType.start : StateType.end;
    final specialId = '__${type.name}_${specialCounter++}';
    return _state(scope, specialId, label: '', type: type);
  }

  _MutableState _state(_StateScope scope, String rawId, {String? label, StateType? type}) {
    final id = unquoteGraphText(rawId.trim());
    final local = scope.states[id];
    if (local != null) {
      if (label != null) local.label = label;
      if (type != null) local.type = type;
      return local;
    }
    final state = _MutableState(id, label ?? id, type ?? StateType.normal);
    scope.states[id] = state;
    return state;
  }
}

({String id, String label, StateType type}) _parseStateDeclaration(String source) {
  var body = source.trim();
  var type = StateType.normal;
  final stereotype = RegExp(r'\s*<<\s*(fork|join|choice)\s*>>\s*$', caseSensitive: false).firstMatch(body);
  if (stereotype != null) {
    type = switch (stereotype.group(1)!.toLowerCase()) {
      'fork' => StateType.fork,
      'join' => StateType.join,
      _ => StateType.choice,
    };
    body = body.substring(0, stereotype.start).trim();
  }
  final alias = RegExp(r'^"([^"]*)"\s+as\s+([^\s]+)$', caseSensitive: false).firstMatch(body);
  if (alias != null) return (id: alias.group(2)!, label: alias.group(1)!, type: type);
  final unquotedAlias = RegExp(r'^(.+?)\s+as\s+([^\s]+)$', caseSensitive: false).firstMatch(body);
  if (unquotedAlias != null) return (id: unquotedAlias.group(2)!, label: unquotedAlias.group(1)!.trim(), type: type);
  final id = unquoteGraphText(body);
  return (id: id, label: id, type: type);
}

final class _StateScope {
  final Map<String, _MutableState> states = {};
  final List<StateTransitionAst> transitions = [];
  GraphDirection? direction;
}

final class _MutableState {
  _MutableState(this.id, this.label, this.type);

  final String id;
  String label;
  StateType type;
  final List<String> descriptions = [];
  final List<_MutableState> children = [];
  final List<StateTransitionAst> transitions = [];
  GraphDirection? direction;
  StateNoteAst? note;
  final List<String> cssClasses = [];
  final Map<String, String> styles = {};

  StateAst freeze() => StateAst(
    id: id,
    label: label,
    type: type,
    descriptions: List.unmodifiable(descriptions),
    children: children.map((state) => state.freeze()).toList(growable: false),
    transitions: List.unmodifiable(transitions),
    direction: direction,
    note: note,
    cssClasses: List.unmodifiable(cssClasses),
    styles: Map.unmodifiable(styles),
  );
}
