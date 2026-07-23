import 'package:mermaid_dart/mermaid_dart.dart';
import 'package:test/test.dart';

const _a = Color(1, 2, 3);
const _b = Color(4, 5, 6);
const _c = Color(7, 8, 9);
const _d = Color(10, 11, 12);
const _e = Color(13, 14, 15);
const _f = Color(16, 17, 18);
const _g = Color(19, 20, 21);
const _h = Color(22, 23, 24);
const _i = Color(25, 26, 27);
const _j = Color(28, 29, 30);
const _k = Color(31, 32, 33);
const _l = Color(34, 35, 36);
const _m = Color(37, 38, 39);
const _n = Color(40, 41, 42);
const _o = Color(43, 44, 45);
const _p = Color(46, 47, 48);
const _q = Color(49, 50, 51);

void main() {
  group('typed Mermaid theme precedence', () {
    test('architecture resolves every global field and every diagram override', () {
      const global = ArchitectureTheme(
        edgeColor: _a,
        edgeArrowColor: _b,
        edgeWidth: 4,
        groupBorderColor: _c,
        groupBorderWidth: 5,
      );
      const explicit = ArchitectureRenderOptions(
        edgeColor: _d,
        edgeArrowColor: _e,
        edgeWidth: 6,
        groupBorderColor: _f,
        groupBorderWidth: 7,
      );

      _expectArchitecture(const ArchitectureRenderOptions().resolveTheme(const MermaidTheme(architecture: global)), [
        _a,
        _b,
        4,
        _c,
        5,
      ]);
      _expectArchitecture(explicit.resolveTheme(const MermaidTheme(architecture: global)), [_d, _e, 6, _f, 7]);
    });

    test('Cynefin resolves every global field and every diagram override', () {
      const global = CynefinTheme(
        domainFontSize: 21,
        itemFontSize: 22,
        boundaryColor: _a,
        boundaryWidth: 23,
        cliffColor: _b,
        cliffWidth: 24,
        arrowColor: _c,
        arrowWidth: 25,
        complexBackground: _d,
        complicatedBackground: _e,
        chaoticBackground: _f,
        clearBackground: _g,
        confusionBackground: _h,
        textColor: _i,
        labelColor: _j,
      );
      const explicit = CynefinRenderOptions(
        domainFontSize: 31,
        itemFontSize: 32,
        strokeColor: _k,
        boundaryWidth: 33,
        cliffColor: _l,
        cliffWidth: 34,
        arrowColor: _m,
        arrowWidth: 35,
        complexColor: _n,
        complicatedColor: _o,
        chaoticColor: _p,
        clearColor: _q,
        confusionColor: _a,
        textColor: _b,
        domainLabelColor: _c,
      );

      _expectCynefin(const CynefinRenderOptions().resolveTheme(const MermaidTheme(cynefin: global)), [
        21,
        22,
        _a,
        23,
        _b,
        24,
        _c,
        25,
        _d,
        _e,
        _f,
        _g,
        _h,
        _i,
        _j,
      ]);
      _expectCynefin(explicit.resolveTheme(const MermaidTheme(cynefin: global)), [
        31,
        32,
        _k,
        33,
        _l,
        34,
        _m,
        35,
        _n,
        _o,
        _p,
        _q,
        _a,
        _b,
        _c,
      ]);
    });

    test('Git Graph resolves every global field and every diagram override', () {
      const globalShadow = ThemeShadow(color: _q, offsetX: 2, offsetY: 3, blurRadius: 4);
      const explicitShadow = ThemeShadow(color: _p, offsetX: 5, offsetY: 6, blurRadius: 7);
      const global = GitGraphTheme(
        branchColors: [_a],
        highlightColors: [_b],
        branchLabelColors: [_c],
        tagLabelColor: _d,
        tagLabelBackground: _e,
        tagLabelBorder: _f,
        tagLabelFontSize: 11,
        commitLabelColor: _g,
        commitLabelBackground: _h,
        commitLabelFontSize: 12,
        commitLineColor: _i,
        tagHoleColor: _j,
        primaryColor: _k,
        specialColor: _l,
        themeColorLimit: 9,
        useGradient: true,
        gradientStart: _m,
        gradientStop: _n,
        filterColor: _o,
        dropShadow: globalShadow,
      );
      const explicit = GitGraphRenderOptions(
        branchColors: [_p],
        highlightColors: [_q],
        branchLabelColors: [_a],
        tagLabelColor: _b,
        tagBackground: _c,
        tagBorder: _d,
        tagLabelFontSize: 13,
        commitLabelColor: _e,
        commitLabelBackground: _f,
        commitLabelFontSize: 14,
        branchLineColor: _g,
        tagHoleColor: _h,
        cherryPickColor: _i,
        specialCommitColor: _j,
        themeColorLimit: 7,
        useGradient: false,
        gradientStart: _k,
        gradientStop: _l,
        filterColor: _m,
        dropShadow: explicitShadow,
      );

      _expectGit(const GitGraphRenderOptions().resolveTheme(const MermaidTheme(gitGraph: global)), [
        const [_a],
        const [_b],
        const [_c],
        _d,
        _e,
        _f,
        11,
        _g,
        _h,
        12,
        _i,
        _j,
        _k,
        _l,
        9,
        true,
        _m,
        _n,
        _o,
        globalShadow,
      ]);
      _expectGit(explicit.resolveTheme(const MermaidTheme(gitGraph: global)), [
        const [_p],
        const [_q],
        const [_a],
        _b,
        _c,
        _d,
        13,
        _e,
        _f,
        14,
        _g,
        _h,
        _i,
        _j,
        7,
        false,
        _k,
        _l,
        _m,
        explicitShadow,
      ]);
    });

    test('pie resolves every global field and every diagram override', () {
      const global = PieTheme(
        titleTextSize: 21,
        titleTextColor: _a,
        sectionTextSize: 22,
        sectionTextColor: _b,
        legendTextSize: 23,
        legendTextColor: _c,
        strokeColor: _d,
        strokeWidth: 24,
        outerStrokeWidth: 25,
        outerStrokeColor: _e,
        opacity: .4,
      );
      const explicit = PieRenderOptions(
        titleTextSize: 31,
        titleText: _f,
        sectionTextSize: 32,
        sectionText: _g,
        legendTextSize: 33,
        legendText: _h,
        sectionStroke: _i,
        sectionStrokeWidth: 34,
        outerStrokeWidth: 35,
        outerStroke: _j,
        sectionOpacity: .8,
      );

      _expectPie(const PieRenderOptions().resolveTheme(const MermaidTheme(pie: global)), [
        21,
        _a,
        22,
        _b,
        23,
        _c,
        _d,
        24,
        25,
        _e,
        .4,
      ]);
      _expectPie(explicit.resolveTheme(const MermaidTheme(pie: global)), [31, _f, 32, _g, 33, _h, _i, 34, 35, _j, .8]);
    });

    test('radar resolves every global field and every diagram override', () {
      const global = RadarTheme(
        axisColor: _a,
        axisStrokeWidth: 21,
        axisLabelFontSize: 22,
        curveOpacity: .3,
        curveStrokeWidth: 23,
        graticuleColor: _b,
        graticuleStrokeWidth: 24,
        graticuleOpacity: .4,
        legendBoxSize: 25,
        legendFontSize: 26,
      );
      const explicit = RadarRenderOptions(
        axisColor: _c,
        axisStrokeWidth: 31,
        axisLabelFontSize: 32,
        seriesOpacity: .7,
        curveStrokeWidth: 33,
        graticuleColor: _d,
        graticuleStrokeWidth: 34,
        graticuleOpacity: .8,
        legendBoxSize: 35,
        legendFontSize: 36,
      );

      _expectRadar(const RadarRenderOptions().resolveTheme(const MermaidTheme(radar: global)), [
        _a,
        21,
        22,
        .3,
        23,
        _b,
        24,
        .4,
        25,
        26,
      ]);
      _expectRadar(explicit.resolveTheme(const MermaidTheme(radar: global)), [_c, 31, 32, .7, 33, _d, 34, .8, 35, 36]);
    });

    test('Wardley resolves every global field and every diagram override', () {
      const global = WardleyTheme(
        backgroundColor: _a,
        axisColor: _b,
        axisTextColor: _c,
        gridColor: _d,
        componentFill: _e,
        componentStroke: _f,
        componentLabelColor: _g,
        linkStroke: _h,
        evolutionStroke: _i,
        annotationStroke: _j,
        annotationTextColor: _k,
        annotationFill: _l,
      );
      const explicit = WardleyRenderOptions(
        backgroundColor: _m,
        axisColor: _n,
        axisTextColor: _o,
        gridColor: _p,
        componentFill: _q,
        componentStroke: _a,
        componentLabelColor: _b,
        linkStroke: _c,
        evolutionStroke: _d,
        annotationStroke: _e,
        annotationTextColor: _f,
        annotationFill: _g,
      );

      _expectWardley(const WardleyRenderOptions().resolveTheme(const MermaidTheme(wardley: global)), [
        _a,
        _b,
        _c,
        _d,
        _e,
        _f,
        _g,
        _h,
        _i,
        _j,
        _k,
        _l,
      ]);
      _expectWardley(explicit.resolveTheme(const MermaidTheme(wardley: global)), [
        _m,
        _n,
        _o,
        _p,
        _q,
        _a,
        _b,
        _c,
        _d,
        _e,
        _f,
        _g,
      ]);
    });

    test('railroad resolves every common theme field and every diagram override', () {
      const global = MermaidTheme(
        fontSize: 21,
        fontFamily: 'global',
        strokeWidth: 22,
        primaryBorder: _e,
        secondBackground: _a,
        secondaryBorder: _b,
        secondaryText: _c,
        mainBackground: _d,
        nodeBorder: _q,
        primaryText: _f,
        line: _g,
        labelBackground: _h,
        tertiaryBorder: _i,
        tertiaryText: _j,
        tertiary: _k,
        title: _l,
      );
      const explicit = RailroadRenderOptions(
        fontSize: 31,
        fontFamily: 'explicit',
        strokeWidth: 32,
        terminalFill: _m,
        terminalStroke: _n,
        terminalTextColor: _o,
        nonTerminalFill: _p,
        nonTerminalStroke: _q,
        nonTerminalTextColor: _a,
        lineColor: _b,
        markerFill: _c,
        commentFill: _d,
        commentStroke: _e,
        commentTextColor: _f,
        specialFill: _g,
        specialStroke: _h,
        ruleNameColor: _i,
      );

      _expectRailroad(const RailroadRenderOptions().resolveTheme(global), [
        21,
        'global',
        2,
        _a,
        _b,
        _c,
        _d,
        _e,
        _f,
        _g,
        _g,
        _h,
        _i,
        _j,
        _k,
        _i,
        _l,
      ]);
      _expectRailroad(explicit.resolveTheme(global), [
        31,
        'explicit',
        32,
        _m,
        _n,
        _o,
        _p,
        _q,
        _a,
        _b,
        _c,
        _d,
        _e,
        _f,
        _g,
        _h,
        _i,
      ]);
    });

    test('Event Modeling exposes and renders its complete typed theme block', () {
      const theme = EventModelingTheme(
        uiFill: _a,
        uiStroke: _b,
        processorFill: _c,
        processorStroke: _d,
        readModelFill: _e,
        readModelStroke: _f,
        commandFill: _g,
        commandStroke: _h,
        eventFill: _i,
        eventStroke: _j,
        swimlaneBackgroundOdd: _k,
        swimlaneBackgroundStroke: _l,
        arrowhead: _m,
        relationStroke: _n,
      );
      expect(_eventFields(theme), [_a, _b, _c, _d, _e, _f, _g, _h, _i, _j, _k, _l, _m, _n]);

      final scene = layoutDiagram(
        const EventModelingAst(
          frames: [
            EventModelTimeFrameAst(
              name: '01',
              entityType: EventModelEntityType.command,
              entityIdentifier: 'Cart.Update',
            ),
          ],
        ),
        options: const RenderOptions(theme: MermaidTheme(eventModeling: theme)),
      );
      final elements = _flatten(scene.elements).toList();
      final frame = elements.whereType<SceneRect>().last;
      expect(frame.fill, const SolidFill(_g));
      expect(frame.stroke?.color, _h);
    });

    test('fixed-size renderers inherit only Mermaid-supported global typography', () {
      const theme = MermaidTheme(fontFamily: 'monospace', fontSize: 27, text: _a);

      final infoTexts = _flatten(
        layoutDiagram(parse(DiagramType.info, 'info showInfo\n'), options: const RenderOptions(theme: theme)).elements,
      ).whereType<SceneText>().toList();
      expect(infoTexts.single.style.fontFamily, 'monospace');
      expect(infoTexts.single.style.fontSize, 32);
      expect(infoTexts.single.style.color, _a);

      final packetTexts = _flatten(
        layoutDiagram(
          parse(DiagramType.packet, '---\ntitle: Packet\n---\npacket\n0-7: "Source"\n'),
          options: const RenderOptions(theme: theme),
        ).elements,
      ).whereType<SceneText>().toList();
      expect(packetTexts.map((text) => text.style.fontFamily), everyElement('monospace'));
      expect(packetTexts.map((text) => text.style.fontSize).toSet(), {10, 12, 14});
      expect(packetTexts.map((text) => text.style.color), everyElement(const Color(0, 0, 0)));

      final treeTexts = _flatten(
        layoutDiagram(
          parse(DiagramType.treeView, 'treeView-beta\nsrc/\n'),
          options: const RenderOptions(theme: theme),
        ).elements,
      ).whereType<SceneText>().toList();
      expect(treeTexts.map((text) => text.style.fontFamily), everyElement('monospace'));
      expect(treeTexts.map((text) => text.style.fontSize), everyElement(16));
      expect(treeTexts.map((text) => text.style.color), everyElement(TreeViewRenderOptions.defaultLabelColor));
    });
  });
}

void _expectArchitecture(ArchitectureTheme theme, List<Object> expected) => expect([
  theme.edgeColor,
  theme.edgeArrowColor,
  theme.edgeWidth,
  theme.groupBorderColor,
  theme.groupBorderWidth,
], expected);

void _expectCynefin(CynefinTheme theme, List<Object> expected) => expect([
  theme.domainFontSize,
  theme.itemFontSize,
  theme.boundaryColor,
  theme.boundaryWidth,
  theme.cliffColor,
  theme.cliffWidth,
  theme.arrowColor,
  theme.arrowWidth,
  theme.complexBackground,
  theme.complicatedBackground,
  theme.chaoticBackground,
  theme.clearBackground,
  theme.confusionBackground,
  theme.textColor,
  theme.labelColor,
], expected);

void _expectGit(GitGraphTheme theme, List<Object> expected) {
  expect([
    theme.branchColors,
    theme.highlightColors,
    theme.branchLabelColors,
    theme.tagLabelColor,
    theme.tagLabelBackground,
    theme.tagLabelBorder,
    theme.tagLabelFontSize,
    theme.commitLabelColor,
    theme.commitLabelBackground,
    theme.commitLabelFontSize,
    theme.commitLineColor!,
    theme.tagHoleColor,
    theme.primaryColor,
    theme.specialColor,
    theme.themeColorLimit,
    theme.useGradient,
    theme.gradientStart,
    theme.gradientStop,
    theme.filterColor,
    theme.dropShadow,
  ], expected);
  final expectedShadow = expected.last as ThemeShadow;
  expect(
    [theme.dropShadow.color, theme.dropShadow.offsetX, theme.dropShadow.offsetY, theme.dropShadow.blurRadius],
    [expectedShadow.color, expectedShadow.offsetX, expectedShadow.offsetY, expectedShadow.blurRadius],
  );
}

void _expectPie(PieTheme theme, List<Object> expected) => expect([
  theme.titleTextSize,
  theme.titleTextColor,
  theme.sectionTextSize,
  theme.sectionTextColor,
  theme.legendTextSize,
  theme.legendTextColor,
  theme.strokeColor,
  theme.strokeWidth,
  theme.outerStrokeWidth,
  theme.outerStrokeColor,
  theme.opacity,
], expected);

void _expectRadar(RadarTheme theme, List<Object> expected) => expect([
  theme.axisColor,
  theme.axisStrokeWidth,
  theme.axisLabelFontSize,
  theme.curveOpacity,
  theme.curveStrokeWidth,
  theme.graticuleColor,
  theme.graticuleStrokeWidth,
  theme.graticuleOpacity,
  theme.legendBoxSize,
  theme.legendFontSize,
], expected);

void _expectWardley(WardleyTheme theme, List<Object> expected) => expect([
  theme.backgroundColor,
  theme.axisColor,
  theme.axisTextColor,
  theme.gridColor,
  theme.componentFill,
  theme.componentStroke,
  theme.componentLabelColor,
  theme.linkStroke,
  theme.evolutionStroke,
  theme.annotationStroke,
  theme.annotationTextColor,
  theme.annotationFill,
], expected);

void _expectRailroad(RailroadTheme theme, List<Object> expected) => expect([
  theme.fontSize,
  theme.fontFamily,
  theme.strokeWidth,
  theme.terminalFill,
  theme.terminalStroke,
  theme.terminalTextColor,
  theme.nonTerminalFill,
  theme.nonTerminalStroke,
  theme.nonTerminalTextColor,
  theme.lineColor,
  theme.markerFill,
  theme.commentFill,
  theme.commentStroke,
  theme.commentTextColor,
  theme.specialFill,
  theme.specialStroke,
  theme.ruleNameColor,
], expected);

List<Color> _eventFields(EventModelingTheme theme) => [
  theme.uiFill,
  theme.uiStroke,
  theme.processorFill,
  theme.processorStroke,
  theme.readModelFill,
  theme.readModelStroke,
  theme.commandFill,
  theme.commandStroke,
  theme.eventFill,
  theme.eventStroke,
  theme.swimlaneBackgroundOdd,
  theme.swimlaneBackgroundStroke,
  theme.arrowhead,
  theme.relationStroke,
];

Iterable<SceneElement> _flatten(Iterable<SceneElement> elements) sync* {
  for (final element in elements) {
    yield element;
    if (element is SceneGroup) yield* _flatten(element.children);
  }
}
