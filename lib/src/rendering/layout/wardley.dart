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

// Mermaid's fixed map primitives. Values in this group are renderer geometry,
// not user configuration, and intentionally remain stable when nodeRadius or
// typography options change.
const _wardleyCoordinateMaximum = 100.0;
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

_LayoutResult _layoutWardley(WardleyAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const WardleyRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  final width = ast.size?.width.toDouble() ?? config.width;
  final height = ast.size?.height.toDouble() ?? config.height;
  final chartWidth = width - config.padding * 2;
  final chartHeight = height - config.padding * 2;
  final model = buildWardleyModel(ast);
  final elements = <SceneElement>[];
  final axisStroke = SceneStroke(color: theme.axisColor);
  final componentStroke = SceneStroke(color: theme.componentStroke);
  final axisStyle = SceneTextStyle(
    fontFamily: _wardleyFontFamily,
    fontSize: config.axisFontSize,
    color: theme.axisTextColor,
  );
  final labelStyle = SceneTextStyle(
    fontFamily: _wardleyFontFamily,
    fontSize: config.labelFontSize,
    color: theme.componentLabelColor,
  );
  Point project(double x, double y) => Point(
    config.padding + x.clamp(0, _wardleyCoordinateMaximum) / _wardleyCoordinateMaximum * chartWidth,
    height - config.padding - y.clamp(0, _wardleyCoordinateMaximum) / _wardleyCoordinateMaximum * chartHeight,
  );
  Point positioned(WardleyPositionAst value) => project(value.x.toDouble(), value.y.toDouble());
  final positions = <String, Point>{for (final node in model.nodes) node.id: project(node.x, node.y)};

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
        style: SceneTextStyle(
          fontFamily: _wardleyFontFamily,
          fontSize: config.axisFontSize * _wardleyTitleFontScale,
          weight: FontWeight.bold,
          color: theme.axisTextColor,
        ),
        cssClasses: const ['wardley-title'],
      ),
    );
  }

  elements.addAll([
    SceneLine(
      id: context.id('wardley-axis'),
      start: Point(config.padding, height - config.padding),
      end: Point(width - config.padding, height - config.padding),
      stroke: axisStroke,
      role: SemanticRole.edge,
      cssClasses: const ['wardley-axis'],
    ),
    SceneLine(
      id: context.id('wardley-axis'),
      start: Point(config.padding, config.padding),
      end: Point(config.padding, height - config.padding),
      stroke: axisStroke,
      role: SemanticRole.edge,
      cssClasses: const ['wardley-axis'],
    ),
    _text(
      context,
      'Evolution',
      config.padding + chartWidth / 2,
      height - config.padding / 4,
      anchor: TextAnchor.middle,
      baseline: TextBaseline.alphabetic,
      style: SceneTextStyle(
        fontFamily: axisStyle.fontFamily,
        fontSize: axisStyle.fontSize,
        weight: FontWeight.bold,
        color: axisStyle.color,
      ),
      cssClasses: const ['wardley-axis-label', 'wardley-axis-label-x'],
    ),
  ]);
  final yLabelCenter = Point(config.padding / 3, config.padding + chartHeight / 2);
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
          style: SceneTextStyle(
            fontFamily: axisStyle.fontFamily,
            fontSize: axisStyle.fontSize,
            weight: FontWeight.bold,
            color: axisStyle.color,
          ),
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
          stroke: SceneStroke(color: config.stageBoundaryColor, dashes: _wardleyStageBoundaryDashes),
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
        height - config.padding / 1.5,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.alphabetic,
        style: SceneTextStyle(
          fontFamily: axisStyle.fontFamily,
          fontSize: config.axisFontSize - _wardleyStageLabelFontReduction,
          color: theme.axisTextColor,
        ),
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
          stroke: SceneStroke(color: theme.gridColor, dashes: _wardleyGridDashes),
          role: SemanticRole.edge,
          cssClasses: const ['wardley-grid-line'],
        ),
        SceneLine(
          id: context.id('wardley-grid'),
          start: Point(config.padding, height - config.padding - chartHeight * ratio),
          end: Point(width - config.padding, height - config.padding - chartHeight * ratio),
          stroke: SceneStroke(color: theme.gridColor, dashes: _wardleyGridDashes),
          role: SemanticRole.edge,
          cssClasses: const ['wardley-grid-line'],
        ),
      ]);
    }
  }

  final squareSize = config.nodeRadius * _wardleyPipelineParentSizeScale;
  for (final pipeline in model.pipelines) {
    final components =
        pipeline.componentIds
            .map((id) => model.nodes.firstWhereOrNull((node) => node.id == id))
            .whereType<WardleyNodeModel>()
            .toList()
          ..sort((left, right) => left.x.compareTo(right.x));
    for (var i = 0; i < components.length - 1; i++) {
      elements.add(
        SceneLine(
          id: context.id('wardley-pipeline-link'),
          start: positions[components[i].id]!,
          end: positions[components[i + 1].id]!,
          stroke: SceneStroke(color: theme.linkStroke, dashes: _wardleyEvolutionDashes),
          role: SemanticRole.edge,
          cssClasses: const ['wardley-pipeline-evolution-link'],
        ),
      );
    }
    if (components.isEmpty) continue;
    final componentPositions = components.map((node) => positions[node.id]!).toList();
    final minX = componentPositions.map((point) => point.x).reduce(math.min);
    final maxX = componentPositions.map((point) => point.x).reduce(math.max);
    final y = componentPositions.last.y;
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
        stroke: SceneStroke(color: theme.componentStroke, width: _wardleyOutlineStrokeWidth),
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
    final sourceNode = model.nodes.firstWhere((node) => node.id == link.sourceId);
    final targetNode = model.nodes.firstWhere((node) => node.id == link.targetId);
    final sourceRadius = sourceNode.isPipelineParent ? squareSize / math.sqrt2 : config.nodeRadius;
    final targetRadius = targetNode.isPipelineParent ? squareSize / math.sqrt2 : config.nodeRadius;
    final start = Point(source.x + dx / distance * sourceRadius, source.y + dy / distance * sourceRadius);
    final end = Point(target.x - dx / distance * targetRadius, target.y - dy / distance * targetRadius);
    elements.add(
      SceneLine(
        id: context.id('wardley-link'),
        start: start,
        end: end,
        stroke: SceneStroke(
          color: theme.linkStroke,
          dashes: link.style == WardleyLinkStyle.dashed ? _wardleyDependencyDashes : const [],
        ),
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
              style: labelStyle,
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
        stroke: SceneStroke(color: theme.evolutionStroke, dashes: _wardleyEvolutionDashes),
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
            WardleyStrategy.build => const Color(238, 238, 238),
            WardleyStrategy.buy => const Color(204, 204, 204),
            WardleyStrategy.outsource => const Color(102, 102, 102),
            WardleyStrategy.market => throw StateError('handled separately'),
          };
          final strategyStroke = strategy == WardleyStrategy.build
              ? SceneStroke(color: config.buildStrategyStroke)
              : componentStroke;
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
          _addWardleyMarket(elements, context, point, config, theme);
      }
    }
    if (node.isPipelineParent) {
      elements.add(
        SceneRect(
          id: context.id('wardley-pipeline-parent'),
          bounds: Bounds.fromCenter(point, Size(squareSize, squareSize)),
          fill: SolidFill(theme.componentFill),
          stroke: componentStroke,
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
          stroke: componentStroke,
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
          stroke: SceneStroke(color: theme.componentStroke, width: _wardleyInertiaStrokeWidth),
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
        style: SceneTextStyle(
          fontFamily: labelStyle.fontFamily,
          fontSize: labelStyle.fontSize,
          weight: isAnchor ? FontWeight.bold : FontWeight.normal,
          color: isAnchor ? config.anchorLabelColor : theme.componentLabelColor,
        ),
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
        stroke: SceneStroke(color: theme.annotationStroke, width: _wardleyOutlineStrokeWidth),
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
        style: SceneTextStyle(
          fontFamily: _wardleyFontFamily,
          fontSize: _wardleyAnnotationNumberFontSize,
          weight: FontWeight.bold,
          color: theme.annotationTextColor,
        ),
        cssClasses: const ['wardley-annotation-number'],
      ),
    );
  }
  if (ast.annotationsBox != null && ast.annotations.isNotEmpty) {
    final sorted = ast.annotations.where((annotation) => annotation.text.isNotEmpty).toList()
      ..sort((left, right) => left.number.compareTo(right.number));
    if (sorted.isNotEmpty) {
      final annotationStyle = SceneTextStyle(
        fontFamily: _wardleyFontFamily,
        fontSize: _wardleyAnnotationTextFontSize,
        color: theme.annotationTextColor,
      );
      final maxWidth = sorted
          .map(
            (annotation) => context.measurer.measure('${annotation.number}. ${annotation.text}', annotationStyle).width,
          )
          .reduce(math.max);
      final textHeight = sorted
          .map(
            (annotation) =>
                context.measurer.measure('${annotation.number}. ${annotation.text}', annotationStyle).height,
          )
          .reduce(math.max);
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
          stroke: SceneStroke(color: theme.annotationStroke, width: _wardleyOutlineStrokeWidth),
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
        style: SceneTextStyle(
          fontFamily: _wardleyFontFamily,
          fontSize: _wardleyNoteFontSize,
          weight: FontWeight.bold,
          color: theme.axisTextColor,
        ),
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
        commands: _wardleyMarkerCommands(point, right: right),
        fill: const SolidFill(_wardleyMarkerFill),
        stroke: componentStroke,
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
        style: SceneTextStyle(
          fontFamily: _wardleyFontFamily,
          fontSize: _wardleyMarkerLabelFontSize,
          weight: FontWeight.bold,
          color: theme.axisTextColor,
        ),
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
) {
  final outerRadius = config.nodeRadius * _wardleyStrategyRadiusScale;
  final dotRadius = config.nodeRadius * _wardleyMarketDotRadiusScale;
  final triangleRadius = config.nodeRadius * _wardleyMarketTriangleRadiusScale;
  final triangleAngle = math.pi / _wardleyMarketTriangleAngleDivisor;
  final left = Point(
    center.x - triangleRadius * math.cos(triangleAngle),
    center.y + triangleRadius * math.sin(triangleAngle),
  );
  final right = Point(
    center.x + triangleRadius * math.cos(triangleAngle),
    center.y + triangleRadius * math.sin(triangleAngle),
  );
  final top = Point(center.x, center.y - triangleRadius);
  final stroke = SceneStroke(color: theme.componentStroke);
  elements.add(
    SceneCircle(
      id: context.id('wardley-market'),
      center: center,
      radius: outerRadius,
      fill: SolidFill(theme.componentFill),
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: const ['wardley-market-overlay'],
    ),
  );
  for (final (start, end) in [(top, left), (left, right), (right, top)]) {
    elements.add(
      SceneLine(
        id: context.id('wardley-market-line'),
        start: start,
        end: end,
        stroke: stroke,
        role: SemanticRole.node,
        cssClasses: const ['wardley-market-line'],
      ),
    );
  }
  for (final point in [top, left, right]) {
    elements.add(
      SceneCircle(
        id: context.id('wardley-market-dot'),
        center: point,
        radius: dotRadius,
        fill: SolidFill(theme.componentFill),
        stroke: SceneStroke(color: theme.componentStroke, width: _wardleyMarketDotStrokeWidth),
        role: SemanticRole.node,
        cssClasses: const ['wardley-market-dot'],
      ),
    );
  }
}

List<PathCommand> _wardleyMarkerCommands(Point origin, {required bool right}) {
  final tailX = origin.x + (right ? 0 : _wardleyMarkerWidth);
  final neckX = origin.x + (right ? _wardleyMarkerWidth - _wardleyMarkerHeadWidth : _wardleyMarkerHeadWidth);
  final tipX = origin.x + (right ? _wardleyMarkerWidth : 0);
  final top = origin.y - _wardleyMarkerHeight / 2;
  final bottom = origin.y + _wardleyMarkerHeight / 2;
  return [
    MoveTo(Point(tailX, top)),
    LineTo(Point(neckX, top)),
    LineTo(Point(neckX, top - _wardleyMarkerNotchDepth)),
    LineTo(Point(tipX, origin.y)),
    LineTo(Point(neckX, bottom + _wardleyMarkerNotchDepth)),
    LineTo(Point(neckX, bottom)),
    LineTo(Point(tailX, bottom)),
    const ClosePath(),
  ];
}
