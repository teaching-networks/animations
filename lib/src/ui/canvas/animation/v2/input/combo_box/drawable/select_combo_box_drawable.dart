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

typedef void SelectCallback();

enum SelectArrowOrientation {
  LEFT,
  RIGHT,
}

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

  /// Color of an disabled arrow.
  final Color disabledColor;

  /// Callback called when the up or down arrow is clicked.
  final SelectCallback callBack;

  /// Orientation of the select arrow.
  final SelectArrowOrientation orientation;

  /// Current padding of the icon.
  double _currentPadding;

  /// Size of an arrow icon.
  double _arrowSize;

  /// The currently hovered arrow.
  bool _hovered = false;

  /// Wether the arrow is disabled.
  bool _disabled = false;

  /// Create drawable.
  SelectComboBoxDrawable({
    Drawable parent,
    this.iconSize = 12,
    this.padding = 2,
    this.color = Colors.DARK_GRAY,
    this.hoveredColor = Colors.BLACK,
    this.disabledColor = Colors.LIGHTGREY,
    this.callBack,
    this.orientation = SelectArrowOrientation.LEFT,
  }) : super(parent: parent) {
    _init();
  }

  /// Initialize the drawable.
  void _init() {
    _currentPadding = padding * window.devicePixelRatio;
    _arrowSize = iconSize * window.devicePixelRatio;

    setSize(
      width: _arrowSize + _currentPadding * 2,
      height: _arrowSize + _currentPadding * 2,
    );
  }

  /// Set the arrow disabled.
  void set disabled(bool value) {
    if (value != _disabled) {
      _disabled = value;
      invalidate();
    }
  }

  @override
  void draw() {
    ctx.translate(_currentPadding, _currentPadding);
    setFillColor(_disabled ? disabledColor : _hovered ? hoveredColor : color);

    ctx.beginPath();
    if (orientation == SelectArrowOrientation.RIGHT) {
      ctx.moveTo(0, 0);
      ctx.lineTo(0, _arrowSize);
      ctx.lineTo(_arrowSize, _arrowSize / 2);
    } else if (orientation == SelectArrowOrientation.LEFT) {
      ctx.moveTo(_arrowSize, 0);
      ctx.lineTo(_arrowSize, _arrowSize);
      ctx.lineTo(0, _arrowSize / 2);
    } else {
      throw new Exception("Orientation unknown");
    }
    ctx.fill();

    ctx.resetTransform();
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  /// Called when the arrow is clicked.
  void _clicked() {
    if (_disabled) {
      return;
    }

    if (callBack != null) {
      callBack();
    }
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    if (containsPos(event.pos)) {
      _clicked();
    }
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
    if (containsPos(event.pos)) {
      if (!_hovered) {
        _hovered = true;
        event.control.setCursorType("pointer");
        invalidate();
      }
    } else if (_hovered) {
      _hovered = false;
      event.control.resetCursorType();
      invalidate();
    }
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    // Do nothing
  }
}
