/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/point/point_style.dart';

/// Painter to draw points.
abstract class PointPainter {
  /// Paint point on the passed rendering context.
  void paint(
    CanvasRenderingContext2D ctx, {
    double x = 0,
    double y = 0,
    PointStyle style,
  });
}

/// Factory for common point painters.
class PointPainterFactory {
  /// Get instance of a common point painter.
  static PointPainter getInstance(String shape) {
    switch (shape) {
      case ".":
        return CirclePointPainter(filled: true);
      case "o":
        return CirclePointPainter(filled: false);
      default:
        throw new Exception("The passed shape '$shape' does not have a point painter assigned.");
    }
  }
}

/// Painter painting points in a circular shape.
class CirclePointPainter implements PointPainter {
  /// Whether the circle is filled.
  final bool filled;

  /// Create circle point painter.
  CirclePointPainter({
    this.filled = true,
  });

  @override
  void paint(
    CanvasRenderingContext2D ctx, {
    double x = 0,
    double y = 0,
    PointStyle style,
  }) {
    if (filled) {
      ctx.setFillColorRgb(style.color.red, style.color.green, style.color.blue, style.color.alpha);
    } else {
      ctx.setStrokeColorRgb(style.color.red, style.color.green, style.color.blue, style.color.alpha);
    }

    ctx.beginPath();
    ctx.ellipse(
      x,
      y,
      style.size * window.devicePixelRatio,
      style.size * window.devicePixelRatio,
      pi * 2,
      0,
      pi * 2,
      false,
    );

    if (filled) {
      ctx.fill();
    } else {
      ctx.stroke();
    }

    return null;
  }
}
