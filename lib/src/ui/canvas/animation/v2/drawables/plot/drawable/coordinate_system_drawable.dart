/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/axis_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/coordinate_system_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/tick_style.dart';
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

  /// The default tick label renderer.
  TickLabelRenderer _defaultTickLabelRenderer;

  /// Create the coordinate system drawable.
  CoordinateSystemDrawable({
    Drawable parent,
    this.style = const CoordinateSystemStyle(),
    @required this.coordinateSystem,
  }) : super(parent: parent) {
    _defaultTickLabelRenderer = TickStyle.precisionTickLabelRenderer(3);
  }

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

  /// Ticks of the x-axis.
  List<double> _xTicks;

  /// Ticks of the y-axis.
  List<double> _yTicks;

  /// Recalculate visual metrics used by the drawing logic.
  void _recalculateVisualMetrics() {
    _xAxisLineWidth = style.xAxis.lineWidth * window.devicePixelRatio;
    _yAxisLineWidth = style.yAxis.lineWidth * window.devicePixelRatio;

    _xAxisArrowHeadSize = style.xAxis.arrowHeadSize * window.devicePixelRatio;
    _yAxisArrowHeadSize = style.yAxis.arrowHeadSize * window.devicePixelRatio;

    _xAxisLineOffset = _xAxisLineWidth / 2 + _xAxisArrowHeadSize / 2;
    if (style.xAxis.ticks != null) {
      _xTicks = style.xAxis.ticks.generator(coordinateSystem.xRange.min, coordinateSystem.xRange.max);

      _xAxisLineOffset += style.xAxis.ticks.labelFontSize * window.devicePixelRatio + style.xAxis.ticks.size;
    }

    _yAxisLineOffset = _yAxisLineWidth / 2 + _yAxisArrowHeadSize / 2;
    if (style.yAxis.ticks != null) {
      _yTicks = style.yAxis.ticks.generator(coordinateSystem.yRange.min, coordinateSystem.yRange.max);

      // Find longest tick label
      String longestTickLabel;
      int longest = -1;
      for (double tick in _yTicks) {
        String label = _renderTickLabel(tick, style.yAxis);
        if (label.length > longest) {
          longest = label.length;
          longestTickLabel = label;
        }
      }

      // Calculate label width
      setFont(size: style.yAxis.ticks.labelFontSize);
      double labelWidth = ctx.measureText(longestTickLabel).width;

      _yAxisLineOffset += labelWidth + style.yAxis.ticks.size;
    }
  }

  /// Render a tick to label.
  String _renderTickLabel(double tick, AxisStyle axisStyle) {
    return axisStyle.ticks.labelRenderer != null ? axisStyle.ticks.labelRenderer(tick) : _defaultTickLabelRenderer(tick);
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

    // Draw ticks
    if (axisStyle.ticks != null) {
      Rectangle<double> drawingArea = getDrawingArea();

      if (axisStyle.ticks.color != null) {
        setStrokeColor(axisStyle.ticks.color);
      }
      setFillColor(axisStyle.ticks.labelColor);

      double halfTick = axisStyle.ticks.size / 2 * window.devicePixelRatio;

      if (axisType == _AxisType.X) {
        setFont(size: axisStyle.ticks.labelFontSize, alignment: TextAlignment.CENTER, baseline: TextBaseline.TOP);
        for (double tick in _xTicks) {
          double x = drawingArea.left + tick / coordinateSystem.xRange.length * drawingArea.width;
          double y = size.height - _xAxisLineOffset;

          ctx.beginPath();
          ctx.moveTo(x, y - halfTick);
          ctx.lineTo(x, y + halfTick);
          ctx.stroke();

          ctx.fillText(_renderTickLabel(tick, axisStyle), x, y + halfTick);
        }
      } else {
        setFont(size: axisStyle.ticks.labelFontSize, alignment: TextAlignment.RIGHT, baseline: TextBaseline.MIDDLE);
        for (double tick in _yTicks) {
          double y = drawingArea.top + drawingArea.height - tick / coordinateSystem.yRange.length * drawingArea.height;
          double x = _yAxisLineOffset;

          ctx.beginPath();
          ctx.moveTo(x - halfTick, y);
          ctx.lineTo(x + halfTick, y);
          ctx.stroke();

          ctx.fillText(_renderTickLabel(tick, axisStyle), x - halfTick, y);
        }
      }
    }

    // Draw label
    String label = axisStyle.label;
    bool hasLabel = label != null && label.isNotEmpty;
    if (!hasLabel) {
      label = axisStyle.labelGenerator();
      hasLabel = true;
    }
    if (hasLabel) {
      setFillColor(axisStyle.labelColor);

      if (axisType == _AxisType.X) {
        setFont(
          baseline: TextBaseline.BOTTOM,
          alignment: TextAlignment.RIGHT,
        );
        ctx.fillText(label, size.width, size.height - _xAxisLineOffset - _xAxisArrowHeadSize);
      } else {
        setFont(
          baseline: TextBaseline.TOP,
          alignment: TextAlignment.LEFT,
        );
        ctx.fillText(label, _yAxisLineOffset + _yAxisArrowHeadSize, 0);
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

  /// Padding of the x axis to the graph.
  double get _xPadding => style.xAxis.padding * window.devicePixelRatio;

  /// Padding of the y axis to the graph.
  double get _yPadding => style.yAxis.padding * window.devicePixelRatio;

  /// Get the drawing area for the actual graph.
  Rectangle<double> getDrawingArea() => new Rectangle(
        _yAxisLineOffset + _yPadding,
        _yAxisArrowHeadSize,
        size.width - _yAxisLineOffset - _yPadding - _xAxisArrowHeadSize,
        size.height - _xAxisLineOffset - _xPadding - _yAxisArrowHeadSize,
      );
}

enum _AxisType { X, Y }
