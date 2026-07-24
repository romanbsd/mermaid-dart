import 'ast.dart';
import 'common_syntax.dart';
import 'graph_syntax.dart';

/// Parses Mermaid `erDiagram` source.
ErDiagramAst parseErDiagram(String source) {
  final prepared = prepareDiagramSource(source, headers: const ['erDiagram']);
  return _ErParser(source, sourceLines(prepared.syntax), prepared.metadata).parse();
}

final class _ErParser {
  _ErParser(this.source, this.lines, this.metadata);

  final String source;
  final List<SourceLine> lines;
  final CommonMetadata metadata;
  final Map<String, _MutableErEntity> entities = {};
  final List<ErRelationshipAst> relationships = [];
  final Map<String, Map<String, String>> classDefinitions = {};
  GraphDirection direction = GraphDirection.topDown;
  var index = 0;

  ErDiagramAst parse() {
    while (index < lines.length) {
      final line = lines[index];
      final text = line.text.trim();
      index++;
      if (text.isEmpty) continue;
      if (parseGraphDirectionStatement(text) case final parsedDirection?) {
        direction = parsedDirection;
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
          mergeCssClasses(_entity(id).cssClasses, classAssignment.cssClasses);
        }
        continue;
      }
      final style = parseGraphStyleAssignment(text);
      if (style != null) {
        for (final id in style.ids) {
          _entity(id).styles.addAll(style.styles);
        }
        continue;
      }
      final entityBlock = RegExp(r'^(.+?)\s*\{$').firstMatch(text);
      if (entityBlock != null) {
        final declaration = _parseErEntityDeclaration(entityBlock.group(1)!);
        final entity = _entity(declaration.id, label: declaration.label, cssClasses: declaration.cssClasses);
        _parseAttributes(entity, line);
        continue;
      }
      final relation = _tryRelationship(text);
      if (relation != null) {
        _entity(relation.from);
        _entity(relation.to);
        relationships.add(relation);
        continue;
      }
      final declaration = _parseErEntityDeclaration(text);
      if (declaration.id.isNotEmpty) {
        _entity(declaration.id, label: declaration.label, cssClasses: declaration.cssClasses);
        continue;
      }
      throwGraphLineError(source, line, 'Unexpected ER diagram statement');
    }
    return ErDiagramAst(
      direction: direction,
      entities: entities.values.map((entity) => entity.freeze()).toList(growable: false),
      relationships: List.unmodifiable(relationships),
      classDefinitions: freezeGraphClassDefinitions(classDefinitions),
      title: metadata.title,
      accessibilityTitle: metadata.accessibilityTitle,
      accessibilityDescription: metadata.accessibilityDescription,
    );
  }

  void _parseAttributes(_MutableErEntity entity, SourceLine declaration) {
    while (index < lines.length) {
      final line = lines[index];
      var text = line.text.trim();
      index++;
      if (text.isEmpty) continue;
      if (text == '}') return;
      final closesBlock = text.endsWith('}');
      if (closesBlock) text = text.substring(0, text.length - 1).trimRight();
      final match = RegExp(
        r'^(`[^`]+`|[^\s]+)\s+(`[^`]+`|[^\s,]+)(?:\s+((?:(?:PK|FK|UK)\s*,?\s*)+))?(?:\s+"([^"]*)")?$',
        caseSensitive: false,
      ).firstMatch(text);
      if (match == null) throwGraphLineError(source, line, 'Expected an attribute type and name');
      final keys = <ErAttributeKey>{};
      for (final key in (match.group(3) ?? '').split(RegExp(r'[\s,]+'))) {
        switch (key.toUpperCase()) {
          case 'PK':
            keys.add(ErAttributeKey.primary);
          case 'FK':
            keys.add(ErAttributeKey.foreign);
          case 'UK':
            keys.add(ErAttributeKey.unique);
        }
      }
      entity.attributes.add(
        ErAttributeAst(
          type: unquoteGraphText(match.group(1)!),
          name: unquoteGraphText(match.group(2)!),
          keys: Set.unmodifiable(keys),
          comment: match.group(4),
        ),
      );
      if (closesBlock) return;
    }
    throwParseError(source, 'Unterminated entity body', declaration.offset + declaration.text.indexOf(RegExp(r'\S')));
  }

  ErRelationshipAst? _tryRelationship(String text) {
    final symbolic = RegExp(
      r'^(`[^`]+`|"[^"]+"|[^\s]+)\s+(\|\||\|o|o\||o\{|\|\{|\}o|\}\||u)(--|\.\.|-\.|\.-)(\|\||\|o|o\||o\{|\|\{|\}o|\}\||u)\s+(`[^`]+`|"[^"]+"|[^\s]+)\s*:\s*(?:"([^"]*)"|(.+))$',
      caseSensitive: false,
    ).firstMatch(text);
    if (symbolic != null) {
      return ErRelationshipAst(
        from: unquoteGraphText(symbolic.group(1)!),
        to: unquoteGraphText(symbolic.group(5)!),
        fromCardinality: _symbolicCardinality(symbolic.group(2)!),
        toCardinality: _symbolicCardinality(symbolic.group(4)!),
        identifying: symbolic.group(3) == '--',
        label: (symbolic.group(6) ?? symbolic.group(7)!).trim(),
      );
    }
    const cardinality =
        r'(only one|one or more|one or many|zero or one|zero or more|zero or many|many\(0\)|many\(1\)|many|one|1\+|0\+)';
    final textual = RegExp(
      '^(`[^`]+`|"[^"]+"|[^\\s]+)\\s+$cardinality\\s+(optionally\\s+to|to)\\s+$cardinality\\s+(`[^`]+`|"[^"]+"|[^\\s]+)\\s*:\\s*(?:"([^"]*)"|(.+))\$',
      caseSensitive: false,
    ).firstMatch(text);
    if (textual == null) return null;
    return ErRelationshipAst(
      from: unquoteGraphText(textual.group(1)!),
      to: unquoteGraphText(textual.group(5)!),
      fromCardinality: _textCardinality(textual.group(2)!),
      toCardinality: _textCardinality(textual.group(4)!),
      identifying: !textual.group(3)!.toLowerCase().startsWith('optionally'),
      label: (textual.group(6) ?? textual.group(7)!).trim(),
    );
  }

  _MutableErEntity _entity(String rawId, {String? label, List<String> cssClasses = const []}) {
    final id = unquoteGraphText(rawId);
    final existing = entities[id];
    if (existing != null) {
      if (label != null) existing.label = label;
      mergeCssClasses(existing.cssClasses, cssClasses);
      return existing;
    }
    return entities[id] = _MutableErEntity(id, label ?? id)..cssClasses.addAll(cssClasses);
  }
}

({String id, String label, List<String> cssClasses}) _parseErEntityDeclaration(String source) {
  var value = source.trim();
  final cssClasses = <String>[];
  final classSeparator = value.indexOf(':::');
  if (classSeparator >= 0) {
    cssClasses.addAll(
      value.substring(classSeparator + 3).split(',').map((item) => item.trim()).where((item) => item.isNotEmpty),
    );
    value = value.substring(0, classSeparator).trim();
  }
  final alias = RegExp(r'^(`[^`]+`|"[^"]+"|[^\s\[]+)\s*\[\s*(`[^`]+`|"[^"]+"|[^\]]+)\s*\]$').firstMatch(value);
  if (alias != null) {
    return (id: unquoteGraphText(alias.group(1)!), label: unquoteGraphText(alias.group(2)!), cssClasses: cssClasses);
  }
  final id = unquoteGraphText(value);
  return (id: id, label: id, cssClasses: cssClasses);
}

ErCardinality _symbolicCardinality(String token) => switch (token.toLowerCase()) {
  '||' => ErCardinality.exactlyOne,
  '|o' || 'o|' => ErCardinality.zeroOrOne,
  '|{' || '}|' => ErCardinality.oneOrMore,
  'o{' || '}o' => ErCardinality.zeroOrMore,
  'u' => ErCardinality.parent,
  _ => ErCardinality.exactlyOne,
};

ErCardinality _textCardinality(String value) => switch (value.toLowerCase()) {
  'only one' || 'one' => ErCardinality.exactlyOne,
  'zero or one' => ErCardinality.zeroOrOne,
  'one or more' || 'one or many' || 'many(1)' || '1+' => ErCardinality.oneOrMore,
  _ => ErCardinality.zeroOrMore,
};

final class _MutableErEntity {
  _MutableErEntity(this.id, this.label);

  final String id;
  String label;
  final List<ErAttributeAst> attributes = [];
  final List<String> cssClasses = [];
  final Map<String, String> styles = {};

  ErEntityAst freeze() => ErEntityAst(
    id: id,
    label: label,
    attributes: List.unmodifiable(attributes),
    cssClasses: List.unmodifiable(cssClasses),
    styles: Map.unmodifiable(styles),
  );
}
