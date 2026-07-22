part of '../layout.dart';

_LayoutResult _layoutWardley(WardleyAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const WardleyRenderOptions());
  final width = ast.size?.width.toDouble() ?? config.width;
  final height = ast.size?.height.toDouble() ?? config.height;
  final chartWidth = width - config.padding * 2;
  final chartHeight = height - config.padding * 2;
  final model = buildWardleyModel(ast);
  final elements = <SceneElement>[];
  final axisStroke = SceneStroke(color: config.axisColor);
  final componentStroke = SceneStroke(color: config.componentStroke);
  final axisStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: config.axisFontSize,
    color: config.axisTextColor,
  );
  final labelStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: config.labelFontSize,
    color: config.componentLabelColor,
  );
  Point project(double x, double y) => Point(
    config.padding + x.clamp(0, 100) / 100 * chartWidth,
    height - config.padding - y.clamp(0, 100) / 100 * chartHeight,
  );
  Point positioned(WardleyPositionAst value) => project(value.x.toDouble(), value.y.toDouble());
  final positions = <String, Point>{for (final node in model.nodes) node.id: project(node.x, node.y)};

  elements.add(
    SceneRect(
      id: context.id('wardley-background'),
      bounds: Bounds(left: 0, top: 0, width: width, height: height),
      fill: SolidFill(config.backgroundColor),
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
        role: SemanticRole.title,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: config.axisFontSize * 1.05,
          weight: FontWeight.bold,
          color: config.axisTextColor,
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
      transforms: [Rotate(-90, center: yLabelCenter)],
      cssClasses: const ['wardley-axis-label-y-group'],
      children: [
        _text(
          context,
          'Visibility',
          yLabelCenter.x,
          yLabelCenter.y,
          anchor: TextAnchor.middle,
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
          stroke: SceneStroke(color: config.axisColor, dashes: const [5, 5]),
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
          fontSize: config.axisFontSize - 2,
          color: config.axisTextColor,
        ),
        cssClasses: const ['wardley-stage-label'],
      ),
    );
    stageStart = stageEnd;
  }

  if (config.showGrid) {
    for (var i = 1; i < 4; i++) {
      final ratio = i / 4;
      elements.addAll([
        SceneLine(
          id: context.id('wardley-grid'),
          start: Point(config.padding + chartWidth * ratio, config.padding),
          end: Point(config.padding + chartWidth * ratio, height - config.padding),
          stroke: SceneStroke(color: config.gridColor, dashes: const [2, 6]),
          role: SemanticRole.edge,
          cssClasses: const ['wardley-grid-line'],
        ),
        SceneLine(
          id: context.id('wardley-grid'),
          start: Point(config.padding, height - config.padding - chartHeight * ratio),
          end: Point(width - config.padding, height - config.padding - chartHeight * ratio),
          stroke: SceneStroke(color: config.gridColor, dashes: const [2, 6]),
          role: SemanticRole.edge,
          cssClasses: const ['wardley-grid-line'],
        ),
      ]);
    }
  }

  final squareSize = config.nodeRadius * 1.6;
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
          stroke: SceneStroke(color: config.linkStroke, dashes: const [4, 4]),
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
    final pipelineHeight = config.nodeRadius * 4;
    final boxTop = y - pipelineHeight / 2;
    positions[pipeline.parentId] = Point((minX + maxX) / 2, boxTop - squareSize / 6);
    elements.add(
      SceneRect(
        id: context.id('wardley-pipeline-box'),
        bounds: Bounds(left: minX - 15, top: boxTop, width: maxX - minX + 30, height: pipelineHeight),
        radiusX: 4,
        radiusY: 4,
        fill: const NoFill(),
        stroke: SceneStroke(color: config.axisColor, width: 1.5),
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
      ScenePath(
        id: context.id('wardley-link'),
        commands: [MoveTo(start), LineTo(end)],
        fill: const NoFill(),
        stroke: SceneStroke(
          color: config.linkStroke,
          dashes: link.style == WardleyLinkStyle.dashed ? const [6, 6] : const [],
        ),
        role: SemanticRole.edge,
        cssClasses: const ['wardley-link'],
        label: link.label,
      ),
    );
    if (link.flow case WardleyLinkFlow.forward || WardleyLinkFlow.bidirectional) {
      elements.add(
        _triangleArrow(
          context,
          tip: end,
          tail: start,
          length: 6,
          halfWidth: 3,
          color: config.linkStroke,
          idPrefix: 'wardley',
          cssClasses: const ['wardley-link-arrow'],
        ),
      );
    }
    if (link.flow case WardleyLinkFlow.backward || WardleyLinkFlow.bidirectional) {
      elements.add(
        _triangleArrow(
          context,
          tip: start,
          tail: end,
          length: 6,
          halfWidth: 3,
          color: config.linkStroke,
          idPrefix: 'wardley',
          cssClasses: const ['wardley-link-arrow'],
        ),
      );
    }
    if (link.label case final label?) {
      final midpoint = Point((source.x + target.x) / 2, (source.y + target.y) / 2);
      final labelPoint = Point(midpoint.x + dy / distance * 8, midpoint.y - dx / distance * 8);
      elements.add(
        _text(
          context,
          label,
          labelPoint.x,
          labelPoint.y,
          anchor: TextAnchor.middle,
          style: labelStyle,
          cssClasses: const ['wardley-link-label'],
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
    final shorten = config.nodeRadius + 2;
    final end = distance > shorten
        ? Point(target.x - dx / distance * shorten, target.y - dy / distance * shorten)
        : target;
    elements.add(
      ScenePath(
        id: context.id('wardley-trend'),
        commands: [MoveTo(origin), LineTo(end)],
        fill: const NoFill(),
        stroke: SceneStroke(color: config.evolutionStroke, dashes: const [4, 4]),
        role: SemanticRole.edge,
        cssClasses: const ['wardley-trend'],
      ),
    );
    if (distance > 0) {
      elements.add(
        _triangleArrow(
          context,
          tip: end,
          tail: origin,
          length: 6,
          halfWidth: 3,
          color: config.evolutionStroke,
          idPrefix: 'wardley',
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
          elements.add(
            SceneCircle(
              id: context.id('wardley-strategy'),
              center: point,
              radius: config.nodeRadius * 2,
              fill: SolidFill(fill),
              stroke: componentStroke,
              role: SemanticRole.node,
              cssClasses: ['wardley-${strategy.name}-overlay'],
            ),
          );
        case WardleyStrategy.market:
          _addWardleyMarket(elements, context, point, config);
      }
    }
    if (node.isPipelineParent) {
      elements.add(
        SceneRect(
          id: context.id('wardley-pipeline-parent'),
          bounds: Bounds(
            left: point.x - squareSize / 2,
            top: point.y - squareSize / 2,
            width: squareSize,
            height: squareSize,
          ),
          fill: SolidFill(config.componentFill),
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
          fill: SolidFill(config.componentFill),
          stroke: componentStroke,
          role: SemanticRole.node,
          cssClasses: const ['wardley-component'],
          label: node.label,
        ),
      );
    }
    if (node.inertia) {
      var offset = node.isPipelineParent ? squareSize / 2 + 15 : config.nodeRadius + 15;
      if (node.strategy != null) offset += config.nodeRadius + 10;
      final lineHeight = node.isPipelineParent ? squareSize : config.nodeRadius * 2;
      elements.add(
        SceneLine(
          id: context.id('wardley-inertia'),
          start: Point(point.x + offset, point.y - lineHeight / 2),
          end: Point(point.x + offset, point.y + lineHeight / 2),
          stroke: SceneStroke(color: config.componentStroke, width: 6),
          role: SemanticRole.annotation,
          cssClasses: const ['wardley-inertia'],
        ),
      );
    }
    final isAnchor = node.kind == WardleyNodeKind.anchor;
    final strategySpacing = node.strategy == null ? 0.0 : 10.0;
    final labelX = point.x + (node.labelOffsetX ?? (isAnchor ? 0 : config.nodeLabelOffset + strategySpacing));
    final labelY = point.y + (node.labelOffsetY ?? (isAnchor ? -3 : -config.nodeLabelOffset - strategySpacing));
    elements.add(
      _text(
        context,
        node.label,
        labelX,
        labelY,
        anchor: isAnchor ? TextAnchor.middle : TextAnchor.start,
        style: SceneTextStyle(
          fontFamily: labelStyle.fontFamily,
          fontSize: labelStyle.fontSize,
          weight: isAnchor ? FontWeight.bold : FontWeight.normal,
          color: isAnchor ? config.axisColor : config.componentLabelColor,
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
        radius: 10,
        fill: const SolidFill(Color(255, 255, 255)),
        stroke: SceneStroke(color: config.axisColor, width: 1.5),
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
          fontFamily: context.options.theme.fontFamily,
          fontSize: 10,
          weight: FontWeight.bold,
          color: config.axisTextColor,
        ),
        cssClasses: const ['wardley-annotation-number'],
      ),
    );
  }
  if (ast.annotationsBox != null && ast.annotations.isNotEmpty) {
    final sorted = ast.annotations.where((annotation) => annotation.text.isNotEmpty).toList()
      ..sort((left, right) => left.number.compareTo(right.number));
    if (sorted.isNotEmpty) {
      const boxPadding = 10.0;
      const lineHeight = 16.0;
      final annotationStyle = SceneTextStyle(
        fontFamily: context.options.theme.fontFamily,
        fontSize: 11,
        color: config.axisTextColor,
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
      final boxWidth = maxWidth + boxPadding * 2 + 105;
      final boxHeight = sorted.length * lineHeight + boxPadding * 2 + textHeight / 2;
      final requested = positioned(ast.annotationsBox!);
      final boxX = requested.x.clamp(config.padding, width - config.padding - boxWidth);
      final boxY = requested.y.clamp(config.padding, height - config.padding - boxHeight);
      elements.add(
        SceneRect(
          id: context.id('wardley-annotations-box'),
          bounds: Bounds(left: boxX, top: boxY, width: boxWidth, height: boxHeight),
          radiusX: 4,
          radiusY: 4,
          fill: const SolidFill(Color(255, 255, 255)),
          stroke: SceneStroke(color: config.axisColor, width: 1.5),
          role: SemanticRole.annotation,
          cssClasses: const ['wardley-annotations-box'],
        ),
      );
      for (var i = 0; i < sorted.length; i++) {
        elements.add(
          _text(
            context,
            '${sorted[i].number}. ${sorted[i].text}',
            boxX + boxPadding,
            boxY + boxPadding + (i + 1) * lineHeight,
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
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: 11,
          weight: FontWeight.bold,
          color: config.axisTextColor,
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
        fill: const SolidFill(Color(255, 255, 255)),
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
        point.x + 30,
        point.y + 30,
        anchor: TextAnchor.middle,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: 10,
          weight: FontWeight.bold,
          color: config.axisTextColor,
        ),
        cssClasses: const ['wardley-marker-label'],
      ),
    );
  }
  return _LayoutResult(width, height, elements);
}

ScenePolygon _triangleArrow(
  _LayoutContext context, {
  required Point tip,
  required Point tail,
  required double length,
  required double halfWidth,
  required Color color,
  required String idPrefix,
  required List<String> cssClasses,
}) {
  final dx = tip.x - tail.x;
  final dy = tip.y - tail.y;
  final distance = math.sqrt(dx * dx + dy * dy);
  final unitX = distance == 0 ? 1.0 : dx / distance;
  final unitY = distance == 0 ? 0.0 : dy / distance;
  final base = Point(tip.x - unitX * length, tip.y - unitY * length);
  return ScenePolygon(
    id: context.id('$idPrefix-arrow'),
    points: [
      tip,
      Point(base.x - unitY * halfWidth, base.y + unitX * halfWidth),
      Point(base.x + unitY * halfWidth, base.y - unitX * halfWidth),
    ],
    fill: SolidFill(color),
    role: SemanticRole.edge,
    cssClasses: cssClasses,
  );
}

void _addWardleyMarket(List<SceneElement> elements, _LayoutContext context, Point center, WardleyRenderOptions config) {
  final outerRadius = config.nodeRadius * 2;
  final dotRadius = config.nodeRadius * .7;
  final triangleRadius = config.nodeRadius * 1.2;
  final left = Point(
    center.x - triangleRadius * math.cos(math.pi / 6),
    center.y + triangleRadius * math.sin(math.pi / 6),
  );
  final right = Point(
    center.x + triangleRadius * math.cos(math.pi / 6),
    center.y + triangleRadius * math.sin(math.pi / 6),
  );
  final top = Point(center.x, center.y - triangleRadius);
  final stroke = SceneStroke(color: config.componentStroke);
  elements.add(
    SceneCircle(
      id: context.id('wardley-market'),
      center: center,
      radius: outerRadius,
      fill: const SolidFill(Color(255, 255, 255)),
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
        fill: const SolidFill(Color(255, 255, 255)),
        stroke: SceneStroke(color: config.componentStroke, width: 2),
        role: SemanticRole.node,
        cssClasses: const ['wardley-market-dot'],
      ),
    );
  }
}

List<PathCommand> _wardleyMarkerCommands(Point origin, {required bool right}) {
  const width = 60.0;
  const height = 30.0;
  const headWidth = 20.0;
  if (right) {
    return [
      MoveTo(Point(origin.x, origin.y - height / 2)),
      LineTo(Point(origin.x + width - headWidth, origin.y - height / 2)),
      LineTo(Point(origin.x + width - headWidth, origin.y - height / 2 - 8)),
      LineTo(Point(origin.x + width, origin.y)),
      LineTo(Point(origin.x + width - headWidth, origin.y + height / 2 + 8)),
      LineTo(Point(origin.x + width - headWidth, origin.y + height / 2)),
      LineTo(Point(origin.x, origin.y + height / 2)),
      const ClosePath(),
    ];
  }
  return [
    MoveTo(Point(origin.x + width, origin.y - height / 2)),
    LineTo(Point(origin.x + headWidth, origin.y - height / 2)),
    LineTo(Point(origin.x + headWidth, origin.y - height / 2 - 8)),
    LineTo(Point(origin.x, origin.y)),
    LineTo(Point(origin.x + headWidth, origin.y + height / 2 + 8)),
    LineTo(Point(origin.x + headWidth, origin.y + height / 2)),
    LineTo(Point(origin.x + width, origin.y + height / 2)),
    const ClosePath(),
  ];
}
