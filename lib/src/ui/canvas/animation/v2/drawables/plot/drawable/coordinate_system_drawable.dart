/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/axis_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/coordinate_system_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/util/coordinate_system.dart';
import 'package:hm_animations/src/ui/canvas/text/alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/baseline.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math.dart' as vector;

/// Drawable drawing a coordinate system.
class CoordinateSystemDrawable extends Drawable {
  /// Quaternion used to rotate an arrow head vector to the left.
  static vector.Quaternion _rotateLeft = vector.Quaternion.axisAngle(vector.Vector3(0.0, 0.0, 1.0), pi / 4 * 3);

  /// Quaternion used to rotate an arrow head vector to the right.
  static vector.Quaternion _rotateRight = vector.Quaternion.axisAngle(vector.Vector3(0.0, 0.0, 1.0), -pi / 4 * 3);

  /// Style of the coordinate system.
  final CoordinateSystemStyle style;

  /// Coordinate system to draw.
  final CoordinateSystem2D coordinateSystem;

  /// Create the coordinate system drawable.
  CoordinateSystemDrawable({
    Drawable parent,
    this.style = const CoordinateSystemStyle(),
    @required this.coordinateSystem,
  }) : super(parent: parent);

  /// Current line width of the x axis.
  double _xAxisLineWidth;

  /// Current line width of the y axis.
  double _yAxisLineWidth;

  /// Current size of the x axis arrow head.
  double _xAxisArrowHeadSize;

  /// Current size of the y axis arrow head.
  double _yAxisArrowHeadSize;

  /// Current offset of the x axis line.
  double _xAxisLineOffset;

  /// Current offset of the y axis line.
  double _yAxisLineOffset;

  /// Recalculate visual metrics used by the drawing logic.
  void _recalculateVisualMetrics() {
    _xAxisLineWidth = style.xAxis.lineWidth * window.devicePixelRatio;
    _yAxisLineWidth = style.yAxis.lineWidth * window.devicePixelRatio;

    _xAxisArrowHeadSize = style.xAxis.arrowHeadSize * window.devicePixelRatio;
    _yAxisArrowHeadSize = style.yAxis.arrowHeadSize * window.devicePixelRatio;

    _xAxisLineOffset = _xAxisLineWidth / 2 + _xAxisArrowHeadSize / 2 + defaultFontSize;
    _yAxisLineOffset = _yAxisLineWidth / 2 + _yAxisArrowHeadSize / 2 + defaultFontSize;
  }

  /// Draw an axis.
  void _drawAxis({
    _AxisType axisType = _AxisType.X,
    AxisStyle axisStyle = const AxisStyle(),
  }) {
    // Setup axis style
    setStrokeColor(axisStyle.color);
    setFillColor(axisStyle.color);
    ctx.lineWidth = axisType == _AxisType.X ? _xAxisLineWidth : _yAxisLineWidth;

    // Draw line
    ctx.beginPath();
    ctx.moveTo(_yAxisLineOffset, size.height - _xAxisLineOffset);
    if (axisType == _AxisType.X)
      ctx.lineTo(size.width - _xAxisLineWidth, size.height - _xAxisLineOffset);
    else
      ctx.lineTo(_yAxisLineOffset, _yAxisLineWidth);
    ctx.stroke();

    // Draw markers
    // TODO

    // Draw arrow head
    if (axisType == _AxisType.X) {
      _drawArrowHead(
        direction: vector.Vector2(1, 0),
        size: _xAxisArrowHeadSize,
        x: size.width,
        y: size.height - _xAxisLineOffset,
      );
    } else {
      _drawArrowHead(
        direction: vector.Vector2(0, -1),
        size: _yAxisArrowHeadSize,
        x: _yAxisLineOffset,
        y: 0,
      );
    }

    // Draw label
    if (axisStyle.label != null && axisStyle.label.isNotEmpty) {
      setFillColor(axisStyle.labelColor);

      if (axisType == _AxisType.X) {
        setFont(
          baseline: TextBaseline.BOTTOM,
          alignment: TextAlignment.RIGHT,
        );
        ctx.fillText(axisStyle.label, size.width - _xAxisArrowHeadSize, size.height);
      } else {
        ctx.save();
        ctx.translate(0, _yAxisArrowHeadSize);
        ctx.rotate(-pi / 2);
        setFont(
          baseline: TextBaseline.TOP,
          alignment: TextAlignment.RIGHT,
        );
        ctx.fillText(axisStyle.label, 0, 0);
        ctx.restore();
      }
    }
  }

  /// Draw an arrow head.
  void _drawArrowHead({
    vector.Vector2 direction,
    double size = 10,
    double x = 0,
    double y = 0,
  }) {
    double hypo = sqrt(2 * pow(size / 2, 2));

    vector.Vector3 dir3D = vector.Vector3(direction.x, direction.y, 0);

    vector.Vector3 leftHead = _rotateLeft.rotated(dir3D);
    leftHead.length = hypo;

    vector.Vector3 rightHead = _rotateRight.rotated(dir3D);
    rightHead.length = hypo;

    double x1 = x + leftHead.x;
    double x2 = x + rightHead.x;
    double y1 = y + leftHead.y;
    double y2 = y + rightHead.y;

    ctx.beginPath();
    ctx.moveTo(x1, y1);
    ctx.lineTo(x, y);
    ctx.lineTo(x2, y2);
    ctx.fill();
  }

  @override
  void draw() {
    if (style == null) {
      return;
    }

    _recalculateVisualMetrics();

    _drawAxis(axisType: _AxisType.X, axisStyle: style.xAxis);
    _drawAxis(axisType: _AxisType.Y, axisStyle: style.yAxis);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  /// Get the current x offset of the coordinate systems x axis.
  double get xOffset => _xAxisLineOffset;

  /// Get teh current y offset of the coordinate systems y axis.
  double get yOffset => _yAxisLineOffset;
}

enum _AxisType { X, Y }
