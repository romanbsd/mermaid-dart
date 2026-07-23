part of '../layout.dart';

// Mermaid's Wardley renderer emits no root typography stylesheet, so text
// uses the browser's generic SVG fallback even when a global fontFamily theme
// variable is configured.
const _wardleyFontFamily = 'sans-serif';

// Non-configurable geometry retained from Mermaid's Wardley renderer. These
// constants affect label readability and browser-measured annotation boxes.
const _wardleyTitleFontScale = 1.05;
const _wardleyLinkLabelOffset = 8.0;
const _wardleyQuarterTurnDegrees = 90.0;
const _wardleyHalfTurnDegrees = 180.0;
const _wardleyAnnotationBoxSafetyWidth = 105.0;
const _wardleyXAxisLabelPaddingDivisor = 4.0;
const _wardleyYAxisLabelPaddingDivisor = 3.0;
const _wardleyStageLabelPaddingDivisor = 1.5;

// Mermaid's fixed map primitives. Values in this group are renderer geometry,
// not user configuration, and intentionally remain stable when nodeRadius or
// typography options change.
const _wardleyGridDivisionCount = 4;
const _wardleyStageLabelFontReduction = 2.0;
const _wardleyStageBoundaryDashes = <double>[5, 5];
const _wardleyGridDashes = <double>[2, 6];
const _wardleyEvolutionDashes = <double>[4, 4];
const _wardleyDependencyDashes = <double>[6, 6];
const _wardleyPipelineParentSizeScale = 1.6;
const _wardleyPipelineHeightScale = 4.0;
const _wardleyPipelineHorizontalPadding = 15.0;
const _wardleyPipelineParentVerticalOffsetDivisor = 6.0;
const _wardleyRoundedBoxRadius = 4.0;
const _wardleyOutlineStrokeWidth = 1.5;
const _wardleyArrowLength = 6.0;
const _wardleyArrowHalfWidth = 3.0;
const _wardleyTrendTargetClearance = 2.0;
const _wardleyInertiaGap = 15.0;
const _wardleyInertiaStrategyGap = 10.0;
const _wardleyInertiaStrokeWidth = 6.0;
const _wardleyStrategyLabelSpacing = 10.0;
const _wardleyAnchorLabelVerticalOffset = -3.0;
const _wardleyAnnotationRadius = 10.0;
const _wardleyAnnotationNumberFontSize = 10.0;
const _wardleyAnnotationBoxPadding = 10.0;
const _wardleyAnnotationLineHeight = 16.0;
const _wardleyAnnotationTextFontSize = 11.0;
const _wardleyNoteFontSize = 11.0;
const _wardleyMarkerWidth = 60.0;
const _wardleyMarkerHeight = 30.0;
const _wardleyMarkerHeadWidth = 20.0;
const _wardleyMarkerNotchDepth = 8.0;
const _wardleyMarkerLabelOffset = 30.0;
const _wardleyMarkerLabelFontSize = 10.0;
const _wardleyMarkerFill = Color(255, 255, 255);
const _wardleyStrategyRadiusScale = 2.0;
const _wardleyMarketDotRadiusScale = .7;
const _wardleyMarketTriangleRadiusScale = 1.2;
const _wardleyMarketTriangleAngleDivisor = 6.0;
const _wardleyMarketDotStrokeWidth = 2.0;
const _wardleyBuildStrategyFill = Color(238, 238, 238);
const _wardleyBuyStrategyFill = Color(204, 204, 204);
const _wardleyOutsourceStrategyFill = Color(102, 102, 102);

final class _WardleyTextStyles {
  factory _WardleyTextStyles(WardleyRenderOptions config, WardleyTheme theme) {
    SceneTextStyle style({required double size, required Color color, FontWeight weight = FontWeight.normal}) =>
        SceneTextStyle(fontFamily: _wardleyFontFamily, fontSize: size, weight: weight, color: color);

    return _WardleyTextStyles._(
      axisLabel: style(size: config.axisFontSize, color: theme.axisTextColor, weight: FontWeight.bold),
      title: style(
        size: config.axisFontSize * _wardleyTitleFontScale,
        color: theme.axisTextColor,
        weight: FontWeight.bold,
      ),
      componentLabel: style(size: config.labelFontSize, color: theme.componentLabelColor),
      anchorLabel: style(size: config.labelFontSize, color: config.anchorLabelColor, weight: FontWeight.bold),
      stageLabel: style(size: config.axisFontSize - _wardleyStageLabelFontReduction, color: theme.axisTextColor),
      annotationNumber: style(
        size: _wardleyAnnotationNumberFontSize,
        color: theme.annotationTextColor,
        weight: FontWeight.bold,
      ),
      annotationText: style(size: _wardleyAnnotationTextFontSize, color: theme.annotationTextColor),
      note: style(size: _wardleyNoteFontSize, color: theme.axisTextColor, weight: FontWeight.bold),
      markerLabel: style(size: _wardleyMarkerLabelFontSize, color: theme.axisTextColor, weight: FontWeight.bold),
    );
  }

  const _WardleyTextStyles._({
    required this.axisLabel,
    required this.title,
    required this.componentLabel,
    required this.anchorLabel,
    required this.stageLabel,
    required this.annotationNumber,
    required this.annotationText,
    required this.note,
    required this.markerLabel,
  });

  final SceneTextStyle axisLabel;
  final SceneTextStyle title;
  final SceneTextStyle componentLabel;
  final SceneTextStyle anchorLabel;
  final SceneTextStyle stageLabel;
  final SceneTextStyle annotationNumber;
  final SceneTextStyle annotationText;
  final SceneTextStyle note;
  final SceneTextStyle markerLabel;
}

final class _WardleyStrokes {
  factory _WardleyStrokes(WardleyRenderOptions config, WardleyTheme theme) => _WardleyStrokes._(
    axis: SceneStroke(color: theme.axisColor),
    component: SceneStroke(color: theme.componentStroke),
    stageBoundary: SceneStroke(color: config.stageBoundaryColor, dashes: _wardleyStageBoundaryDashes),
    grid: SceneStroke(color: theme.gridColor, dashes: _wardleyGridDashes),
    evolution: SceneStroke(color: theme.evolutionStroke, dashes: _wardleyEvolutionDashes),
    pipelineEvolution: SceneStroke(color: theme.linkStroke, dashes: _wardleyEvolutionDashes),
    pipelineBox: SceneStroke(color: theme.componentStroke, width: _wardleyOutlineStrokeWidth),
    link: SceneStroke(color: theme.linkStroke),
    dependency: SceneStroke(color: theme.linkStroke, dashes: _wardleyDependencyDashes),
    buildStrategy: SceneStroke(color: config.buildStrategyStroke),
    inertia: SceneStroke(color: theme.componentStroke, width: _wardleyInertiaStrokeWidth),
    annotation: SceneStroke(color: theme.annotationStroke, width: _wardleyOutlineStrokeWidth),
    marketDot: SceneStroke(color: theme.componentStroke, width: _wardleyMarketDotStrokeWidth),
  );

  const _WardleyStrokes._({
    required this.axis,
    required this.component,
    required this.stageBoundary,
    required this.grid,
    required this.evolution,
    required this.pipelineEvolution,
    required this.pipelineBox,
    required this.link,
    required this.dependency,
    required this.buildStrategy,
    required this.inertia,
    required this.annotation,
    required this.marketDot,
  });

  final SceneStroke axis;
  final SceneStroke component;
  final SceneStroke stageBoundary;
  final SceneStroke grid;
  final SceneStroke evolution;
  final SceneStroke pipelineEvolution;
  final SceneStroke pipelineBox;
  final SceneStroke link;
  final SceneStroke dependency;
  final SceneStroke buildStrategy;
  final SceneStroke inertia;
  final SceneStroke annotation;
  final SceneStroke marketDot;
}

_LayoutResult _layoutWardley(WardleyAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const WardleyRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  final width = ast.size?.width.toDouble() ?? config.width;
  final height = ast.size?.height.toDouble() ?? config.height;
  final chartWidth = width - config.padding * 2;
  final chartHeight = height - config.padding * 2;
  final model = buildWardleyModel(ast);
  final elements = <SceneElement>[];
  final textStyles = _WardleyTextStyles(config, theme);
  final strokes = _WardleyStrokes(config, theme);
  Point project(double x, double y) =>
      projectWardleyPoint(x: x, y: y, width: width, height: height, padding: config.padding);
  Point positioned(WardleyPositionAst value) => project(value.x.toDouble(), value.y.toDouble());
  final positions = <String, Point>{};
  final nodesById = <String, WardleyNodeModel>{};
  for (final node in model.nodes) {
    positions.putIfAbsent(node.id, () => project(node.x, node.y));
    nodesById.putIfAbsent(node.id, () => node);
  }

  elements.add(
    SceneRect(
      id: context.id('wardley-background'),
      bounds: Bounds(left: 0, top: 0, width: width, height: height),
      fill: SolidFill(theme.backgroundColor),
      role: SemanticRole.group,
      cssClasses: const ['wardley-background'],
    ),
  );
  if (ast.title case final title?) {
    elements.add(
      _text(
        context,
        title,
        width / 2,
        config.padding / 2,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.central,
        role: SemanticRole.title,
        style: textStyles.title,
        cssClasses: const ['wardley-title'],
      ),
    );
  }

  elements.addAll([
    SceneLine(
      id: context.id('wardley-axis'),
      start: Point(config.padding, height - config.padding),
      end: Point(width - config.padding, height - config.padding),
      stroke: strokes.axis,
      role: SemanticRole.edge,
      cssClasses: const ['wardley-axis'],
    ),
    SceneLine(
      id: context.id('wardley-axis'),
      start: Point(config.padding, config.padding),
      end: Point(config.padding, height - config.padding),
      stroke: strokes.axis,
      role: SemanticRole.edge,
      cssClasses: const ['wardley-axis'],
    ),
    _text(
      context,
      'Evolution',
      config.padding + chartWidth / 2,
      height - config.padding / _wardleyXAxisLabelPaddingDivisor,
      anchor: TextAnchor.middle,
      baseline: TextBaseline.alphabetic,
      style: textStyles.axisLabel,
      cssClasses: const ['wardley-axis-label', 'wardley-axis-label-x'],
    ),
  ]);
  final yLabelCenter = Point(config.padding / _wardleyYAxisLabelPaddingDivisor, config.padding + chartHeight / 2);
  elements.add(
    SceneGroup(
      id: context.id('wardley-y-label'),
      transforms: [Rotate(-_wardleyQuarterTurnDegrees, center: yLabelCenter)],
      cssClasses: const ['wardley-axis-label-y-group'],
      children: [
        _text(
          context,
          'Visibility',
          yLabelCenter.x,
          yLabelCenter.y,
          anchor: TextAnchor.middle,
          baseline: TextBaseline.alphabetic,
          style: textStyles.axisLabel,
          cssClasses: const ['wardley-axis-label', 'wardley-axis-label-y'],
        ),
      ],
    ),
  );

  final stages = ast.evolutionStages.isEmpty
      ? const [
          WardleyEvolutionStageAst(name: 'Genesis'),
          WardleyEvolutionStageAst(name: 'Custom Built'),
          WardleyEvolutionStageAst(name: 'Product'),
          WardleyEvolutionStageAst(name: 'Commodity'),
        ]
      : ast.evolutionStages;
  final hasCompleteBoundaries = stages.every((stage) => stage.boundary != null);
  var stageStart = 0.0;
  for (var i = 0; i < stages.length; i++) {
    final stage = stages[i];
    final stageEnd = hasCompleteBoundaries ? stage.boundary!.toDouble() : (i + 1) / stages.length;
    final startX = config.padding + stageStart * chartWidth;
    final endX = config.padding + stageEnd * chartWidth;
    if (i > 0) {
      elements.add(
        SceneLine(
          id: context.id('wardley-stage-boundary'),
          start: Point(startX, config.padding),
          end: Point(startX, height - config.padding),
          stroke: strokes.stageBoundary,
          role: SemanticRole.edge,
          cssClasses: const ['wardley-stage-boundary'],
        ),
      );
    }
    elements.add(
      _text(
        context,
        stage.secondName == null ? stage.name : '${stage.name} / ${stage.secondName}',
        (startX + endX) / 2,
        height - config.padding / _wardleyStageLabelPaddingDivisor,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.alphabetic,
        style: textStyles.stageLabel,
        cssClasses: const ['wardley-stage-label'],
      ),
    );
    stageStart = stageEnd;
  }

  if (config.showGrid) {
    for (var i = 1; i < _wardleyGridDivisionCount; i++) {
      final ratio = i / _wardleyGridDivisionCount;
      elements.addAll([
        SceneLine(
          id: context.id('wardley-grid'),
          start: Point(config.padding + chartWidth * ratio, config.padding),
          end: Point(config.padding + chartWidth * ratio, height - config.padding),
          stroke: strokes.grid,
          role: SemanticRole.edge,
          cssClasses: const ['wardley-grid-line'],
        ),
        SceneLine(
          id: context.id('wardley-grid'),
          start: Point(config.padding, height - config.padding - chartHeight * ratio),
          end: Point(width - config.padding, height - config.padding - chartHeight * ratio),
          stroke: strokes.grid,
          role: SemanticRole.edge,
          cssClasses: const ['wardley-grid-line'],
        ),
      ]);
    }
  }

  final squareSize = config.nodeRadius * _wardleyPipelineParentSizeScale;
  for (final pipeline in model.pipelines) {
    final components = pipeline.componentIds.map((id) => nodesById[id]).whereType<WardleyNodeModel>().toList()
      ..sort((left, right) => left.x.compareTo(right.x));
    for (var i = 0; i < components.length - 1; i++) {
      elements.add(
        SceneLine(
          id: context.id('wardley-pipeline-link'),
          start: positions[components[i].id]!,
          end: positions[components[i + 1].id]!,
          stroke: strokes.pipelineEvolution,
          role: SemanticRole.edge,
          cssClasses: const ['wardley-pipeline-evolution-link'],
        ),
      );
    }
    if (components.isEmpty) continue;
    final firstPosition = positions[components.first.id]!;
    final lastPosition = positions[components.last.id]!;
    final minX = firstPosition.x;
    final maxX = lastPosition.x;
    final y = lastPosition.y;
    final pipelineHeight = config.nodeRadius * _wardleyPipelineHeightScale;
    final boxTop = y - pipelineHeight / 2;
    positions[pipeline.parentId] = Point(
      (minX + maxX) / 2,
      boxTop - squareSize / _wardleyPipelineParentVerticalOffsetDivisor,
    );
    elements.add(
      SceneRect(
        id: context.id('wardley-pipeline-box'),
        bounds: Bounds(
          left: minX - _wardleyPipelineHorizontalPadding,
          top: boxTop,
          width: maxX - minX + _wardleyPipelineHorizontalPadding * 2,
          height: pipelineHeight,
        ),
        radiusX: _wardleyRoundedBoxRadius,
        radiusY: _wardleyRoundedBoxRadius,
        fill: const NoFill(),
        stroke: strokes.pipelineBox,
        role: SemanticRole.group,
        cssClasses: const ['wardley-pipeline-box'],
      ),
    );
  }

  final pipelineChildren = <String, Set<String>>{
    for (final pipeline in model.pipelines) pipeline.parentId: pipeline.componentIds.toSet(),
  };
  for (final link in model.links) {
    if (pipelineChildren[link.targetId]?.contains(link.sourceId) ?? false) continue;
    final source = positions[link.sourceId];
    final target = positions[link.targetId];
    if (source == null || target == null) continue;
    final dx = target.x - source.x;
    final dy = target.y - source.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) continue;
    final sourceNode = nodesById[link.sourceId]!;
    final targetNode = nodesById[link.targetId]!;
    final sourceRadius = sourceNode.isPipelineParent ? squareSize / math.sqrt2 : config.nodeRadius;
    final targetRadius = targetNode.isPipelineParent ? squareSize / math.sqrt2 : config.nodeRadius;
    final start = Point(source.x + dx / distance * sourceRadius, source.y + dy / distance * sourceRadius);
    final end = Point(target.x - dx / distance * targetRadius, target.y - dy / distance * targetRadius);
    elements.add(
      SceneLine(
        id: context.id('wardley-link'),
        start: start,
        end: end,
        stroke: link.style == WardleyLinkStyle.dashed ? strokes.dependency : strokes.link,
        role: SemanticRole.edge,
        cssClasses: const ['wardley-link'],
        label: link.label,
      ),
    );
    if (link.flow case WardleyLinkFlow.forward || WardleyLinkFlow.bidirectional) {
      elements.add(
        _wardleyArrow(
          context,
          tip: end,
          tail: start,
          color: theme.linkStroke,
          cssClasses: const ['wardley-link-arrow'],
        ),
      );
    }
    if (link.flow case WardleyLinkFlow.backward || WardleyLinkFlow.bidirectional) {
      elements.add(
        _wardleyArrow(
          context,
          tip: start,
          tail: end,
          color: theme.linkStroke,
          cssClasses: const ['wardley-link-arrow'],
        ),
      );
    }
    if (link.label case final label?) {
      final midpoint = Point((source.x + target.x) / 2, (source.y + target.y) / 2);
      final labelPoint = Point(
        midpoint.x + dy / distance * _wardleyLinkLabelOffset,
        midpoint.y - dx / distance * _wardleyLinkLabelOffset,
      );
      var labelAngle = math.atan2(dy, dx) * _wardleyHalfTurnDegrees / math.pi;
      if (labelAngle > _wardleyQuarterTurnDegrees || labelAngle < -_wardleyQuarterTurnDegrees) {
        labelAngle += _wardleyHalfTurnDegrees;
      }
      elements.add(
        SceneGroup(
          id: context.id('wardley-link-label-group'),
          transforms: [Rotate(labelAngle, center: labelPoint)],
          cssClasses: const ['wardley-link-label-group'],
          children: [
            _text(
              context,
              label,
              labelPoint.x,
              labelPoint.y,
              anchor: TextAnchor.middle,
              baseline: TextBaseline.central,
              style: textStyles.componentLabel,
              cssClasses: const ['wardley-link-label'],
            ),
          ],
        ),
      );
    }
  }

  for (final trend in model.trends) {
    final origin = positions[trend.nodeId];
    if (origin == null) continue;
    final target = project(trend.targetX, trend.targetY);
    final dx = target.x - origin.x;
    final dy = target.y - origin.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final shorten = config.nodeRadius + _wardleyTrendTargetClearance;
    final end = distance > shorten
        ? Point(target.x - dx / distance * shorten, target.y - dy / distance * shorten)
        : target;
    elements.add(
      SceneLine(
        id: context.id('wardley-trend'),
        start: origin,
        end: end,
        stroke: strokes.evolution,
        role: SemanticRole.edge,
        cssClasses: const ['wardley-trend'],
      ),
    );
    if (distance > 0) {
      elements.add(
        _wardleyArrow(
          context,
          tip: end,
          tail: origin,
          color: theme.evolutionStroke,
          cssClasses: const ['wardley-trend-arrow'],
        ),
      );
    }
  }

  for (final node in model.nodes) {
    final point = positions[node.id]!;
    if (node.strategy case final strategy?) {
      switch (strategy) {
        case WardleyStrategy.build || WardleyStrategy.buy || WardleyStrategy.outsource:
          final fill = switch (strategy) {
            WardleyStrategy.build => _wardleyBuildStrategyFill,
            WardleyStrategy.buy => _wardleyBuyStrategyFill,
            WardleyStrategy.outsource => _wardleyOutsourceStrategyFill,
            WardleyStrategy.market => throw StateError('handled separately'),
          };
          final strategyStroke = strategy == WardleyStrategy.build ? strokes.buildStrategy : strokes.component;
          elements.add(
            SceneCircle(
              id: context.id('wardley-strategy'),
              center: point,
              radius: config.nodeRadius * _wardleyStrategyRadiusScale,
              fill: SolidFill(fill),
              stroke: strategyStroke,
              role: SemanticRole.node,
              cssClasses: ['wardley-${strategy.name}-overlay'],
            ),
          );
        case WardleyStrategy.market:
          _addWardleyMarket(elements, context, point, config, theme, strokes);
      }
    }
    if (node.isPipelineParent) {
      elements.add(
        SceneRect(
          id: context.id('wardley-pipeline-parent'),
          bounds: Bounds.fromCenter(point, Size(squareSize, squareSize)),
          fill: SolidFill(theme.componentFill),
          stroke: strokes.component,
          role: SemanticRole.node,
          cssClasses: const ['wardley-pipeline-parent'],
          label: node.label,
        ),
      );
    } else if (node.kind != WardleyNodeKind.anchor && node.strategy != WardleyStrategy.market) {
      elements.add(
        SceneCircle(
          id: context.id('wardley-component'),
          center: point,
          radius: config.nodeRadius,
          fill: SolidFill(theme.componentFill),
          stroke: strokes.component,
          role: SemanticRole.node,
          cssClasses: const ['wardley-component'],
          label: node.label,
        ),
      );
    }
    if (node.inertia) {
      var offset = node.isPipelineParent ? squareSize / 2 + _wardleyInertiaGap : config.nodeRadius + _wardleyInertiaGap;
      if (node.strategy != null) {
        offset += config.nodeRadius + _wardleyInertiaStrategyGap;
      }
      final lineHeight = node.isPipelineParent ? squareSize : config.nodeRadius * 2;
      elements.add(
        SceneLine(
          id: context.id('wardley-inertia'),
          start: Point(point.x + offset, point.y - lineHeight / 2),
          end: Point(point.x + offset, point.y + lineHeight / 2),
          stroke: strokes.inertia,
          role: SemanticRole.annotation,
          cssClasses: const ['wardley-inertia'],
        ),
      );
    }
    final isAnchor = node.kind == WardleyNodeKind.anchor;
    final strategySpacing = node.strategy == null ? 0.0 : _wardleyStrategyLabelSpacing;
    final labelX = point.x + (node.labelOffsetX ?? (isAnchor ? 0 : config.nodeLabelOffset + strategySpacing));
    final labelY =
        point.y +
        (node.labelOffsetY ??
            (isAnchor ? _wardleyAnchorLabelVerticalOffset : -config.nodeLabelOffset - strategySpacing));
    elements.add(
      _text(
        context,
        node.label,
        labelX,
        labelY,
        anchor: isAnchor ? TextAnchor.middle : TextAnchor.start,
        baseline: isAnchor ? TextBaseline.central : TextBaseline.alphabetic,
        style: isAnchor ? textStyles.anchorLabel : textStyles.componentLabel,
        cssClasses: const ['wardley-node-label'],
      ),
    );
  }

  for (final annotation in ast.annotations) {
    final point = positioned(annotation.position);
    elements.add(
      SceneCircle(
        id: context.id('wardley-annotation'),
        center: point,
        radius: _wardleyAnnotationRadius,
        fill: SolidFill(theme.annotationFill),
        stroke: strokes.annotation,
        role: SemanticRole.annotation,
        cssClasses: const ['wardley-annotation-circle'],
      ),
    );
    elements.add(
      _text(
        context,
        '${annotation.number}',
        point.x,
        point.y,
        anchor: TextAnchor.middle,
        style: textStyles.annotationNumber,
        cssClasses: const ['wardley-annotation-number'],
      ),
    );
  }
  if (ast.annotationsBox != null && ast.annotations.isNotEmpty) {
    final sorted = ast.annotations.where((annotation) => annotation.text.isNotEmpty).toList()
      ..sort((left, right) => left.number.compareTo(right.number));
    if (sorted.isNotEmpty) {
      final annotationStyle = textStyles.annotationText;
      var maxWidth = 0.0;
      var textHeight = 0.0;
      for (final annotation in sorted) {
        final size = context.measurer.measure('${annotation.number}. ${annotation.text}', annotationStyle);
        maxWidth = math.max(maxWidth, size.width);
        textHeight = math.max(textHeight, size.height);
      }
      final boxWidth = maxWidth + _wardleyAnnotationBoxPadding * 2 + _wardleyAnnotationBoxSafetyWidth;
      final boxHeight =
          sorted.length * _wardleyAnnotationLineHeight + _wardleyAnnotationBoxPadding * 2 + textHeight / 2;
      final requested = positioned(ast.annotationsBox!);
      final boxX = requested.x.clamp(config.padding, width - config.padding - boxWidth);
      final boxY = requested.y.clamp(config.padding, height - config.padding - boxHeight);
      elements.add(
        SceneRect(
          id: context.id('wardley-annotations-box'),
          bounds: Bounds(left: boxX, top: boxY, width: boxWidth, height: boxHeight),
          radiusX: _wardleyRoundedBoxRadius,
          radiusY: _wardleyRoundedBoxRadius,
          fill: SolidFill(theme.annotationFill),
          stroke: strokes.annotation,
          role: SemanticRole.annotation,
          cssClasses: const ['wardley-annotations-box'],
        ),
      );
      for (var i = 0; i < sorted.length; i++) {
        elements.add(
          _text(
            context,
            '${sorted[i].number}. ${sorted[i].text}',
            boxX + _wardleyAnnotationBoxPadding,
            boxY + _wardleyAnnotationBoxPadding + (i + 1) * _wardleyAnnotationLineHeight,
            style: annotationStyle,
            cssClasses: const ['wardley-annotation-text'],
          ),
        );
      }
    }
  }

  for (final note in ast.notes) {
    final point = positioned(note.position);
    elements.add(
      _text(
        context,
        note.text,
        point.x,
        point.y,
        role: SemanticRole.annotation,
        baseline: TextBaseline.alphabetic,
        style: textStyles.note,
        cssClasses: const ['wardley-note'],
      ),
    );
  }
  for (final marker in ast.markers) {
    final point = positioned(marker.position);
    final right = marker is WardleyAcceleratorAst;
    elements.add(
      ScenePath(
        id: context.id('wardley-marker'),
        commands: wardleyMarkerCommands(
          point,
          right: right,
          width: _wardleyMarkerWidth,
          height: _wardleyMarkerHeight,
          headWidth: _wardleyMarkerHeadWidth,
          notchDepth: _wardleyMarkerNotchDepth,
        ),
        fill: const SolidFill(_wardleyMarkerFill),
        stroke: strokes.component,
        role: SemanticRole.annotation,
        cssClasses: const ['wardley-marker'],
        label: marker.name,
      ),
    );
    elements.add(
      _text(
        context,
        marker.name,
        point.x + _wardleyMarkerLabelOffset,
        point.y + _wardleyMarkerLabelOffset,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.alphabetic,
        style: textStyles.markerLabel,
        cssClasses: const ['wardley-marker-label'],
      ),
    );
  }
  return _LayoutResult(width, height, elements);
}

ScenePolygon _wardleyArrow(
  _LayoutContext context, {
  required Point tip,
  required Point tail,
  required Color color,
  required List<String> cssClasses,
}) => _triangleArrow(
  context,
  tip: tip,
  tail: tail,
  length: _wardleyArrowLength,
  halfWidth: _wardleyArrowHalfWidth,
  color: color,
  idPrefix: 'wardley',
  cssClasses: cssClasses,
);

void _addWardleyMarket(
  List<SceneElement> elements,
  _LayoutContext context,
  Point center,
  WardleyRenderOptions config,
  WardleyTheme theme,
  _WardleyStrokes strokes,
) {
  final outerRadius = config.nodeRadius * _wardleyStrategyRadiusScale;
  final dotRadius = config.nodeRadius * _wardleyMarketDotRadiusScale;
  final triangleRadius = config.nodeRadius * _wardleyMarketTriangleRadiusScale;
  final triangleAngle = math.pi / _wardleyMarketTriangleAngleDivisor;
  final triangle = wardleyMarketTriangle(center: center, radius: triangleRadius, angle: triangleAngle);
  elements.add(
    SceneCircle(
      id: context.id('wardley-market'),
      center: center,
      radius: outerRadius,
      fill: SolidFill(theme.componentFill),
      stroke: strokes.component,
      role: SemanticRole.node,
      cssClasses: const ['wardley-market-overlay'],
    ),
  );
  for (final (start, end) in [
    (triangle.top, triangle.left),
    (triangle.left, triangle.right),
    (triangle.right, triangle.top),
  ]) {
    elements.add(
      SceneLine(
        id: context.id('wardley-market-line'),
        start: start,
        end: end,
        stroke: strokes.component,
        role: SemanticRole.node,
        cssClasses: const ['wardley-market-line'],
      ),
    );
  }
  for (final point in [triangle.top, triangle.left, triangle.right]) {
    elements.add(
      SceneCircle(
        id: context.id('wardley-market-dot'),
        center: point,
        radius: dotRadius,
        fill: SolidFill(theme.componentFill),
        stroke: strokes.marketDot,
        role: SemanticRole.node,
        cssClasses: const ['wardley-market-dot'],
      ),
    );
  }
}
