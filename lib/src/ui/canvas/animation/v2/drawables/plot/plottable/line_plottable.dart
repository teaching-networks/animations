/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/plottable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/plottable_style.dart';

/// Plottable which results in a line graph.
abstract class LinePlottable extends Plottable {
  /// Style of the plottable.
  final PlottableStyle style;

  /// Create plottable.
  LinePlottable({
    this.style,
  });

  /// Draw the plottable.
  @override
  void draw(CanvasRenderingContext2D ctx, List<Point<double>> coordinates) {
    // Draw line
    if (style.line != null && coordinates.length >= 2) {
      ctx.setStrokeColorRgb(style.line.color.red, style.line.color.green, style.line.color.blue, style.line.color.alpha);

      ctx.lineWidth = style.line.lineWidth * window.devicePixelRatio;
      ctx.lineJoin = style.line.lineJoin;
      ctx.lineCap = style.line.lineCap;

      ctx.beginPath();
      Point<double> p = coordinates.first;
      ctx.moveTo(p.x, p.y);
      for (int i = 1; i < coordinates.length; i++) {
        p = coordinates[i];
        ctx.lineTo(p.x, p.y);
      }
      ctx.stroke();
    }

    // Draw points.
    if (style.points != null && style.points.painter != null) {
      ctx.beginPath();
      Point<double> p = coordinates.first;
      ctx.moveTo(p.x, p.y);
      style.points.painter.paint(
        ctx,
        x: p.x,
        y: p.y,
        style: style.points,
      );
      for (int i = 1; i < coordinates.length; i++) {
        p = coordinates[i];
        ctx.lineTo(p.x, p.y);
        style.points.painter.paint(
          ctx,
          x: p.x,
          y: p.y,
          style: style.points,
        );
      }
      ctx.stroke();
    }
  }
}
