/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/container/container.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/container/round_rect/round_rect_style.dart';

/// Container displaying its contents in a round rectangle.
class RoundRectContainer extends Container {
  /// Child of the container.
  final Drawable child;

  /// Style of the round rectangle.
  final RoundRectStyle style;

  /// Current offset of the child drawable inside the container.
  double _offset = 0;

  /// Current offset the border is causing.
  double _borderOffset = 0;

  /// Create round container.
  RoundRectContainer({
    Drawable parent,
    this.child,
    this.style = const RoundRectStyle(),
  }) : super(parent: parent) {
    _init();
  }

  /// Initialize the container.
  void _init() {
    _recalculateSize();
  }

  /// Recalculate the size of the container.
  void _recalculateSize() {
    _borderOffset = style.borderThickness * window.devicePixelRatio;
    _offset = _borderOffset + style.padding * window.devicePixelRatio;

    setSize(
      width: child.size.width + _offset * 2,
      height: child.size.height + _offset * 2,
    );
  }

  @override
  void layout() {
    _drawRect();
    _drawContent();
  }

  /// Draw round rect.
  void _drawRect() {
    _drawPath(style.isRound ? calculateRoundRectPath() : calculateDefaultRectPath());
  }

  /// Draw the passed path.
  void _drawPath(Path2D path) {
    ctx.translate(_borderOffset / 2, _borderOffset / 2);

    if (style.hasFill) {
      setFillColor(style.fillColor);
      ctx.fill(path);
    }

    if (style.hasBorder) {
      setStrokeColor(style.borderColor);
      ctx.lineWidth = _borderOffset;
      ctx.stroke(path);
    }

    ctx.resetTransform();
  }

  /// Calculate the path of a default rectangle (without rounded edges).
  Path2D calculateDefaultRectPath() {
    Path2D path = Path2D();
    path.rect(0, 0, size.width, size.height);
    return path;
  }

  /// Calculate the round rectangles path.
  Path2D calculateRoundRectPath() {
    double scale = window.devicePixelRatio;

    double topLeft = style.edges.topLeft * scale;
    double topRight = style.edges.topRight * scale;
    double bottomLeft = style.edges.bottomLeft * scale;
    double bottomRight = style.edges.bottomRight * scale;

    double width = size.width - _borderOffset;
    double height = size.height - _borderOffset;

    Path2D path = Path2D();

    // Upper line
    path.moveTo(topLeft, 0);
    path.lineTo(width - topRight, 0);

    // Top right curve
    path.quadraticCurveTo(width, 0, width, topRight);

    // Right line
    path.lineTo(width, height - bottomRight);

    // Bottom right curve
    path.quadraticCurveTo(width, height, width - bottomRight, height);

    // Bottom line
    path.lineTo(bottomLeft, height);

    // Bottom left curve
    path.quadraticCurveTo(0, height, 0, height - bottomLeft);

    // Left line
    path.lineTo(0, topLeft);

    // Top left curve
    path.quadraticCurveTo(0, 0, topLeft, 0);

    path.closePath();

    return path;
  }

  /// Draw the containers content.
  void _drawContent() {
    child.render(
      ctx,
      lastPassTimestamp,
      x: _offset,
      y: _offset,
    );
  }

  @override
  void onChildSizeChange(SizeChange change) {
    _recalculateSize();
  }

  @override
  void onParentSizeChange(SizeChange change) {
    // Round rectangle Container is always the size of the
  }
}
