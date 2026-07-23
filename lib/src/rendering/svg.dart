import 'package:xml/xml.dart';

import 'options.dart';
import 'scene.dart';

String renderSvg(DiagramScene scene, {SvgRenderOptions options = const SvgRenderOptions()}) {
  final builder = XmlBuilder();
  if (options.includeXmlDeclaration) {
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  }
  final title = scene.accessibilityTitle ?? scene.title;
  final description = scene.accessibilityDescription ?? scene.description;
  final widthPolicy = switch (options.widthMode) {
    SvgWidthMode.scene => scene.widthPolicy,
    SvgWidthMode.fixed => SceneWidthPolicy.fixed,
    SvgWidthMode.fitContainer => SceneWidthPolicy.fitContainer,
  };
  builder.element(
    'svg',
    namespaceUris: const {null: 'http://www.w3.org/2000/svg'},
    attributes: {
      if (options.rootId != null) 'id': options.rootId!,
      'viewBox': _bounds(scene.viewport),
      if (widthPolicy == SceneWidthPolicy.fitContainer) ...{
        'width': '100%',
        'style': 'max-width: ${_number(scene.viewport.width)}px;',
      } else ...{
        'width': _number(scene.viewport.width),
        'height': _number(scene.viewport.height),
      },
      'role': 'img',
      'aria-roledescription': scene.diagramType.wireName,
      if (title != null) 'aria-labelledby': 'diagram-title',
      if (description != null) 'aria-describedby': 'diagram-description',
    },
    nest: () {
      if (title != null) builder.element('title', attributes: const {'id': 'diagram-title'}, nest: title);
      if (description != null) {
        builder.element('desc', attributes: const {'id': 'diagram-description'}, nest: description);
      }
      if (scene.clips.isNotEmpty) {
        builder.element(
          'defs',
          nest: () {
            for (final clip in scene.clips) {
              builder.element(
                'clipPath',
                attributes: {'id': clip.id},
                nest: () => _element(builder, clip.path, omitIdentity: true),
              );
            }
          },
        );
      }
      if (scene.background.alpha > 0) {
        builder.element(
          'rect',
          attributes: {
            'x': _number(scene.viewport.left),
            'y': _number(scene.viewport.top),
            'width': _number(scene.viewport.width),
            'height': _number(scene.viewport.height),
            'fill': scene.background.hex,
            if (scene.background.alpha < 255) 'fill-opacity': _number(scene.background.alpha / 255),
            'class': 'background',
          },
        );
      }
      for (final element in scene.elements) {
        _element(builder, element);
      }
    },
  );
  final document = builder.buildDocument();
  return options.pretty ? document.toXmlString(pretty: true, indent: '  ') : document.toXmlString();
}

void _element(XmlBuilder builder, SceneElement element, {bool omitIdentity = false}) {
  final common = <String, String>{
    if (!omitIdentity) 'id': element.id,
    if (element.cssClasses.isNotEmpty) 'class': element.cssClasses.join(' '),
    if (element.role != null) 'data-role': element.role!.name,
    if (element.label != null) 'aria-label': element.label!,
  };
  switch (element) {
    case SceneGroup(:final children, :final transforms, :final clipId):
      builder.element(
        'g',
        attributes: {
          ...common,
          if (transforms.isNotEmpty) 'transform': transforms.map(_transform).join(' '),
          if (clipId != null) 'clip-path': 'url(#$clipId)',
        },
        nest: () {
          for (final child in children) {
            _element(builder, child);
          }
        },
      );
    case SceneLine(:final start, :final end, :final stroke):
      builder.element(
        'line',
        attributes: {
          ...common,
          'x1': _number(start.x),
          'y1': _number(start.y),
          'x2': _number(end.x),
          'y2': _number(end.y),
          ..._stroke(stroke),
        },
      );
    case SceneRect(:final bounds, :final radiusX, :final radiusY, :final fill, :final stroke):
      builder.element(
        'rect',
        attributes: {
          ...common,
          'x': _number(bounds.left),
          'y': _number(bounds.top),
          'width': _number(bounds.width),
          'height': _number(bounds.height),
          if (radiusX != 0) 'rx': _number(radiusX),
          if (radiusY != 0) 'ry': _number(radiusY),
          ..._fill(fill),
          ..._stroke(stroke),
        },
      );
    case SceneCircle(:final center, :final radius, :final fill, :final stroke):
      builder.element(
        'circle',
        attributes: {
          ...common,
          'cx': _number(center.x),
          'cy': _number(center.y),
          'r': _number(radius),
          ..._fill(fill),
          ..._stroke(stroke),
        },
      );
    case SceneEllipse(:final center, :final radiusX, :final radiusY, :final fill, :final stroke):
      builder.element(
        'ellipse',
        attributes: {
          ...common,
          'cx': _number(center.x),
          'cy': _number(center.y),
          'rx': _number(radiusX),
          'ry': _number(radiusY),
          ..._fill(fill),
          ..._stroke(stroke),
        },
      );
    case ScenePolygon(:final points, :final fill, :final stroke):
      builder.element(
        'polygon',
        attributes: {...common, 'points': _points(points), ..._fill(fill), ..._stroke(stroke)},
      );
    case ScenePolyline(:final points, :final fill, :final stroke):
      builder.element(
        'polyline',
        attributes: {...common, 'points': _points(points), ..._fill(fill), ..._stroke(stroke)},
      );
    case ScenePath(:final commands, :final fill, :final stroke):
      builder.element(
        'path',
        attributes: {...common, 'd': commands.map(_command).join(' '), ..._fill(fill), ..._stroke(stroke)},
      );
    case SceneText(:final position, :final text, :final style, :final anchor, :final baseline):
      builder.element(
        'text',
        attributes: {
          ...common,
          'x': _number(position.x),
          'y': _number(position.y),
          'text-anchor': anchor.name,
          'dominant-baseline': switch (baseline) {
            TextBaseline.alphabetic => 'alphabetic',
            TextBaseline.central => 'central',
            TextBaseline.middle => 'middle',
            TextBaseline.hanging => 'hanging',
          },
          'font-family': style.fontFamily,
          'font-size': _number(style.fontSize),
          'font-weight': switch (style.weight) {
            FontWeight.normal => '400',
            FontWeight.medium => '500',
            FontWeight.semibold => '600',
            FontWeight.bold => '700',
          },
          if (style.style == FontStyle.italic) 'font-style': 'italic',
          'fill': style.color.hex,
          if (style.color.alpha < 255) 'fill-opacity': _number(style.color.alpha / 255),
        },
        nest: () {
          final lines = text.split('\n');
          if (lines.length == 1) {
            builder.text(text);
          } else {
            for (var i = 0; i < lines.length; i++) {
              builder.element(
                'tspan',
                attributes: {'x': _number(position.x), if (i > 0) 'dy': '${_number(style.lineHeight)}em'},
                nest: lines[i],
              );
            }
          }
        },
      );
    case SceneIcon(:final position, :final geometry, :final fill, :final stroke):
      builder.element(
        'g',
        attributes: {...common, 'transform': 'translate(${_number(position.x)} ${_number(position.y)})'},
        nest: () {
          for (final path in geometry.paths) {
            builder.element(
              'path',
              attributes: {'d': path.map(_command).join(' '), ..._fill(fill), ..._stroke(stroke)},
            );
          }
        },
      );
  }
}

Map<String, String> _fill(SceneFill? fill) => switch (fill) {
  null => const {},
  NoFill() => const {'fill': 'none'},
  SolidFill(:final color) => {'fill': color.hex, if (color.alpha < 255) 'fill-opacity': _number(color.alpha / 255)},
};

Map<String, String> _stroke(SceneStroke? stroke) => stroke == null
    ? const {}
    : {
        'stroke': stroke.color.hex,
        'stroke-width': _number(stroke.width),
        if (stroke.color.alpha < 255) 'stroke-opacity': _number(stroke.color.alpha / 255),
        if (stroke.dashes.isNotEmpty) 'stroke-dasharray': stroke.dashes.map(_number).join(' '),
        'stroke-linecap': stroke.cap.name,
        'stroke-linejoin': stroke.join.name,
      };

String _transform(SceneTransform transform) => switch (transform) {
  Translate(:final x, :final y) => 'translate(${_number(x)} ${_number(y)})',
  Scale(:final x, :final y) => 'scale(${_number(x)}${y == null ? '' : ' ${_number(y)}'})',
  Rotate(:final degrees, :final center) =>
    'rotate(${_number(degrees)}${center == null ? '' : ' ${_number(center.x)} ${_number(center.y)}'})',
  MatrixTransform(:final a, :final b, :final c, :final d, :final e, :final f) =>
    'matrix(${[a, b, c, d, e, f].map(_number).join(' ')})',
};

String _command(PathCommand command) => switch (command) {
  MoveTo(:final point) => 'M${_number(point.x)} ${_number(point.y)}',
  LineTo(:final point) => 'L${_number(point.x)} ${_number(point.y)}',
  CubicTo(:final control1, :final control2, :final end) =>
    'C${_number(control1.x)} ${_number(control1.y)} ${_number(control2.x)} ${_number(control2.y)} ${_number(end.x)} ${_number(end.y)}',
  QuadraticTo(:final control, :final end) =>
    'Q${_number(control.x)} ${_number(control.y)} ${_number(end.x)} ${_number(end.y)}',
  ArcTo(:final radiusX, :final radiusY, :final rotation, :final largeArc, :final clockwise, :final end) =>
    'A${_number(radiusX)} ${_number(radiusY)} ${_number(rotation)} ${largeArc ? 1 : 0} ${clockwise ? 1 : 0} ${_number(end.x)} ${_number(end.y)}',
  ClosePath() => 'Z',
};

String _points(List<Point> points) => points.map((point) => '${_number(point.x)},${_number(point.y)}').join(' ');
String _bounds(Bounds bounds) =>
    '${_number(bounds.left)} ${_number(bounds.top)} ${_number(bounds.width)} ${_number(bounds.height)}';

// Four digits keep ordinary SVG compact. Six are retained only when the
// shorter representation would cross a centipixel comparison boundary.
const _svgCompactFractionDigits = 4;
const _svgPreciseFractionDigits = 6;
const _svgComparisonFractionDigits = 2;

String _number(num value) {
  if (!value.isFinite) return '0';
  var rounded = value.toStringAsFixed(_svgCompactFractionDigits);
  if (double.parse(rounded).toStringAsFixed(_svgComparisonFractionDigits) !=
      value.toStringAsFixed(_svgComparisonFractionDigits)) {
    rounded = value.toStringAsFixed(_svgPreciseFractionDigits);
  }
  if (rounded.contains('.')) {
    while (rounded.endsWith('0')) {
      rounded = rounded.substring(0, rounded.length - 1);
    }
    if (rounded.endsWith('.')) rounded = rounded.substring(0, rounded.length - 1);
  }
  return rounded == '-0' ? '0' : rounded;
}
