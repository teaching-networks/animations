/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';

/// Drawable simulating a checkbox input component.
class CheckboxDrawable extends Drawable implements MouseListener {
  /// State of the checkbox.
  _CheckboxState _state;

  /// Style of the checkbox.
  CheckboxStyle _style;

  /// Label to show.
  String _label;

  /// Options for the label.
  CheckboxLabelOptions _labelOptions;

  /// Stream controller emitting events whenever the checked status of the drawable changes.
  StreamController<bool> _checkedStreamController = StreamController<bool>.broadcast();

  /// Drawable showing the label (if any).
  TextDrawable _labelDrawable;

  /// Round rectangle for the border of the checkbox.
  RoundRectangle _roundRect = RoundRectangle(
    radiusSizeType: SizeType.PIXEL,
    radius: Edges.all(2),
  );

  /// Create drawable.
  CheckboxDrawable({
    Drawable parent,
    bool checked = false,
    String label,
    CheckboxStyle style = const CheckboxStyle(),
    CheckboxLabelOptions labelOptions = const CheckboxLabelOptions(),
  })  : _state = _CheckboxState(checked: checked),
        _style = style,
        _label = label,
        _labelOptions = labelOptions,
        super(parent: parent) {
    _init();
  }

  /// Get the current checked status of the checkbox.
  /// Also see the [checkedChanges] getter to get a stream
  /// of changes of the checked status of the checkbox!
  bool get checked => _state.checked;

  /// Set the checked status of the checkbox programmatically.
  set checked(bool value) {
    if (value == _state.checked) {
      return;
    }

    _state.checked = value;
    _checkedStreamController.add(_state.checked);
    invalidate();
  }

  /// Get the current label of the checkbox.
  String get label => _label;

  /// Set the label of the checkbox.
  set label(String value) {
    if (label == null) {
      _labelDrawable = null;
    }

    _label = value;
    _initLabel();
    _calculateSize();

    invalidate();
  }

  /// Get notified of checked changes whenever the checked status of the checkbox changes.
  Stream<bool> get checkedChanges => _checkedStreamController.stream;

  /// Initialize the drawable.
  void _init() {
    _initLabel();
    _calculateSize();
  }

  /// Initialize the label.
  void _initLabel() {
    if (_label == null) {
      return;
    }

    _labelDrawable = TextDrawable(
      parent: this,
      text: _label,
      color: _labelOptions.textColor,
      textSize: _labelOptions.fontSize != null ? _labelOptions.fontSize : null,
      fontFamilies: _labelOptions.fontFamily,
      alignment: TextAlignment.LEFT,
      lineHeight: 1.0,
    );
  }

  /// Calculate the size of the drawable.
  void _calculateSize() {
    double checkboxSize = _style.size * window.devicePixelRatio;

    double width = checkboxSize;
    double height = checkboxSize;

    if (_labelDrawable != null) {
      width += _style.labelDistance * window.devicePixelRatio;

      width += _labelDrawable.size.width;
      height = max(height, _labelDrawable.size.height);
    }

    setSize(
      width: width,
      height: height,
    );
  }

  @override
  void draw() {
    Size s = _drawCheckbox();
    _drawLabel(offset: s.width);
  }

  /// Draw a checkbox.
  /// Returns the drawn checkbox size.
  Size _drawCheckbox() {
    if (_state.checked) {
      return _drawCheckedCheckbox();
    } else {
      return _drawUncheckedCheckbox();
    }
  }

  /// Draw the checked checkbox.
  Size _drawCheckedCheckbox() {
    double s = _style.size * window.devicePixelRatio;
    Size boxSize = Size(s, s);

    _roundRect.paintMode = PaintMode.FILL;

    if (_state.active) {
      _roundRect.color = _style.activeTickedColor;
    } else if (_state.hovered) {
      _roundRect.color = _style.hoverTickedColor;
    } else {
      _roundRect.color = _style.tickedColor;
    }

    _roundRect.render(ctx, Rectangle<double>(0, 0, boxSize.width, boxSize.height));

    // Draw tick
    ctx.lineWidth = _style.relativeTickThickness * s;
    setStrokeColor(_style.tickColor);
    ctx.beginPath();
    ctx.moveTo(boxSize.width * 0.25, boxSize.height * 0.5);
    ctx.lineTo(boxSize.width * 0.45, boxSize.height * 0.7);
    ctx.lineTo(boxSize.width * 0.75, boxSize.height * 0.25);
    ctx.stroke();

    return boxSize;
  }

  /// Draw the unchecked checkbox.
  Size _drawUncheckedCheckbox() {
    double offset = _style.borderWidth * window.devicePixelRatio;
    double s = _style.size * window.devicePixelRatio;
    Size boxSize = Size(s, s);

    _roundRect.paintMode = PaintMode.STROKE;
    _roundRect.strokeWidth = _style.borderWidth * window.devicePixelRatio;

    if (_state.active) {
      _roundRect.color = _style.activeBorderColor;
    } else if (_state.hovered) {
      _roundRect.color = _style.hoverBorderColor;
    } else {
      _roundRect.color = _style.borderColor;
    }

    _roundRect.render(ctx, Rectangle<double>(offset / 2, offset / 2, boxSize.width - offset, boxSize.height - offset));

    return boxSize;
  }

  /// Draw the label (if any).
  void _drawLabel({double offset = 0}) {
    if (_labelDrawable == null) {
      return;
    }

    _labelDrawable.render(
      ctx,
      lastPassTimestamp,
      x: offset + _style.labelDistance * window.devicePixelRatio,
      y: (size.height - _labelDrawable.size.height) / 2,
    );
  }

  @override
  void update(num timestamp) {
    // Nothing to update.
  }

  @override
  bool needsRepaint() => _labelDrawable != null ? _labelDrawable.needsRepaint() : false;

  @override
  void onMouseDown(CanvasMouseEvent event) {
    if (!containsPos(event.pos)) {
      return;
    }

    _state.active = true;
    invalidate();
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
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

  /// What to do when the mouse enters the checkbox.
  void _onMouseEnter(CanvasMouseEvent event) {
    if (event.control.getCursorType() != "pointer") {
      event.control.setCursorType("pointer");
    }
  }

  /// What to do when the mouse leaves the checkbox.
  void _onMouseLeave(CanvasMouseEvent event) {
    if (event.control.getCursorType() == "pointer") {
      event.control.resetCursorType();
    }
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    if (_state.active) {
      _state.active = false;
      invalidate();
    }

    if (!containsPos(event.pos)) {
      return;
    }

    if (_state.hovered) {
      checked = !checked;
    }
  }
}

/// Options for the checkbox label.
class CheckboxLabelOptions {
  /// Font size to use for the label text.
  final double fontSize;

  /// Font family to use for the label text.
  final String fontFamily;

  /// Color of the label text.
  final Color textColor;

  /// Create options.
  const CheckboxLabelOptions({
    this.fontSize,
    this.fontFamily = "sans-serif",
    this.textColor = Colors.BLACK,
  });
}

/// Style of the checkbox.
class CheckboxStyle {
  /// Default size of the checkbox.
  static const double _defaultCheckboxSize = 18;

  /// Default distance of the label to the checkbox.
  static const double _defaultLabelDistance = 5;

  /// Default width of the checkbox border.
  static const double _defaultBorderWidth = 2;

  /// Default thickness of the tick.
  static const double _defaultRelativeTickThickness = 0.1;

  /// Size of the checkbox box.
  final double size;

  /// Distance of the label to the checkbox.
  final double labelDistance;

  /// Color of the checkbox border.
  final Color borderColor;

  /// Color of the checkbox border when hovered.
  final Color hoverBorderColor;

  /// Color of the checkbox border when active.
  final Color activeBorderColor;

  /// Color of the checkbox when ticked.
  final Color tickedColor;

  /// Color of the checkbox when ticked and hovered.
  final Color hoverTickedColor;

  /// Color of the checkbox when ticked and active.
  final Color activeTickedColor;

  /// Width of the border.
  final double borderWidth;

  /// Thickness of the tick relative to the checkbox size. Range ]0.0; 1.0].
  final double relativeTickThickness;

  /// Color of the tick.
  final Color tickColor;

  /// Create style.
  const CheckboxStyle({
    this.size = _defaultCheckboxSize,
    this.labelDistance = _defaultLabelDistance,
    this.borderColor = Colors.GRAY,
    this.hoverBorderColor = Colors.GRAY_BBB,
    this.activeBorderColor = Colors.DARK_GRAY,
    this.tickedColor = const Color.hex(0xFF4285F4),
    this.hoverTickedColor = const Color.hex(0xFF73A6F7),
    this.activeTickedColor = const Color.hex(0xFF2B77F3),
    this.borderWidth = _defaultBorderWidth,
    this.relativeTickThickness = _defaultRelativeTickThickness,
    this.tickColor = Colors.WHITE,
  });
}

/// State of the checkbox.
class _CheckboxState {
  /// Whether the checkbox is currently checked.
  bool checked;

  /// Whether the checkbox is currently hovered over.
  bool hovered;

  /// Whether the checkbox is currently active (mouse down but not yet released).
  bool active;

  /// Create checkbox state.
  _CheckboxState({
    this.checked = false,
    this.hovered = false,
    this.active = false,
  });
}
