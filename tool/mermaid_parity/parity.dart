import 'dart:convert';
import 'dart:io';

import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:mermaid_dart/src/rendering/svg_normalizer.dart';
import 'package:xml/xml.dart';

final class ParityManifest {
  ParityManifest({required this.mermaidVersion, required this.fixtures}) {
    if (mermaidVersion.isEmpty) throw const FormatException('mermaidVersion must not be empty');
    final identifiers = fixtures.map((fixture) => fixture.id).toSet();
    if (identifiers.length != fixtures.length) {
      throw const FormatException('Fixture IDs must be unique');
    }
  }

  factory ParityManifest.fromJson(Object? json) {
    if (json case {'mermaidVersion': final String version, 'fixtures': final List<Object?> fixtures}) {
      return ParityManifest(
        mermaidVersion: version,
        fixtures: fixtures.map(ParityFixture.fromJson).toList(growable: false),
      );
    }
    throw const FormatException('Invalid parity fixture manifest');
  }

  static ParityManifest load(File file) => ParityManifest.fromJson(jsonDecode(file.readAsStringSync()));

  final String mermaidVersion;
  final List<ParityFixture> fixtures;
}

final class ParityFixture {
  const ParityFixture({
    required this.id,
    required this.type,
    required this.source,
    this.textMeasurements = const {},
    this.diagramConfig = const {},
    this.themeVariables = const {},
  });

  factory ParityFixture.fromJson(Object? json) {
    if (json case {'id': final String id, 'type': final String type, 'source': final String source}) {
      if (id.isEmpty || source.isEmpty) throw const FormatException('Fixture fields must not be empty');
      final textMeasurements = switch (json['textMeasurements']) {
        null => const <String, Size>{},
        final Map<String, Object?> values => {
          for (final MapEntry(:key, :value) in values.entries) key: _textMeasurement(value),
        },
        _ => throw const FormatException('Invalid fixture textMeasurements'),
      };
      final diagramType = DiagramType.fromWireName(type);
      final diagramConfig = _diagramConfig(json, diagramType);
      final themeVariables = _themeVariables(json['themeVariables']);
      return ParityFixture(
        id: id,
        type: diagramType,
        source: source,
        textMeasurements: textMeasurements,
        diagramConfig: diagramConfig,
        themeVariables: themeVariables,
      );
    }
    throw const FormatException('Invalid parity fixture');
  }

  final String id;
  final DiagramType type;
  final String source;
  final Map<String, Size> textMeasurements;
  final Map<String, Object> diagramConfig;
  final Map<String, Object> themeVariables;

  Map<String, Object> get mermaidConfig => {
    if (themeVariables.isNotEmpty) 'themeVariables': themeVariables,
    if (diagramConfig.isNotEmpty) _mermaidConfigNames[type]!: diagramConfig,
  };

  TextMeasurer get textMeasurer => _FixtureTextMeasurer(textMeasurements);

  RenderOptions get renderOptions {
    const architectureDefaults = ArchitectureRenderOptions();
    const cynefinDefaults = CynefinRenderOptions();
    const eventModelingDefaults = EventModelingRenderOptions();
    const gitGraphDefaults = GitGraphRenderOptions();
    const packetDefaults = PacketRenderOptions();
    const pieDefaults = PieRenderOptions();
    const radarDefaults = RadarRenderOptions();
    const railroadDefaults = RailroadRenderOptions();
    const treeViewDefaults = TreeViewRenderOptions();
    const treemapDefaults = TreemapRenderOptions();
    const wardleyDefaults = WardleyRenderOptions();
    return RenderOptions(
      theme: _themeOptions(themeVariables),
      padding: 0,
      architecture: ArchitectureRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, architectureDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, architectureDefaults),
        padding: (diagramConfig['padding'] as num?)?.toDouble() ?? architectureDefaults.padding,
        iconSize: (diagramConfig['iconSize'] as num?)?.toDouble() ?? architectureDefaults.iconSize,
        fontSize: (diagramConfig['fontSize'] as num?)?.toDouble() ?? architectureDefaults.fontSize,
        randomize: diagramConfig['randomize'] as bool? ?? architectureDefaults.randomize,
        nodeSeparation: (diagramConfig['nodeSeparation'] as num?)?.toDouble() ?? architectureDefaults.nodeSeparation,
        idealEdgeLengthMultiplier:
            (diagramConfig['idealEdgeLengthMultiplier'] as num?)?.toDouble() ??
            architectureDefaults.idealEdgeLengthMultiplier,
        edgeElasticity: (diagramConfig['edgeElasticity'] as num?)?.toDouble() ?? architectureDefaults.edgeElasticity,
        numIter: diagramConfig['numIter'] as int? ?? architectureDefaults.numIter,
        seed: diagramConfig['seed'] as int? ?? architectureDefaults.seed,
      ),
      cynefin: CynefinRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, cynefinDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, cynefinDefaults),
        width: (diagramConfig['width'] as num?)?.toDouble() ?? cynefinDefaults.width,
        height: (diagramConfig['height'] as num?)?.toDouble() ?? cynefinDefaults.height,
        padding: (diagramConfig['padding'] as num?)?.toDouble() ?? cynefinDefaults.padding,
        showDomainDescriptions:
            diagramConfig['showDomainDescriptions'] as bool? ?? cynefinDefaults.showDomainDescriptions,
        boundaryAmplitude:
            (diagramConfig['boundaryAmplitude'] as num?)?.toDouble() ?? cynefinDefaults.boundaryAmplitude,
        seed: diagramConfig['seed'] as int? ?? cynefinDefaults.seed,
      ),
      eventModeling: EventModelingRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, eventModelingDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, eventModelingDefaults),
        padding: (diagramConfig['padding'] as num?)?.toDouble() ?? eventModelingDefaults.padding,
        rowHeight: (diagramConfig['rowHeight'] as num?)?.toDouble() ?? eventModelingDefaults.rowHeight,
      ),
      gitGraph: GitGraphRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, gitGraphDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, gitGraphDefaults),
        titleTopMargin: (diagramConfig['titleTopMargin'] as num?)?.toDouble() ?? gitGraphDefaults.titleTopMargin,
        diagramPadding: (diagramConfig['diagramPadding'] as num?)?.toDouble() ?? gitGraphDefaults.diagramPadding,
        nodeLabel: _gitGraphNodeLabelOptions(diagramConfig['nodeLabel'], gitGraphDefaults.nodeLabel),
        mainBranchName: diagramConfig['mainBranchName'] as String? ?? gitGraphDefaults.mainBranchName,
        mainBranchOrder: (diagramConfig['mainBranchOrder'] as num?)?.toDouble() ?? gitGraphDefaults.mainBranchOrder,
        showCommitLabel: diagramConfig['showCommitLabel'] as bool? ?? gitGraphDefaults.showCommitLabel,
        showBranches: diagramConfig['showBranches'] as bool? ?? gitGraphDefaults.showBranches,
        rotateCommitLabel: diagramConfig['rotateCommitLabel'] as bool? ?? gitGraphDefaults.rotateCommitLabel,
        parallelCommits: diagramConfig['parallelCommits'] as bool? ?? gitGraphDefaults.parallelCommits,
        arrowMarkerAbsolute: diagramConfig['arrowMarkerAbsolute'] as bool? ?? gitGraphDefaults.arrowMarkerAbsolute,
      ),
      packet: PacketRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, packetDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, packetDefaults),
        rowHeight: (diagramConfig['rowHeight'] as num?)?.toDouble() ?? packetDefaults.rowHeight,
        bitWidth: (diagramConfig['bitWidth'] as num?)?.toDouble() ?? packetDefaults.bitWidth,
        bitsPerRow: diagramConfig['bitsPerRow'] as int? ?? packetDefaults.bitsPerRow,
        showBits: diagramConfig['showBits'] as bool? ?? packetDefaults.showBits,
        paddingX: (diagramConfig['paddingX'] as num?)?.toDouble() ?? packetDefaults.paddingX,
        paddingY: (diagramConfig['paddingY'] as num?)?.toDouble() ?? packetDefaults.paddingY,
      ),
      pie: PieRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, pieDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, pieDefaults),
        donutHole: (diagramConfig['donutHole'] as num?)?.toDouble() ?? pieDefaults.donutHole,
        highlightSlice: diagramConfig['highlightSlice'] as String? ?? pieDefaults.highlightSlice,
        textPosition: (diagramConfig['textPosition'] as num?)?.toDouble() ?? pieDefaults.textPosition,
        legendPosition: switch (diagramConfig['legendPosition']) {
          final String value => _pieLegendPosition(value),
          _ => pieDefaults.legendPosition,
        },
      ),
      radar: RadarRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, radarDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, radarDefaults),
        width: (diagramConfig['width'] as num?)?.toDouble() ?? radarDefaults.width,
        height: (diagramConfig['height'] as num?)?.toDouble() ?? radarDefaults.height,
        marginTop: (diagramConfig['marginTop'] as num?)?.toDouble() ?? radarDefaults.marginTop,
        marginRight: (diagramConfig['marginRight'] as num?)?.toDouble() ?? radarDefaults.marginRight,
        marginBottom: (diagramConfig['marginBottom'] as num?)?.toDouble() ?? radarDefaults.marginBottom,
        marginLeft: (diagramConfig['marginLeft'] as num?)?.toDouble() ?? radarDefaults.marginLeft,
        axisScaleFactor: (diagramConfig['axisScaleFactor'] as num?)?.toDouble() ?? radarDefaults.axisScaleFactor,
        axisLabelFactor: (diagramConfig['axisLabelFactor'] as num?)?.toDouble() ?? radarDefaults.axisLabelFactor,
        curveTension: (diagramConfig['curveTension'] as num?)?.toDouble() ?? radarDefaults.curveTension,
      ),
      railroad: RailroadRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, railroadDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, railroadDefaults),
        compactMode: diagramConfig['compactMode'] as bool? ?? railroadDefaults.compactMode,
        padding: (diagramConfig['padding'] as num?)?.toDouble() ?? railroadDefaults.padding,
        verticalSeparation:
            (diagramConfig['verticalSeparation'] as num?)?.toDouble() ?? railroadDefaults.verticalSeparation,
        horizontalSeparation:
            (diagramConfig['horizontalSeparation'] as num?)?.toDouble() ?? railroadDefaults.horizontalSeparation,
        arcRadius: (diagramConfig['arcRadius'] as num?)?.toDouble() ?? railroadDefaults.arcRadius,
        fontSize: (diagramConfig['fontSize'] as num?)?.toDouble() ?? railroadDefaults.fontSize,
        fontFamily: diagramConfig['fontFamily'] as String? ?? railroadDefaults.fontFamily,
        strokeWidth: (diagramConfig['strokeWidth'] as num?)?.toDouble() ?? railroadDefaults.strokeWidth,
        showMarkers: diagramConfig['showMarkers'] as bool? ?? railroadDefaults.showMarkers,
        markerRadius: (diagramConfig['markerRadius'] as num?)?.toDouble() ?? railroadDefaults.markerRadius,
        terminalFill: _configuredColor(diagramConfig, 'terminalFill', railroadDefaults.terminalFill),
        terminalStroke: _configuredColor(diagramConfig, 'terminalStroke', railroadDefaults.terminalStroke),
        terminalTextColor: _configuredColor(diagramConfig, 'terminalTextColor', railroadDefaults.terminalTextColor),
        nonTerminalFill: _configuredColor(diagramConfig, 'nonTerminalFill', railroadDefaults.nonTerminalFill),
        nonTerminalStroke: _configuredColor(diagramConfig, 'nonTerminalStroke', railroadDefaults.nonTerminalStroke),
        nonTerminalTextColor: _configuredColor(
          diagramConfig,
          'nonTerminalTextColor',
          railroadDefaults.nonTerminalTextColor,
        ),
        lineColor: _configuredColor(diagramConfig, 'lineColor', railroadDefaults.lineColor),
        markerFill: _configuredColor(diagramConfig, 'markerFill', railroadDefaults.markerFill),
        commentFill: _configuredColor(diagramConfig, 'commentFill', railroadDefaults.commentFill),
        commentStroke: _configuredColor(diagramConfig, 'commentStroke', railroadDefaults.commentStroke),
        commentTextColor: _configuredColor(diagramConfig, 'commentTextColor', railroadDefaults.commentTextColor),
        specialFill: _configuredColor(diagramConfig, 'specialFill', railroadDefaults.specialFill),
        specialStroke: _configuredColor(diagramConfig, 'specialStroke', railroadDefaults.specialStroke),
        ruleNameColor: _configuredColor(diagramConfig, 'ruleNameColor', railroadDefaults.ruleNameColor),
      ),
      treeView: TreeViewRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, treeViewDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, treeViewDefaults),
        rowIndent: (diagramConfig['rowIndent'] as num?)?.toDouble() ?? treeViewDefaults.rowIndent,
        paddingX: (diagramConfig['paddingX'] as num?)?.toDouble() ?? treeViewDefaults.paddingX,
        paddingY: (diagramConfig['paddingY'] as num?)?.toDouble() ?? treeViewDefaults.paddingY,
        lineThickness: (diagramConfig['lineThickness'] as num?)?.toDouble() ?? treeViewDefaults.lineThickness,
        showIcons: diagramConfig['showIcons'] as bool? ?? treeViewDefaults.showIcons,
        defaultIconPack: diagramConfig['defaultIconPack'] as String? ?? treeViewDefaults.defaultIconPack,
        filenameIcons: diagramConfig['filenameIcons'] as Map<String, String>? ?? treeViewDefaults.filenameIcons,
        extensionIcons: diagramConfig['extensionIcons'] as Map<String, String>? ?? treeViewDefaults.extensionIcons,
      ),
      treemap: TreemapRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, treemapDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, treemapDefaults),
        padding: (diagramConfig['padding'] as num?)?.toDouble() ?? treemapDefaults.padding,
        diagramPadding: (diagramConfig['diagramPadding'] as num?)?.toDouble() ?? treemapDefaults.diagramPadding,
        showValues: diagramConfig['showValues'] as bool? ?? treemapDefaults.showValues,
        nodeWidth: (diagramConfig['nodeWidth'] as num?)?.toDouble() ?? treemapDefaults.nodeWidth,
        nodeHeight: (diagramConfig['nodeHeight'] as num?)?.toDouble() ?? treemapDefaults.nodeHeight,
        borderWidth: (diagramConfig['borderWidth'] as num?)?.toDouble() ?? treemapDefaults.borderWidth,
        valueFontSize: (diagramConfig['valueFontSize'] as num?)?.toDouble() ?? treemapDefaults.valueFontSize,
        labelFontSize: (diagramConfig['labelFontSize'] as num?)?.toDouble() ?? treemapDefaults.labelFontSize,
        valueFormat: switch (diagramConfig['valueFormat']) {
          final String value => _treemapValueFormat(value),
          _ => treemapDefaults.valueFormat,
        },
      ),
      wardley: WardleyRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, wardleyDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, wardleyDefaults),
        width: (diagramConfig['width'] as num?)?.toDouble() ?? wardleyDefaults.width,
        height: (diagramConfig['height'] as num?)?.toDouble() ?? wardleyDefaults.height,
        padding: (diagramConfig['padding'] as num?)?.toDouble() ?? wardleyDefaults.padding,
        nodeRadius: (diagramConfig['nodeRadius'] as num?)?.toDouble() ?? wardleyDefaults.nodeRadius,
        nodeLabelOffset: (diagramConfig['nodeLabelOffset'] as num?)?.toDouble() ?? wardleyDefaults.nodeLabelOffset,
        axisFontSize: (diagramConfig['axisFontSize'] as num?)?.toDouble() ?? wardleyDefaults.axisFontSize,
        labelFontSize: (diagramConfig['labelFontSize'] as num?)?.toDouble() ?? wardleyDefaults.labelFontSize,
        showGrid: diagramConfig['showGrid'] as bool? ?? wardleyDefaults.showGrid,
      ),
    );
  }
}

const _themePaletteLength = 12;

Map<String, Object> _themeVariables(Object? value) {
  if (value == null) return const {};
  if (value is! Map<String, Object?> || value.isEmpty) {
    throw const FormatException('Invalid fixture themeVariables');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final validKey =
        RegExp(r'^pie(?:[1-9]|1[0-2])$').hasMatch(key) ||
        RegExp(r'^cScale(?:Peer|Label)?(?:[0-9]|1[01])$').hasMatch(key);
    if (!validKey || value is! String || !_fixtureHexColor.hasMatch(value.trim())) {
      throw const FormatException('Invalid fixture themeVariables');
    }
    result[key] = value.trim();
  }
  return Map.unmodifiable(result);
}

MermaidTheme _themeOptions(Map<String, Object> variables) {
  const defaults = MermaidTheme();
  final pieColors = [...defaults.pieColors];
  final categoricalColors = [...defaults.categoricalColors];
  final categoricalPeerColors = [...defaults.categoricalPeerColors];
  final categoricalLabelColors = [...defaults.categoricalLabelColors];
  for (var index = 0; index < _themePaletteLength; index++) {
    if (variables['pie${index + 1}'] case final String color) {
      pieColors[index] = _fixtureColor(color);
    }
    if (variables['cScale$index'] case final String color) {
      categoricalColors[index] = _fixtureColor(color);
    }
    if (variables['cScalePeer$index'] case final String color) {
      categoricalPeerColors[index] = _fixtureColor(color);
    }
    if (variables['cScaleLabel$index'] case final String color) {
      categoricalLabelColors[index] = _fixtureColor(color);
    }
  }
  return MermaidTheme(
    pieColors: List.unmodifiable(pieColors),
    categoricalColors: List.unmodifiable(categoricalColors),
    categoricalPeerColors: List.unmodifiable(categoricalPeerColors),
    categoricalLabelColors: List.unmodifiable(categoricalLabelColors),
  );
}

double? _configuredUseWidth(Map<String, Object> config, DiagramRenderOptions defaults) =>
    (config['useWidth'] as num?)?.toDouble() ?? defaults.useWidth;

bool? _configuredUseMaxWidth(Map<String, Object> config, DiagramRenderOptions defaults) =>
    config['useMaxWidth'] as bool? ?? defaults.useMaxWidth;

const _fixtureOptionNames = {
  DiagramType.architecture: 'architectureOptions',
  DiagramType.cynefin: 'cynefinOptions',
  DiagramType.eventModeling: 'eventModelingOptions',
  DiagramType.gitGraph: 'gitGraphOptions',
  DiagramType.packet: 'packetOptions',
  DiagramType.pie: 'pieOptions',
  DiagramType.radar: 'radarOptions',
  DiagramType.railroad: 'railroadOptions',
  DiagramType.railroadAbnf: 'railroadOptions',
  DiagramType.railroadEbnf: 'railroadOptions',
  DiagramType.railroadPeg: 'railroadOptions',
  DiagramType.treeView: 'treeViewOptions',
  DiagramType.treemap: 'treemapOptions',
  DiagramType.wardley: 'wardleyOptions',
};

const _mermaidConfigNames = {
  DiagramType.architecture: 'architecture',
  DiagramType.cynefin: 'cynefin',
  DiagramType.eventModeling: 'eventmodeling',
  DiagramType.gitGraph: 'gitGraph',
  DiagramType.packet: 'packet',
  DiagramType.pie: 'pie',
  DiagramType.radar: 'radar',
  DiagramType.railroad: 'railroad',
  DiagramType.railroadAbnf: 'railroad',
  DiagramType.railroadEbnf: 'railroad',
  DiagramType.railroadPeg: 'railroad',
  DiagramType.treeView: 'treeView',
  DiagramType.treemap: 'treemap',
  DiagramType.wardley: 'wardley-beta',
};

const _baseDiagramConfigKeys = {'useWidth', 'useMaxWidth'};

Object? _baseDiagramConfigValue(String key, Object? value) => switch ((key, value)) {
  ('useWidth', final num option) when option > 0 => option,
  ('useMaxWidth', final bool option) => option,
  _ => null,
};

Map<String, Object> _diagramConfig(Map<Object?, Object?> json, DiagramType type) {
  final supplied = _fixtureOptionNames.values.toSet().where(json.containsKey).toList(growable: false);
  if (supplied.isEmpty) return const {};
  final expected = _fixtureOptionNames[type];
  if (supplied.length != 1 || supplied.single != expected) {
    throw FormatException('${supplied.first} require a ${type.name} fixture');
  }
  final value = json[expected];
  return switch (type) {
    DiagramType.architecture => _architectureConfig(value),
    DiagramType.cynefin => _cynefinConfig(value),
    DiagramType.eventModeling => _eventModelingConfig(value),
    DiagramType.gitGraph => _gitGraphConfig(value),
    DiagramType.packet => _packetConfig(value),
    DiagramType.pie => _pieConfig(value),
    DiagramType.radar => _radarConfig(value),
    DiagramType.railroad ||
    DiagramType.railroadAbnf ||
    DiagramType.railroadEbnf ||
    DiagramType.railroadPeg => _railroadConfig(value),
    DiagramType.treeView => _treeViewConfig(value),
    DiagramType.treemap => _treemapConfig(value),
    DiagramType.wardley => _wardleyConfig(value),
    _ => throw FormatException('$expected are not supported for ${type.name} fixtures'),
  };
}

const _railroadConfigKeys = {
  ..._baseDiagramConfigKeys,
  'compactMode',
  'padding',
  'verticalSeparation',
  'horizontalSeparation',
  'arcRadius',
  'fontSize',
  'fontFamily',
  'terminalFill',
  'terminalStroke',
  'terminalTextColor',
  'nonTerminalFill',
  'nonTerminalStroke',
  'nonTerminalTextColor',
  'lineColor',
  'strokeWidth',
  'markerFill',
  'commentFill',
  'commentStroke',
  'commentTextColor',
  'specialFill',
  'specialStroke',
  'ruleNameColor',
  'showMarkers',
  'markerRadius',
};

const _railroadColorConfigKeys = {
  'terminalFill',
  'terminalStroke',
  'terminalTextColor',
  'nonTerminalFill',
  'nonTerminalStroke',
  'nonTerminalTextColor',
  'lineColor',
  'markerFill',
  'commentFill',
  'commentStroke',
  'commentTextColor',
  'specialFill',
  'specialStroke',
  'ruleNameColor',
};

final _fixtureHexColor = RegExp(r'^#[0-9a-f]{3,4}(?:[0-9a-f]{3,4})?$', caseSensitive: false);

Map<String, Object> _railroadConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_railroadConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture railroadOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('compactMode' || 'showMarkers', final bool option) => option,
            (
              'padding' ||
                  'verticalSeparation' ||
                  'horizontalSeparation' ||
                  'arcRadius' ||
                  'fontSize' ||
                  'strokeWidth' ||
                  'markerRadius',
              final num option,
            )
                when option >= 0 =>
              option,
            ('fontFamily', final String option) when option.trim().isNotEmpty => option.trim(),
            (final String colorKey, final String option)
                when _railroadColorConfigKeys.contains(colorKey) && _fixtureHexColor.hasMatch(option.trim()) =>
              option.trim(),
            _ => null,
          };
    if (valid == null) {
      throw const FormatException('Invalid fixture railroadOptions');
    }
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

Color _configuredColor(Map<String, Object> config, String key, Color fallback) => switch (config[key]) {
  final String value => _fixtureColor(value),
  _ => fallback,
};

Color _fixtureColor(String value) {
  final hex = value.substring(1);
  final expanded = hex.length <= 4 ? [for (final digit in hex.split('')) '$digit$digit'].join() : hex;
  return Color.fromHex(expanded);
}

const _treemapConfigKeys = {
  ..._baseDiagramConfigKeys,
  'padding',
  'diagramPadding',
  'showValues',
  'nodeWidth',
  'nodeHeight',
  'borderWidth',
  'valueFontSize',
  'labelFontSize',
  'valueFormat',
};
const _treemapValueFormatNames = {'', ',', r'$0,0'};

Map<String, Object> _treemapConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_treemapConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture treemapOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('showValues', final bool option) => option,
            ('nodeWidth' || 'nodeHeight', final num option) when option > 0 => option,
            ('padding' || 'diagramPadding' || 'borderWidth' || 'valueFontSize' || 'labelFontSize', final num option)
                when option >= 0 =>
              option,
            ('valueFormat', final String option) when _treemapValueFormatNames.contains(option) => option,
            _ => null,
          };
    if (valid == null) {
      throw const FormatException('Invalid fixture treemapOptions');
    }
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

TreemapValueFormat _treemapValueFormat(String value) => switch (value) {
  '' => TreemapValueFormat.plain,
  ',' => TreemapValueFormat.grouped,
  r'$0,0' => TreemapValueFormat.currencyGrouped,
  _ => throw FormatException('Unknown treemap value format: $value'),
};

const _gitGraphConfigKeys = {
  ..._baseDiagramConfigKeys,
  'titleTopMargin',
  'diagramPadding',
  'nodeLabel',
  'mainBranchName',
  'mainBranchOrder',
  'showCommitLabel',
  'showBranches',
  'rotateCommitLabel',
  'parallelCommits',
  'arrowMarkerAbsolute',
};
const _gitGraphNodeLabelKeys = {'width', 'height', 'x', 'y'};

Map<String, Object> _gitGraphConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_gitGraphConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture gitGraphOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            (
              'showCommitLabel' || 'showBranches' || 'rotateCommitLabel' || 'parallelCommits' || 'arrowMarkerAbsolute',
              final bool option,
            ) =>
              option,
            ('titleTopMargin' || 'diagramPadding', final num option) when option >= 0 => option,
            ('mainBranchOrder', final num option) => option,
            ('mainBranchName', final String option) when option.trim().isNotEmpty => option.trim(),
            ('nodeLabel', final Map<String, Object?> option) => _gitGraphNodeLabelConfig(option),
            _ => null,
          };
    if (valid == null) {
      throw const FormatException('Invalid fixture gitGraphOptions');
    }
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

Map<String, Object>? _gitGraphNodeLabelConfig(Map<String, Object?> value) {
  if (value.isEmpty || value.keys.any((key) => !_gitGraphNodeLabelKeys.contains(key))) return null;
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = switch ((key, value)) {
      ('width' || 'height', final num option) when option > 0 => option,
      ('x' || 'y', final num option) => option,
      _ => null,
    };
    if (valid == null) return null;
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

GitGraphNodeLabelOptions _gitGraphNodeLabelOptions(Object? value, GitGraphNodeLabelOptions defaults) {
  if (value is! Map<String, Object>) return defaults;
  return GitGraphNodeLabelOptions(
    width: (value['width'] as num?)?.toDouble() ?? defaults.width,
    height: (value['height'] as num?)?.toDouble() ?? defaults.height,
    x: (value['x'] as num?)?.toDouble() ?? defaults.x,
    y: (value['y'] as num?)?.toDouble() ?? defaults.y,
  );
}

const _cynefinConfigKeys = {
  ..._baseDiagramConfigKeys,
  'width',
  'height',
  'padding',
  'showDomainDescriptions',
  'boundaryAmplitude',
  'seed',
};

Map<String, Object> _cynefinConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_cynefinConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture cynefinOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('width' || 'height', final num option) when option > 0 => option,
            ('padding' || 'boundaryAmplitude', final num option) when option >= 0 => option,
            ('showDomainDescriptions', final bool option) => option,
            ('seed', final int option) => option,
            _ => null,
          };
    if (valid == null) {
      throw const FormatException('Invalid fixture cynefinOptions');
    }
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

const _wardleyConfigKeys = {
  ..._baseDiagramConfigKeys,
  'width',
  'height',
  'padding',
  'nodeRadius',
  'nodeLabelOffset',
  'axisFontSize',
  'labelFontSize',
  'showGrid',
};

Map<String, Object> _wardleyConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_wardleyConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture wardleyOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('width' || 'height' || 'nodeRadius' || 'axisFontSize' || 'labelFontSize', final num option)
                when option > 0 =>
              option,
            ('padding' || 'nodeLabelOffset', final num option) when option >= 0 => option,
            ('showGrid', final bool option) => option,
            _ => null,
          };
    if (valid == null) {
      throw const FormatException('Invalid fixture wardleyOptions');
    }
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

Map<String, Object> _eventModelingConfig(Object? value) {
  if (value is! Map<String, Object?> ||
      value.isEmpty ||
      value.keys.any((key) => !_baseDiagramConfigKeys.contains(key) && key != 'padding' && key != 'rowHeight')) {
    throw const FormatException('Invalid fixture eventModelingOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('padding', final num option) when option >= 0 => option,
            ('rowHeight', final num option) when option > 0 => option,
            _ => null,
          };
    if (valid == null) {
      throw const FormatException('Invalid fixture eventModelingOptions');
    }
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

const _treeViewConfigKeys = {
  ..._baseDiagramConfigKeys,
  'rowIndent',
  'paddingX',
  'paddingY',
  'lineThickness',
  'showIcons',
  'defaultIconPack',
  'filenameIcons',
  'extensionIcons',
};

Map<String, Object> _treeViewConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_treeViewConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture treeViewOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('rowIndent' || 'paddingX' || 'paddingY', final num option) when option >= 0 => option,
            ('lineThickness', final num option) when option > 0 => option,
            ('showIcons', final bool option) => option,
            ('defaultIconPack', final String option) => option,
            ('filenameIcons' || 'extensionIcons', final Map<String, Object?> option) => _treeViewIconMap(option),
            _ => null,
          };
    if (valid == null) {
      throw const FormatException('Invalid fixture treeViewOptions');
    }
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

Map<String, String>? _treeViewIconMap(Map<String, Object?> value) {
  final result = <String, String>{};
  for (final MapEntry(:key, :value) in value.entries) {
    switch (value) {
      case final String icon when key.isNotEmpty && icon.isNotEmpty:
        result[key] = icon;
      default:
        return null;
    }
  }
  return Map.unmodifiable(result);
}

const _radarConfigKeys = {
  ..._baseDiagramConfigKeys,
  'width',
  'height',
  'marginTop',
  'marginRight',
  'marginBottom',
  'marginLeft',
  'axisScaleFactor',
  'axisLabelFactor',
  'curveTension',
};

Map<String, Object> _radarConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_radarConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture radarOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('width' || 'height', final num option) when option > 0 => option,
            ('marginTop' || 'marginRight' || 'marginBottom' || 'marginLeft', final num option) when option >= 0 =>
              option,
            ('axisScaleFactor' || 'axisLabelFactor', final num option) when option > 0 => option,
            ('curveTension', final num option) when option >= 0 && option <= 1 => option,
            _ => null,
          };
    if (valid == null) throw const FormatException('Invalid fixture radarOptions');
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

const _architectureConfigKeys = {
  ..._baseDiagramConfigKeys,
  'padding',
  'iconSize',
  'fontSize',
  'randomize',
  'nodeSeparation',
  'idealEdgeLengthMultiplier',
  'edgeElasticity',
  'numIter',
  'seed',
};

Map<String, Object> _architectureConfig(Object? value) {
  if (value == null) return const {};
  if (value is! Map<String, Object?> || value.keys.any((key) => !_architectureConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture architectureOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('padding', final num option) when option >= 0 => option,
            ('iconSize' || 'fontSize' || 'nodeSeparation', final num option) when option > 0 => option,
            ('randomize', final bool option) => option,
            ('idealEdgeLengthMultiplier', final num option) when option > 0 => option,
            ('edgeElasticity', final num option) when option >= 0 && option <= 1 => option,
            ('numIter', final int option) when option > 0 => option,
            ('seed', final int option) => option,
            _ => null,
          };
    if (valid == null) throw const FormatException('Invalid fixture architectureOptions');
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

Map<String, Object> _pieConfig(Object? value) {
  if (value == null) return const {};
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_pieConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture pieOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('donutHole', final num option) => option,
            ('highlightSlice', final String option) when option.isNotEmpty => option,
            ('textPosition', final num option) => option,
            ('legendPosition', final String option) when _pieLegendPositionNames.contains(option) => option,
            _ => null,
          };
    if (valid == null) throw const FormatException('Invalid fixture pieOptions');
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

const _pieConfigKeys = {..._baseDiagramConfigKeys, 'donutHole', 'highlightSlice', 'textPosition', 'legendPosition'};
const _pieLegendPositionNames = {'top', 'bottom', 'left', 'right', 'center'};

PieLegendPosition _pieLegendPosition(String value) => switch (value) {
  'top' => PieLegendPosition.top,
  'bottom' => PieLegendPosition.bottom,
  'left' => PieLegendPosition.left,
  'right' => PieLegendPosition.right,
  'center' => PieLegendPosition.center,
  _ => throw FormatException('Unknown pie legend position: $value'),
};

Map<String, Object> _packetConfig(Object? value) {
  const keys = {..._baseDiagramConfigKeys, 'rowHeight', 'bitWidth', 'bitsPerRow', 'showBits', 'paddingX', 'paddingY'};
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !keys.contains(key))) {
    throw const FormatException('Invalid fixture packetOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('rowHeight' || 'bitWidth', final num option) when option > 0 => option,
            ('bitsPerRow', final int option) when option > 0 => option,
            ('showBits', final bool option) => option,
            ('paddingX' || 'paddingY', final num option) when option >= 0 => option,
            _ => null,
          };
    if (valid == null) throw const FormatException('Invalid fixture packetOptions');
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

Size _textMeasurement(Object? json) {
  if (json case {'width': final num width, 'height': final num height} when width >= 0 && height >= 0) {
    return Size(width.toDouble(), height.toDouble());
  }
  throw const FormatException('Invalid fixture text measurement');
}

final class _FixtureTextMeasurer implements TextMeasurer {
  const _FixtureTextMeasurer(this.measurements);

  final Map<String, Size> measurements;

  @override
  Size measure(String text, SceneTextStyle style) =>
      measurements[text] ?? const DeterministicTextMeasurer().measure(text, style);
}

final class SvgSnapshot {
  SvgSnapshot._({
    required this.canonicalSvg,
    required this.viewBox,
    required this.text,
    required this.elementCounts,
    required this.geometry,
    required this.paint,
  });

  factory SvgSnapshot.fromSvg(String svg) {
    final sourceDocument = XmlDocument.parse(svg);
    final canonicalSvg = canonicalizeSvgForComparison(svg);
    final document = XmlDocument.parse(canonicalSvg);
    const elementNames = {'circle', 'ellipse', 'line', 'path', 'polygon', 'polyline', 'rect', 'text'};
    final elements = document.descendants.whereType<XmlElement>().toList();
    final comparableElements = elements.where((element) => _isComparableGeometryElement(element, document.rootElement));
    final textElements = comparableElements.where(
      (element) =>
          (element.name.local == 'text' || element.name.local == 'foreignObject') &&
          element.innerText.trim().isNotEmpty,
    );
    return SvgSnapshot._(
      canonicalSvg: canonicalSvg,
      // Read the viewport from the source document. Canonical SVG intentionally
      // rounds attributes for stable structural output, which would otherwise
      // introduce a second rounding step before visual comparison.
      viewBox: _normalizedNumberList(sourceDocument.rootElement.getAttribute('viewBox')),
      text: [for (final element in textElements) _normalizedVisibleText(element)]..sort(),
      elementCounts: {
        for (final name in elementNames)
          name: name == 'text'
              ? textElements.length
              : comparableElements.where((element) => element.name.local == name).length,
      },
      // Preserve source precision while flattening transforms. Canonicalizing
      // first can round local coordinates and their translation separately,
      // moving the final absolute point across a comparison boundary.
      geometry: _geometrySignatures(sourceDocument.rootElement),
      paint: _paintSignatures(sourceDocument.rootElement),
    );
  }

  final String canonicalSvg;
  final String? viewBox;
  final List<String> text;
  final Map<String, int> elementCounts;
  final List<String> geometry;
  final List<String> paint;
}

final class SvgComparison {
  const SvgComparison({
    required this.exact,
    required this.sameViewport,
    required this.sameText,
    required this.sameElementCounts,
    required this.sameGeometry,
    required this.samePaint,
  });

  factory SvgComparison.compare(SvgSnapshot dart, SvgSnapshot mermaid) {
    final sameGeometry = _listEquals(dart.geometry, mermaid.geometry);
    return SvgComparison(
      exact: dart.canonicalSvg == mermaid.canonicalSvg,
      sameViewport: dart.viewBox == null || mermaid.viewBox == null || dart.viewBox == mermaid.viewBox,
      sameText: _listEquals(dart.text, mermaid.text),
      sameElementCounts: _mapEquals(dart.elementCounts, mermaid.elementCounts),
      sameGeometry: sameGeometry,
      // Paint is paired with normalized geometry. If geometry differs, the
      // paint comparison has no reliable element correspondence of its own.
      samePaint: !sameGeometry || _listEquals(dart.paint, mermaid.paint),
    );
  }

  final bool exact;
  final bool sameViewport;
  final bool sameText;
  final bool sameElementCounts;
  final bool sameGeometry;
  final bool samePaint;

  bool get visualParity => sameViewport && sameText && sameElementCounts && sameGeometry && samePaint;

  String get summary => exact
      ? 'exact'
      : [
          if (!sameViewport) 'viewport',
          if (!sameText) 'text',
          if (!sameElementCounts) 'elements',
          if (!sameGeometry) 'geometry',
          if (!samePaint) 'paint',
        ].join(', ');
}

const _visibleElements = {'circle', 'ellipse', 'foreignObject', 'line', 'path', 'polygon', 'polyline', 'rect', 'text'};

List<String> _geometrySignatures(XmlElement root) => _elementSignatures(root, _geometrySignature);

List<String> _paintSignatures(XmlElement root) => _elementSignatures(root, _paintSignature);

List<String> _elementSignatures(
  XmlElement root,
  String Function(XmlElement element, String transform, String styleSheets) signature,
) {
  final signatures = <String>[];
  final styleSheets = root.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 'style')
      .map((element) => element.innerText)
      .join('\n');

  void visit(XmlElement element, String inheritedTransform) {
    if (!_isComparableGeometryElement(element, root)) return;
    final ownTransform = element.getAttribute('transform') ?? '';
    final stylesheetScale = _stylesheetScaleTransform(element, styleSheets);
    final transform = [inheritedTransform, ownTransform, stylesheetScale].where((value) => value.isNotEmpty).join(' ');
    final isEmptyText =
        (element.name.local == 'text' || element.name.local == 'foreignObject') && element.innerText.trim().isEmpty;
    if (_visibleElements.contains(element.name.local) && !isEmptyText) {
      signatures.add(signature(element, transform, styleSheets));
    }
    for (final child in element.childElements) {
      visit(child, transform);
    }
  }

  visit(root, '');
  return signatures..sort();
}

/// Converts Mermaid's static CSS `scale` property into the equivalent SVG
/// transform so stylesheet-driven and explicitly positioned geometry compare
/// identically. Interactive pseudo-class rules do not match until activated.
String _stylesheetScaleTransform(XmlElement element, String styleSheets) {
  final value = _stylesheetProperty(
    element,
    styleSheets,
    'scale',
  )?.replaceFirst(RegExp(r'\s*!important\s*$', caseSensitive: false), '').trim();
  return value == null || value.isEmpty || value == 'none' ? '' : 'scale($value)';
}

// SVG presentation properties that materially affect the visible paint while
// remaining backend-neutral. Geometry and text positioning are compared
// separately, so typography metrics do not belong in this list.
const _paintProperties = <String, String>{
  'fill': 'black',
  'stroke': 'none',
  'stroke-width': '1',
  'stroke-dasharray': 'none',
  'stroke-linecap': 'butt',
  'stroke-linejoin': 'miter',
};

// A line has no enclosed area, so fill and join properties cannot change its
// rendered appearance.
const _linePaintProperties = <String, String>{
  'stroke': 'none',
  'stroke-width': '1',
  'stroke-dasharray': 'none',
  'stroke-linecap': 'butt',
};

String _paintSignature(XmlElement element, String transform, String styleSheets) {
  final geometry = _geometrySignature(element, transform, styleSheets);
  final properties = element.name.local == 'line' ? _linePaintProperties : _paintProperties;
  final normalized = {
    for (final MapEntry(:key, :value) in properties.entries)
      key: _normalizedPaintValue(
        key,
        _inheritedPresentationValue(element, key, styleSheets) ?? value,
        element,
        styleSheets,
      ),
  };
  final fillOpacity = _effectiveChannelOpacity(element, 'fill-opacity', styleSheets);
  final strokeOpacity = _effectiveChannelOpacity(element, 'stroke-opacity', styleSheets);
  if (fillOpacity == '0') normalized['fill'] = 'none';
  if (strokeOpacity == '0') normalized['stroke'] = 'none';
  final values = <String>[
    for (final MapEntry(:key, :value) in normalized.entries) '$key=$value',
    if (normalized['fill'] != null && normalized['fill'] != 'none') 'fill-opacity=$fillOpacity',
    if (normalized['stroke'] != 'none') 'stroke-opacity=$strokeOpacity',
  ];
  return '$geometry|${values.join('|')}';
}

String? _inheritedPresentationValue(XmlElement element, String name, String styleSheets) {
  for (XmlElement? current = element; current != null; current = current.parentElement) {
    final value = _localPresentationValue(current, name, styleSheets);
    if (value != null && value != 'inherit') return value;
  }
  return null;
}

String? _localPresentationValue(XmlElement element, String name, String styleSheets) =>
    _inlineStyleValue(element, name) ?? _stylesheetProperty(element, styleSheets, name) ?? element.getAttribute(name);

String? _inlineStyleValue(XmlElement element, String name) {
  for (final declaration in (element.getAttribute('style') ?? '').split(';').reversed) {
    final separator = declaration.indexOf(':');
    if (separator < 0 || declaration.substring(0, separator).trim() != name) continue;
    return declaration.substring(separator + 1).trim();
  }
  return null;
}

String? _stylesheetProperty(XmlElement element, String styleSheets, String name) {
  String? value;
  for (final rule in _cssRule.allMatches(styleSheets)) {
    for (final selector in rule[1]!.split(',')) {
      if (!_matchesSimpleSelector(element, selector.trim())) continue;
      final declaration = RegExp(
        '(?:^|;)\\s*${RegExp.escape(name)}\\s*:\\s*([^;]+)',
        caseSensitive: false,
      ).firstMatch(rule[2]!);
      if (declaration != null) value = declaration[1]!.trim();
    }
  }
  return value;
}

String _effectiveChannelOpacity(XmlElement element, String channel, String styleSheets) {
  final channelOpacity = double.tryParse(_inheritedPresentationValue(element, channel, styleSheets) ?? '') ?? 1;
  final paintChannel = channel == 'fill-opacity' ? 'fill' : 'stroke';
  final paint = _inheritedPresentationValue(element, paintChannel, styleSheets) ?? '';
  final embeddedOpacity = _parseRgba(paint)?.alpha ?? 1;
  return _formatNumber(channelOpacity * embeddedOpacity * _effectiveOpacity(element, styleSheets));
}

double _effectiveOpacity(XmlElement element, String styleSheets) {
  var opacity = 1.0;
  for (XmlElement? current = element; current != null; current = current.parentElement) {
    final value = _localPresentationValue(current, 'opacity', styleSheets);
    if (value != null) opacity *= double.tryParse(value) ?? 1;
  }
  return opacity;
}

String _normalizedPaintValue(String name, String value, XmlElement element, String styleSheets) {
  var normalized = value
      .replaceFirst(RegExp(r'\s*!important\s*$', caseSensitive: false), '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
  if (normalized == 'currentcolor') {
    normalized = _inheritedPresentationValue(element, 'color', styleSheets) ?? 'black';
  }
  if (name == 'fill' || name == 'stroke') return _normalizedColor(normalized);
  if (name == 'stroke-dasharray' && normalized != 'none') {
    return normalized
        .split(_svgNumericListSeparator)
        .where((part) => part.isNotEmpty)
        .map(
          (part) => switch (double.tryParse(part)) {
            final number? => _formatNumber(number),
            null => part,
          },
        )
        .join(' ');
  }
  if (name == 'stroke-width' && normalized.endsWith('px')) {
    normalized = normalized.substring(0, normalized.length - 2);
  }
  final number = double.tryParse(normalized);
  return number == null ? normalized : _formatNumber(number);
}

final _svgNumericListSeparator = RegExp(r'[\s,]+');

String _normalizedColor(String value) {
  final compact = value.replaceAll(' ', '');
  if (_namedCssColors[compact] case final hex?) return hex;
  if (compact.startsWith('#') && compact.length == 4) {
    final hex = compact.substring(1);
    return '#${[for (final digit in hex.split('')) '$digit$digit'].join()}';
  }
  if (_parseRgba(compact) case (:final channels, alpha: _)) {
    // Alpha participates in the separately normalized channel opacity.
    return _hexColor(channels);
  }
  final rgb = _rgbColor.firstMatch(compact);
  if (rgb != null) {
    final channels = [for (var index = 1; index <= 3; index++) int.parse(rgb[index]!)];
    return _hexColor(channels);
  }
  final hsl = _hslColor.firstMatch(compact);
  if (hsl != null) {
    final hue = (double.parse(hsl[1]!) % _fullHueDegrees) / _fullHueDegrees;
    final saturation = double.parse(hsl[2]!) / _fullPercentage;
    final lightness = double.parse(hsl[3]!) / _fullPercentage;
    if (saturation == 0) {
      final gray = (lightness * _colorChannelMax).round();
      return _hexColor([gray, gray, gray]);
    }
    final upper = lightness < _halfIntensity
        ? lightness * (1 + saturation)
        : lightness + saturation - lightness * saturation;
    final lower = 2 * lightness - upper;
    return _hexColor([
      (_hueChannel(lower, upper, hue + _oneThirdTurn) * _colorChannelMax).round(),
      (_hueChannel(lower, upper, hue) * _colorChannelMax).round(),
      (_hueChannel(lower, upper, hue - _oneThirdTurn) * _colorChannelMax).round(),
    ]);
  }
  return compact;
}

// Named colors emitted by Mermaid themes that need comparison with scene
// colors, which are serialized as hexadecimal RGB values.
const _namedCssColors = <String, String>{
  'black': '#000000',
  'lightgrey': '#d3d3d3',
  'red': '#ff0000',
  'white': '#ffffff',
};

({List<int> channels, double alpha})? _parseRgba(String value) {
  final compact = value
      .replaceFirst(RegExp(r'\s*!important\s*$', caseSensitive: false), '')
      .replaceAll(' ', '')
      .toLowerCase();
  final match = _rgbaColor.firstMatch(compact);
  if (match == null) return null;
  return (
    channels: [for (var index = 1; index <= 3; index++) int.parse(match[index]!)],
    alpha: double.parse(match[4]!),
  );
}

String _hexColor(List<int> channels) =>
    '#${channels.map((channel) => channel.clamp(0, _colorChannelMax).toInt().toRadixString(16).padLeft(2, '0')).join()}';

double _hueChannel(double lower, double upper, double hue) {
  if (hue < 0) hue += 1;
  if (hue > 1) hue -= 1;
  if (hue < _oneSixthTurn) return lower + (upper - lower) * hue / _oneSixthTurn;
  if (hue < _halfIntensity) return upper;
  if (hue < _twoThirdsTurn) {
    return lower + (upper - lower) * (_twoThirdsTurn - hue) / _oneSixthTurn;
  }
  return lower;
}

// CSS color-space constants used by the HSL-to-RGB conversion.
const _colorChannelMax = 255;
const _fullHueDegrees = 360;
const _fullPercentage = 100;
const _halfIntensity = 0.5;
const _oneSixthTurn = 1 / 6;
const _oneThirdTurn = 1 / 3;
const _twoThirdsTurn = 2 / 3;

final _rgbColor = RegExp(r'^rgb\((\d{1,3}),(\d{1,3}),(\d{1,3})\)$');
final _rgbaColor = RegExp(r'^rgba\((\d{1,3}),(\d{1,3}),(\d{1,3}),((?:\d+\.?\d*|\.\d+))\)$');
final _hslColor = RegExp(r'^hsl\((-?(?:\d+\.?\d*|\.\d+)),((?:\d+\.?\d*|\.\d+))%,((?:\d+\.?\d*|\.\d+))%\)$');

String _geometrySignature(XmlElement element, String transform, String styleSheets) {
  final styles = <String, String>{
    for (final declaration in (element.getAttribute('style') ?? '').split(';'))
      if (declaration.split(':') case [final name, final value]) name.trim(): value.trim(),
  };
  String attribute(String name, [String fallback = '']) => element.getAttribute(name) ?? styles[name] ?? fallback;
  final translation = _Translation.parse(transform);
  String number(String value) => _translatedNumber(value, 0);
  String x(String value) => _translatedNumber(value, translation?.dx ?? 0);
  String y(String value) => _translatedNumber(value, translation?.dy ?? 0);
  final name = element.name.local;
  final values = switch (name) {
    'circle' => [x(attribute('cx', '0')), y(attribute('cy', '0')), number(attribute('r', '0'))],
    'ellipse' => [
      x(attribute('cx', '0')),
      y(attribute('cy', '0')),
      number(attribute('rx', '0')),
      number(attribute('ry', '0')),
    ],
    'line' => [x(attribute('x1', '0')), y(attribute('y1', '0')), x(attribute('x2', '0')), y(attribute('y2', '0'))],
    'path' => [
      _translatedPath(
        attribute('d'),
        translation,
        roundingBias: _hasScaleTransform(transform) ? _scaledPathRoundingBias : _numericComparisonTieEpsilon,
      ),
    ],
    'polygon' => [_translatedPolygonPoints(attribute('points'), translation)],
    'polyline' => [_translatedPoints(attribute('points'), translation)],
    'rect' => [
      x(attribute('x', '0')),
      y(attribute('y', '0')),
      number(attribute('width', '0')),
      number(attribute('height', '0')),
      number(attribute('rx', '0')),
      number(attribute('ry', attribute('rx', '0'))),
    ],
    'foreignObject' => _foreignObjectGeometryValues(element, translation),
    'text' => _textGeometryValues(element, translation, styleSheets, attribute),
    _ => const <String>[],
  };
  final kind = name == 'foreignObject' ? 'text' : name;
  final text = name == 'text' || name == 'foreignObject' ? _normalizedVisibleText(element) : '';
  return [kind, if (translation == null) _normalizedTransform(transform) else '', ...values, text].join('|');
}

bool _isComparableGeometryElement(XmlElement element, XmlElement root) {
  for (XmlElement? ancestor = element; ancestor != null && ancestor != root; ancestor = ancestor.parentElement) {
    final classes = (ancestor.getAttribute('class') ?? '').split(RegExp(r'\s+'));
    if (ancestor.name.local == 'svg' ||
        ancestor.name.local == 'defs' ||
        ancestor.name.local == 'clipPath' ||
        _isDisplayNone(ancestor) ||
        ancestor.getAttribute('data-role') == 'icon' ||
        classes.contains('treemapSectionHeader') ||
        classes.contains('wardley-link-arrow') ||
        classes.contains('wardley-trend-arrow') ||
        classes.contains('em-arrowhead')) {
      return false;
    }
  }
  if (element.name.local == 'rect' &&
      (_numberAttribute(element, 'width') ?? 0) == 0 &&
      (_numberAttribute(element, 'height') ?? 0) == 0) {
    return false;
  }
  return true;
}

bool _isDisplayNone(XmlElement element) {
  if (element.getAttribute('display') == 'none') return true;
  final style = element.getAttribute('style') ?? '';
  return RegExp(r'(?:^|;)\s*display\s*:\s*none\s*(?:;|$)', caseSensitive: false).hasMatch(style);
}

double? _numberAttribute(XmlElement element, String name) => double.tryParse(element.getAttribute(name) ?? '');

List<String> _foreignObjectGeometryValues(XmlElement element, _Translation? translation) {
  final left = _numberAttribute(element, 'x') ?? 0;
  final top = _numberAttribute(element, 'y') ?? 0;
  final width = _numberAttribute(element, 'width') ?? 0;
  final height = _numberAttribute(element, 'height') ?? 0;
  return [
    _formatNumber(left + width / 2 + (translation?.dx ?? 0)),
    _formatNumber(top + height / 2 + (translation?.dy ?? 0)),
    '16',
    'middle',
    'central',
  ];
}

String _normalizedVisibleText(XmlElement element) {
  final buffer = StringBuffer();

  void collect(XmlNode node) {
    switch (node) {
      case XmlText(:final value):
        buffer.write(value.replaceAll('\u00a0', ' '));
      case XmlElement() when node.name.local == 'br':
        buffer.write(' ');
      case XmlElement(:final children) when node.name.local == 'tspan':
        for (final child in children) {
          collect(child);
        }
        buffer.write(' ');
      case XmlElement(:final children):
        for (final child in children) {
          collect(child);
        }
      default:
        break;
    }
  }

  collect(element);
  return buffer.toString().trim().replaceAll(RegExp(r'\s+'), ' ');
}

List<String> _textGeometryValues(
  XmlElement element,
  _Translation? translation,
  String styleSheets,
  String Function(String name, [String fallback]) attribute,
) {
  final fontSize = _svgLength(attribute('font-size', _stylesheetFontSize(element, styleSheets) ?? '16'), 16);
  final span = element.descendants.whereType<XmlElement>().where((child) => child.name.local == 'tspan').firstOrNull;
  final localX = _svgLength(span?.getAttribute('x') ?? attribute('x', '0'), fontSize);
  final localY =
      _svgLength(span?.getAttribute('y') ?? attribute('y', '0'), fontSize) +
      _svgLength(span?.getAttribute('dy') ?? '0', fontSize);
  final anchor =
      attribute('text-anchor', '').nullIfEmpty ??
      _inheritedAttribute(element, 'text-anchor') ??
      _stylesheetTextAnchor(element, styleSheets) ??
      'start';
  final rawBaseline =
      attribute('dominant-baseline', '').nullIfEmpty ??
      _inheritedAttribute(element, 'dominant-baseline') ??
      _stylesheetBaseline(element, styleSheets) ??
      'alphabetic';
  final baseline = switch (rawBaseline) {
    'auto' => 'alphabetic',
    'start' => 'hanging',
    'middle' || 'central' => 'central',
    final value => value,
  };
  return [
    _formatNumber(localX + (translation?.dx ?? 0)),
    _formatNumber(localY + (translation?.dy ?? 0)),
    _formatNumber(fontSize),
    anchor,
    baseline,
  ];
}

String? _inheritedAttribute(XmlElement element, String name) {
  for (var ancestor = element.parentElement; ancestor != null; ancestor = ancestor.parentElement) {
    if (ancestor.getAttribute(name) case final value?) return value;
  }
  return null;
}

double _svgLength(String value, double fontSize) {
  final trimmed = value.trim();
  if (trimmed.endsWith('em')) return double.parse(trimmed.substring(0, trimmed.length - 2)) * fontSize;
  if (trimmed.endsWith('px')) return double.parse(trimmed.substring(0, trimmed.length - 2));
  return double.parse(trimmed);
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}

String _normalizedTransform(String transform) => _transformFunction
    .allMatches(transform)
    .map((match) {
      final values = _pathToken.allMatches(match[2]!).map((value) => _formatNumber(double.parse(value[0]!))).join(' ');
      return '${match[1]!.toLowerCase()}($values)';
    })
    .join(' ');

final class _Translation {
  const _Translation(this.dx, this.dy);

  static _Translation? parse(String transform) {
    if (transform.trim().isEmpty) return const _Translation(0, 0);
    final matches = _translate.allMatches(transform).toList();
    if (matches.isEmpty || transform.replaceAll(_translate, '').trim().isNotEmpty) return null;
    var dx = 0.0;
    var dy = 0.0;
    for (final match in matches) {
      dx += double.parse(match[1]!);
      dy += double.parse(match[2] ?? '0');
    }
    return _Translation(dx, dy);
  }

  final double dx;
  final double dy;
}

final _translate = RegExp(
  r'translate\(\s*(-?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?)'
  r'(?:\s*[, ]\s*(-?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?))?\s*\)',
  caseSensitive: false,
);
final _pathToken = RegExp(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?', caseSensitive: false);
final _transformFunction = RegExp(r'([A-Za-z]+)\s*\(([^)]*)\)');

String _translatedNumber(String value, double offset) => _formatNumber(double.parse(value) + offset);

String? _normalizedNumberList(String? value) {
  if (value == null) return null;
  return value
      .trim()
      .split(RegExp(r'[\s,]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => _formatNumber(double.parse(part)))
      .join(' ');
}

String _formatNumber(double value, {double roundingBias = _numericComparisonTieEpsilon}) {
  final tieAdjusted = value + (value.isNegative ? -roundingBias : roundingBias);
  var formatted = tieAdjusted.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  if (formatted == '-0') formatted = '0';
  return formatted;
}

// Canonical SVG may truncate a value exactly onto a half-cent boundary before
// this visual comparison runs. Bias exact ties by a negligible amount.
const _numericComparisonTieEpsilon = 1e-9;

// Mermaid's D3 paths use three fractional digits while the Dart serializer
// retains four. Scaled paths can therefore straddle a centipixel boundary;
// half of one millipixel covers the serializers' maximum rounding delta.
const _scaledPathRoundingBias = .0005;

String? _stylesheetFontSize(XmlElement element, String styleSheets) {
  String? fontSize;
  for (final rule in _cssRule.allMatches(styleSheets)) {
    final declaration = _cssFontSize.firstMatch(rule[2]!);
    if (declaration == null) continue;
    for (final selector in rule[1]!.split(',')) {
      if (_matchesSimpleSelector(element, selector.trim())) {
        fontSize = _formatNumber(double.parse(declaration[1]!));
      }
    }
  }
  return fontSize;
}

String? _stylesheetBaseline(XmlElement element, String styleSheets) =>
    _stylesheetValue(element, styleSheets, _cssBaseline);

String? _stylesheetTextAnchor(XmlElement element, String styleSheets) =>
    _stylesheetValue(element, styleSheets, _cssTextAnchor);

String? _stylesheetValue(XmlElement element, String styleSheets, RegExp declarationPattern) {
  String? value;
  for (final rule in _cssRule.allMatches(styleSheets)) {
    final declaration = declarationPattern.firstMatch(rule[2]!);
    if (declaration == null) continue;
    for (final selector in rule[1]!.split(',')) {
      if (_matchesSimpleSelector(element, selector.trim())) value = declaration[1];
    }
  }
  return value;
}

bool _matchesSimpleSelector(XmlElement element, String selector) {
  final parts = selector.split(RegExp(r'\s+'));
  // Mermaid scopes generated rules under the root SVG ID. Ignore that scope
  // only for descendant selectors; a standalone ID selector still targets the
  // root element and must not match every descendant.
  if (parts.length > 1 && parts.first.startsWith('#')) parts.removeAt(0);
  if (parts.isEmpty) return true;
  if (!_matchesSelectorPart(element, parts.last)) return false;
  var ancestor = element.parentElement;
  for (var index = parts.length - 2; index >= 0; index--) {
    while (ancestor != null && !_matchesSelectorPart(ancestor, parts[index])) {
      ancestor = ancestor.parentElement;
    }
    if (ancestor == null) return false;
    ancestor = ancestor.parentElement;
  }
  return true;
}

bool _matchesSelectorPart(XmlElement element, String selector) {
  selector = selector.replaceFirst(RegExp(r':.*$'), '');
  if (selector == '*') return true;
  final tokens = _simpleSelectorToken.allMatches(selector).toList();
  if (tokens.isEmpty || tokens.map((token) => token[0]).join() != selector) return false;
  final classes = (element.getAttribute('class') ?? '').split(RegExp(r'\s+')).toSet();
  for (final token in tokens) {
    final prefix = token[1]!;
    final value = token[2]!;
    final matches = switch (prefix) {
      '' => element.name.local == value,
      '.' => classes.contains(value),
      '#' => element.getAttribute('id') == value || (element.name.local == 'svg' && element.parentElement == null),
      _ => false,
    };
    if (!matches) return false;
  }
  return true;
}

final _cssRule = RegExp(r'([^{}]+)\{([^{}]*)\}');
final _simpleSelectorToken = RegExp(r'([.#]?)([A-Za-z_][\w-]*)');
final _cssFontSize = RegExp(r'font-size\s*:\s*(-?(?:\d+\.?\d*|\.\d+))px', caseSensitive: false);
final _cssBaseline = RegExp(r'dominant-baseline\s*:\s*([\w-]+)', caseSensitive: false);
final _cssTextAnchor = RegExp(r'text-anchor\s*:\s*([\w-]+)', caseSensitive: false);

String _translatedPoints(String points, _Translation? translation) {
  final values = _pathToken.allMatches(points).map((match) => double.parse(match[0]!)).toList();
  return [
    for (var index = 0; index < values.length; index += 2)
      '${_formatNumber(values[index] + (translation?.dx ?? 0))},'
          '${_formatNumber(values[index + 1] + (translation?.dy ?? 0))}',
  ].join(' ');
}

String _translatedPolygonPoints(String points, _Translation? translation) {
  final translated = _translatedPoints(points, translation).split(' ');
  if (translated.length < 2) return translated.join(' ');
  final rotations = [
    for (var offset = 0; offset < translated.length; offset++)
      [...translated.skip(offset), ...translated.take(offset)].join(' '),
  ]..sort();
  return rotations.first;
}

String _translatedPath(String path, _Translation? translation, {double roundingBias = _numericComparisonTieEpsilon}) {
  final canonicalPath = _canonicalAxisAlignedCommands(path);
  final tokens = _pathToken.allMatches(canonicalPath).map((match) => match[0]!).toList();
  final result = <String>[];
  String? command;
  var parameter = 0;
  for (final token in tokens) {
    if (RegExp(r'^[A-Za-z]$').hasMatch(token)) {
      command = token;
      parameter = 0;
      result.add(token);
      continue;
    }
    final value = double.parse(token);
    final offset = command == null || command == command.toLowerCase()
        ? 0.0
        : switch (command.toUpperCase()) {
            'H' => translation?.dx ?? 0,
            'V' => translation?.dy ?? 0,
            'M' || 'L' || 'T' => parameter.isEven ? translation?.dx ?? 0 : translation?.dy ?? 0,
            'C' => switch (parameter % 6) {
              0 || 2 || 4 => translation?.dx ?? 0,
              _ => translation?.dy ?? 0,
            },
            'S' || 'Q' => switch (parameter % 4) {
              0 || 2 => translation?.dx ?? 0,
              _ => translation?.dy ?? 0,
            },
            'A' => switch (parameter % 7) {
              5 => translation?.dx ?? 0,
              6 => translation?.dy ?? 0,
              _ => 0,
            },
            _ => 0,
          };
    result.add(_formatNumber(value + offset, roundingBias: roundingBias));
    parameter++;
  }
  return result.join(' ');
}

bool _hasScaleTransform(String transform) =>
    _transformFunction.allMatches(transform).any((match) => match[1]!.toLowerCase() == 'scale');

String _canonicalAxisAlignedCommands(String path) {
  final tokens = _pathToken.allMatches(path).map((match) => match[0]!).toList();
  final result = <String>[];
  var cursor = 0;
  String? command;
  var currentX = 0.0;
  var currentY = 0.0;
  var subpathX = 0.0;
  var subpathY = 0.0;
  var consumedMove = false;
  while (cursor < tokens.length) {
    if (_isPathCommand(tokens[cursor])) {
      command = tokens[cursor++];
      consumedMove = false;
      if (command.toUpperCase() == 'Z') {
        result.add(command);
        currentX = subpathX;
        currentY = subpathY;
        continue;
      }
    }
    if (command == null) return path;
    final upper = command.toUpperCase();
    final arity = _pathCommandArity(upper);
    if (arity == 0 || cursor + arity > tokens.length || _isPathCommand(tokens[cursor])) return path;
    final values = [for (var index = 0; index < arity; index++) double.parse(tokens[cursor++])];
    final relative = command == command.toLowerCase();
    if (upper == 'H') {
      final x = relative ? currentX + values.single : values.single;
      result.addAll([
        relative ? 'l' : 'L',
        relative ? values.single.toString() : x.toString(),
        relative ? '0' : currentY.toString(),
      ]);
      currentX = x;
      continue;
    }
    if (upper == 'V') {
      final y = relative ? currentY + values.single : values.single;
      result.addAll([
        relative ? 'l' : 'L',
        relative ? '0' : currentX.toString(),
        relative ? values.single.toString() : y.toString(),
      ]);
      currentY = y;
      continue;
    }
    final emittedCommand = upper == 'M' && consumedMove ? (relative ? 'l' : 'L') : command;
    result.add(emittedCommand);
    result.addAll(values.map((value) => value.toString()));
    final end = switch (upper) {
      'M' || 'L' || 'T' => (values[arity - 2], values[arity - 1]),
      'C' || 'S' || 'Q' => (values[arity - 2], values[arity - 1]),
      'A' => (values[5], values[6]),
      _ => (currentX, currentY),
    };
    currentX = relative ? currentX + end.$1 : end.$1;
    currentY = relative ? currentY + end.$2 : end.$2;
    if (upper == 'M' && !consumedMove) {
      subpathX = currentX;
      subpathY = currentY;
      consumedMove = true;
    }
  }
  return result.join(' ');
}

bool _isPathCommand(String token) => token.length == 1 && RegExp(r'[A-Za-z]').hasMatch(token);

int _pathCommandArity(String command) => switch (command) {
  'H' || 'V' => 1,
  'M' || 'L' || 'T' => 2,
  'S' || 'Q' => 4,
  'C' => 6,
  'A' => 7,
  _ => 0,
};

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (left.length != right.length) return false;
  for (final MapEntry(:key, :value) in left.entries) {
    if (right[key] != value) return false;
  }
  return true;
}
