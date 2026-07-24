import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:mermaid_dart/mermaid_dart.dart' as mermaid;

import 'flutter_icon_data_resolver.dart';
import 'flutter_text_measurer.dart';

/// Paints a geometry-complete Mermaid scene directly onto a Flutter [Canvas].
final class MermaidScenePainter extends CustomPainter {
  /// Creates a painter for [scene].
  const MermaidScenePainter(
    this.scene, {
    this.textDirection = TextDirection.ltr,
    this.textScaler = TextScaler.noScaling,
    this.alignment = Alignment.center,
    this.iconDataResolver,
  });

  /// The backend-neutral scene to paint.
  final mermaid.DiagramScene scene;

  /// The direction used to shape and position text.
  final TextDirection textDirection;

  /// The platform text scaling applied while painting.
  final TextScaler textScaler;

  /// How an aspect-ratio-preserving scene is positioned in the canvas.
  final Alignment alignment;

  /// Resolves scene icon references to Flutter font glyphs.
  final FlutterIconDataResolver? iconDataResolver;

  @override
  void paint(Canvas canvas, Size size) {
    final viewport = scene.viewport;
    if (size.isEmpty || viewport.width <= 0 || viewport.height <= 0) return;

    final scale = math.min(
      size.width / viewport.width,
      size.height / viewport.height,
    );
    final paintedWidth = viewport.width * scale;
    final paintedHeight = viewport.height * scale;
    final offset = alignment.alongOffset(
      Offset(size.width - paintedWidth, size.height - paintedHeight),
    );

    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(offset.dx, offset.dy)
      ..scale(scale)
      ..translate(-viewport.left, -viewport.top);
    if (scene.background.alpha > 0) {
      canvas.drawRect(
        Rect.fromLTWH(
          viewport.left,
          viewport.top,
          viewport.width,
          viewport.height,
        ),
        Paint()
          ..style = PaintingStyle.fill
          ..color = flutterColor(scene.background),
      );
    }
    for (final element in scene.elements) {
      _paintElement(canvas, element);
    }
    canvas.restore();
  }

  void _paintElement(Canvas canvas, mermaid.SceneElement element) {
    switch (element) {
      case mermaid.SceneGroup(
        :final children,
        :final transforms,
        :final clipId,
      ):
        canvas.save();
        for (final transform in transforms) {
          _applyTransform(canvas, transform);
        }
        if (clipId != null) {
          final clip = _clipPath(clipId);
          if (clip != null) canvas.clipPath(_scenePath(clip.commands));
        }
        for (final child in children) {
          _paintElement(canvas, child);
        }
        canvas.restore();
      case mermaid.SceneLine(:final start, :final end, :final stroke):
        if (stroke != null) {
          _drawStroke(
            canvas,
            ui.Path()
              ..moveTo(start.x, start.y)
              ..lineTo(end.x, end.y),
            stroke,
          );
        }
      case mermaid.SceneRect(
        :final bounds,
        :final radiusX,
        :final radiusY,
        :final fill,
        :final stroke,
      ):
        final rect = _rect(bounds);
        final resolvedRadiusX = radiusX == 0 ? radiusY : radiusX;
        final resolvedRadiusY = radiusY == 0 ? radiusX : radiusY;
        final path = ui.Path()
          ..addRRect(RRect.fromRectXY(rect, resolvedRadiusX, resolvedRadiusY));
        _drawShape(canvas, path, fill, stroke);
      case mermaid.SceneCircle(
        :final center,
        :final radius,
        :final fill,
        :final stroke,
      ):
        final path = ui.Path()
          ..addOval(Rect.fromCircle(center: _offset(center), radius: radius));
        _drawShape(canvas, path, fill, stroke);
      case mermaid.SceneEllipse(
        :final center,
        :final radiusX,
        :final radiusY,
        :final fill,
        :final stroke,
      ):
        final path = ui.Path()
          ..addOval(
            Rect.fromCenter(
              center: _offset(center),
              width: radiusX * 2,
              height: radiusY * 2,
            ),
          );
        _drawShape(canvas, path, fill, stroke);
      case mermaid.ScenePolygon(:final points, :final fill, :final stroke):
        _drawShape(canvas, _pointsPath(points, close: true), fill, stroke);
      case mermaid.ScenePolyline(:final points, :final fill, :final stroke):
        _drawShape(canvas, _pointsPath(points), fill, stroke);
      case mermaid.ScenePath(:final commands, :final fill, :final stroke):
        _drawShape(canvas, _scenePath(commands), fill, stroke);
      case mermaid.SceneText():
        _paintText(canvas, element);
      case mermaid.SceneIcon(
        :final reference,
        :final position,
        :final geometry,
        :final fill,
        :final stroke,
      ):
        canvas
          ..save()
          ..translate(position.x, position.y);
        if (iconDataResolver?.resolveIconData(reference) case final icon?) {
          _paintIconData(canvas, icon, geometry.bounds, fill);
        } else {
          for (final commands in geometry.paths) {
            _drawShape(canvas, _scenePath(commands), fill, stroke);
          }
          for (final path in geometry.styledPaths) {
            _drawShape(
              canvas,
              _scenePath(path.commands),
              path.fill,
              path.stroke,
            );
          }
        }
        canvas.restore();
    }
  }

  mermaid.ScenePath? _clipPath(String id) {
    for (final clip in scene.clips) {
      if (clip.id == id) return clip.path;
    }
    return null;
  }

  void _paintText(Canvas canvas, mermaid.SceneText text) {
    final painter = createFlutterTextPainter(
      text.text,
      text.style,
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();
    final x = switch (text.anchor) {
      mermaid.TextAnchor.start => text.position.x,
      mermaid.TextAnchor.middle => text.position.x - painter.width / 2,
      mermaid.TextAnchor.end => text.position.x - painter.width,
    };
    final firstLine = painter.computeLineMetrics().firstOrNull;
    final y = switch (text.baseline) {
      mermaid.TextBaseline.alphabetic =>
        text.position.y - (firstLine?.baseline ?? painter.height),
      mermaid.TextBaseline.central ||
      mermaid.TextBaseline.middle => text.position.y - painter.height / 2,
      mermaid.TextBaseline.hanging ||
      mermaid.TextBaseline.textBeforeEdge => text.position.y,
    };
    painter.paint(canvas, Offset(x, y));
  }

  void _paintIconData(
    Canvas canvas,
    IconData icon,
    mermaid.Bounds bounds,
    mermaid.SceneFill? fill,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          color: switch (fill) {
            mermaid.SolidFill(:final color) => flutterColor(color),
            _ => const ui.Color(0xff000000),
          },
          fontSize: bounds.height,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontFamilyFallback: icon.fontFamilyFallback,
          height: 1,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
      textDirection: textDirection,
      textScaler: TextScaler.noScaling,
    )..layout();
    final offset = Offset(
      bounds.left + (bounds.width - painter.width) / 2,
      bounds.top + (bounds.height - painter.height) / 2,
    );
    if (icon.matchTextDirection && textDirection == TextDirection.rtl) {
      final centerX = bounds.left + bounds.width / 2;
      canvas
        ..save()
        ..translate(centerX * 2, 0)
        ..scale(-1, 1);
      painter.paint(canvas, offset);
      canvas.restore();
    } else {
      painter.paint(canvas, offset);
    }
  }

  void _drawShape(
    Canvas canvas,
    ui.Path path,
    mermaid.SceneFill? fill,
    mermaid.SceneStroke? stroke,
  ) {
    switch (fill) {
      case mermaid.NoFill():
        break;
      case mermaid.SolidFill(:final color):
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = flutterColor(color),
        );
      case null:
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.fill
            ..color = const Color(0xff000000),
        );
    }
    if (stroke != null) _drawStroke(canvas, path, stroke);
  }

  void _drawStroke(Canvas canvas, ui.Path path, mermaid.SceneStroke stroke) {
    canvas.drawPath(
      stroke.dashes.isEmpty ? path : _dashedPath(path, stroke.dashes),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = flutterColor(stroke.color)
        ..strokeWidth = stroke.width
        ..strokeCap = switch (stroke.cap) {
          mermaid.StrokeCap.butt => StrokeCap.butt,
          mermaid.StrokeCap.round => StrokeCap.round,
          mermaid.StrokeCap.square => StrokeCap.square,
        }
        ..strokeJoin = switch (stroke.join) {
          mermaid.StrokeJoin.miter => StrokeJoin.miter,
          mermaid.StrokeJoin.round => StrokeJoin.round,
          mermaid.StrokeJoin.bevel => StrokeJoin.bevel,
        },
    );
  }

  void _applyTransform(Canvas canvas, mermaid.SceneTransform transform) {
    switch (transform) {
      case mermaid.Translate(:final x, :final y):
        canvas.translate(x, y);
      case mermaid.Scale(:final x, :final y):
        canvas.scale(x, y ?? x);
      case mermaid.Rotate(:final degrees, :final center):
        if (center != null) canvas.translate(center.x, center.y);
        canvas.rotate(degrees * math.pi / 180);
        if (center != null) canvas.translate(-center.x, -center.y);
      case mermaid.MatrixTransform(
        :final a,
        :final b,
        :final c,
        :final d,
        :final e,
        :final f,
      ):
        canvas.transform(
          Float64List.fromList([
            a,
            b,
            0,
            0,
            c,
            d,
            0,
            0,
            0,
            0,
            1,
            0,
            e,
            f,
            0,
            1,
          ]),
        );
    }
  }

  @override
  bool shouldRepaint(MermaidScenePainter oldDelegate) =>
      scene != oldDelegate.scene ||
      textDirection != oldDelegate.textDirection ||
      textScaler != oldDelegate.textScaler ||
      alignment != oldDelegate.alignment ||
      iconDataResolver != oldDelegate.iconDataResolver;
}

ui.Path _pointsPath(List<mermaid.Point> points, {bool close = false}) {
  final path = ui.Path();
  if (points case [final first, ...final rest]) {
    path.moveTo(first.x, first.y);
    for (final point in rest) {
      path.lineTo(point.x, point.y);
    }
    if (close) path.close();
  }
  return path;
}

ui.Path _scenePath(List<mermaid.PathCommand> commands) {
  final path = ui.Path();
  for (final command in commands) {
    switch (command) {
      case mermaid.MoveTo(:final point):
        path.moveTo(point.x, point.y);
      case mermaid.LineTo(:final point):
        path.lineTo(point.x, point.y);
      case mermaid.CubicTo(:final control1, :final control2, :final end):
        path.cubicTo(
          control1.x,
          control1.y,
          control2.x,
          control2.y,
          end.x,
          end.y,
        );
      case mermaid.QuadraticTo(:final control, :final end):
        path.quadraticBezierTo(control.x, control.y, end.x, end.y);
      case mermaid.ArcTo(
        :final radiusX,
        :final radiusY,
        :final rotation,
        :final largeArc,
        :final clockwise,
        :final end,
      ):
        if (radiusX <= 0 || radiusY <= 0) {
          path.lineTo(end.x, end.y);
        } else {
          path.arcToPoint(
            _offset(end),
            radius: Radius.elliptical(radiusX, radiusY),
            rotation: rotation,
            largeArc: largeArc,
            clockwise: clockwise,
          );
        }
      case mermaid.ClosePath():
        path.close();
    }
  }
  return path;
}

ui.Path _dashedPath(ui.Path source, List<double> sourcePattern) {
  final positive = sourcePattern.where((length) => length > 0).toList();
  if (positive.isEmpty) return source;
  final pattern = positive.length.isOdd ? [...positive, ...positive] : positive;
  final result = ui.Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    var patternIndex = 0;
    var draw = true;
    while (distance < metric.length) {
      final next = math.min(distance + pattern[patternIndex], metric.length);
      if (draw) {
        result.addPath(metric.extractPath(distance, next), Offset.zero);
      }
      distance = next;
      patternIndex = (patternIndex + 1) % pattern.length;
      draw = !draw;
    }
  }
  return result;
}

Offset _offset(mermaid.Point point) => Offset(point.x, point.y);

Rect _rect(mermaid.Bounds bounds) =>
    Rect.fromLTWH(bounds.left, bounds.top, bounds.width, bounds.height);
