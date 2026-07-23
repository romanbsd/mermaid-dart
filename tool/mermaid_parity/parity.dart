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
    const flowchartDefaults = FlowchartRenderOptions();
    const ganttDefaults = GanttRenderOptions();
    const gitGraphDefaults = GitGraphRenderOptions();
    const kanbanDefaults = KanbanRenderOptions();
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
      flowchart: FlowchartRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, flowchartDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, flowchartDefaults),
        nodeSpacing: (diagramConfig['nodeSpacing'] as num?)?.toDouble() ?? flowchartDefaults.nodeSpacing,
        rankSpacing: (diagramConfig['rankSpacing'] as num?)?.toDouble() ?? flowchartDefaults.rankSpacing,
        diagramPadding: (diagramConfig['diagramPadding'] as num?)?.toDouble() ?? flowchartDefaults.diagramPadding,
        nodePadding: (diagramConfig['nodePadding'] as num?)?.toDouble() ?? flowchartDefaults.nodePadding,
        edgeWidth: (diagramConfig['edgeWidth'] as num?)?.toDouble() ?? flowchartDefaults.edgeWidth,
      ),
      gantt: GanttRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, ganttDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, ganttDefaults),
        titleTopMargin: (diagramConfig['titleTopMargin'] as num?)?.toDouble() ?? ganttDefaults.titleTopMargin,
        barHeight: (diagramConfig['barHeight'] as num?)?.toDouble() ?? ganttDefaults.barHeight,
        barGap: (diagramConfig['barGap'] as num?)?.toDouble() ?? ganttDefaults.barGap,
        topPadding: (diagramConfig['topPadding'] as num?)?.toDouble() ?? ganttDefaults.topPadding,
        rightPadding: (diagramConfig['rightPadding'] as num?)?.toDouble() ?? ganttDefaults.rightPadding,
        leftPadding: (diagramConfig['leftPadding'] as num?)?.toDouble() ?? ganttDefaults.leftPadding,
        gridLineStartPadding:
            (diagramConfig['gridLineStartPadding'] as num?)?.toDouble() ?? ganttDefaults.gridLineStartPadding,
        fontSize: (diagramConfig['fontSize'] as num?)?.toDouble() ?? ganttDefaults.fontSize,
        sectionFontSize: (diagramConfig['sectionFontSize'] as num?)?.toDouble() ?? ganttDefaults.sectionFontSize,
        numberSectionStyles: diagramConfig['numberSectionStyles'] as int? ?? ganttDefaults.numberSectionStyles,
        axisFormat: diagramConfig['axisFormat'] as String? ?? ganttDefaults.axisFormat,
        tickInterval: switch (diagramConfig['tickInterval']) {
          final String value => _ganttTickInterval(value),
          _ => ganttDefaults.tickInterval,
        },
        topAxis: diagramConfig['topAxis'] as bool? ?? ganttDefaults.topAxis,
        displayMode: switch (diagramConfig['displayMode']) {
          'compact' => GanttDisplayMode.compact,
          _ => ganttDefaults.displayMode,
        },
        weekday: switch (diagramConfig['weekday']) {
          final String value => GanttWeekday.values.byName(value),
          _ => ganttDefaults.weekday,
        },
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
      kanban: KanbanRenderOptions(
        useWidth: _configuredUseWidth(diagramConfig, kanbanDefaults),
        useMaxWidth: _configuredUseMaxWidth(diagramConfig, kanbanDefaults),
        padding: (diagramConfig['padding'] as num?)?.toDouble() ?? kanbanDefaults.padding,
        sectionWidth: (diagramConfig['sectionWidth'] as num?)?.toDouble() ?? kanbanDefaults.sectionWidth,
        ticketBaseUrl: diagramConfig['ticketBaseUrl'] as String? ?? kanbanDefaults.ticketBaseUrl,
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
        fontSize: (diagramConfig['fontSize'] as num?)?.toDouble(),
        fontFamily: diagramConfig['fontFamily'] as String?,
        strokeWidth: (diagramConfig['strokeWidth'] as num?)?.toDouble(),
        showMarkers: diagramConfig['showMarkers'] as bool? ?? railroadDefaults.showMarkers,
        markerRadius: (diagramConfig['markerRadius'] as num?)?.toDouble() ?? railroadDefaults.markerRadius,
        terminalFill: _configuredOptionalColor(diagramConfig, 'terminalFill'),
        terminalStroke: _configuredOptionalColor(diagramConfig, 'terminalStroke'),
        terminalTextColor: _configuredOptionalColor(diagramConfig, 'terminalTextColor'),
        nonTerminalFill: _configuredOptionalColor(diagramConfig, 'nonTerminalFill'),
        nonTerminalStroke: _configuredOptionalColor(diagramConfig, 'nonTerminalStroke'),
        nonTerminalTextColor: _configuredOptionalColor(diagramConfig, 'nonTerminalTextColor'),
        lineColor: _configuredOptionalColor(diagramConfig, 'lineColor'),
        markerFill: _configuredOptionalColor(diagramConfig, 'markerFill'),
        commentFill: _configuredOptionalColor(diagramConfig, 'commentFill'),
        commentStroke: _configuredOptionalColor(diagramConfig, 'commentStroke'),
        commentTextColor: _configuredOptionalColor(diagramConfig, 'commentTextColor'),
        specialFill: _configuredOptionalColor(diagramConfig, 'specialFill'),
        specialStroke: _configuredOptionalColor(diagramConfig, 'specialStroke'),
        ruleNameColor: _configuredOptionalColor(diagramConfig, 'ruleNameColor'),
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
const _gitThemePaletteLength = 8;

const _themeColorKeys = {
  'background',
  'primaryColor',
  'primaryBorderColor',
  'primaryTextColor',
  'lineColor',
  'secondaryColor',
  'tertiaryColor',
  'secondaryBorderColor',
  'tertiaryBorderColor',
  'secondaryTextColor',
  'tertiaryTextColor',
  'textColor',
  'titleColor',
  'mainBkg',
  'secondBkg',
  'labelBackground',
  'nodeBorder',
  'archEdgeColor',
  'archEdgeArrowColor',
  'archGroupBorderColor',
  'emUiFill',
  'emUiStroke',
  'emProcessorFill',
  'emProcessorStroke',
  'emReadModelFill',
  'emReadModelStroke',
  'emCommandFill',
  'emCommandStroke',
  'emEventFill',
  'emEventStroke',
  'emSwimlaneBackgroundOdd',
  'emSwimlaneBackgroundStroke',
  'emArrowhead',
  'emRelationStroke',
  'tagLabelColor',
  'tagLabelBackground',
  'tagLabelBorder',
  'commitLabelColor',
  'commitLabelBackground',
  'commitLineColor',
  'filterColor',
  'pieTitleTextColor',
  'pieSectionTextColor',
  'pieLegendTextColor',
  'pieStrokeColor',
  'pieOuterStrokeColor',
};

const _themeNumberKeys = {
  'strokeWidth',
  'fontSize',
  'THEME_COLOR_LIMIT',
  'archEdgeWidth',
  'archGroupBorderWidth',
  'tagLabelFontSize',
  'commitLabelFontSize',
  'pieTitleTextSize',
  'pieSectionTextSize',
  'pieLegendTextSize',
  'pieStrokeWidth',
  'pieOuterStrokeWidth',
  'pieOpacity',
};

const _nestedThemeColorKeys = {
  'cynefin': {
    'boundaryColor',
    'cliffColor',
    'arrowColor',
    'complexBg',
    'complicatedBg',
    'chaoticBg',
    'clearBg',
    'confusionBg',
    'textColor',
    'labelColor',
  },
  'radar': {'axisColor', 'graticuleColor'},
  'wardley': {
    'backgroundColor',
    'axisColor',
    'axisTextColor',
    'gridColor',
    'componentFill',
    'componentStroke',
    'componentLabelColor',
    'linkStroke',
    'evolutionStroke',
    'annotationStroke',
    'annotationTextColor',
    'annotationFill',
  },
};

const _nestedThemeNumberKeys = {
  'cynefin': {'domainFontSize', 'itemFontSize', 'boundaryWidth', 'cliffWidth', 'arrowWidth'},
  'radar': {
    'axisStrokeWidth',
    'axisLabelFontSize',
    'curveOpacity',
    'curveStrokeWidth',
    'graticuleStrokeWidth',
    'graticuleOpacity',
    'legendBoxSize',
    'legendFontSize',
  },
  'wardley': <String>{},
};

Map<String, Object> _themeVariables(Object? value) {
  if (value == null) return const {};
  if (value is! Map<String, Object?> || value.isEmpty) {
    throw const FormatException('Invalid fixture themeVariables');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final isPalette = RegExp(
      r'^(?:pie(?:[1-9]|1[0-2])|cScale(?:Peer|Label)?(?:[0-9]|1[01])|git(?:Inv)?[0-7]|gitBranchLabel[0-7])$',
    ).hasMatch(key);
    final validated = switch ((key, value)) {
      (final key, final String color) when (isPalette || _themeColorKeys.contains(key)) => _validatedThemeColor(color),
      (final key, final Object number) when _themeNumberKeys.contains(key) => _validatedThemeNumber(key, number),
      ('fontFamily', final String family) when family.trim().isNotEmpty => family.trim(),
      ('useGradient', final bool enabled) => enabled,
      ('gradientStart' || 'gradientStop', final String color) => _validatedThemeColor(color),
      ('dropShadow', final String shadow) when _themeShadow(shadow) != null => shadow.trim(),
      (final nested, final Map<String, Object?> values) when _nestedThemeColorKeys.containsKey(nested) =>
        _validatedNestedTheme(nested, values),
      _ => null,
    };
    if (validated == null) {
      throw const FormatException('Invalid fixture themeVariables');
    }
    result[key] = validated;
  }
  return Map.unmodifiable(result);
}

MermaidTheme _themeOptions(Map<String, Object> variables) {
  const defaults = MermaidTheme();
  final pieColors = [...defaults.pieColors];
  final categoricalColors = [...defaults.categoricalColors];
  final categoricalPeerColors = [...defaults.categoricalPeerColors];
  final categoricalLabelColors = [...defaults.categoricalLabelColors];
  final gitColors = [...defaults.gitGraph.branchColors];
  final gitHighlightColors = [...defaults.gitGraph.highlightColors];
  final gitLabelColors = [...defaults.gitGraph.branchLabelColors];
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
  for (var index = 0; index < _gitThemePaletteLength; index++) {
    if (variables['git$index'] case final String color) gitColors[index] = _fixtureColor(color);
    if (variables['gitInv$index'] case final String color) gitHighlightColors[index] = _fixtureColor(color);
    if (variables['gitBranchLabel$index'] case final String color) gitLabelColors[index] = _fixtureColor(color);
  }
  final cynefin = _nestedTheme(variables, 'cynefin');
  final radar = _nestedTheme(variables, 'radar');
  final wardley = _nestedTheme(variables, 'wardley');
  final background = _themeColor(variables, 'background', defaults.background);
  final primary = _themeColor(variables, 'primaryColor', defaults.primary);
  final secondary = _themeColor(variables, 'secondaryColor', defaults.secondary);
  final text = _themeColor(variables, 'textColor', defaults.text);
  final backgroundOverride = _themeOptionalColor(variables, 'background');
  final primaryOverride = _themeOptionalColor(variables, 'primaryColor');
  final primaryBorderOverride = _themeOptionalColor(variables, 'primaryBorderColor');
  final primaryTextOverride = _themeOptionalColor(variables, 'primaryTextColor');
  final lineOverride = _themeOptionalColor(variables, 'lineColor');
  final secondaryOverride = _themeOptionalColor(variables, 'secondaryColor');
  final secondaryBorderOverride = _themeOptionalColor(variables, 'secondaryBorderColor');
  final secondaryTextOverride = _themeOptionalColor(variables, 'secondaryTextColor');
  final textOverride = _themeOptionalColor(variables, 'textColor');
  return MermaidTheme(
    background: background,
    primary: primary,
    primaryBorder: primaryBorderOverride,
    primaryText: primaryTextOverride,
    line: lineOverride,
    secondary: secondary,
    tertiary: _themeOptionalColor(variables, 'tertiaryColor'),
    secondaryBorder: secondaryBorderOverride,
    tertiaryBorder: _themeOptionalColor(variables, 'tertiaryBorderColor'),
    secondaryText: secondaryTextOverride,
    tertiaryText: _themeOptionalColor(variables, 'tertiaryTextColor'),
    text: text,
    title: _themeOptionalColor(variables, 'titleColor'),
    mainBackground: _themeOptionalColor(variables, 'mainBkg'),
    secondBackground: _themeOptionalColor(variables, 'secondBkg'),
    labelBackground: _themeOptionalColor(variables, 'labelBackground'),
    nodeBorder: _themeOptionalColor(variables, 'nodeBorder'),
    strokeWidth: variables.containsKey('strokeWidth')
        ? _themeDouble(variables, 'strokeWidth', defaults.strokeWidth)
        : null,
    fontFamily: variables['fontFamily'] as String?,
    fontSize: _themeDouble(variables, 'fontSize', defaults.fontSize),
    pieColors: List.unmodifiable(pieColors),
    categoricalColors: List.unmodifiable(categoricalColors),
    categoricalPeerColors: List.unmodifiable(categoricalPeerColors),
    categoricalLabelColors: List.unmodifiable(categoricalLabelColors),
    architecture: ArchitectureTheme(
      edgeColor: _themeColor(variables, 'archEdgeColor', lineOverride ?? defaults.architecture.edgeColor),
      edgeArrowColor: _themeColor(
        variables,
        'archEdgeArrowColor',
        lineOverride ?? defaults.architecture.edgeArrowColor,
      ),
      edgeWidth: _themeDouble(variables, 'archEdgeWidth', defaults.architecture.edgeWidth),
      groupBorderColor: _themeColor(
        variables,
        'archGroupBorderColor',
        primaryBorderOverride ?? defaults.architecture.groupBorderColor,
      ),
      groupBorderWidth: _themeDouble(variables, 'archGroupBorderWidth', defaults.architecture.groupBorderWidth),
    ),
    cynefin: CynefinTheme(
      domainFontSize: _nestedThemeDouble(cynefin, 'domainFontSize', defaults.cynefin.domainFontSize),
      itemFontSize: _nestedThemeDouble(cynefin, 'itemFontSize', defaults.cynefin.itemFontSize),
      boundaryColor: _nestedThemeColor(cynefin, 'boundaryColor', lineOverride ?? defaults.cynefin.boundaryColor),
      boundaryWidth: _nestedThemeDouble(cynefin, 'boundaryWidth', defaults.cynefin.boundaryWidth),
      cliffColor: _nestedThemeColor(cynefin, 'cliffColor', defaults.cynefin.cliffColor),
      cliffWidth: _nestedThemeDouble(cynefin, 'cliffWidth', defaults.cynefin.cliffWidth),
      arrowColor: _nestedThemeColor(cynefin, 'arrowColor', lineOverride ?? defaults.cynefin.arrowColor),
      arrowWidth: _nestedThemeDouble(cynefin, 'arrowWidth', defaults.cynefin.arrowWidth),
      complexBackground: _nestedThemeColor(cynefin, 'complexBg', defaults.cynefin.complexBackground),
      complicatedBackground: _nestedThemeColor(cynefin, 'complicatedBg', defaults.cynefin.complicatedBackground),
      chaoticBackground: _nestedThemeColor(cynefin, 'chaoticBg', defaults.cynefin.chaoticBackground),
      clearBackground: _nestedThemeColor(cynefin, 'clearBg', defaults.cynefin.clearBackground),
      confusionBackground: _nestedThemeColor(cynefin, 'confusionBg', defaults.cynefin.confusionBackground),
      textColor: _nestedThemeColor(cynefin, 'textColor', textOverride ?? defaults.cynefin.textColor),
      labelColor: _nestedThemeColor(cynefin, 'labelColor', primaryTextOverride ?? defaults.cynefin.labelColor),
    ),
    eventModeling: EventModelingTheme(
      uiFill: _themeColor(variables, 'emUiFill', defaults.eventModeling.uiFill),
      uiStroke: _themeColor(variables, 'emUiStroke', defaults.eventModeling.uiStroke),
      processorFill: _themeColor(variables, 'emProcessorFill', defaults.eventModeling.processorFill),
      processorStroke: _themeColor(variables, 'emProcessorStroke', defaults.eventModeling.processorStroke),
      readModelFill: _themeColor(variables, 'emReadModelFill', defaults.eventModeling.readModelFill),
      readModelStroke: _themeColor(variables, 'emReadModelStroke', defaults.eventModeling.readModelStroke),
      commandFill: _themeColor(variables, 'emCommandFill', defaults.eventModeling.commandFill),
      commandStroke: _themeColor(variables, 'emCommandStroke', defaults.eventModeling.commandStroke),
      eventFill: _themeColor(variables, 'emEventFill', defaults.eventModeling.eventFill),
      eventStroke: _themeColor(variables, 'emEventStroke', defaults.eventModeling.eventStroke),
      swimlaneBackgroundOdd: _themeColor(
        variables,
        'emSwimlaneBackgroundOdd',
        defaults.eventModeling.swimlaneBackgroundOdd,
      ),
      swimlaneBackgroundStroke: _themeColor(
        variables,
        'emSwimlaneBackgroundStroke',
        defaults.eventModeling.swimlaneBackgroundStroke,
      ),
      arrowhead: _themeColor(variables, 'emArrowhead', lineOverride ?? defaults.eventModeling.arrowhead),
      relationStroke: _themeColor(variables, 'emRelationStroke', lineOverride ?? defaults.eventModeling.relationStroke),
    ),
    gitGraph: GitGraphTheme(
      branchColors: List.unmodifiable(gitColors),
      highlightColors: List.unmodifiable(gitHighlightColors),
      branchLabelColors: List.unmodifiable(gitLabelColors),
      tagLabelColor: _themeColor(variables, 'tagLabelColor', primaryTextOverride ?? defaults.gitGraph.tagLabelColor),
      tagLabelBackground: _themeColor(
        variables,
        'tagLabelBackground',
        primaryOverride ?? defaults.gitGraph.tagLabelBackground,
      ),
      tagLabelBorder: _themeColor(
        variables,
        'tagLabelBorder',
        primaryBorderOverride ?? defaults.gitGraph.tagLabelBorder,
      ),
      tagLabelFontSize: _themeDouble(variables, 'tagLabelFontSize', defaults.gitGraph.tagLabelFontSize),
      commitLabelColor: _themeColor(
        variables,
        'commitLabelColor',
        secondaryTextOverride ?? defaults.gitGraph.commitLabelColor,
      ),
      commitLabelBackground: _themeColor(
        variables,
        'commitLabelBackground',
        secondaryOverride ?? defaults.gitGraph.commitLabelBackground,
      ),
      commitLabelFontSize: _themeDouble(variables, 'commitLabelFontSize', defaults.gitGraph.commitLabelFontSize),
      commitLineColor: _themeOptionalColor(variables, 'commitLineColor') ?? defaults.gitGraph.commitLineColor,
      tagHoleColor: textOverride ?? defaults.gitGraph.tagHoleColor,
      primaryColor: primaryOverride ?? defaults.gitGraph.primaryColor,
      specialColor: primaryOverride ?? defaults.gitGraph.specialColor,
      themeColorLimit: _themeInt(variables, 'THEME_COLOR_LIMIT', defaults.gitGraph.themeColorLimit),
      useGradient: variables['useGradient'] as bool? ?? defaults.gitGraph.useGradient,
      gradientStart: _themeColor(variables, 'gradientStart', primaryBorderOverride ?? defaults.gitGraph.gradientStart),
      gradientStop: _themeColor(variables, 'gradientStop', secondaryBorderOverride ?? defaults.gitGraph.gradientStop),
      filterColor: _themeColor(variables, 'filterColor', defaults.gitGraph.filterColor),
      dropShadow: switch (variables['dropShadow']) {
        final String shadow => _themeShadow(shadow)!,
        _ => defaults.gitGraph.dropShadow,
      },
    ),
    pie: PieTheme(
      titleTextSize: _themeDouble(variables, 'pieTitleTextSize', defaults.pie.titleTextSize),
      titleTextColor: _themeColor(variables, 'pieTitleTextColor', defaults.pie.titleTextColor),
      sectionTextSize: _themeDouble(variables, 'pieSectionTextSize', defaults.pie.sectionTextSize),
      sectionTextColor: _themeColor(variables, 'pieSectionTextColor', textOverride ?? defaults.pie.sectionTextColor),
      legendTextSize: _themeDouble(variables, 'pieLegendTextSize', defaults.pie.legendTextSize),
      legendTextColor: _themeColor(variables, 'pieLegendTextColor', defaults.pie.legendTextColor),
      strokeColor: _themeColor(variables, 'pieStrokeColor', defaults.pie.strokeColor),
      strokeWidth: _themeDouble(variables, 'pieStrokeWidth', defaults.pie.strokeWidth),
      outerStrokeWidth: _themeDouble(variables, 'pieOuterStrokeWidth', defaults.pie.outerStrokeWidth),
      outerStrokeColor: _themeColor(variables, 'pieOuterStrokeColor', defaults.pie.outerStrokeColor),
      opacity: _themeDouble(variables, 'pieOpacity', defaults.pie.opacity),
    ),
    radar: RadarTheme(
      axisColor: _nestedThemeColor(radar, 'axisColor', lineOverride ?? defaults.radar.axisColor),
      axisStrokeWidth: _nestedThemeDouble(radar, 'axisStrokeWidth', defaults.radar.axisStrokeWidth),
      axisLabelFontSize: _nestedThemeDouble(radar, 'axisLabelFontSize', defaults.radar.axisLabelFontSize),
      curveOpacity: _nestedThemeDouble(radar, 'curveOpacity', defaults.radar.curveOpacity),
      curveStrokeWidth: _nestedThemeDouble(radar, 'curveStrokeWidth', defaults.radar.curveStrokeWidth),
      graticuleColor: _nestedThemeColor(radar, 'graticuleColor', defaults.radar.graticuleColor),
      graticuleStrokeWidth: _nestedThemeDouble(radar, 'graticuleStrokeWidth', defaults.radar.graticuleStrokeWidth),
      graticuleOpacity: _nestedThemeDouble(radar, 'graticuleOpacity', defaults.radar.graticuleOpacity),
      legendBoxSize: _nestedThemeDouble(radar, 'legendBoxSize', defaults.radar.legendBoxSize),
      legendFontSize: _nestedThemeDouble(radar, 'legendFontSize', defaults.radar.legendFontSize),
    ),
    wardley: WardleyTheme(
      backgroundColor: _nestedThemeColor(
        wardley,
        'backgroundColor',
        backgroundOverride ?? defaults.wardley.backgroundColor,
      ),
      axisColor: _nestedThemeColor(wardley, 'axisColor', lineOverride ?? defaults.wardley.axisColor),
      axisTextColor: _nestedThemeColor(wardley, 'axisTextColor', primaryTextOverride ?? defaults.wardley.axisTextColor),
      gridColor: _nestedThemeColor(wardley, 'gridColor', defaults.wardley.gridColor),
      componentFill: _nestedThemeColor(wardley, 'componentFill', backgroundOverride ?? defaults.wardley.componentFill),
      componentStroke: _nestedThemeColor(wardley, 'componentStroke', lineOverride ?? defaults.wardley.componentStroke),
      componentLabelColor: _nestedThemeColor(
        wardley,
        'componentLabelColor',
        primaryTextOverride ?? defaults.wardley.componentLabelColor,
      ),
      linkStroke: _nestedThemeColor(wardley, 'linkStroke', lineOverride ?? defaults.wardley.linkStroke),
      evolutionStroke: _nestedThemeColor(wardley, 'evolutionStroke', defaults.wardley.evolutionStroke),
      annotationStroke: _nestedThemeColor(
        wardley,
        'annotationStroke',
        lineOverride ?? defaults.wardley.annotationStroke,
      ),
      annotationTextColor: _nestedThemeColor(
        wardley,
        'annotationTextColor',
        primaryTextOverride ?? defaults.wardley.annotationTextColor,
      ),
      annotationFill: _nestedThemeColor(
        wardley,
        'annotationFill',
        backgroundOverride ?? defaults.wardley.annotationFill,
      ),
    ),
  );
}

Object? _validatedThemeColor(String value) {
  final trimmed = value.trim();
  return _fixtureHexColor.hasMatch(trimmed) ? trimmed : null;
}

Object? _validatedThemeNumber(String key, Object value) {
  final parsed = _cssNumber(value);
  if (parsed == null || parsed < 0 || (key == 'THEME_COLOR_LIMIT' && parsed != parsed.roundToDouble())) return null;
  return value is String ? value.trim() : value;
}

Map<String, Object>? _validatedNestedTheme(String name, Map<String, Object?> values) {
  if (values.isEmpty) return null;
  final colors = _nestedThemeColorKeys[name]!;
  final numbers = _nestedThemeNumberKeys[name]!;
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in values.entries) {
    final validated = switch (value) {
      final String color when colors.contains(key) => _validatedThemeColor(color),
      final Object number when numbers.contains(key) => _validatedThemeNumber(key, number),
      _ => null,
    };
    if (validated == null) return null;
    result[key] = validated;
  }
  return Map.unmodifiable(result);
}

Map<String, Object> _nestedTheme(Map<String, Object> variables, String key) =>
    variables[key] as Map<String, Object>? ?? const {};

double? _cssNumber(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text.trim().replaceFirst(RegExp(r'px$'), '')),
  _ => null,
};

double _themeDouble(Map<String, Object> values, String key, double fallback) => _cssNumber(values[key]) ?? fallback;

int _themeInt(Map<String, Object> values, String key, int fallback) => _cssNumber(values[key])?.round() ?? fallback;

Color? _themeOptionalColor(Map<String, Object> values, String key) => switch (values[key]) {
  final String color => _fixtureColor(color),
  _ => null,
};

Color _themeColor(Map<String, Object> values, String key, Color fallback) =>
    _themeOptionalColor(values, key) ?? fallback;

double _nestedThemeDouble(Map<String, Object> values, String key, double fallback) =>
    _cssNumber(values[key]) ?? fallback;

Color _nestedThemeColor(Map<String, Object> values, String key, Color fallback) =>
    _themeOptionalColor(values, key) ?? fallback;

final _dropShadowPattern = RegExp(
  r'^drop-shadow\(\s*(-?\d+(?:\.\d+)?)px\s+(-?\d+(?:\.\d+)?)px\s+(\d+(?:\.\d+)?)px\s+(#[0-9a-f]{3,8})\s*\)$',
  caseSensitive: false,
);

ThemeShadow? _themeShadow(String value) {
  final match = _dropShadowPattern.firstMatch(value.trim());
  if (match == null || !_fixtureHexColor.hasMatch(match.group(4)!)) return null;
  return ThemeShadow(
    offsetX: double.parse(match.group(1)!),
    offsetY: double.parse(match.group(2)!),
    blurRadius: double.parse(match.group(3)!),
    color: _fixtureColor(match.group(4)!),
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
  DiagramType.flowchart: 'flowchartOptions',
  DiagramType.gantt: 'ganttOptions',
  DiagramType.gitGraph: 'gitGraphOptions',
  DiagramType.kanban: 'kanbanOptions',
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
  DiagramType.flowchart: 'flowchart',
  DiagramType.gantt: 'gantt',
  DiagramType.gitGraph: 'gitGraph',
  DiagramType.kanban: 'kanban',
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
    DiagramType.flowchart => _flowchartConfig(value),
    DiagramType.gantt => _ganttConfig(value),
    DiagramType.gitGraph => _gitGraphConfig(value),
    DiagramType.kanban => _kanbanConfig(value),
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

const _kanbanConfigKeys = {..._baseDiagramConfigKeys, 'padding', 'sectionWidth', 'ticketBaseUrl'};

const _flowchartConfigKeys = {
  ..._baseDiagramConfigKeys,
  'nodeSpacing',
  'rankSpacing',
  'diagramPadding',
  'nodePadding',
  'edgeWidth',
};

Map<String, Object> _flowchartConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_flowchartConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture flowchartOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('nodeSpacing' || 'rankSpacing' || 'nodePadding' || 'edgeWidth', final num option) when option > 0 =>
              option,
            ('diagramPadding', final num option) when option >= 0 => option,
            _ => null,
          };
    if (valid == null) throw const FormatException('Invalid fixture flowchartOptions');
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

const _ganttConfigKeys = {
  ..._baseDiagramConfigKeys,
  'titleTopMargin',
  'barHeight',
  'barGap',
  'topPadding',
  'rightPadding',
  'leftPadding',
  'gridLineStartPadding',
  'fontSize',
  'sectionFontSize',
  'numberSectionStyles',
  'axisFormat',
  'tickInterval',
  'topAxis',
  'displayMode',
  'weekday',
};

Map<String, Object> _ganttConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_ganttConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture ganttOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            (
              'titleTopMargin' ||
                  'barHeight' ||
                  'barGap' ||
                  'topPadding' ||
                  'rightPadding' ||
                  'leftPadding' ||
                  'gridLineStartPadding' ||
                  'fontSize' ||
                  'sectionFontSize',
              final num option,
            )
                when option >= 0 =>
              option,
            ('numberSectionStyles', final int option) when option > 0 => option,
            ('axisFormat', final String option) when option.isNotEmpty => option,
            ('tickInterval', final String option) when _ganttTickPattern.hasMatch(option) => option,
            ('topAxis', final bool option) => option,
            ('displayMode', '' || 'compact') => value,
            ('weekday', final String option) when GanttWeekday.values.any((day) => day.name == option) => option,
            _ => null,
          };
    if (valid == null) throw const FormatException('Invalid fixture ganttOptions');
    result[key] = valid;
  }
  return Map.unmodifiable(result);
}

final _ganttTickPattern = RegExp(r'^([1-9]\d*)(millisecond|second|minute|hour|day|week|month)$');

GanttTickInterval _ganttTickInterval(String value) {
  final match = _ganttTickPattern.firstMatch(value)!;
  return GanttTickInterval(int.parse(match.group(1)!), GanttTickUnit.values.byName(match.group(2)!));
}

Map<String, Object> _kanbanConfig(Object? value) {
  if (value is! Map<String, Object?> || value.isEmpty || value.keys.any((key) => !_kanbanConfigKeys.contains(key))) {
    throw const FormatException('Invalid fixture kanbanOptions');
  }
  final result = <String, Object>{};
  for (final MapEntry(:key, :value) in value.entries) {
    final valid = _baseDiagramConfigKeys.contains(key)
        ? _baseDiagramConfigValue(key, value)
        : switch ((key, value)) {
            ('padding', final num option) when option >= 0 => option,
            ('sectionWidth', final num option) when option > 0 => option,
            ('ticketBaseUrl', final String option) => option,
            _ => null,
          };
    if (valid == null) throw const FormatException('Invalid fixture kanbanOptions');
    result[key] = valid;
  }
  return Map.unmodifiable(result);
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

Color? _configuredOptionalColor(Map<String, Object> config, String key) => switch (config[key]) {
  final String value => _fixtureColor(value),
  _ => null,
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
    final comparisonViewport = _comparisonViewport(sourceDocument.rootElement);
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
      viewBox: comparisonViewport.size,
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
      geometry: _geometrySignatures(sourceDocument.rootElement, initialTransform: comparisonViewport.originTransform),
      paint: _paintSignatures(sourceDocument.rootElement, initialTransform: comparisonViewport.originTransform),
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
    final sameGeometry = _signatureListsEqual(dart.geometry, mermaid.geometry);
    return SvgComparison(
      exact: dart.canonicalSvg == mermaid.canonicalSvg,
      sameViewport: dart.viewBox == null || mermaid.viewBox == null || dart.viewBox == mermaid.viewBox,
      sameText: _listEquals(dart.text, mermaid.text),
      sameElementCounts: _mapEquals(dart.elementCounts, mermaid.elementCounts),
      sameGeometry: sameGeometry,
      // Paint is paired with normalized geometry. If geometry differs, the
      // paint comparison has no reliable element correspondence of its own.
      samePaint: !sameGeometry || _signatureListsEqual(dart.paint, mermaid.paint),
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

({String? size, String originTransform}) _comparisonViewport(XmlElement root) {
  final raw = root.getAttribute('viewBox');
  if (raw == null) return (size: null, originTransform: '');
  final values = raw.trim().split(RegExp(r'[\s,]+')).where((value) => value.isNotEmpty).map(double.tryParse).toList();
  if (values.length != 4 || values.any((value) => value == null)) {
    return (size: _normalizedNumberList(raw), originTransform: '');
  }
  final [left, top, width, height] = values.cast<double>();
  return (size: '${_formatNumber(width)} ${_formatNumber(height)}', originTransform: 'translate(${-left}, ${-top})');
}

List<String> _geometrySignatures(XmlElement root, {String initialTransform = ''}) =>
    _elementSignatures(root, _geometrySignature, initialTransform: initialTransform);

List<String> _paintSignatures(XmlElement root, {String initialTransform = ''}) =>
    _elementSignatures(root, _paintSignature, initialTransform: initialTransform);

List<String> _elementSignatures(
  XmlElement root,
  String Function(XmlElement element, String transform, String styleSheets) signature, {
  String initialTransform = '',
}) {
  final signatures = <String>[];
  final styleSheets = root.descendants
      .whereType<XmlElement>()
      .where((element) => element.name.local == 'style')
      .map((element) => element.innerText)
      .join('\n');

  void visit(XmlElement element, String inheritedTransform) {
    if (!_isComparableGeometryElement(element, root)) return;
    final ownTransform = element.getAttribute('transform') ?? '';
    final stylesheetTransform = _stylesheetTransform(element, styleSheets);
    final stylesheetScale = _stylesheetScaleTransform(element, styleSheets);
    final transform = [
      inheritedTransform,
      ownTransform,
      stylesheetTransform,
      stylesheetScale,
    ].where((value) => value.isNotEmpty).join(' ');
    final isEmptyText =
        (element.name.local == 'text' || element.name.local == 'foreignObject') && element.innerText.trim().isEmpty;
    if (_visibleElements.contains(element.name.local) && !isEmptyText) {
      signatures.add(signature(element, transform, styleSheets));
    }
    for (final child in element.childElements) {
      visit(child, transform);
    }
  }

  visit(root, initialTransform);
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

/// Converts a static CSS transform and its transform origin into an equivalent
/// SVG transform list. Mermaid's Gantt milestones use this form.
String _stylesheetTransform(XmlElement element, String styleSheets) {
  final value = _stylesheetProperty(element, styleSheets, 'transform');
  if (value == null || value == 'none') return '';
  final transform = value.replaceAll(RegExp(r'deg\b', caseSensitive: false), '');
  final origin =
      element.getAttribute('transform-origin') ?? _stylesheetProperty(element, styleSheets, 'transform-origin');
  if (origin == null) return transform;
  final coordinates = _signatureNumber.allMatches(origin).map((match) => double.parse(match.group(0)!)).toList();
  if (coordinates.length < 2) return transform;
  final x = _formatNumber(coordinates[0]);
  final y = _formatNumber(coordinates[1]);
  return 'translate($x $y) $transform translate(-$x -$y)';
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
  'blue': '#0000ff',
  'grey': '#808080',
  'lightblue': '#add8e6',
  'lightgrey': '#d3d3d3',
  'navy': '#000080',
  'orange': '#ffa500',
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
    'foreignObject' => _foreignObjectGeometryValues(element, translation, styleSheets),
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

List<String> _foreignObjectGeometryValues(XmlElement element, _Translation? translation, String styleSheets) {
  final left = _numberAttribute(element, 'x') ?? 0;
  final top = _numberAttribute(element, 'y') ?? 0;
  final width = _numberAttribute(element, 'width') ?? 0;
  final height = _numberAttribute(element, 'height') ?? 0;
  final textElement = _firstVisibleTextElement(element) ?? element;
  return [
    _formatNumber(left + width / 2 + (translation?.dx ?? 0)),
    _formatNumber(top + height / 2 + (translation?.dy ?? 0)),
    _formatNumber(_computedFontSize(textElement, styleSheets)),
    'middle',
    'central',
    ..._typographyGeometryValues(element, styleSheets),
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
  final textElement = _firstVisibleTextElement(element) ?? element;
  final fontSize = _computedFontSize(textElement, styleSheets);
  final span = element.descendants.whereType<XmlElement>().where((child) => child.name.local == 'tspan').firstOrNull;
  final localX = _svgLength(span?.getAttribute('x') ?? attribute('x', '0'), fontSize);
  final localY =
      _svgLength(span?.getAttribute('y') ?? attribute('y', '0'), fontSize) +
      _svgLength(span?.getAttribute('dy') ?? attribute('dy', '0'), fontSize);
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
  // Mermaid createText uses y=-0.1em/dy=1.1em inside a group whose
  // dominant-baseline=start. Chrome paints that wrapper from the group's
  // translated top; counting the tspan's one-em advance again puts the
  // normalized geometry a full line too low.
  final normalizedY = rawBaseline == 'start' ? localY - fontSize : localY;
  return [
    _formatNumber(localX + (translation?.dx ?? 0)),
    _formatNumber(normalizedY + (translation?.dy ?? 0)),
    _formatNumber(fontSize),
    anchor,
    baseline,
    ..._typographyGeometryValues(element, styleSheets),
  ];
}

// CSS's computed equivalents for the keyword font weights. Keeping the
// normalized signature numeric makes keyword and SVG-attribute forms equal.
const _normalFontWeight = '400';
const _boldFontWeight = '700';
const _normalFontStyle = 'normal';
const _defaultSvgFontSize = 16.0;

List<String> _typographyGeometryValues(XmlElement element, String styleSheets) {
  final textElement = _firstVisibleTextElement(element) ?? element;
  final family = _inheritedPresentationValue(textElement, 'font-family', styleSheets) ?? 'sans-serif';
  return [
    family
        .split(',')
        .map((part) => part.trim().replaceAllMapped(RegExp(r'''^(['"])(.*)\1$'''), (match) => match[2]!).toLowerCase())
        .join(','),
    _normalizedFontWeight(textElement, styleSheets),
    _normalizedFontStyle(textElement, styleSheets),
  ];
}

XmlElement? _firstVisibleTextElement(XmlElement element) =>
    element.descendants.whereType<XmlText>().where((node) => node.value.trim().isNotEmpty).firstOrNull?.parentElement;

double _computedFontSize(XmlElement element, String styleSheets) {
  final ancestors = <XmlElement>[];
  for (XmlElement? current = element; current != null; current = current.parentElement) {
    ancestors.add(current);
  }

  var fontSize = _defaultSvgFontSize;
  for (final current in ancestors.reversed) {
    final rawValue = _localPresentationValue(current, 'font-size', styleSheets);
    if (rawValue == null || rawValue.trim().toLowerCase() == 'inherit') continue;
    final value = rawValue.replaceFirst(RegExp(r'\s*!important\s*$', caseSensitive: false), '').trim().toLowerCase();
    if (value.endsWith('rem')) {
      fontSize = _defaultSvgFontSize * double.parse(value.substring(0, value.length - 3));
    } else if (value.endsWith('em')) {
      fontSize *= double.parse(value.substring(0, value.length - 2));
    } else if (value.endsWith('%')) {
      fontSize *= double.parse(value.substring(0, value.length - 1)) / _fullPercentage;
    } else if (value.endsWith('px')) {
      fontSize = double.parse(value.substring(0, value.length - 2));
    } else if (double.tryParse(value) case final number?) {
      fontSize = number;
    }
  }
  return fontSize;
}

String _normalizedFontWeight(XmlElement element, String styleSheets) {
  for (XmlElement? current = element; current != null; current = current.parentElement) {
    final value = _localPresentationValue(current, 'font-weight', styleSheets);
    if (value != null && value != 'inherit') {
      return switch (value.trim().toLowerCase()) {
        'normal' => _normalFontWeight,
        'bold' => _boldFontWeight,
        final weight => weight,
      };
    }
    if (current.name.local case 'b' || 'strong') return _boldFontWeight;
  }
  return _normalFontWeight;
}

String _normalizedFontStyle(XmlElement element, String styleSheets) {
  for (XmlElement? current = element; current != null; current = current.parentElement) {
    final value = _localPresentationValue(current, 'font-style', styleSheets);
    if (value != null && value != 'inherit') return value.trim().toLowerCase();
    if (current.name.local case 'i' || 'em') return 'italic';
  }
  return _normalFontStyle;
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

String _normalizedTransform(String transform) {
  final result = <String>[];
  var translateX = 0.0;
  var translateY = 0.0;

  void flushTranslation() {
    if (translateX == 0 && translateY == 0) return;
    result.add('translate(${_formatNumber(translateX)} ${_formatNumber(translateY)})');
    translateX = 0;
    translateY = 0;
  }

  for (final match in _transformFunction.allMatches(transform)) {
    final name = match[1]!.toLowerCase();
    final values = _pathToken.allMatches(match[2]!).map((value) => double.parse(value[0]!)).toList();
    if (name == 'translate') {
      translateX += values.first;
      translateY += values.length > 1 ? values[1] : 0;
      continue;
    }
    flushTranslation();
    if (name == 'scale' && values.length == 1) values.add(values.single);
    result.add('$name(${values.map(_formatNumber).join(' ')})');
  }
  flushTranslation();
  return result.join(' ');
}

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
final _signatureNumber = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?', caseSensitive: false);
final _transformFunction = RegExp(r'([A-Za-z]+)\s*\(([^)]*)\)');
const _geometryComparisonTolerance = 0.011;

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

bool _signatureListsEqual(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (!_signaturesEqual(left[index], right[index])) return false;
  }
  return true;
}

bool _signaturesEqual(String left, String right) {
  if (left == right) return true;
  final leftNumbers = _signatureNumber.allMatches(left).toList();
  final rightNumbers = _signatureNumber.allMatches(right).toList();
  if (leftNumbers.length != rightNumbers.length) return false;
  var leftEnd = 0;
  var rightEnd = 0;
  for (var index = 0; index < leftNumbers.length; index++) {
    final leftNumber = leftNumbers[index];
    final rightNumber = rightNumbers[index];
    if (left.substring(leftEnd, leftNumber.start) != right.substring(rightEnd, rightNumber.start)) return false;
    final delta = (double.parse(leftNumber.group(0)!) - double.parse(rightNumber.group(0)!)).abs();
    if (delta > _geometryComparisonTolerance) return false;
    leftEnd = leftNumber.end;
    rightEnd = rightNumber.end;
  }
  return left.substring(leftEnd) == right.substring(rightEnd);
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  if (left.length != right.length) return false;
  for (final MapEntry(:key, :value) in left.entries) {
    if (right[key] != value) return false;
  }
  return true;
}
