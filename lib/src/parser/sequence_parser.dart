import 'dart:convert';

import 'ast.dart';
import 'common_syntax.dart';

/// Parses Mermaid `sequenceDiagram` syntax.
SequenceAst parseSequence(String source) {
  // Jison tokenizes a semicolon as a newline, including immediately after the
  // header. Replace only that delimiter with equal-width whitespace before the
  // shared header pass so all original diagnostic offsets remain valid.
  final normalized = source.replaceFirstMapped(RegExp(r'^(\s*sequenceDiagram);'), (match) => '${match.group(1)} ');
  final prepared = prepareDiagramSource(normalized, headers: const ['sequenceDiagram']);
  return _SequenceParser(source, prepared).parse();
}

final class _SequenceParser {
  _SequenceParser(this.source, this.prepared) : lines = _sequenceSourceLines(prepared.syntax);

  final String source;
  final PreparedDiagramSource prepared;
  final List<SourceLine> lines;
  final participants = <String, _MutableSequenceParticipant>{};
  final boxes = <SequenceBoxAst>[];
  var index = 0;
  var messageIndex = 0;
  SequenceAutoNumberAst? autoNumber;
  String? pendingCreated;
  String? pendingDestroyed;

  SequenceAst parse() {
    final statements = _parseStatements(const {});
    if (pendingCreated case final id?) {
      _fail("Created participant '$id' must be followed by a message to it");
    }
    if (pendingDestroyed case final id?) {
      _fail("Destroyed participant '$id' must be followed by a message involving it");
    }
    return SequenceAst(
      participants: [for (final participant in participants.values) participant.freeze()],
      statements: statements,
      boxes: List.unmodifiable(boxes),
      autoNumber: autoNumber,
      title: prepared.metadata.title,
      accessibilityTitle: prepared.metadata.accessibilityTitle,
      accessibilityDescription: prepared.metadata.accessibilityDescription,
    );
  }

  List<SequenceStatementAst> _parseStatements(Set<String> terminators) {
    final statements = <SequenceStatementAst>[];
    while (index < lines.length) {
      final line = lines[index];
      final text = line.text.trim();
      if (text.isEmpty) {
        index++;
        continue;
      }
      final keyword = _keyword(text);
      if (terminators.contains(keyword)) break;

      if (keyword == 'end') {
        _fail('Unexpected end', line);
      } else if (keyword == 'participant' || keyword == 'actor') {
        _parseParticipant(text, line);
        index++;
      } else if (keyword == 'create') {
        _parseParticipant(text.substring('create'.length).trim(), line, created: true);
        index++;
      } else if (keyword == 'destroy') {
        final id = text.substring('destroy'.length).trim();
        if (id.isEmpty) _fail('Expected participant after destroy', line);
        _participant(id);
        participants[id]!.destroyedAt = messageIndex;
        pendingDestroyed = id;
        index++;
      } else if (keyword == 'box') {
        _parseBox(line, text);
      } else if (_blockKinds.containsKey(keyword)) {
        statements.add(_parseBlock(line, text, keyword));
      } else if (keyword == 'rect') {
        statements.add(_parseRect(line, text));
      } else if (keyword == 'note') {
        statements.add(_parseNote(line, text));
        index++;
      } else if (keyword == 'activate' || keyword == 'deactivate') {
        final id = text.substring(keyword.length).trim();
        if (id.isEmpty) _fail('Expected participant after $keyword', line);
        _participant(id);
        statements.add(SequenceActivationAst(participantId: id, active: keyword == 'activate'));
        index++;
      } else if (keyword == 'autonumber') {
        _parseAutoNumber(line, text);
        index++;
      } else if (keyword == 'links' || keyword == 'link' || keyword == 'properties') {
        _parseParticipantData(line, text, keyword);
        index++;
      } else if (keyword == 'details') {
        // Mermaid resolves `details` through a browser DOM element. The pure
        // Dart parser retains the participant but has no external DOM payload.
        final id = _beforeColon(text.substring(keyword.length).trim());
        if (id.isNotEmpty) _participant(id);
        index++;
      } else {
        statements.add(_parseMessage(line, text));
        index++;
      }
    }
    return List.unmodifiable(statements);
  }

  void _parseParticipant(String text, SourceLine line, {bool created = false}) {
    final match = RegExp(r'^(participant|actor)\s+(.+)$', caseSensitive: false).firstMatch(text);
    if (match == null) _fail('Expected participant or actor declaration', line);
    final declaredKind = match.group(1)!.toLowerCase() == 'actor'
        ? SequenceParticipantKind.actor
        : SequenceParticipantKind.participant;
    var declaration = match.group(2)!.trim();
    final configMatch = RegExp(r'@\{([\s\S]*?)\}').firstMatch(declaration);
    final config = configMatch?.group(1);
    if (configMatch != null) {
      declaration = declaration.replaceRange(configMatch.start, configMatch.end, '').trim();
    }
    final aliasMatch = RegExp(r'^(.+?)\s+as\s+(.+)$', caseSensitive: false).firstMatch(declaration);
    final id = (aliasMatch?.group(1) ?? declaration).trim();
    var label = (aliasMatch?.group(2) ?? id).trim();
    if (id.isEmpty) _fail('Expected participant identifier', line);

    var kind = declaredKind;
    if (config != null) {
      final type = RegExp(r'''(?:^|[,{\s])["']?type["']?\s*:\s*["']?([\w-]+)''').firstMatch(config)?.group(1);
      final alias = RegExp(r'''(?:^|[,{\s])["']?alias["']?\s*:\s*["']([^"']+)''').firstMatch(config)?.group(1);
      kind = _participantKind(type) ?? kind;
      if (alias != null && aliasMatch == null) label = alias;
    }

    final participant = _participant(id, label: label, kind: kind);
    if (created) {
      if (participant.createdAt != null) {
        _fail("Participant '$id' is already declared as created", line);
      }
      participant.createdAt = messageIndex;
      pendingCreated = id;
    }
  }

  void _parseBox(SourceLine opener, String text) {
    final data = _boxData(text.substring('box'.length).trim());
    index++;
    final ids = <String>[];
    while (index < lines.length) {
      final line = lines[index];
      final current = line.text.trim();
      if (current.isEmpty) {
        index++;
        continue;
      }
      final keyword = _keyword(current);
      if (keyword == 'end') {
        index++;
        boxes.add(SequenceBoxAst(label: data.label, color: data.color, participantIds: List.unmodifiable(ids)));
        return;
      }
      if (keyword != 'participant' && keyword != 'actor') {
        _fail('Only participant declarations are allowed directly inside a box', line);
      }
      _parseParticipant(current, line);
      final declaration = RegExp(
        r'^(?:participant|actor)\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(current)!.group(1)!;
      final id = declaration
          .replaceFirst(RegExp(r'@\{[\s\S]*?\}'), '')
          .split(RegExp(r'\s+as\s+', caseSensitive: false))
          .first
          .trim();
      ids.add(id);
      index++;
    }
    _fail('Unterminated box', opener);
  }

  SequenceBlockAst _parseBlock(SourceLine opener, String text, String keyword) {
    final kind = _blockKinds[keyword]!;
    final separators = switch (kind) {
      SequenceBlockKind.alt => const {'else', 'end'},
      SequenceBlockKind.par || SequenceBlockKind.parOver => const {'and', 'end'},
      SequenceBlockKind.critical => const {'option', 'end'},
      _ => const {'end'},
    };
    final sections = <SequenceBlockSectionAst>[];
    var label = _messageText(text.substring(keyword.length));
    index++;

    while (true) {
      final statements = _parseStatements(separators);
      sections.add(SequenceBlockSectionAst(label: label, statements: statements));
      if (index >= lines.length) _fail('Unterminated $keyword block', opener);
      final line = lines[index];
      final separatorText = line.text.trim();
      final separator = _keyword(separatorText);
      if (separator == 'end') {
        index++;
        break;
      }
      label = _messageText(separatorText.substring(separator.length));
      index++;
    }
    return SequenceBlockAst(kind: kind, sections: List.unmodifiable(sections));
  }

  SequenceRectAst _parseRect(SourceLine opener, String text) {
    final color = _messageText(text.substring('rect'.length));
    index++;
    final statements = _parseStatements(const {'end'});
    if (index >= lines.length) _fail('Unterminated rect block', opener);
    index++;
    return SequenceRectAst(color: color, statements: statements);
  }

  SequenceNoteAst _parseNote(SourceLine line, String text) {
    final match = RegExp(
      r'^note\s+(left\s+of|right\s+of|over)\s+([^:]+)\s*:(.*)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) _fail('Invalid note statement', line);
    final placement = switch (match.group(1)!.toLowerCase().replaceAll(RegExp(r'\s+'), ' ')) {
      'left of' => SequenceNotePlacement.leftOf,
      'right of' => SequenceNotePlacement.rightOf,
      _ => SequenceNotePlacement.over,
    };
    final ids = match.group(2)!.split(',').map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty || ids.length > 2) _fail('A note must reference one or two participants', line);
    for (final id in ids) {
      _participant(id);
    }
    return SequenceNoteAst(
      participantIds: List.unmodifiable(ids),
      text: _messageText(match.group(3)!),
      placement: placement,
    );
  }

  void _parseAutoNumber(SourceLine line, String text) {
    final values = text.substring('autonumber'.length).trim().split(RegExp(r'\s+'));
    if (values.length == 1 && values.single.toLowerCase() == 'off') {
      autoNumber = const SequenceAutoNumberAst(visible: false);
      return;
    }
    if (values.length == 1 && values.single.isEmpty) {
      autoNumber = const SequenceAutoNumberAst();
      return;
    }
    if (values.length > 2) _fail('Expected autonumber, autonumber off, or autonumber START [STEP]', line);
    final start = num.tryParse(values.first);
    final step = values.length == 2 ? num.tryParse(values.last) : 1;
    if (start == null || step == null) _fail('Invalid autonumber value', line);
    autoNumber = SequenceAutoNumberAst(start: start, step: step);
  }

  void _parseParticipantData(SourceLine line, String text, String keyword) {
    final rest = text.substring(keyword.length).trim();
    final colon = rest.indexOf(':');
    if (colon < 1) _fail('Expected $keyword PARTICIPANT: data', line);
    final id = rest.substring(0, colon).trim();
    final data = _messageText(rest.substring(colon + 1));
    final participant = _participant(id);
    try {
      if (keyword == 'link') {
        final separator = data.indexOf('@');
        if (separator <= 0) _fail('Expected link label @ destination', line);
        participant.links[data.substring(0, separator).trim()] = data.substring(separator + 1).trim();
      } else {
        final decoded = jsonDecode(data);
        if (decoded is! Map) _fail('Expected a JSON object', line);
        if (keyword == 'links') {
          participant.links.addAll(decoded.map((key, value) => MapEntry('$key', '$value')));
        } else {
          participant.properties.addAll(decoded.map((key, value) => MapEntry('$key', value)));
        }
      }
    } on FormatException {
      _fail('Invalid JSON in $keyword statement', line);
    }
  }

  SequenceMessageAst _parseMessage(SourceLine line, String text) {
    final colon = text.indexOf(':');
    if (colon < 0) _fail('Expected a sequence message', line);
    final relation = text.substring(0, colon).trim();
    final message = _messageText(text.substring(colon + 1));
    final match = _findArrow(relation);
    if (match == null) _fail('Expected a sequence message arrow', line);

    var from = relation.substring(0, match.start).trim();
    var remainder = relation.substring(match.end).trim();
    var activateTarget = false;
    var deactivateSource = false;
    if (remainder.startsWith('+')) {
      activateTarget = true;
      remainder = remainder.substring(1).trim();
    } else if (remainder.startsWith('-')) {
      deactivateSource = true;
      remainder = remainder.substring(1).trim();
    }
    from = from.replaceAll('()', '').trim();
    final to = remainder.replaceAll('()', '').trim();
    if (from.isEmpty || to.isEmpty) _fail('Expected participants on both sides of the message', line);
    _participant(from);
    _participant(to);

    if (pendingCreated case final id?) {
      if (to != id) _fail("Created participant '$id' must be the destination of the next message", line);
      pendingCreated = null;
    }
    if (pendingDestroyed case final id?) {
      if (from != id && to != id) _fail("Destroyed participant '$id' must be involved in the next message", line);
      pendingDestroyed = null;
    }

    messageIndex++;
    return SequenceMessageAst(
      from: from,
      to: to,
      text: message,
      arrow: match.arrow,
      activateTarget: activateTarget,
      deactivateSource: deactivateSource,
    );
  }

  _MutableSequenceParticipant _participant(
    String id, {
    String? label,
    SequenceParticipantKind kind = SequenceParticipantKind.participant,
  }) {
    final existing = participants[id];
    if (existing != null) {
      if (label != null) existing.label = label;
      if (kind != SequenceParticipantKind.participant) existing.kind = kind;
      return existing;
    }
    return participants[id] = _MutableSequenceParticipant(id: id, label: label ?? id, kind: kind);
  }

  Never _fail(String message, [SourceLine? line]) {
    final target = line ?? (index < lines.length ? lines[index] : (lines.isEmpty ? null : lines.last));
    throwParseError(source, message, target?.offset ?? source.length);
  }
}

const _blockKinds = <String, SequenceBlockKind>{
  'loop': SequenceBlockKind.loop,
  'opt': SequenceBlockKind.opt,
  'alt': SequenceBlockKind.alt,
  'par': SequenceBlockKind.par,
  'par_over': SequenceBlockKind.parOver,
  'critical': SequenceBlockKind.critical,
  'break': SequenceBlockKind.breakBlock,
};

String _keyword(String text) => text.split(RegExp(r'\s+')).first.toLowerCase();

String _beforeColon(String text) {
  final colon = text.indexOf(':');
  return (colon < 0 ? text : text.substring(0, colon)).trim();
}

String _messageText(String text) =>
    text.trim().replaceFirst(RegExp(r'^:?(?:no)?wrap:', caseSensitive: false), '').trim();

({String color, String label}) _boxData(String text) {
  final functional = RegExp(r'^((?:rgba?|hsla?)\s*\([^)]*\))\s*(.*)$', caseSensitive: false).firstMatch(text);
  if (functional != null) {
    return (color: functional.group(1)!.trim(), label: _messageText(functional.group(2)!));
  }
  final words = text.trim().split(RegExp(r'\s+'));
  const namedColors = {
    'transparent',
    'black',
    'white',
    'red',
    'green',
    'blue',
    'yellow',
    'gray',
    'grey',
    'orange',
    'purple',
    'pink',
  };
  if (words.isNotEmpty && namedColors.contains(words.first.toLowerCase())) {
    return (color: words.first, label: _messageText(words.skip(1).join(' ')));
  }
  return (color: 'transparent', label: _messageText(text));
}

SequenceParticipantKind? _participantKind(String? type) => switch (type?.toLowerCase()) {
  'participant' => SequenceParticipantKind.participant,
  'actor' => SequenceParticipantKind.actor,
  'boundary' => SequenceParticipantKind.boundary,
  'control' => SequenceParticipantKind.control,
  'entity' => SequenceParticipantKind.entity,
  'database' => SequenceParticipantKind.database,
  'collections' => SequenceParticipantKind.collections,
  'queue' => SequenceParticipantKind.queue,
  _ => null,
};

final _arrows = <String, SequenceArrow>{
  '<<-->>': SequenceArrow.bidirectionalDotted,
  '<<->>': SequenceArrow.bidirectionalSolid,
  '-->>': SequenceArrow.dotted,
  '->>': SequenceArrow.solid,
  '-->': SequenceArrow.dottedOpen,
  '->': SequenceArrow.solidOpen,
  '--x': SequenceArrow.dottedCross,
  '-x': SequenceArrow.solidCross,
  '--)': SequenceArrow.dottedPoint,
  '-)': SequenceArrow.solidPoint,
  '--|\\': SequenceArrow.solidTopDotted,
  '--|/': SequenceArrow.solidBottomDotted,
  '--\\\\': SequenceArrow.stickTopDotted,
  '--//': SequenceArrow.stickBottomDotted,
  '/|--': SequenceArrow.solidTopReverseDotted,
  '\\|--': SequenceArrow.solidBottomReverseDotted,
  '//--': SequenceArrow.stickTopReverseDotted,
  '\\\\--': SequenceArrow.stickBottomReverseDotted,
  '-|\\': SequenceArrow.solidTop,
  '-|/': SequenceArrow.solidBottom,
  '-\\\\': SequenceArrow.stickTop,
  '-//': SequenceArrow.stickBottom,
  '/|-': SequenceArrow.solidTopReverse,
  '\\|-': SequenceArrow.solidBottomReverse,
  '//-': SequenceArrow.stickTopReverse,
  '\\\\-': SequenceArrow.stickBottomReverse,
};

({int start, int end, SequenceArrow arrow})? _findArrow(String relation) {
  ({int start, int end, SequenceArrow arrow})? best;
  for (final entry in _arrows.entries) {
    final start = relation.indexOf(entry.key);
    if (start < 0) continue;
    if (best == null || start < best.start || start == best.start && entry.key.length > best.end - best.start) {
      best = (start: start, end: start + entry.key.length, arrow: entry.value);
    }
  }
  return best;
}

final class _MutableSequenceParticipant {
  _MutableSequenceParticipant({required this.id, required this.label, required this.kind});

  final String id;
  String label;
  SequenceParticipantKind kind;
  int? createdAt;
  int? destroyedAt;
  final links = <String, String>{};
  final properties = <String, Object?>{};

  SequenceParticipantAst freeze() => SequenceParticipantAst(
    id: id,
    label: label,
    kind: kind,
    createdAt: createdAt,
    destroyedAt: destroyedAt,
    links: Map.unmodifiable(links),
    properties: Map.unmodifiable(properties),
  );
}

List<SourceLine> _sequenceSourceLines(String source) {
  final result = <SourceLine>[];
  for (final line in sourceLines(source)) {
    final comment = line.text.indexOf('#');
    final text = comment < 0 ? line.text : line.text.substring(0, comment);
    var start = 0;
    for (var index = 0; index <= text.length; index++) {
      if (index != text.length && text.codeUnitAt(index) != 59) continue;
      result.add(SourceLine(text: text.substring(start, index), offset: line.offset + start));
      start = index + 1;
    }
  }
  return result;
}
