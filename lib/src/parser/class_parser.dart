import 'ast.dart';
import 'common_syntax.dart';
import 'graph_syntax.dart';

/// Parses Mermaid `classDiagram` and `classDiagram-v2` source.
ClassDiagramAst parseClassDiagram(String source) {
  final prepared = prepareDiagramSource(source, headers: const ['classDiagram-v2', 'classDiagram']);
  return _ClassParser(source, sourceLines(prepared.syntax), prepared.metadata).parse();
}

final class _ClassParser {
  _ClassParser(this.source, this.lines, this.metadata);

  final String source;
  final List<SourceLine> lines;
  final CommonMetadata metadata;
  final Map<String, _MutableClass> classes = {};
  final List<ClassRelationAst> relations = [];
  final List<ClassNamespaceAst> namespaces = [];
  final List<ClassNoteAst> notes = [];
  final Map<String, Map<String, String>> classDefinitions = {};
  GraphDirection direction = GraphDirection.topDown;
  var index = 0;

  ClassDiagramAst parse() {
    _parseStatements();
    return ClassDiagramAst(
      direction: direction,
      classes: classes.values.map((value) => value.freeze()).toList(growable: false),
      relations: List.unmodifiable(relations),
      namespaces: List.unmodifiable(namespaces),
      notes: List.unmodifiable(notes),
      classDefinitions: freezeGraphClassDefinitions(classDefinitions),
      title: metadata.title,
      accessibilityTitle: metadata.accessibilityTitle,
      accessibilityDescription: metadata.accessibilityDescription,
    );
  }

  void _parseStatements({String? namespaceId, int? openingOffset}) {
    final namespaceClasses = <String>[];
    while (index < lines.length) {
      final line = lines[index];
      final text = line.text.trim();
      index++;
      if (text.isEmpty) continue;
      if (text == '}') {
        if (openingOffset == null) throwGraphLineError(source, line, 'Unexpected closing brace');
        if (namespaceId != null) {
          namespaces.add(
            ClassNamespaceAst(id: namespaceId, label: namespaceId, classIds: List.unmodifiable(namespaceClasses)),
          );
        }
        return;
      }
      final namespaceMatch = RegExp(r'^namespace\s+(.+?)\s*\{$').firstMatch(text);
      if (namespaceMatch != null) {
        final id = unquoteGraphText(namespaceMatch.group(1)!);
        _parseStatements(namespaceId: id, openingOffset: line.offset + line.text.indexOf('namespace'));
        continue;
      }
      final classAssignment = parseGraphClassAssignment(text, caseSensitive: true);
      if (classAssignment != null && !text.contains('<<') && !text.endsWith('{') && !text.contains('[')) {
        for (final id in classAssignment.ids) {
          mergeCssClasses(_class(id, namespaceId: namespaceId).cssClasses, classAssignment.cssClasses);
        }
        continue;
      }
      final classMatch = RegExp(r'^class\s+(.+?)(?:\s*:::\s*([^\s{]+))?\s*(\{\}|\{)?$').firstMatch(text);
      if (classMatch != null) {
        final declaration = _parseClassDeclaration(classMatch.group(1)!);
        final node = _class(declaration.id, label: declaration.label, namespaceId: namespaceId);
        if (declaration.annotation case final annotation?) node.annotations.add(annotation);
        if (namespaceId != null && !namespaceClasses.contains(node.id)) namespaceClasses.add(node.id);
        if (classMatch.group(2) case final cssClass?) mergeCssClasses(node.cssClasses, parseCssClasses(cssClass));
        if (classMatch.group(3) == '{') _parseClassBody(node, line);
        continue;
      }
      if (_parseCommonStatement(text, namespaceId, namespaceClasses)) continue;
      throwGraphLineError(source, line, 'Unexpected class diagram statement');
    }
    if (openingOffset != null) throwParseError(source, 'Unterminated block', openingOffset);
  }

  void _parseClassBody(_MutableClass node, SourceLine declaration) {
    while (index < lines.length) {
      final line = lines[index];
      final text = line.text.trim();
      index++;
      if (text.isEmpty) continue;
      if (text == '}') return;
      final annotation = RegExp(r'^<<\s*(.*?)\s*>>$').firstMatch(text);
      if (annotation != null) {
        node.annotations.add(annotation.group(1)!);
      } else {
        node.members.add(ClassMemberAst(text: text, kind: _memberKind(text)));
      }
    }
    throwParseError(source, 'Unterminated class body', declaration.offset + declaration.text.indexOf('class'));
  }

  bool _parseCommonStatement(String text, String? namespaceId, List<String> namespaceClasses) {
    if (parseGraphDirectionStatement(text) case final parsedDirection?) {
      direction = parsedDirection;
      return true;
    }
    final annotation = RegExp(r'^<<\s*(.*?)\s*>>\s+(.+)$').firstMatch(text);
    if (annotation != null) {
      _class(unquoteGraphText(annotation.group(2)!), namespaceId: namespaceId).annotations.add(annotation.group(1)!);
      return true;
    }
    final noteFor = RegExp(
      r'^note\s+for\s+(.+?)\s+("(?:[^"\\]|\\.)*"|`[^`]*`)$',
      caseSensitive: false,
    ).firstMatch(text);
    if (noteFor != null) {
      final id = unquoteGraphText(noteFor.group(1)!);
      _class(id, namespaceId: namespaceId);
      notes.add(ClassNoteAst(text: unquoteGraphText(noteFor.group(2)!), classId: id));
      return true;
    }
    final note = RegExp(r'^note\s+("(?:[^"\\]|\\.)*"|`[^`]*`)$', caseSensitive: false).firstMatch(text);
    if (note != null) {
      notes.add(ClassNoteAst(text: unquoteGraphText(note.group(1)!)));
      return true;
    }
    final classDef = parseGraphClassDefinition(text, caseSensitive: true);
    if (classDef != null) {
      for (final name in classDef.names) {
        classDefinitions[name] = classDef.styles;
      }
      return true;
    }
    final classAssignment = parseGraphClassAssignment(text, caseSensitive: true);
    if (classAssignment != null) {
      for (final id in classAssignment.ids) {
        mergeCssClasses(_class(id, namespaceId: namespaceId).cssClasses, classAssignment.cssClasses);
      }
      return true;
    }
    final style = parseGraphStyleAssignment(text, caseSensitive: true);
    if (style != null) {
      for (final id in style.ids) {
        _class(id, namespaceId: namespaceId).styles.addAll(style.styles);
      }
      return true;
    }
    final inlineMember = RegExp(r'^(.+?)\s*:\s*(.+)$').firstMatch(text);
    if (inlineMember != null && !_looksLikeRelation(text)) {
      final id = unquoteGraphText(inlineMember.group(1)!);
      final node = _class(id, namespaceId: namespaceId);
      if (namespaceId != null && !namespaceClasses.contains(id)) namespaceClasses.add(id);
      final member = inlineMember.group(2)!.trim();
      node.members.add(ClassMemberAst(text: member, kind: _memberKind(member)));
      return true;
    }
    final relation = _tryRelation(text);
    if (relation != null) {
      _class(relation.from, namespaceId: namespaceId);
      _class(relation.to, namespaceId: namespaceId);
      relations.add(relation);
      return true;
    }
    return false;
  }

  ClassRelationAst? _tryRelation(String text) {
    final match = RegExp(
      r'^(`[^`]+`|"[^"]+"|[^\s"]+)\s+(?:"([^"]*)"\s+)?(<\|(?:--|\.\.)|(?:--|\.\.)\|>|\*(?:--|\.\.)|(?:--|\.\.)\*|o(?:--|\.\.)|(?:--|\.\.)o|<(?:(?:--)|\.\.)|(?:(?:--)|\.\.)>|\(\)(?:--|\.\.)|(?:--|\.\.)\(\)|--|\.\.)\s+(?:"([^"]*)"\s+)?(`[^`]+`|"[^"]+"|[^\s"]+)(?:\s*:\s*(.*))?$',
    ).firstMatch(text);
    if (match == null) return null;
    final operator = match.group(3)!;
    return ClassRelationAst(
      from: unquoteGraphText(match.group(1)!),
      to: unquoteGraphText(match.group(5)!),
      fromCardinality: match.group(2),
      toCardinality: match.group(4),
      startMarker: _startMarker(operator),
      endMarker: _endMarker(operator),
      line: operator.contains('..') ? ClassRelationLine.dotted : ClassRelationLine.solid,
      label: switch (match.group(6)?.trim()) {
        final value? when value.isNotEmpty => value,
        _ => null,
      },
    );
  }

  _MutableClass _class(String rawId, {String? label, String? namespaceId}) {
    final id = unquoteGraphText(rawId);
    final existing = classes[id];
    if (existing != null) {
      if (label != null) existing.label = label;
      existing.namespaceId ??= namespaceId;
      return existing;
    }
    return classes[id] = _MutableClass(id, label ?? id, namespaceId);
  }
}

({String id, String label, String? annotation}) _parseClassDeclaration(String source) {
  var value = source.trim();
  String? annotation;
  final annotated = RegExp(r'^(.+?)\s+<<\s*(.*?)\s*>>$').firstMatch(value);
  if (annotated != null) {
    value = annotated.group(1)!.trim();
    annotation = annotated.group(2)!;
  }
  final labeled = RegExp(r'^(`[^`]+`|[^\s\[]+)\s*\[\s*"([^"]*)"\s*\]$').firstMatch(value);
  if (labeled != null) {
    return (id: unquoteGraphText(labeled.group(1)!), label: labeled.group(2)!, annotation: annotation);
  }
  final id = unquoteGraphText(value);
  return (
    id: id,
    label: id.replaceAllMapped(RegExp(r'~([^~]+)~'), (match) => '<${match.group(1)}>'),
    annotation: annotation,
  );
}

ClassMemberKind _memberKind(String text) =>
    text.contains('(') && text.contains(')') ? ClassMemberKind.method : ClassMemberKind.attribute;

bool _looksLikeRelation(String text) => RegExp(r'(?:--|\.\.)').hasMatch(text);

ClassRelationMarker _startMarker(String operator) {
  if (operator.startsWith('<|')) return ClassRelationMarker.extension;
  if (operator.startsWith('*')) return ClassRelationMarker.composition;
  if (operator.startsWith('o')) return ClassRelationMarker.aggregation;
  if (operator.startsWith('<')) return ClassRelationMarker.dependency;
  if (operator.startsWith('()')) return ClassRelationMarker.lollipop;
  return ClassRelationMarker.none;
}

ClassRelationMarker _endMarker(String operator) {
  if (operator.endsWith('|>')) return ClassRelationMarker.extension;
  if (operator.endsWith('*')) return ClassRelationMarker.composition;
  if (operator.endsWith('o')) return ClassRelationMarker.aggregation;
  if (operator.endsWith('>')) return ClassRelationMarker.dependency;
  if (operator.endsWith('()')) return ClassRelationMarker.lollipop;
  return ClassRelationMarker.none;
}

final class _MutableClass {
  _MutableClass(this.id, this.label, this.namespaceId);

  final String id;
  String label;
  final List<String> annotations = [];
  final List<ClassMemberAst> members = [];
  final List<String> cssClasses = [];
  final Map<String, String> styles = {};
  String? namespaceId;

  ClassAst freeze() => ClassAst(
    id: id,
    label: label,
    annotations: List.unmodifiable(annotations),
    members: List.unmodifiable(members),
    cssClasses: List.unmodifiable(cssClasses),
    styles: Map.unmodifiable(styles),
    namespaceId: namespaceId,
  );
}
