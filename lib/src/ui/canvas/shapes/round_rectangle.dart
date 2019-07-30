/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';

/**
 * Rounded Rectangle shape.
 */
class RoundRectangle extends CanvasDrawable {
  static const SizeType DEFAULT_RADIUS_SIZE_TYPE = SizeType.PERCENT;
  static const Edges DEFAULT_RADIUS = const Edges();
  static const Color DEFAULT_COLOR = Colors.BLACK;
  static const PaintMode DEFAULT_PAINT_MODE = PaintMode.FILL;
  static const double DEFAULT_STROKE_WIDTH = 1.0;

  /**
   * Size type to use for example for the radius edges and stroke width.
   */
  final SizeType _sizeType;

  /**
   * Radius of the rounded rectangle edges.
   */
  Edges radius;

  /**
   * Color of the rectangle.
   */
  Color color;

  /**
   * Which paint mode to use.
   */
  PaintMode paintMode;

  /**
   * In case the paint mode is set to stroke.
   */
  double strokeWidth;

  RoundRectangle(
      {SizeType radiusSizeType = DEFAULT_RADIUS_SIZE_TYPE,
      Edges radius = DEFAULT_RADIUS,
      Color color = DEFAULT_COLOR,
      PaintMode paintMode = DEFAULT_PAINT_MODE,
      double strokeWidth = DEFAULT_STROKE_WIDTH})
      : this._sizeType = radiusSizeType,
        this.radius = radius,
        this.color = color,
        this.paintMode = paintMode,
        this.strokeWidth = strokeWidth;

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    Edges r = radius;
    double lineWidth = strokeWidth;
    if (_sizeType == SizeType.PERCENT) {
      // Convert edges from percent to the actual pixel sizes.
      r = Edges.convertPercent(r, new Size(rect.width, rect.height));

      // Convert strokeWidth to pixel
      lineWidth = lineWidth * min(rect.width, rect.height);
    }

    r *= window.devicePixelRatio;

    context.beginPath();

    // Upper line
    context.moveTo(rect.left + r.topLeft, rect.top);
    context.lineTo(rect.left + rect.width - r.topRight, rect.top);

    // Top right curve
    context.quadraticCurveTo(rect.left + rect.width, rect.top, rect.left + rect.width, rect.top + r.topRight);

    // Right line
    context.lineTo(rect.left + rect.width, rect.top + rect.height - r.bottomRight);

    // Bottom right curve
    context.quadraticCurveTo(rect.left + rect.width, rect.top + rect.height, rect.left + rect.width - r.bottomRight, rect.top + rect.height);

    // Bottom line
    context.lineTo(rect.left + r.bottomLeft, rect.top + rect.height);

    // Bottom left curve
    context.quadraticCurveTo(rect.left, rect.top + rect.height, rect.left, rect.top + rect.height - r.bottomLeft);

    // Left line
    context.lineTo(rect.left, rect.top + r.topLeft);

    // Top left curve
    context.quadraticCurveTo(rect.left, rect.top, rect.left + r.topLeft, rect.top);

    context.closePath();

    switch (paintMode) {
      case PaintMode.FILL:
        setFillColor(context, color);
        context.fill();
        break;
      case PaintMode.STROKE:
        context.lineWidth = lineWidth;
        setStrokeColor(context, color);
        context.stroke();
        break;
      default:
        throw new Exception("Rounded Rectangle does not support paint mode '${paintMode}'");
    }
  }
}
