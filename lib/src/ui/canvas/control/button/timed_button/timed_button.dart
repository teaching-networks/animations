/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim_helper.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/text/alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

import '../../../canvas_component.dart';

/// Action to execute.
typedef void Action();

/// A timed button will visualize a ticking timer.
class TimedButton extends Drawable implements MouseListener {
  /// Default color of the button.
  static const Color _defaultButtonColor = Colors.SLATE_GREY;

  /// Default color of the text.
  static const Color _defaultTextColor = Colors.WHITE;

  /// Default roundness (in pixel) of the button.
  static const double _defaultRoundness = 5;

  /// Default text size.
  static const double _defaultTextSize = 16;

  /// Default padding of the button.
  static const double _defaultPadding = 10;

  /// Text on the button.
  final String text;

  /// Action to execute when the timer runs out or the button is clicked.
  final Action action;

  /// Duration of the timer.
  final Duration duration;

  /// Color of the button.
  final Color color;

  /// Color of the text.
  final Color textColor;

  /// Roundness of the button in pixel.
  final double roundness;

  /// Text size of the buttons text.
  final double textSize;

  /// Padding of the button.
  final double padding;

  /// Animation of the timer.
  final Anim _timerAnimation;

  final RoundRectangle _roundRect;
  final RoundRectangle _progressRect;
  final TextDrawable _textDrawable;

  bool _isMouseOver = false;

  /// Create button.
  TimedButton({
    @required this.text,
    @required this.action,
    @required this.duration,
    this.color = _defaultButtonColor,
    this.textColor = _defaultTextColor,
    this.roundness = _defaultRoundness,
    this.textSize = _defaultTextSize,
    this.padding = _defaultPadding,
  })  : _timerAnimation = AnimHelper(
            duration: duration,
            onEnd: (timestamp) {
              action();
            }),
        _roundRect = RoundRectangle(
          color: color,
          paintMode: PaintMode.FILL,
          radius: Edges.all(roundness),
          radiusSizeType: SizeType.PIXEL,
        ),
        _progressRect = RoundRectangle(
          color: Color.brighten(color, 0.2),
          paintMode: PaintMode.FILL,
          radius: Edges.all(roundness),
          radiusSizeType: SizeType.PIXEL,
        ),
        _textDrawable = TextDrawable(
          text: text,
          color: textColor,
          alignment: TextAlignment.CENTER,
          textSize: textSize,
          lineHeight: 1.0,
          wrapAtLength: 50,
        ) {
    _textDrawable.setParent(this);

    _updateSize();
  }

  /// Update the size of the button.
  void _updateSize() {
    // Size of the button depends mainly on the text.
    setSize(
      width: _textDrawable.size.width + padding * 2,
      height: _textDrawable.size.height + padding * 2,
    );
  }

  @override
  void draw() {
    _roundRect.render(ctx, Rectangle<double>(0, 0, size.width, size.height), lastPassTimestamp);

    if (_timerAnimation.running) {
      _progressRect.render(ctx, Rectangle<double>(0, 0, size.width * _timerAnimation.progress, size.height), lastPassTimestamp);
    }

    _textDrawable.render(
      ctx,
      lastPassTimestamp,
      x: padding,
      y: padding,
    );
  }

  @override
  bool needsRepaint() => _timerAnimation.running;

  @override
  void update(num timestamp) {
    _timerAnimation.update(timestamp);
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    // Do nothing
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
    bool mouseOver = containsPos(event.pos);

    if (mouseOver != _isMouseOver) {
      _isMouseOver = mouseOver;
      _onMouseOverChange(_isMouseOver);
    }
  }

  void _onMouseOverChange(bool isMouseOver) {
    if (isMouseOver) {
      _roundRect.color = Color.brighten(color, 0.3);
    } else {
      _roundRect.color = color;
    }

    invalidate();
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    if (containsPos(event.pos)) {
      _onButtonClicked();
    }
  }

  void _onButtonClicked() {
    _timerAnimation.reset();
    action();

    invalidate();
  }

  /// Start the timer.
  void start() {
    _timerAnimation.start();
  }

  /// Reset the timer.
  void reset() {
    _timerAnimation.reset();

    invalidate();
  }
}
