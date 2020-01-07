/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/focus/focusable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/text/alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

typedef void OnClick();

/// Drawable drawing a button UI component.
class ButtonDrawable extends Drawable implements MouseListener, FocusableDrawable {
  /// Current state of the button.
  final _ButtonDrawableState _state;

  /// Style of the button drawable.
  final ButtonDrawableStyle _style;

  /// Callback called on button click.
  final OnClick _onClick;

  /// Text to display on the button.
  String _text;

  /// Subscription to windows key up events.
  Function _windowKeyUpSub;

  /// Drawable drawing the buttons text.
  TextDrawable _textDrawable;

  /// Round rectangle used to draw the button background.
  RoundRectangle _roundRect = RoundRectangle(
    radiusSizeType: SizeType.PIXEL,
    paintMode: PaintMode.FILL,
    strokeWidth: 0,
  );

  /// Create button.
  ButtonDrawable({
    Drawable parent,
    String text = "",
    OnClick onClick,
    bool disabled = false,
    ButtonDrawableStyle style = const ButtonDrawableStyle(),
  })  : _text = text,
        _style = style,
        _onClick = onClick,
        _state = _ButtonDrawableState(
          disabled: disabled,
        ),
        super(parent: parent) {
    _init();
  }

  /// Initialize the button.
  void _init() {
    _windowKeyUpSub = (event) => _onKeyUp(event);
    window.addEventListener("keyup", _windowKeyUpSub);

    _initRoundRect();
    _initTextDrawable();
    _calculateSize();
  }

  /// Initialize the round rectangle used to draw the button background.
  void _initRoundRect() {
    _roundRect.radius = Edges.all(_style.roundedRadius);
  }

  /// Initialize the text drawable showing the buttons text.
  void _initTextDrawable() {
    _textDrawable = TextDrawable(
      parent: this,
      text: _text,
      alignment: TextAlignment.CENTER,
      color: _state.disabled ? _style.textDisabledColor : _style.textColor,
      fontFamilies: _style.fontFamilies,
      textSize: _style.textSize,
    );
  }

  @override
  void cleanup() {
    window.removeEventListener("keyup", _windowKeyUpSub);

    super.cleanup();
  }

  /// Set the text displayed on the button.
  set text(String text) {
    _text = text;
    _textDrawable.text = text;
    _calculateSize();
    invalidate();
  }

  /// Get the text display on the button.
  String get text => _text;

  /// Set the button disabled or enabled.
  set disabled(bool isDisabled) {
    if (_state.disabled == isDisabled) {
      return;
    }

    _state.disabled = isDisabled;

    if (hasFocus()) {
      blur();
    }

    _initTextDrawable();
    _calculateSize();
    invalidate();
  }

  /// Check whether the button is currently disabled or enabled.
  bool get disabled => _state.disabled;

  /// Calculate the size of the button drawable.
  void _calculateSize() {
    double padding = window.devicePixelRatio * _style.padding;
    double shadowPadding = window.devicePixelRatio * _style.shadowBlur;

    setSize(
      width: _textDrawable.size.width + padding * 2 + shadowPadding * 2,
      height: _textDrawable.size.height + padding * 2 + shadowPadding * 2,
    );
  }

  /// What should happen when a key is released.
  void _onKeyUp(KeyboardEvent event) {
    if (!_state.focused || _state.disabled) {
      return;
    }

    if (event.key == "Enter") {
      if (_onClick != null) {
        _onClick();
      }
    }
  }

  @override
  void draw() {
    _drawBackground();
    _drawText();
  }

  /// Draw the buttons text.
  void _drawText() {
    _textDrawable.render(ctx, lastPassTimestamp, x: (size.width - _textDrawable.size.width) / 2, y: (size.height - _textDrawable.size.height) / 2);
  }

  /// Draw the button background.
  void _drawBackground() {
    _roundRect.paintMode = PaintMode.FILL;

    if (_state.disabled) {
      _roundRect.color = _style.buttonDisabledColor;
    } else if (_state.active) {
      _roundRect.color = _style.buttonActiveColor;
    } else if (_state.hovered) {
      _roundRect.color = _style.buttonHoveredColor;
    } else {
      _roundRect.color = _style.buttonColor;
    }

    double shadowBlur = _style.shadowBlur * window.devicePixelRatio;
    double shadowOffsetY = _style.shadowOffsetY * window.devicePixelRatio;

    ctx.shadowColor = hasFocus() ? _style.focusColor.toCSSColorString() : _style.shadowColor.toCSSColorString();
    ctx.shadowBlur = shadowBlur;
    ctx.shadowOffsetY = shadowOffsetY;
    _roundRect.render(ctx, Rectangle<double>(shadowBlur, shadowBlur - shadowOffsetY, size.width - shadowBlur * 2, size.height - shadowBlur * 2));
    ctx.shadowBlur = 0;
    ctx.shadowColor = "";
    ctx.shadowOffsetY = 0;
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    if (_state.disabled) {
      return;
    }

    if (!containsPos(event.pos)) {
      if (hasFocus()) {
        blur();
      }
      return;
    }

    if (!hasFocus()) {
      focus();
    }

    _state.active = true;
    invalidate();
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
    if (_state.disabled) {
      return;
    }

    if (containsPos(event.pos)) {
      if (!_state.hovered) {
        _state.hovered = true;
        invalidate();

        _onMouseEnter(event);
      }
    } else {
      if (_state.hovered) {
        _state.hovered = false;
        invalidate();

        _onMouseLeave(event);
      }
    }
  }

  /// What should happen if the mouse enters the button.
  void _onMouseEnter(CanvasMouseEvent event) {
    if (event.control.getCursorType() != "pointer") {
      event.control.setCursorType("pointer");
    }
  }

  /// What should happen if the mouse leaves the button.
  void _onMouseLeave(CanvasMouseEvent event) {
    if (event.control.getCursorType() == "pointer") {
      event.control.resetCursorType();
    }
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    if (_state.disabled) {
      return;
    }

    if (_state.active) {
      _state.active = false;
      invalidate();
    }

    if (!containsPos(event.pos)) {
      return;
    }

    if (_state.hovered) {
      if (_onClick != null) {
        _onClick();
      }
    }
  }

  @override
  bool hasFocus() {
    return _state.focused;
  }

  @override
  void onBlur() {
    _state.focused = false;
    invalidate();
  }

  @override
  bool requestFocus() {
    if (_state.disabled) {
      return false;
    }

    if (!_state.focused) {
      _state.focused = true;
      invalidate();
      return true;
    }

    return false;
  }
}

/// Style of the button drawable.
class ButtonDrawableStyle {
  /// Padding of the button.
  final double padding;

  /// How much to round the border.
  final double roundedRadius;

  /// Color of the button text.
  final Color textColor;

  /// Color of the button text when disabled.
  final Color textDisabledColor;

  /// Size of the text.
  final double textSize;

  /// Font families to use for the button text.
  final String fontFamilies;

  /// Color of the button.
  final Color buttonColor;

  /// Color of the button when hovered.
  final Color buttonHoveredColor;

  /// Color of the button when active.
  final Color buttonActiveColor;

  /// Color of the button when disabled.
  final Color buttonDisabledColor;

  /// Focus border color.
  final Color focusColor;

  /// Blur of the shadow.
  final double shadowBlur;

  /// Color of the shadow.
  final Color shadowColor;

  /// Y offset of the shadow.
  final double shadowOffsetY;

  /// Create style.
  const ButtonDrawableStyle({
    this.padding = 4,
    this.roundedRadius = 2,
    this.textColor = Colors.DARK_GRAY,
    this.textDisabledColor = Colors.GRAY,
    this.textSize = CanvasContextUtil.DEFAULT_FONT_SIZE_PX,
    this.fontFamilies = "sans-serif",
    this.buttonColor = Colors.WHITE,
    this.buttonHoveredColor = Colors.LIGHTER_GRAY,
    this.buttonActiveColor = Colors.GRAY_BBB,
    this.buttonDisabledColor = Colors.LIGHTGREY,
    this.focusColor = Colors.SPACE_BLUE,
    this.shadowBlur = 3,
    this.shadowColor = Colors.GRAY,
    this.shadowOffsetY = 1,
  });
}

/// Current state of a button drawable.
class _ButtonDrawableState {
  /// Whether the button is currently focused.
  bool focused;

  /// Whether the button is currently hovered.
  bool hovered;

  /// Whether the button is currently active.
  bool active;

  /// Whether the button is currently disabled.
  bool disabled;

  /// Create state.
  _ButtonDrawableState({
    this.focused = false,
    this.hovered = false,
    this.active = false,
    this.disabled = false,
  });
}
