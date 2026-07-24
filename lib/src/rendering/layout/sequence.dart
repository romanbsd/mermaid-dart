part of '../layout.dart';

// Defaults and geometry below follow Mermaid.js 11.16's sequence config and
// renderer concepts while keeping all output backend-neutral.
const _sequenceLineWidth = 2.0;
const _sequenceLifelineDash = <double>[3, 3];
const _sequenceArrowLength = 10.0;
const _sequenceArrowHalfHeight = 4.0;
const _sequenceSelfMessageWidth = 40.0;
const _sequenceFrameLabelGap = 7.0;
const _sequenceDestructionRadius = 6.0;
// Mermaid's default 16px message metrics place the first label 32 units
// below the actor boxes and advance successive message rows by 46 units.
const _sequenceInitialMessageOffset = 31.0;
const _sequenceMessageRowPadding = 11.0;
// Mermaid places participants in content coordinates and applies diagram
// margins to the viewport, rather than translating the participant geometry.
const _sequenceActorLifelineOffset = 80.0;
const _sequenceActorHeadRadius = 15.0;
const _sequenceActorFigureWidth = 36.0;
// Mermaid's UML participant symbols use a 22px radius for boundary, control,
// and entity figures in sequence diagrams.
const _sequenceParticipantSymbolRadius = 22.0;
// Mermaid offsets the second rectangle in a collections participant by 6px.
const _sequenceCollectionsOffset = 6.0;
const _sequenceNumberRadius = 6.0;
const _sequenceActivationStartOffset = 2.0;
const _sequenceFrameNotchTop = 13.0;
const _sequenceFrameNotchLeft = 8.4;
// Classic Mermaid Sequence paint defaults are independent of the generic
// primary/secondary palette used by most diagram families.
const _sequenceActivationFill = Color(244, 244, 244);
const _sequenceActivationStroke = Color(102, 102, 102);
const _sequenceNoteFill = Color(255, 245, 173);
const _sequenceNoteStroke = Color(170, 170, 51);
const _sequenceFrameDash = <double>[2, 2];

_LayoutResult _layoutSequence(SequenceAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const SequenceRenderOptions());
  final theme = context.options.theme;
  final participantStyle = SceneTextStyle(
    fontFamily: theme.fontFamily,
    fontSize: config.actorFontSize,
    color: const Color(0, 0, 0),
  );
  final messageStyle = SceneTextStyle(
    fontFamily: theme.fontFamily,
    fontSize: config.messageFontSize,
    color: theme.primaryText,
  );
  final noteStyle = SceneTextStyle(
    fontFamily: theme.fontFamily,
    fontSize: config.noteFontSize,
    color: const Color(0, 0, 0),
  );
  final participantWidths = <String, double>{
    for (final participant in ast.participants)
      participant.id: math.max(
        config.actorWidth,
        context.measurer.measure(participant.label, participantStyle).width + 2 * config.wrapPadding,
      ),
  };
  final centers = <String, double>{};
  var x = 0.0;
  for (final participant in ast.participants) {
    final width = participantWidths[participant.id]!;
    centers[participant.id] = x + width / 2;
    x += width + config.actorMargin;
  }
  final width = ast.participants.isEmpty ? 0.0 : x - config.actorMargin;
  final boxBand = ast.boxes.isEmpty ? 0.0 : config.labelBoxHeight + config.boxMargin;
  final top = boxBand;
  final topActorBottom = top + config.actorHeight;
  final statementTop = topActorBottom + _sequenceInitialMessageOffset;
  final background = <SceneElement>[];
  final topActors = <SceneElement>[];
  final footerActors = <SceneElement>[];
  final participantStarts = <String, double>{};
  final participantEnds = <String, double>{};

  for (final box in ast.boxes) {
    final members = box.participantIds.where(centers.containsKey).toList();
    if (members.isEmpty) continue;
    final first = members.first;
    final last = members.last;
    final left = centers[first]! - participantWidths[first]! / 2 - config.boxMargin;
    final right = centers[last]! + participantWidths[last]! / 2 + config.boxMargin;
    final bounds = Bounds(
      left: left,
      top: config.diagramMarginY,
      width: right - left,
      height: config.actorHeight + boxBand + config.boxMargin,
    );
    background.add(
      SceneRect(
        id: context.id('sequence-box'),
        bounds: bounds,
        fill: SolidFill(_sequenceCssColor(box.color) ?? const Color(255, 255, 255, 0)),
        stroke: SceneStroke(color: theme.line),
        cssClasses: const ['sequence-box'],
        role: SemanticRole.group,
        label: box.label,
      ),
    );
    if (box.label.isNotEmpty) {
      background.add(
        _text(
          context,
          box.label,
          left + config.boxTextMargin,
          config.diagramMarginY + config.labelBoxHeight / 2,
          style: participantStyle,
          cssClasses: const ['sequence-box-label'],
        ),
      );
    }
  }

  for (final participant in ast.participants) {
    if (participant.createdAt == null) {
      topActors.addAll(
        _sequenceParticipant(
          participant,
          centers[participant.id]!,
          top,
          participantWidths[participant.id]!,
          config,
          context,
          participantStyle,
        ),
      );
      participantStarts[participant.id] = participant.kind == SequenceParticipantKind.actor
          ? top + _sequenceActorLifelineOffset
          : topActorBottom;
    }
  }

  final builder = _SequenceLayoutBuilder(
    ast: ast,
    context: context,
    config: config,
    centers: centers,
    participantWidths: participantWidths,
    participantStyle: participantStyle,
    messageStyle: messageStyle,
    noteStyle: noteStyle,
    participantStarts: participantStarts,
    participantEnds: participantEnds,
    y: statementTop,
    contentLeft: ast.participants.isEmpty ? 0 : centers.values.first - participantWidths.values.first / 2,
    contentRight: ast.participants.isEmpty ? 0 : centers.values.last + participantWidths.values.last / 2,
  )..render(ast.statements);

  final contentBottom = builder.contentBottom;
  final footerTop = contentBottom + (config.mirrorActors ? 2 * config.boxMargin : 0);
  if (config.mirrorActors) {
    for (final participant in ast.participants) {
      footerActors.addAll(
        _sequenceParticipant(
          participant,
          centers[participant.id]!,
          footerTop,
          participantWidths[participant.id]!,
          config,
          context,
          participantStyle,
        ),
      );
    }
  }
  final lifelineBottom = config.mirrorActors ? footerTop : contentBottom;
  final lifelines = <SceneElement>[];
  for (final participant in ast.participants) {
    final start =
        participantStarts[participant.id] ??
        (participant.kind == SequenceParticipantKind.actor ? top + _sequenceActorLifelineOffset : topActorBottom);
    final end = participantEnds[participant.id] ?? lifelineBottom;
    if (end <= start) continue;
    lifelines.add(
      SceneLine(
        id: context.id('sequence-lifeline'),
        start: Point(centers[participant.id]!, start),
        end: Point(centers[participant.id]!, end),
        stroke: SceneStroke(color: theme.primaryBorder, width: _sequenceLineWidth),
        cssClasses: const ['sequence-lifeline'],
        role: SemanticRole.edge,
        label: '${participant.label} lifeline',
      ),
    );
  }

  final activations = builder.finishActivations(lifelineBottom);
  final height =
      (config.mirrorActors ? footerTop + config.actorHeight : lifelineBottom) +
      config.diagramMarginY +
      config.bottomMarginAdjustment;
  return _LayoutResult(
    width,
    height,
    [...background, ...lifelines, ...topActors, ...builder.elements, ...activations, ...footerActors],
    bounds: Bounds(
      left: -config.diagramMarginX,
      top: -config.diagramMarginY,
      width: width + 2 * config.diagramMarginX,
      height: height + config.diagramMarginY,
    ),
  );
}

List<SceneElement> _sequenceParticipant(
  SequenceParticipantAst participant,
  double centerX,
  double top,
  double width,
  SequenceRenderOptions config,
  _LayoutContext context,
  SceneTextStyle style,
) {
  final fill = SolidFill(context.options.theme.primary);
  final link = participant.links.values.firstOrNull;
  final classes = ['sequence-participant', 'sequence-participant-${participant.kind.name}'];
  if (participant.kind == SequenceParticipantKind.actor) {
    final border = SceneStroke(color: context.options.theme.primaryBorder, width: _sequenceLineWidth);
    final halfWidth = _sequenceActorFigureWidth / 2;
    return [
      SceneLine(
        id: context.id('sequence-actor-torso'),
        start: Point(centerX, top + 25),
        end: Point(centerX, top + 45),
        stroke: border,
        cssClasses: const ['sequence-participant', 'sequence-participant-actor'],
      ),
      SceneLine(
        id: context.id('sequence-actor-arms'),
        start: Point(centerX - halfWidth, top + 33),
        end: Point(centerX + halfWidth, top + 33),
        stroke: border,
        cssClasses: const ['sequence-participant', 'sequence-participant-actor'],
      ),
      SceneLine(
        id: context.id('sequence-actor-leg'),
        start: Point(centerX - halfWidth, top + 60),
        end: Point(centerX, top + 45),
        stroke: border,
        cssClasses: const ['sequence-participant', 'sequence-participant-actor'],
      ),
      SceneLine(
        id: context.id('sequence-actor-leg'),
        start: Point(centerX, top + 45),
        end: Point(centerX + halfWidth - 2, top + 60),
        stroke: border,
        cssClasses: const ['sequence-participant', 'sequence-participant-actor'],
      ),
      SceneCircle(
        id: context.id('sequence-actor-head'),
        center: Point(centerX, top + 10),
        radius: _sequenceActorHeadRadius,
        fill: SolidFill(context.options.theme.primary),
        stroke: border,
        role: SemanticRole.node,
        cssClasses: const ['sequence-participant', 'sequence-participant-actor'],
        label: participant.label,
      ),
      _text(
        context,
        participant.label,
        centerX,
        top + 67.5,
        anchor: TextAnchor.middle,
        style: style,
        link: participant.links.values.firstOrNull,
        cssClasses: const ['sequence-participant-label', 'sequence-participant-actor-label'],
      ),
    ];
  }
  final border = SceneStroke(color: context.options.theme.primaryBorder);
  final bounds = Bounds(left: centerX - width / 2, top: top, width: width, height: config.actorHeight);
  final symbolCenterY = top + _sequenceParticipantSymbolRadius;
  final symbolLabelY = top + config.actorHeight - 2;

  List<SceneElement> withLabel(List<SceneElement> geometry) => [
    ...geometry,
    _text(
      context,
      participant.label,
      centerX,
      participant.kind == SequenceParticipantKind.participant ? top + config.actorHeight / 2 : symbolLabelY,
      anchor: TextAnchor.middle,
      style: style,
      link: link,
      cssClasses: const ['sequence-participant-label'],
    ),
  ];

  switch (participant.kind) {
    case SequenceParticipantKind.actor:
      throw StateError('Actor participants are handled above.');
    case SequenceParticipantKind.participant:
      return withLabel([
        SceneRect(
          id: context.id('sequence-participant'),
          bounds: bounds,
          radiusX: 3,
          radiusY: 3,
          fill: fill,
          stroke: border,
          role: SemanticRole.node,
          cssClasses: classes,
          label: participant.label,
        ),
      ]);
    case SequenceParticipantKind.collections:
      final shadowBounds = Bounds(
        left: bounds.left - _sequenceCollectionsOffset,
        top: bounds.top + _sequenceCollectionsOffset,
        width: bounds.width,
        height: bounds.height - _sequenceCollectionsOffset,
      );
      return withLabel([
        SceneRect(
          id: context.id('sequence-collections-shadow'),
          bounds: shadowBounds,
          fill: fill,
          stroke: border,
          cssClasses: classes,
        ),
        SceneRect(
          id: context.id('sequence-participant'),
          bounds: bounds,
          fill: fill,
          stroke: border,
          role: SemanticRole.node,
          cssClasses: classes,
          label: participant.label,
        ),
      ]);
    case SequenceParticipantKind.boundary:
      final radius = _sequenceParticipantSymbolRadius;
      return withLabel([
        SceneLine(
          id: context.id('sequence-boundary-stem'),
          start: Point(centerX - radius * 2.5, symbolCenterY),
          end: Point(centerX - radius, symbolCenterY),
          stroke: border,
          cssClasses: classes,
        ),
        SceneLine(
          id: context.id('sequence-boundary-bar'),
          start: Point(centerX - radius * 2.5, symbolCenterY - 10),
          end: Point(centerX - radius * 2.5, symbolCenterY + 10),
          stroke: border,
          cssClasses: classes,
        ),
        SceneCircle(
          id: context.id('sequence-participant'),
          center: Point(centerX, symbolCenterY),
          radius: radius,
          fill: fill,
          stroke: border,
          role: SemanticRole.node,
          cssClasses: classes,
          label: participant.label,
        ),
      ]);
    case SequenceParticipantKind.control:
      final radius = _sequenceParticipantSymbolRadius;
      return withLabel([
        SceneCircle(
          id: context.id('sequence-participant'),
          center: Point(centerX, symbolCenterY),
          radius: radius,
          fill: fill,
          stroke: border,
          role: SemanticRole.node,
          cssClasses: classes,
          label: participant.label,
        ),
        ScenePath(
          id: context.id('sequence-control-arrow'),
          commands: [
            MoveTo(Point(centerX - radius / 2, symbolCenterY - radius)),
            ArcTo(
              radiusX: radius,
              radiusY: radius,
              largeArc: true,
              end: Point(centerX + radius / 2, symbolCenterY - radius),
            ),
            LineTo(Point(centerX + radius / 2 - 5, symbolCenterY - radius - 3)),
          ],
          stroke: border,
          cssClasses: classes,
        ),
      ]);
    case SequenceParticipantKind.entity:
      final radius = _sequenceParticipantSymbolRadius;
      return withLabel([
        SceneCircle(
          id: context.id('sequence-participant'),
          center: Point(centerX, symbolCenterY),
          radius: radius,
          fill: fill,
          stroke: border,
          role: SemanticRole.node,
          cssClasses: classes,
          label: participant.label,
        ),
        SceneLine(
          id: context.id('sequence-entity-underline'),
          start: Point(centerX - radius, symbolCenterY + radius),
          end: Point(centerX + radius, symbolCenterY + radius),
          stroke: border,
          cssClasses: classes,
        ),
      ]);
    case SequenceParticipantKind.database:
      final cylinderWidth = width / 3;
      final cylinderHeight = width / 3;
      final left = centerX - cylinderWidth / 2;
      final right = centerX + cylinderWidth / 2;
      final radiusY = cylinderWidth / 2 / (2.5 + cylinderWidth / 50);
      return withLabel([
        ScenePath(
          id: context.id('sequence-participant'),
          commands: [
            MoveTo(Point(left, top + radiusY)),
            ArcTo(radiusX: cylinderWidth / 2, radiusY: radiusY, end: Point(right, top + radiusY)),
            ArcTo(radiusX: cylinderWidth / 2, radiusY: radiusY, end: Point(left, top + radiusY)),
            LineTo(Point(left, top + cylinderHeight - radiusY)),
            ArcTo(
              radiusX: cylinderWidth / 2,
              radiusY: radiusY,
              clockwise: false,
              end: Point(right, top + cylinderHeight - radiusY),
            ),
            LineTo(Point(right, top + radiusY)),
          ],
          fill: fill,
          stroke: border,
          role: SemanticRole.node,
          cssClasses: classes,
          label: participant.label,
        ),
      ]);
    case SequenceParticipantKind.queue:
      final radiusY = config.actorHeight / 2;
      final radiusX = radiusY / (2.5 + config.actorHeight / 50);
      final left = bounds.left + radiusX;
      final right = bounds.right - radiusX;
      return withLabel([
        ScenePath(
          id: context.id('sequence-participant'),
          commands: [
            MoveTo(Point(left, top)),
            LineTo(Point(right, top)),
            ArcTo(radiusX: radiusX, radiusY: radiusY, end: Point(right, top + config.actorHeight)),
            LineTo(Point(left, top + config.actorHeight)),
            ArcTo(radiusX: radiusX, radiusY: radiusY, clockwise: false, end: Point(left, top)),
            ClosePath(),
          ],
          fill: fill,
          stroke: border,
          role: SemanticRole.node,
          cssClasses: classes,
          label: participant.label,
        ),
        ScenePath(
          id: context.id('sequence-queue-rim'),
          commands: [
            MoveTo(Point(right, top)),
            ArcTo(radiusX: radiusX, radiusY: radiusY, end: Point(right, top + config.actorHeight)),
          ],
          stroke: border,
          cssClasses: classes,
        ),
      ]);
  }
}

final class _SequenceLayoutBuilder {
  _SequenceLayoutBuilder({
    required this.ast,
    required this.context,
    required this.config,
    required this.centers,
    required this.participantWidths,
    required this.participantStyle,
    required this.messageStyle,
    required this.noteStyle,
    required this.participantStarts,
    required this.participantEnds,
    required this.y,
    required this.contentLeft,
    required this.contentRight,
  }) : autoNumber = ast.autoNumber?.start ?? 1,
       contentBottom = y;

  final SequenceAst ast;
  final _LayoutContext context;
  final SequenceRenderOptions config;
  final Map<String, double> centers;
  final Map<String, double> participantWidths;
  final SceneTextStyle participantStyle;
  final SceneTextStyle messageStyle;
  final SceneTextStyle noteStyle;
  final Map<String, double> participantStarts;
  final Map<String, double> participantEnds;
  final double contentLeft;
  final double contentRight;
  final elements = <SceneElement>[];
  final activationStarts = <String, List<double>>{};
  final activationSpans = <({String participantId, double start, double end, int depth})>[];
  double y;
  double contentBottom;
  double? lastMessageLineY;
  num autoNumber;
  var messageIndex = 0;

  void render(List<SequenceStatementAst> statements) {
    for (final statement in statements) {
      switch (statement) {
        case SequenceMessageAst():
          _message(statement);
        case SequenceNoteAst():
          _note(statement);
        case SequenceActivationAst():
          statement.active ? _startActivation(statement.participantId, y) : _endActivation(statement.participantId, y);
        case SequenceBlockAst():
          _block(statement);
        case SequenceRectAst():
          _rect(statement);
      }
    }
  }

  void _message(SequenceMessageAst message) {
    final fromX = centers[message.from];
    final toX = centers[message.to];
    if (fromX == null || toX == null) return;
    final created = ast.participants.where((participant) => participant.id == message.to).firstOrNull;
    if (created?.createdAt == messageIndex) {
      final actorTop = y - config.actorHeight / 2;
      elements.addAll(
        _sequenceParticipant(
          created!,
          toX,
          actorTop,
          participantWidths[message.to]!,
          config,
          context,
          participantStyle,
        ),
      );
      participantStarts[message.to] = y;
    }

    final numberVisible = ast.autoNumber?.visible ?? config.showSequenceNumbers;
    final direction = toX == fromX ? 1.0 : (toX > fromX ? 1.0 : -1.0);
    final fromBounds = _activationBounds(message.from);
    final toBounds = _activationBounds(message.to);
    var lineStartX = direction > 0 ? fromBounds.right : fromBounds.left;
    var lineEndX = direction > 0 ? toBounds.left : toBounds.right;
    if (message.activateTarget && (activationStarts[message.to]?.isEmpty ?? true)) {
      lineEndX -= direction * (config.activationWidth / 2 - 1);
    }
    if (_sequenceShortensForMarker(message.arrow)) lineEndX -= direction * 3;
    final labelX = toX == fromX ? fromX + _sequenceSelfMessageWidth / 2 : ((lineStartX + lineEndX) / 2).roundToDouble();
    elements.add(
      _text(
        context,
        message.text,
        labelX,
        y,
        anchor: TextAnchor.middle,
        style: messageStyle,
        cssClasses: const ['sequence-message-label'],
      ),
    );
    final lineY = y + config.messageFontSize / 2 + _sequenceFrameLabelGap;
    lastMessageLineY = lineY;
    final stroke = SceneStroke(
      color: context.options.theme.line,
      width: _sequenceLineWidth,
      dashes: message.arrow.isDotted ? _sequenceLifelineDash : const [],
    );
    if (fromX == toX) {
      elements.add(
        ScenePath(
          id: context.id('sequence-message-line'),
          commands: [
            MoveTo(Point(fromX, lineY)),
            LineTo(Point(fromX + _sequenceSelfMessageWidth, lineY)),
            LineTo(Point(fromX + _sequenceSelfMessageWidth, lineY + config.messageMargin)),
            LineTo(Point(fromX, lineY + config.messageMargin)),
          ],
          stroke: stroke,
          cssClasses: const ['sequence-message-line'],
          role: SemanticRole.edge,
          label: message.text,
        ),
      );
      elements.addAll(_sequenceMarker(message.arrow, Point(fromX, lineY + config.messageMargin), -1, context));
      contentBottom = math.max(contentBottom, lineY + config.messageMargin);
      y += config.messageMargin + _sequenceMessageRowPadding;
    } else {
      if (numberVisible) lineStartX += _sequenceNumberRadius;
      elements.add(
        SceneLine(
          id: context.id('sequence-message-line'),
          start: Point(lineStartX, lineY),
          end: Point(lineEndX, lineY),
          stroke: stroke,
          cssClasses: const ['sequence-message-line'],
          role: SemanticRole.edge,
          label: message.text,
        ),
      );
      if (numberVisible) {
        final numberX = direction > 0
            ? math.min(fromBounds.left, toBounds.left) + 1
            : math.max(fromBounds.right, toBounds.right) - 1;
        elements.add(
          SceneLine(
            id: context.id('sequence-number-marker'),
            start: Point(numberX, lineY),
            end: Point(numberX, lineY),
            stroke: const SceneStroke(color: Color(0, 0, 0, 0), width: _sequenceLineWidth),
            cssClasses: const ['sequence-number-marker'],
          ),
        );
        elements.add(
          _text(
            context,
            _sequenceNumber(autoNumber),
            numberX,
            lineY + 4,
            anchor: TextAnchor.middle,
            baseline: TextBaseline.alphabetic,
            style: const SceneTextStyle(fontFamily: 'sans-serif', fontSize: 12, color: Color(255, 255, 255)),
            cssClasses: const ['sequence-number'],
          ),
        );
      }
      elements.addAll(_sequenceMarker(message.arrow, Point(toX, lineY), direction, context));
      if (message.arrow.isBidirectional) {
        elements.addAll(_sequenceMarker(message.arrow, Point(fromX, lineY), -direction, context));
      }
    }

    if (message.activateTarget) _startActivation(message.to, lineY + _sequenceActivationStartOffset);
    if (message.deactivateSource) _endActivation(message.from, lineY);
    final destroyed = ast.participants.where((participant) => participant.destroyedAt == messageIndex).firstOrNull;
    if (destroyed != null) {
      participantEnds[destroyed.id] = lineY;
      elements.addAll(_sequenceDestruction(centers[destroyed.id]!, lineY, context));
    }
    messageIndex++;
    autoNumber += ast.autoNumber?.step ?? 1;
    contentBottom = math.max(contentBottom, lineY);
    y += config.messageMargin + _sequenceMessageRowPadding;
  }

  void _note(SequenceNoteAst note) {
    final xs = note.participantIds.map((id) => centers[id]).whereType<double>().toList();
    if (xs.isEmpty) return;
    final measured = context.measurer.measure(note.text, noteStyle);
    final width = switch (note.placement) {
      SequenceNotePlacement.leftOf ||
      SequenceNotePlacement.rightOf => math.max(config.actorWidth, measured.width + 2 * config.noteMargin),
      SequenceNotePlacement.over => math.max(config.actorWidth, measured.width + 2 * config.noteMargin),
    };
    final height = measured.height + 2 * config.noteMargin;
    final firstId = note.participantIds.first;
    final lastId = note.participantIds.last;
    final firstLeft = centers[firstId]! - participantWidths[firstId]! / 2;
    final lastLeft = centers[lastId]! - participantWidths[lastId]! / 2;
    final anchorX = switch (note.placement) {
      SequenceNotePlacement.leftOf =>
        firstLeft - width + (participantWidths[firstId]! - config.actorMargin) / 2 + width / 2,
      SequenceNotePlacement.rightOf => lastLeft + (participantWidths[lastId]! + config.actorMargin) / 2 + width / 2,
      SequenceNotePlacement.over => (xs.first + xs.last) / 2,
    };
    final top = y + config.boxMargin;
    final bounds = Bounds(left: anchorX - width / 2, top: top, width: width, height: height);
    elements.add(
      SceneRect(
        id: context.id('sequence-note'),
        bounds: bounds,
        fill: const SolidFill(_sequenceNoteFill),
        stroke: const SceneStroke(color: _sequenceNoteStroke),
        cssClasses: const ['sequence-note'],
        role: SemanticRole.annotation,
        label: note.text,
      ),
    );
    elements.add(
      _text(
        context,
        note.text,
        anchorX,
        top + height / 2 + 1.5,
        anchor: TextAnchor.middle,
        style: noteStyle,
        cssClasses: const ['sequence-note-label'],
      ),
    );
    contentBottom = math.max(contentBottom, bounds.bottom);
    y = bounds.bottom;
  }

  void _block(SequenceBlockAst block) {
    final insertAt = elements.length;
    final startY = lastMessageLineY == null ? y : lastMessageLineY! + config.boxMargin;
    final kind = _sequenceBlockName(block.kind);
    final separators = <double>[];
    final participantIds = _sequenceParticipantIds(block);
    final blockCenters = participantIds.map((id) => centers[id]).whereType<double>();
    final left = blockCenters.isEmpty
        ? contentLeft - config.boxMargin
        : blockCenters.reduce(math.min) - config.boxMargin - 1;
    final right = blockCenters.isEmpty
        ? contentRight + config.boxMargin
        : participantIds.map((id) => centers[id]).whereType<double>().reduce(math.max) + config.boxMargin + 1;
    var endY = startY + config.labelBoxHeight;

    for (var sectionIndex = 0; sectionIndex < block.sections.length; sectionIndex++) {
      final section = block.sections[sectionIndex];
      if (sectionIndex == 0) {
        elements.add(
          _text(
            context,
            kind,
            left + config.labelBoxWidth / 2,
            startY + _sequenceFrameNotchTop,
            anchor: TextAnchor.middle,
            style: participantStyle,
            cssClasses: const ['sequence-block-kind'],
          ),
        );
        if (section.label.isNotEmpty) {
          elements.add(
            _text(
              context,
              '[${section.label}]',
              (left + right) / 2 + config.labelBoxWidth / 2,
              startY + config.labelBoxHeight - 2,
              anchor: TextAnchor.middle,
              baseline: TextBaseline.alphabetic,
              style: participantStyle,
              cssClasses: const ['sequence-block-label'],
            ),
          );
        }
        y = startY + config.labelBoxHeight + config.boxMargin + config.messageMargin + 1;
      } else {
        final separatorY = (lastMessageLineY ?? y) + config.boxMargin + config.boxTextMargin;
        separators.add(separatorY);
        if (section.label.isNotEmpty) {
          elements.add(
            _text(
              context,
              '[${section.label}]',
              (left + right) / 2,
              separatorY + config.labelBoxHeight - 2,
              anchor: TextAnchor.middle,
              baseline: TextBaseline.alphabetic,
              style: participantStyle,
              cssClasses: const ['sequence-block-section-label'],
            ),
          );
        }
        y = separatorY + config.labelBoxHeight + config.messageMargin + config.boxTextMargin + 1;
      }
      render(section.statements);
      endY = (lastMessageLineY ?? y) + config.boxMargin;
    }
    final frameStroke = SceneStroke(
      color: context.options.theme.primaryBorder,
      width: _sequenceLineWidth,
      dashes: _sequenceFrameDash,
    );
    elements.insertAll(insertAt, [
      SceneLine(
        id: context.id('sequence-block-top'),
        start: Point(left, startY),
        end: Point(right, startY),
        stroke: frameStroke,
        cssClasses: ['sequence-block', 'sequence-block-$kind'],
      ),
      SceneLine(
        id: context.id('sequence-block-right'),
        start: Point(right, startY),
        end: Point(right, endY),
        stroke: frameStroke,
        cssClasses: ['sequence-block', 'sequence-block-$kind'],
      ),
      SceneLine(
        id: context.id('sequence-block-bottom'),
        start: Point(left, endY),
        end: Point(right, endY),
        stroke: frameStroke,
        cssClasses: ['sequence-block', 'sequence-block-$kind'],
      ),
      SceneLine(
        id: context.id('sequence-block-left'),
        start: Point(left, startY),
        end: Point(left, endY),
        stroke: frameStroke,
        cssClasses: ['sequence-block', 'sequence-block-$kind'],
      ),
      ScenePolygon(
        id: context.id('sequence-block-label-box'),
        points: [
          Point(left, startY),
          Point(left + config.labelBoxWidth, startY),
          Point(left + config.labelBoxWidth, startY + _sequenceFrameNotchTop),
          Point(left + config.labelBoxWidth - _sequenceFrameNotchLeft, startY + config.labelBoxHeight),
          Point(left, startY + config.labelBoxHeight),
        ],
        fill: SolidFill(context.options.theme.primary),
        stroke: SceneStroke(color: context.options.theme.primaryBorder),
        cssClasses: const ['sequence-block-label-box'],
        role: SemanticRole.group,
        label: kind,
      ),
    ]);
    for (final separatorY in separators) {
      elements.add(
        SceneLine(
          id: context.id('sequence-block-separator'),
          start: Point(left, separatorY),
          end: Point(right, separatorY),
          stroke: SceneStroke(
            color: context.options.theme.primaryBorder,
            width: _sequenceLineWidth,
            dashes: _sequenceLifelineDash,
          ),
          cssClasses: const ['sequence-block-separator'],
        ),
      );
    }
    y = endY;
    contentBottom = math.max(contentBottom, endY);
  }

  void _rect(SequenceRectAst rect) {
    final insertAt = elements.length;
    final startY = y;
    render(rect.statements);
    elements.insert(
      insertAt,
      SceneRect(
        id: context.id('sequence-rect'),
        bounds: Bounds(
          left: contentLeft - config.boxMargin,
          top: startY,
          width: contentRight - contentLeft + 2 * config.boxMargin,
          height: math.max(config.messageMargin, y - startY),
        ),
        fill: SolidFill(_sequenceCssColor(rect.color) ?? const Color(238, 238, 238, 128)),
        cssClasses: const ['sequence-rect'],
        role: SemanticRole.background,
      ),
    );
    contentBottom = math.max(contentBottom, y);
  }

  void _startActivation(String participantId, double at) {
    activationStarts.putIfAbsent(participantId, () => []).add(at);
  }

  void _endActivation(String participantId, double at) {
    final starts = activationStarts[participantId];
    if (starts == null || starts.isEmpty) return;
    final depth = starts.length - 1;
    activationSpans.add((participantId: participantId, start: starts.removeLast(), end: at, depth: depth));
  }

  ({double left, double right}) _activationBounds(String participantId) {
    final center = centers[participantId]!;
    final count = activationStarts[participantId]?.length ?? 0;
    if (count == 0) return (left: center - 1, right: center + 1);
    return (
      left: center - config.activationWidth / 2,
      right: center + config.activationWidth / 2 + (count - 1) * config.activationWidth / 2,
    );
  }

  List<SceneElement> finishActivations(double end) {
    for (final entry in activationStarts.entries) {
      while (entry.value.isNotEmpty) {
        final depth = entry.value.length - 1;
        activationSpans.add((participantId: entry.key, start: entry.value.removeLast(), end: end, depth: depth));
      }
    }
    return [
      for (final span in activationSpans)
        if (centers[span.participantId] case final center?)
          SceneRect(
            id: context.id('sequence-activation'),
            bounds: Bounds(
              left: center - config.activationWidth / 2 + span.depth * config.activationWidth / 2,
              top: span.start,
              width: config.activationWidth,
              height: math.max(1, span.end - span.start),
            ),
            fill: const SolidFill(_sequenceActivationFill),
            stroke: const SceneStroke(color: _sequenceActivationStroke),
            cssClasses: const ['sequence-activation'],
            role: SemanticRole.node,
            label: '${span.participantId} activation',
          ),
    ];
  }
}

List<SceneElement> _sequenceMarker(SequenceArrow arrow, Point tip, double direction, _LayoutContext context) {
  final color = context.options.theme.line;
  if (arrow == SequenceArrow.solidCross || arrow == SequenceArrow.dottedCross) {
    return [
      SceneLine(
        id: context.id('sequence-cross'),
        start: Point(tip.x - _sequenceDestructionRadius, tip.y - _sequenceDestructionRadius),
        end: Point(tip.x + _sequenceDestructionRadius, tip.y + _sequenceDestructionRadius),
        stroke: SceneStroke(color: color, width: _sequenceLineWidth),
        cssClasses: const ['sequence-message-marker'],
      ),
      SceneLine(
        id: context.id('sequence-cross'),
        start: Point(tip.x - _sequenceDestructionRadius, tip.y + _sequenceDestructionRadius),
        end: Point(tip.x + _sequenceDestructionRadius, tip.y - _sequenceDestructionRadius),
        stroke: SceneStroke(color: color, width: _sequenceLineWidth),
        cssClasses: const ['sequence-message-marker'],
      ),
    ];
  }
  if (arrow == SequenceArrow.solidPoint || arrow == SequenceArrow.dottedPoint) {
    return [
      ScenePolygon(
        id: context.id('sequence-point'),
        points: [
          Point(tip.x, tip.y - _sequenceArrowHalfHeight),
          Point(tip.x + _sequenceArrowHalfHeight, tip.y),
          Point(tip.x, tip.y + _sequenceArrowHalfHeight),
          Point(tip.x - _sequenceArrowHalfHeight, tip.y),
        ],
        fill: SolidFill(color),
        cssClasses: const ['sequence-message-marker'],
      ),
    ];
  }
  final baseX = tip.x - direction * _sequenceArrowLength;
  final points = [Point(baseX, tip.y - _sequenceArrowHalfHeight), tip, Point(baseX, tip.y + _sequenceArrowHalfHeight)];
  final open = arrow == SequenceArrow.solidOpen || arrow == SequenceArrow.dottedOpen;
  return [
    if (open)
      ScenePath(
        id: context.id('sequence-arrow'),
        commands: [MoveTo(points.first), LineTo(points[1]), LineTo(points.last)],
        stroke: SceneStroke(color: color, width: _sequenceLineWidth),
        cssClasses: const ['sequence-message-marker'],
      )
    else
      ScenePolygon(
        id: context.id('sequence-arrow'),
        points: points,
        fill: SolidFill(color),
        stroke: SceneStroke(color: color, width: _sequenceLineWidth),
        cssClasses: const ['sequence-message-marker'],
      ),
  ];
}

List<SceneElement> _sequenceDestruction(double x, double y, _LayoutContext context) => [
  SceneLine(
    id: context.id('sequence-destroy'),
    start: Point(x - _sequenceDestructionRadius, y - _sequenceDestructionRadius),
    end: Point(x + _sequenceDestructionRadius, y + _sequenceDestructionRadius),
    stroke: SceneStroke(color: context.options.theme.line, width: 2),
    cssClasses: const ['sequence-destruction'],
  ),
  SceneLine(
    id: context.id('sequence-destroy'),
    start: Point(x - _sequenceDestructionRadius, y + _sequenceDestructionRadius),
    end: Point(x + _sequenceDestructionRadius, y - _sequenceDestructionRadius),
    stroke: SceneStroke(color: context.options.theme.line, width: 2),
    cssClasses: const ['sequence-destruction'],
  ),
];

String _sequenceBlockName(SequenceBlockKind kind) => switch (kind) {
  SequenceBlockKind.breakBlock => 'break',
  SequenceBlockKind.parOver => 'par_over',
  _ => kind.name,
};

Set<String> _sequenceParticipantIds(SequenceBlockAst block) {
  final result = <String>{};
  void collect(Iterable<SequenceStatementAst> statements) {
    for (final statement in statements) {
      switch (statement) {
        case SequenceMessageAst(:final from, :final to):
          result
            ..add(from)
            ..add(to);
        case SequenceNoteAst(:final participantIds):
          result.addAll(participantIds);
        case SequenceActivationAst(:final participantId):
          result.add(participantId);
        case SequenceBlockAst(:final sections):
          for (final section in sections) {
            collect(section.statements);
          }
        case SequenceRectAst(:final statements):
          collect(statements);
      }
    }
  }

  for (final section in block.sections) {
    collect(section.statements);
  }
  return result;
}

bool _sequenceShortensForMarker(SequenceArrow arrow) => switch (arrow) {
  SequenceArrow.solid ||
  SequenceArrow.dotted ||
  SequenceArrow.bidirectionalSolid ||
  SequenceArrow.bidirectionalDotted ||
  SequenceArrow.solidCross ||
  SequenceArrow.dottedCross ||
  SequenceArrow.solidPoint ||
  SequenceArrow.dottedPoint => true,
  _ => false,
};

String _sequenceNumber(num value) =>
    value is int || value == value.roundToDouble() ? value.toInt().toString() : value.toString();

Color? _sequenceCssColor(String source) {
  final value = source.trim();
  final basic = _parseCssColor(value);
  if (basic != null) return basic;
  final match = RegExp(
    r'^rgba?\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*(?:,\s*(\d*\.?\d+)\s*)?\)$',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return value.toLowerCase() == 'transparent' ? const Color(0, 0, 0, 0) : null;
  final red = double.parse(match.group(1)!).round().clamp(0, 255);
  final green = double.parse(match.group(2)!).round().clamp(0, 255);
  final blue = double.parse(match.group(3)!).round().clamp(0, 255);
  final alpha = match.group(4) == null ? 255 : (double.parse(match.group(4)!) * 255).round().clamp(0, 255);
  return Color(red, green, blue, alpha);
}
