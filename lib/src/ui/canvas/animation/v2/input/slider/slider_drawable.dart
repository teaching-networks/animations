/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math' as math;

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/focus/focusable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim_helper.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/text/alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';

/// Formatter used to format a sliders value.
typedef String ValueFormatter(double value);

/// Callback when the slider value changes.
typedef void SliderValueChangeCallback(double value);

/// A slider input control.
class SliderDrawable extends Drawable implements FocusableDrawable, MouseListener {
  /// Internal state of the slider.
  final _SliderState _state = _SliderState();

  /// Style of the slider.
  SliderStyle _style;

  /// Minimum value of the slider.
  double _min;

  /// Maximum value of the slider.
  double _max;

  /// Step to do when changing the slider handle.
  double _step;

  /// Current value of the slider.
  double _value;

  /// Width of the slider.
  double _width;

  /// Drawable drawing the sliders current value if [_style.showValue] is truthy.
  TextDrawable _valueDrawable;

  /// Animation invoked when focusing the slider and [_style.animate] is truthy.
  Anim _focusAnimation;

  /// Animation invoked when hovering the slider and [_style.animate] is truthy.
  Anim _hoverAnimation;

  /// Subscription to key up events.
  Function _windowKeyDownSub;

  /// Subscription to window mouse up events.
  Function _windowMouseUpSub;

  /// Callback to be called when the value of the slider changes.
  SliderValueChangeCallback _changeCallback;

  /// Create slider drawable.
  SliderDrawable({
    Drawable parent,
    SliderStyle style = const SliderStyle(),
    double min = -1,
    double max = 1,
    double step = 0.1,
    double value = 0,
    double width = 200,
    SliderValueChangeCallback changeCallback,
  })  : _style = style,
        _min = min,
        _max = max,
        _step = step,
        _value = value,
        _width = width,
        _changeCallback = changeCallback,
        super(parent: parent) {
    _init();
  }

  /// Initialize the drawable.
  void _init() {
    if (_style.showValue) {
      _valueDrawable = TextDrawable(
        parent: this,
        text: _formattedValue,
        color: _style.valueTextColor,
        alignment: TextAlignment.CENTER,
        textSize: _style.valueTextSize,
        lineHeight: _style.valueTextLineHeight,
        fontFamilies: _style.valueTextFontFamilies,
      );
    }

    _focusAnimation = AnimHelper(
      curve: Curves.easeOutCubic,
      duration: Duration(milliseconds: 200),
      onEnd: (_) => invalidate(),
    );

    _hoverAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(milliseconds: 200),
      onEnd: (_) => invalidate(),
    );

    _windowKeyDownSub = (event) => _onKeyDown(event);
    window.addEventListener("keydown", _windowKeyDownSub);

    _windowMouseUpSub = (event) => _onWindowMouseUp(event);
    window.addEventListener("mouseup", _windowMouseUpSub);

    _recalculateSize();
  }

  @override
  void cleanup() {
    window.removeEventListener("keydown", _windowKeyDownSub);
    window.removeEventListener("mouseup", _windowMouseUpSub);

    super.cleanup();
  }

  /// Set the disabled state of the slider drawable.
  set disabled(bool value) {
    if (value != _state.disabled) {
      _state.disabled = value;

      if (_state.disabled && hasFocus()) {
        blur();
      }

      _state.dragged = false;

      invalidate();
    }
  }

  /// Check whether the slider drawable is disabled.
  bool get disabled => _state.disabled;

  /// Set the style of the slider.
  set style(SliderStyle value) {
    _style = value;

    invalidate();
  }

  /// Get the currently set style of the slider.
  SliderStyle get style => _style;

  /// Set the minimum value of the slider.
  set min(double newMin) {
    _min = newMin;
    if (value < _min) {
      setValue(_min);
    }

    invalidate();
  }

  /// Get the minimum value of the slider.
  double get min => _min;

  /// Set the maximum value of the sider.
  set max(double newMax) {
    _max = newMax;
    if (value > _max) {
      setValue(_max);
    }

    invalidate();
  }

  /// Get the maximum value of the slider.
  double get max => _max;

  /// Set the step to do when changing the slider handle.
  set step(double value) {
    _step = value;
  }

  /// Get the step to do when changing the slider handle.
  double get step => _step;

  /// Set the current value of the slider.
  setValue(double v, {bool informChangeListener = true}) {
    double newValue = math.min(math.max(v, _min), _max);

    // Round to next nearest [step].
    double rest = newValue % step;
    double lower = newValue - rest;
    double higher = lower + step;

    if (newValue - lower < higher - newValue) {
      newValue = lower;
    } else {
      newValue = higher;
    }

    if (newValue != _value) {
      _value = newValue;

      if (_style.showValue) {
        double oldHeight = _valueDrawable.size.height;
        _valueDrawable.text = _formattedValue;

        if (_valueDrawable.size.height != oldHeight) {
          _recalculateSize();
        }
      }

      invalidate();

      if (_changeCallback != null && informChangeListener) {
        _changeCallback(value);
      }
    }
  }

  /// Get the current value of the slider.
  double get value => _value;

  /// Set the current width of the slider.
  set width(double value) {
    _width = value;

    _recalculateSize();
  }

  /// Get the current width of the slider.
  double get width => _width;

  /// Recalculate the size of the drawable.
  void _recalculateSize() {
    double maxHandleSize = _style.handleSize + (_style.handleBorderSize + _style.focusBorderSize) * 2;

    double width = _width + maxHandleSize;
    double height = math.max(_style.barSize, maxHandleSize);

    if (_style.showValue) {
      height += _valueDrawable.size.height;
    }

    setSize(
      width: width * window.devicePixelRatio,
      height: height * window.devicePixelRatio,
    );
  }

  @override
  bool hasFocus() => _state.focused;

  @override
  bool requestFocus() {
    if (_state.disabled) {
      return false;
    }

    if (!_state.focused) {
      _state.focused = true;
      invalidate();

      if (_style.animate) {
        _focusAnimation.reset(resetReverse: true);
        _focusAnimation.start();
      }
    }

    return true;
  }

  @override
  void onBlur() {
    if (_state.focused) {
      _state.focused = false;
      invalidate();

      if (_style.animate) {
        if (!_focusAnimation.reversed) _focusAnimation.reverse();
        _focusAnimation.start();
      }
    }
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    if (!containsPos(event.pos)) {
      if (hasFocus()) {
        blur();
      }
      return;
    }

    if (!hasFocus()) {
      focus();
    }

    if (_state.disabled) {
      return;
    }

    _state.dragged = true;
    _setValueForMouseEvent(event);
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

    if (_state.dragged) {
      _setValueForMouseEvent(event);
    }
  }

  /// Set the value for the passed mouse [event].
  void _setValueForMouseEvent(CanvasMouseEvent event) {
    double handlePadding = (_style.handleSize / 2 + _style.handleBorderSize + _style.focusBorderSize) * window.devicePixelRatio;

    double minX = lastRenderAbsoluteXOffset + handlePadding;
    double maxX = lastRenderAbsoluteXOffset + size.width - handlePadding;

    double curX = event.pos.x;

    if (curX > minX && curX < maxX) {
      double range = maxX - minX;
      double relativePos = (curX - minX) / range;

      setValue(min + (max - min) * relativePos);
    } else if (curX >= maxX) {
      setValue(max);
    } else if (curX <= minX) {
      setValue(min);
    }
  }

  /// What should happen when the mouse enters the slider.
  void _onMouseEnter(CanvasMouseEvent event) {
    if (event.control.getCursorType() != "pointer") {
      event.control.setCursorType("pointer");
    }

    if (_style.animate) {
      _hoverAnimation.reset(resetReverse: true);
      _hoverAnimation.start();
    }
  }

  /// What should happen when the mouse leaves the slider.
  void _onMouseLeave(CanvasMouseEvent event) {
    if (event.control.getCursorType() == "pointer") {
      event.control.resetCursorType();
    }

    if (_style.animate) {
      if (!_hoverAnimation.reversed) _hoverAnimation.reverse();
      _hoverAnimation.start();
    }
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    if (_state.disabled) {
      return;
    }

    if (_state.dragged) {
      _state.dragged = false;
    }
  }

  /// What should happen on the mouse up event on the window.
  void _onWindowMouseUp(MouseEvent event) {
    if (_state.disabled) {
      return;
    }

    if (_state.dragged) {
      _state.dragged = false;
    }
  }

  /// What should happen on the key down event.
  void _onKeyDown(KeyboardEvent event) {
    if (!_state.focused) {
      return;
    }

    double s = event.ctrlKey ? (max - min) * 0.1 : step;

    if (event.key == "ArrowLeft") {
      setValue(value - s);
    } else if (event.key == "ArrowRight") {
      setValue(value + s);
    }
  }

  @override
  void draw() {
    double focusBorderSize = _style.focusBorderSize * window.devicePixelRatio;
    double handleBorderSize = _style.handleBorderSize * window.devicePixelRatio;
    double handleSize = _style.handleSize * window.devicePixelRatio;
    double barSize = _style.barSize * window.devicePixelRatio;

    _drawBar(((focusBorderSize + handleBorderSize) * 2 + handleSize) / 2, barSize);
    _drawHandle(handleSize, handleBorderSize, focusBorderSize);

    if (_style.showValue) {
      _valueDrawable.render(
        ctx,
        lastPassTimestamp,
        x: (size.width - _valueDrawable.size.width) / 2,
        y: math.max(focusBorderSize * 2 + handleSize, barSize),
      );
    }
  }

  /// Draw the slider bar.
  void _drawBar(double padding, double barSize) {
    setFillColor(_state.disabled ? _style.disabledColor : _style.barColor);
    ctx.fillRect(padding, padding - barSize / 2, size.width - padding * 2, barSize);
  }

  /// Get the x offset of the handle for the current value.
  double getHandleXOffset(double padding) => padding + ((_value - _min) / (_max - _min) * (size.width - padding * 2));

  /// Draw the slider handle.
  void _drawHandle(double handleSize, double handleBorderSize, double focusBorderSize) {
    double radius = handleSize / 2;
    double yOffset = radius + handleBorderSize + focusBorderSize;
    double xOffset = getHandleXOffset(yOffset);

    if (_state.focused || _focusAnimation.running) {
      setFillColor(_focusAnimation.running ? Color.opacity(_style.focusedColor, _focusAnimation.progress * _style.focusedColor.alpha) : _style.focusedColor);
      ctx.beginPath();
      ctx.arc(xOffset, yOffset, radius + focusBorderSize + handleBorderSize, 0, 2 * math.pi);
      ctx.fill();
    }

    setFillColor(_style.handleBorderColor);
    ctx.beginPath();
    ctx.arc(xOffset, yOffset, radius + handleBorderSize, 0, 2 * math.pi);
    ctx.fill();

    if (_state.disabled) {
      setFillColor(_style.disabledColor);
    } else if (_state.hovered || _hoverAnimation.running) {
      if (_hoverAnimation.running) {
        setFillColor(Color.merge(_style.handleColor, _style.hoveredHandleColor, _hoverAnimation.progress));
      } else {
        setFillColor(_style.hoveredHandleColor);
      }
    } else {
      setFillColor(_style.handleColor);
    }
    ctx.beginPath();
    ctx.arc(xOffset, yOffset, radius, 0, 2 * math.pi);
    ctx.fill();
  }

  @override
  bool needsRepaint() => _focusAnimation.running || _hoverAnimation.running;

  @override
  void update(num timestamp) {
    _focusAnimation.update(timestamp);
    _hoverAnimation.update(timestamp);
  }

  /// Get the current value in a formatted representation.
  String get _formattedValue => _style.valueFormatter != null ? _style.valueFormatter(_value) : _value.toStringAsFixed(2);
}

/// Style of the slider drawable.
class SliderStyle {
  /// Whether the slider animations are enabled.
  final bool animate;

  /// Whether to show the value underneath the slider.
  final bool showValue;

  /// Formatter used to format the value before displaying when [showValue] is truthy.
  final ValueFormatter valueFormatter;

  /// Size of the slider bar.
  final double barSize;

  /// Size of the slider handle.
  final double handleSize;

  /// Size of the handle border.
  final double handleBorderSize;

  /// Color when disabled.
  final Color disabledColor;

  /// Color of the slider bar.
  final Color barColor;

  /// Color of the slider handle.
  final Color handleColor;

  /// Color of the handle when the slider is hovered.
  final Color hoveredHandleColor;

  /// Color of the slider handle border.
  final Color handleBorderColor;

  /// Color of the sliders focus.
  final Color focusedColor;

  /// Size of the focus border around the handle when the slider is focused.
  final double focusBorderSize;

  /// Color of the value.
  final Color valueTextColor;

  /// Size of the value text.
  final double valueTextSize;

  /// Line height of the value text.
  final double valueTextLineHeight;

  /// Font families to use for the value text.
  final String valueTextFontFamilies;

  /// Create style.
  const SliderStyle({
    this.animate = true,
    this.showValue = true,
    this.valueFormatter = null,
    this.barSize = 2,
    this.handleSize = 20,
    this.handleBorderSize = 2,
    this.barColor = const Color.hex(0xFF4285F4),
    this.handleColor = const Color.hex(0xFF4285F4),
    this.hoveredHandleColor = const Color.hex(0xFF64A7F6),
    this.handleBorderColor = Colors.WHITE,
    this.disabledColor = Colors.GRAY,
    this.focusedColor = const Color.hex(0x99999999),
    this.focusBorderSize = 7,
    this.valueTextColor = Colors.BLACK,
    this.valueTextSize = CanvasContextUtil.DEFAULT_FONT_SIZE_PX,
    this.valueTextLineHeight = 1.0,
    this.valueTextFontFamilies = "Consolas, 'Courier New', Courier, monospace",
  });
}

/// Internal state of the slider.
class _SliderState {
  /// Whether the slider is focused.
  bool focused;

  /// Whether the slider is hovered.
  bool hovered;

  /// Whether the slider handle is dragged.
  bool dragged;

  /// Whether the slider is disabled.
  bool disabled;

  /// Create state
  _SliderState({
    this.focused = false,
    this.hovered = false,
    this.dragged = false,
    this.disabled = false,
  });
}
