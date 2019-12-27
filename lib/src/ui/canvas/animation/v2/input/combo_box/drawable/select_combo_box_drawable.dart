/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

typedef void SelectCallback(bool isUp);

/// Drawable which will show select arrow icons.
class SelectComboBoxDrawable extends Drawable implements MouseListener {
  /// Size of the drawable.
  final double iconSize;

  /// Padding of the icon.
  final double padding;

  /// Color of a arrow.
  final Color color;

  /// Color of a hovered arrow.
  final Color hoveredColor;

  /// Callback called when the up or down arrow is clicked.
  final SelectCallback callBack;

  /// Current padding of the icon.
  double _currentPadding;

  /// Padding between the two arrows.
  double _arrowOffset;

  /// Size of an arrow icon.
  double _arrowSize;

  /// The currently hovered arrow.
  int _hoveredArrow;

  /// Create drawable.
  SelectComboBoxDrawable({
    Drawable parent,
    this.iconSize = 12,
    this.padding = 2,
    this.color = Colors.DARK_GRAY,
    this.hoveredColor = Colors.BLACK,
    this.callBack,
  }) : super(parent: parent) {
    _init();
  }

  /// Initialize the drawable.
  void _init() {
    _arrowOffset = 3 * window.devicePixelRatio;
    _currentPadding = padding * window.devicePixelRatio;
    double s = iconSize * window.devicePixelRatio;
    _arrowSize = (s - _arrowOffset) / 2;

    setSize(
      width: s + _currentPadding * 2,
      height: s + _currentPadding * 2,
    );
  }

  @override
  void draw() {
    ctx.translate(_currentPadding, _currentPadding);

    double w = size.width - _currentPadding * 2;

    // Draw upper arrow
    setFillColor(_hoveredArrow != null && _hoveredArrow == 1 ? hoveredColor : color);
    ctx.beginPath();
    ctx.moveTo(w / 2, 0);
    ctx.lineTo(w, _arrowSize);
    ctx.lineTo(0, _arrowSize);
    ctx.fill();

    ctx.translate(0, _arrowSize + _arrowOffset);

    // Draw lower arrow
    setFillColor(_hoveredArrow != null && _hoveredArrow == 2 ? hoveredColor : color);
    ctx.beginPath();
    ctx.moveTo(0, 0);
    ctx.lineTo(w, 0);
    ctx.lineTo(w / 2, _arrowSize);
    ctx.fill();

    ctx.resetTransform();
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  /// Called when the upper button is clicked.
  void _upClicked() {
    if (callBack != null) {
      callBack(true);
    }
  }

  /// Called when the lower button is clicked.
  void _downClicked() {
    if (callBack != null) {
      callBack(false);
    }
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    if (containsPos(event.pos)) {
      int hoveredArrow = getHoveredArrow(event.pos);
      if (hoveredArrow == 1) {
        _upClicked();
      } else if (hoveredArrow == 2) {
        _downClicked();
      }
    }
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
    if (containsPos(event.pos)) {
      int hoveredArrow = getHoveredArrow(event.pos);
      if (_hoveredArrow != hoveredArrow) {
        _hoveredArrow = hoveredArrow;
        invalidate();
      }
      event.control.setCursorType("pointer");
    } else if (_hoveredArrow != null) {
      _hoveredArrow = null;
      event.control.resetCursorType();
      invalidate();
    }
  }

  /// Get the currently hovered arrow.
  int getHoveredArrow(Point<double> pos) {
    return pos.y - lastRenderAbsoluteYOffset > _currentPadding + _arrowSize + _arrowOffset / 2 ? 2 : 1;
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    // Do nothing
  }
}
