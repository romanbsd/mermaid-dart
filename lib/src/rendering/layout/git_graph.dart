part of '../layout.dart';

// Mermaid gitGraph renderer constants. The names document which upstream
// coordinate or spacing rule each otherwise non-obvious value represents.
const _gitLayoutOffset = 10.0;
const _gitCommitStep = 40.0;
const _gitDefaultPosition = 30.0;
const _gitLaneYCorrection = 2.0;
const _gitRotatedBranchSpacing = 40.0;
const _gitRotatedLabelClearance = 30.0;
const _gitBranchLabelBackgroundLeftInset = 23.0;
const _gitBranchLabelHorizontalPadding = 18.0;
const _gitBranchLabelVerticalPadding = 4.0;
const _gitBranchLabelTextInset = 14.0;
const _gitVerticalBranchLabelBackgroundInset = 10.0;
const _gitVerticalBranchLabelTextInset = 5.0;
const _gitEdgeRadius = 20.0;
const _gitCommitLabelFontSize = 10.0;
const _gitCommitLabelBaselineOffset = 25.0;
const _gitCommitLabelBackgroundTopOffset = 13.5;
const _gitCommitLabelPadding = 2.0;
const _gitVerticalCommitLabelTopOffset = 12.0;
const _gitVerticalCommitLabelTextInset = 8.0;
const _gitVerticalCommitLabelBackgroundInset = 13.0;
const _gitCommitLabelRotation = -45.0;
const _gitRotatedLabelBaseX = -7.5;
const _gitRotatedLabelBaseY = 10.0;
const _gitRotatedLabelWidthReference = 25.0;
const _gitRotatedLabelXScale = 9.5;
const _gitRotatedLabelYScale = 8.5;

_LayoutResult _layoutGitGraph(GitGraphAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const GitGraphRenderOptions());
  final model = buildGitGraphModel(ast, config);
  final direction = ast.direction ?? GitGraphDirection.leftToRight;
  final vertical = direction != GitGraphDirection.leftToRight;
  final branchStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: context.options.theme.fontSize,
    weight: FontWeight.bold,
    color: context.options.theme.primaryText,
  );
  final commitStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: _gitCommitLabelFontSize,
    color: config.commitLabelColor,
  );
  final branchWidths = {
    for (final branch in model.branches) branch.name: context.measurer.measure(branch.name, branchStyle).width,
  };
  final branchPositions = <String, double>{};
  var branchCursor = 0.0;
  for (final branch in model.branches) {
    branchPositions[branch.name] = branchCursor;
    branchCursor +=
        config.branchSpacing +
        (config.rotateCommitLabel ? _gitRotatedBranchSpacing : 0) +
        (vertical ? (branchWidths[branch.name] ?? 0) / 2 : 0);
  }
  final axisPositions = <String, double>{};
  for (final commit in model.commits) {
    final parentAxis = commit.parents
        .map((parent) => axisPositions[parent])
        .whereType<double>()
        .fold<double?>(null, (maximum, value) => maximum == null || value > maximum ? value : maximum);
    axisPositions[commit.id] = parentAxis == null ? 0 : parentAxis + config.commitSpacing;
  }
  final maxAxis = axisPositions.values.fold<double>(0, math.max);
  final maxPosition =
      maxAxis +
      (vertical ? _gitDefaultPosition + _gitLayoutOffset + _gitCommitStep : _gitLayoutOffset + _gitCommitStep);
  final positions = <String, Point>{};
  for (final commit in model.commits) {
    final axis = axisPositions[commit.id]!;
    final branch = branchPositions[commit.branch]!;
    positions[commit.id] = switch (direction) {
      GitGraphDirection.leftToRight => Point(_gitLayoutOffset + axis, branch - _gitLaneYCorrection),
      GitGraphDirection.topToBottom => Point(branch, _gitDefaultPosition + _gitLayoutOffset + axis),
      GitGraphDirection.bottomToTop => Point(branch, maxPosition - _gitLayoutOffset - axis),
    };
  }
  final elements = <SceneElement>[];

  if (config.showBranches) {
    for (var i = 0; i < model.branches.length; i++) {
      final branch = model.branches[i];
      final lane = branchPositions[branch.name]!;
      final color = _gitBranchColor(config, i);
      final labelStyle = SceneTextStyle(
        fontFamily: branchStyle.fontFamily,
        fontSize: branchStyle.fontSize,
        weight: branchStyle.weight,
        color: _gitBranchLabelColor(config, i),
      );
      final (start, end, labelPoint, labelAnchor) = switch (direction) {
        GitGraphDirection.leftToRight => (
          Point(0, lane - _gitLaneYCorrection),
          Point(maxPosition, lane - _gitLaneYCorrection),
          Point(
            -branchWidths[branch.name]! -
                _gitBranchLabelTextInset -
                (config.rotateCommitLabel ? _gitRotatedLabelClearance : 0),
            lane - _gitLaneYCorrection,
          ),
          TextAnchor.start,
        ),
        GitGraphDirection.topToBottom => (
          Point(lane, _gitDefaultPosition),
          Point(lane, maxPosition),
          Point(lane - branchWidths[branch.name]! / 2 - _gitVerticalBranchLabelTextInset, 0),
          TextAnchor.start,
        ),
        GitGraphDirection.bottomToTop => (
          Point(lane, maxPosition),
          Point(lane, _gitDefaultPosition),
          Point(lane - branchWidths[branch.name]! / 2 - _gitVerticalBranchLabelTextInset, maxPosition),
          TextAnchor.start,
        ),
      };
      elements.add(
        SceneLine(
          id: context.id('git-branch'),
          start: start,
          end: end,
          stroke: SceneStroke(
            color: config.branchLineColor,
            width: config.branchLineWidth,
            dashes: config.branchLineDashes,
          ),
          role: SemanticRole.edge,
          cssClasses: const ['git-branch-line'],
          label: branch.name,
        ),
      );
      final size = context.measurer.measure(branch.name, branchStyle);
      final labelBounds = switch (direction) {
        GitGraphDirection.leftToRight => Bounds(
          left:
              -size.width -
              _gitBranchLabelBackgroundLeftInset -
              (config.rotateCommitLabel ? _gitRotatedLabelClearance : 0),
          top: labelPoint.y - size.height / 2 - _gitLaneYCorrection,
          width: size.width + _gitBranchLabelHorizontalPadding,
          height: size.height + _gitBranchLabelVerticalPadding,
        ),
        GitGraphDirection.topToBottom => Bounds(
          left: lane - size.width / 2 - _gitVerticalBranchLabelBackgroundInset,
          top: 0,
          width: size.width + _gitBranchLabelHorizontalPadding,
          height: size.height + _gitBranchLabelVerticalPadding,
        ),
        GitGraphDirection.bottomToTop => Bounds(
          left: lane - size.width / 2 - _gitVerticalBranchLabelBackgroundInset,
          top: maxPosition,
          width: size.width + _gitBranchLabelHorizontalPadding,
          height: size.height + _gitBranchLabelVerticalPadding,
        ),
      };
      elements.add(
        SceneRect(
          id: context.id('git-branch-label-background'),
          bounds: labelBounds,
          radiusX: 4,
          radiusY: 4,
          fill: SolidFill(color),
          role: SemanticRole.legend,
          cssClasses: const ['git-branch-label-background'],
        ),
      );
      elements.add(
        _text(
          context,
          branch.name,
          labelPoint.x,
          direction == GitGraphDirection.leftToRight
              ? labelPoint.y - size.height / 2 - _gitLaneYCorrection + branchStyle.fontSize
              : labelPoint.y + branchStyle.fontSize,
          anchor: labelAnchor,
          baseline: TextBaseline.alphabetic,
          role: SemanticRole.legend,
          style: labelStyle,
          cssClasses: const ['git-branch-label'],
        ),
      );
    }
  }

  for (final commit in model.commits) {
    final end = positions[commit.id]!;
    for (var parentIndex = 0; parentIndex < commit.parents.length; parentIndex++) {
      final parentId = commit.parents[parentIndex];
      final start = positions[parentId];
      if (start == null) continue;
      final parent = model.commits.firstWhere((candidate) => candidate.id == parentId);
      final colorBranch = commit.kind == GitCommitKind.merge && parentIndex > 0 ? parent.branch : commit.branch;
      final branchIndex = model.branches.indexWhere((branch) => branch.name == colorBranch);
      elements.add(
        ScenePath(
          id: context.id('git-edge'),
          commands: _gitEdgeCommands(start, end, direction),
          fill: const NoFill(),
          stroke: SceneStroke(
            color: _gitBranchColor(config, branchIndex),
            width: config.commitEdgeWidth,
            cap: config.commitEdgeCap,
          ),
          role: SemanticRole.edge,
          cssClasses: const ['git-commit-edge'],
          label: '${parent.id} to ${commit.id}',
        ),
      );
    }
  }

  for (final commit in model.commits) {
    final point = positions[commit.id]!;
    final branchIndex = model.branches.indexWhere((branch) => branch.name == commit.branch);
    final color = _gitBranchColor(config, branchIndex);
    _addGitCommit(elements, context, commit, point, color, config);
    if (config.showCommitLabel &&
        commit.kind != GitCommitKind.cherryPick &&
        (commit.kind != GitCommitKind.merge || commit.customId)) {
      _addGitCommitLabel(
        elements,
        context,
        commit.id,
        point,
        axisPositions[commit.id]!,
        commitStyle,
        config,
        direction,
      );
    }
    _addGitTags(elements, context, commit.tags, point, commitStyle, config, direction);
  }

  if (ast.title case final title?) {
    elements.add(
      _text(
        context,
        title,
        maxPosition / 2,
        config.titleTopMargin,
        anchor: TextAnchor.middle,
        role: SemanticRole.title,
        style: SceneTextStyle(
          fontFamily: context.options.theme.fontFamily,
          fontSize: context.options.theme.fontSize,
          weight: FontWeight.bold,
          color: context.options.theme.primaryText,
        ),
        cssClasses: const ['git-title'],
      ),
    );
  }
  final bounds = _sceneGeometryBounds(elements) ?? const Bounds(left: 0, top: 0, width: 1, height: 1);
  return _LayoutResult(
    math.max(bounds.width, 1),
    math.max(bounds.height, 1),
    elements,
    bounds: bounds,
    viewportPadding: config.diagramPadding,
  );
}

Color _gitBranchColor(GitGraphRenderOptions config, int index) {
  final colors = config.branchColors.isEmpty ? GitGraphRenderOptions.defaultBranchColors : config.branchColors;
  return colors[(index < 0 ? 0 : index) % colors.length];
}

Color _gitBranchLabelColor(GitGraphRenderOptions config, int index) {
  final colors = config.branchLabelColors.isEmpty
      ? GitGraphRenderOptions.defaultBranchLabelColors
      : config.branchLabelColors;
  return colors[(index < 0 ? 0 : index) % colors.length];
}

List<PathCommand> _gitEdgeCommands(Point start, Point end, GitGraphDirection direction) {
  if (start.x == end.x || start.y == end.y) return [MoveTo(start), LineTo(end)];
  return switch (direction) {
    GitGraphDirection.leftToRight when start.y < end.y => [
      MoveTo(start),
      LineTo(Point(start.x, end.y - _gitEdgeRadius)),
      ArcTo(
        radiusX: _gitEdgeRadius,
        radiusY: _gitEdgeRadius,
        clockwise: false,
        end: Point(start.x + _gitEdgeRadius, end.y),
      ),
      LineTo(end),
    ],
    GitGraphDirection.leftToRight => [
      MoveTo(start),
      LineTo(Point(start.x, end.y + _gitEdgeRadius)),
      ArcTo(
        radiusX: _gitEdgeRadius,
        radiusY: _gitEdgeRadius,
        clockwise: true,
        end: Point(start.x + _gitEdgeRadius, end.y),
      ),
      LineTo(end),
    ],
    GitGraphDirection.topToBottom when start.x < end.x => [
      MoveTo(start),
      LineTo(Point(end.x - _gitEdgeRadius, start.y)),
      ArcTo(
        radiusX: _gitEdgeRadius,
        radiusY: _gitEdgeRadius,
        clockwise: true,
        end: Point(end.x, start.y + _gitEdgeRadius),
      ),
      LineTo(end),
    ],
    GitGraphDirection.topToBottom => [
      MoveTo(start),
      LineTo(Point(end.x + _gitEdgeRadius, start.y)),
      ArcTo(
        radiusX: _gitEdgeRadius,
        radiusY: _gitEdgeRadius,
        clockwise: false,
        end: Point(end.x, start.y + _gitEdgeRadius),
      ),
      LineTo(end),
    ],
    GitGraphDirection.bottomToTop when start.x < end.x => [
      MoveTo(start),
      LineTo(Point(end.x - _gitEdgeRadius, start.y)),
      ArcTo(
        radiusX: _gitEdgeRadius,
        radiusY: _gitEdgeRadius,
        clockwise: false,
        end: Point(end.x, start.y - _gitEdgeRadius),
      ),
      LineTo(end),
    ],
    GitGraphDirection.bottomToTop => [
      MoveTo(start),
      LineTo(Point(end.x + _gitEdgeRadius, start.y)),
      ArcTo(
        radiusX: _gitEdgeRadius,
        radiusY: _gitEdgeRadius,
        clockwise: true,
        end: Point(end.x, start.y - _gitEdgeRadius),
      ),
      LineTo(end),
    ],
  };
}

void _addGitCommit(
  List<SceneElement> elements,
  _LayoutContext context,
  GitCommitModel commit,
  Point point,
  Color color,
  GitGraphRenderOptions config,
) {
  final stroke = SceneStroke(color: color, width: config.commitStrokeWidth);
  final fill = SolidFill(color);
  if (commit.decoratedType == GitGraphCommitType.highlight) {
    elements.addAll([
      SceneRect(
        id: context.id('git-highlight'),
        bounds: Bounds(
          left: point.x - config.commitRadius,
          top: point.y - config.commitRadius,
          width: config.commitRadius * 2,
          height: config.commitRadius * 2,
        ),
        fill: fill,
        stroke: stroke,
        role: SemanticRole.node,
        cssClasses: const ['git-commit-highlight-outer'],
        label: commit.id,
      ),
      SceneRect(
        id: context.id('git-highlight-inner'),
        bounds: Bounds(left: point.x - 6, top: point.y - 6, width: 12, height: 12),
        fill: SolidFill(context.options.theme.background),
        stroke: stroke,
        role: SemanticRole.node,
        cssClasses: const ['git-commit-highlight-inner'],
      ),
    ]);
    return;
  }

  if (commit.kind == GitCommitKind.cherryPick) {
    elements.add(
      SceneCircle(
        id: context.id('git-cherry'),
        center: point,
        radius: config.commitRadius,
        fill: fill,
        stroke: stroke,
        role: SemanticRole.node,
        cssClasses: const ['git-commit-cherry-outer'],
        label: commit.id,
      ),
    );
    for (final offset in const [-3.0, 3.0]) {
      elements.add(
        SceneCircle(
          id: context.id('git-cherry-dot'),
          center: Point(point.x + offset, point.y + 2),
          radius: 2.75,
          fill: const SolidFill(Color(255, 255, 255)),
          role: SemanticRole.node,
          cssClasses: const ['git-commit-cherry-dot'],
        ),
      );
      elements.add(
        SceneLine(
          id: context.id('git-cherry-stem'),
          start: Point(point.x + offset, point.y + 1),
          end: Point(point.x, point.y - 5),
          stroke: const SceneStroke(color: Color(255, 255, 255)),
          role: SemanticRole.node,
          cssClasses: const ['git-commit-cherry-stem'],
        ),
      );
    }
    return;
  }

  elements.add(
    SceneCircle(
      id: context.id('git-commit'),
      center: point,
      radius: config.commitRadius,
      fill: fill,
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: [commit.kind == GitCommitKind.merge ? 'git-commit-merge-outer' : 'git-commit-normal'],
      label: commit.message.isEmpty ? commit.id : commit.message,
    ),
  );
  if (commit.kind == GitCommitKind.merge && commit.customType == null) {
    elements.add(
      SceneCircle(
        id: context.id('git-merge-inner'),
        center: point,
        radius: 6,
        fill: SolidFill(context.options.theme.background),
        stroke: stroke,
        role: SemanticRole.node,
        cssClasses: const ['git-commit-merge-inner'],
      ),
    );
  }
  if (commit.decoratedType == GitGraphCommitType.reverse) {
    elements.add(
      ScenePath(
        id: context.id('git-reverse'),
        commands: [
          MoveTo(Point(point.x - 5, point.y - 5)),
          LineTo(Point(point.x + 5, point.y + 5)),
          MoveTo(Point(point.x - 5, point.y + 5)),
          LineTo(Point(point.x + 5, point.y - 5)),
        ],
        fill: const NoFill(),
        stroke: SceneStroke(color: context.options.theme.background, width: 2),
        role: SemanticRole.node,
        cssClasses: const ['git-commit-reverse-mark'],
      ),
    );
  }
}

void _addGitCommitLabel(
  List<SceneElement> elements,
  _LayoutContext context,
  String label,
  Point commit,
  double axisPosition,
  SceneTextStyle style,
  GitGraphRenderOptions config,
  GitGraphDirection direction,
) {
  final size = context.measurer.measure(label, style);
  final horizontal = direction == GitGraphDirection.leftToRight;
  final position = horizontal
      ? Point(commit.x - size.width / 2, commit.y + _gitCommitLabelBaselineOffset)
      : Point(
          commit.x - size.width - _gitVerticalCommitLabelTextInset,
          commit.y + size.height - _gitVerticalCommitLabelTopOffset,
        );
  final bounds = horizontal
      ? Bounds(
          left: commit.x - size.width / 2 - _gitCommitLabelPadding,
          top: commit.y + _gitCommitLabelBackgroundTopOffset,
          width: size.width + _gitCommitLabelPadding * 2,
          height: size.height + _gitCommitLabelPadding * 2,
        )
      : Bounds(
          left: commit.x - size.width - _gitVerticalCommitLabelBackgroundInset,
          top: commit.y - _gitVerticalCommitLabelTopOffset,
          width: size.width + _gitCommitLabelPadding * 2,
          height: size.height + _gitCommitLabelPadding * 2,
        );
  final children = <SceneElement>[
    SceneRect(
      id: context.id('git-commit-label-background'),
      bounds: bounds,
      fill: SolidFill(config.commitLabelBackground),
      role: SemanticRole.label,
      cssClasses: const ['git-commit-label-background'],
    ),
    _text(
      context,
      label,
      position.x,
      position.y,
      baseline: TextBaseline.alphabetic,
      style: style,
      cssClasses: const ['git-commit-label'],
    ),
  ];
  if (config.rotateCommitLabel) {
    final transforms = horizontal
        ? <SceneTransform>[
            Translate(
              _gitRotatedLabelBaseX -
                  ((size.width + _gitRotatedLabelBaseY) / _gitRotatedLabelWidthReference) * _gitRotatedLabelXScale,
              _gitRotatedLabelBaseY + (size.width / _gitRotatedLabelWidthReference) * _gitRotatedLabelYScale,
            ),
            Rotate(_gitCommitLabelRotation, center: Point(axisPosition, commit.y)),
          ]
        : <SceneTransform>[Rotate(_gitCommitLabelRotation, center: commit)];
    elements.add(
      SceneGroup(
        id: context.id('git-commit-label-group'),
        transforms: transforms,
        cssClasses: const ['git-commit-label-rotated'],
        children: children,
      ),
    );
  } else {
    elements.addAll(children);
  }
}

void _addGitTags(
  List<SceneElement> elements,
  _LayoutContext context,
  List<String> tags,
  Point commit,
  SceneTextStyle style,
  GitGraphRenderOptions config,
  GitGraphDirection direction,
) {
  for (var i = 0; i < tags.length; i++) {
    final tag = tags[tags.length - i - 1];
    final size = context.measurer.measure(tag, style);
    final center = direction == GitGraphDirection.leftToRight
        ? Point(commit.x, commit.y - 20 - i * 20)
        : Point(commit.x + 18 + i * 20, commit.y - 18);
    final left = center.x - size.width / 2 - 4;
    final right = center.x + size.width / 2 + 4;
    final top = center.y - size.height / 2 - 2;
    final bottom = center.y + size.height / 2 + 2;
    final polygon = ScenePolygon(
      id: context.id('git-tag'),
      points: [
        Point(left - 6, center.y),
        Point(left, top),
        Point(right, top),
        Point(right, bottom),
        Point(left, bottom),
      ],
      fill: SolidFill(context.options.theme.secondary),
      stroke: SceneStroke(color: context.options.theme.line),
      role: SemanticRole.annotation,
      cssClasses: const ['git-tag-background'],
      label: tag,
    );
    final children = <SceneElement>[
      polygon,
      SceneCircle(
        id: context.id('git-tag-hole'),
        center: Point(left - 2, center.y),
        radius: 1.5,
        fill: SolidFill(context.options.theme.background),
        role: SemanticRole.annotation,
        cssClasses: const ['git-tag-hole'],
      ),
      _text(
        context,
        tag,
        center.x,
        center.y,
        anchor: TextAnchor.middle,
        style: style,
        cssClasses: const ['git-tag-label'],
      ),
    ];
    if (direction != GitGraphDirection.leftToRight) {
      elements.add(
        SceneGroup(
          id: context.id('git-tag-group'),
          transforms: [Rotate(45, center: commit)],
          cssClasses: const ['git-tag-rotated'],
          children: children,
        ),
      );
    } else {
      elements.addAll(children);
    }
  }
}

final class _TreemapLayoutNode {
  _TreemapLayoutNode(this.label, {this.ownValue, this.cssClass});

  final String label;
  final double? ownValue;
  final String? cssClass;
  final children = <_TreemapLayoutNode>[];

  double get value => ownValue ?? children.fold(0, (sum, child) => sum + child.value);
}

final class _TreemapClassStyle {
  const _TreemapClassStyle({this.fill, this.stroke, this.text});

  final Color? fill;
  final Color? stroke;
  final Color? text;
}
