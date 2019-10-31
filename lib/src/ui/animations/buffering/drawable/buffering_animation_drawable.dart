/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/vertical_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/slider/slider_drawable.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';

/// The root drawable of the buffering animation.
class BufferingAnimationDrawable extends Drawable {
  /// Slider used to specify the playback buffer size.
  Drawable _playoutBufferSizeSlider;

  /// Slider used to specify the mean network rate.
  Drawable _meanNetworkRateSlider;

  /// Slider used to specify the variance of the network rate.
  Drawable _networkRateVarianceSlider;

  /// Create the buffering animation drawable.
  BufferingAnimationDrawable() {
    _init();
  }

  /// Initialize the drawable.
  void _init() {
    _playoutBufferSizeSlider = _createSlider(
      label: "Playout buffer size",
      changeCallback: (value) => print("Playback buffer size: $value"),
      min: 0,
      max: 1024,
      value: 128,
      step: 8,
      valueFormatter: (value) => "${value.toInt()} Byte",
    );

    _meanNetworkRateSlider = _createSlider(
      label: "Mean network rate",
      changeCallback: (value) => print("Mean network rate: $value"),
      min: 0,
      max: 1024,
      value: 128,
      step: 8,
      valueFormatter: (value) => "${value.toInt()} Byte/s",
    );

    _networkRateVarianceSlider = _createSlider(
      label: "Network rate variance",
      changeCallback: (value) => print("Network rate variance: $value"),
      min: 0,
      max: 1024,
      value: 32,
      step: 8,
      valueFormatter: (value) => "${value.toInt()} Byte/s",
    );
  }

  /// Create a slider input control.
  Drawable _createSlider({
    String label,
    SliderValueChangeCallback changeCallback,
    double min,
    double max,
    double value,
    double step,
    ValueFormatter valueFormatter,
  }) {
    return VerticalLayout(
      parent: this,
      alignment: HorizontalAlignment.CENTER,
      children: [
        TextDrawable(
          text: label,
        ),
        SliderDrawable(
          value: value,
          min: min,
          max: max,
          step: step,
          changeCallback: changeCallback,
          style: SliderStyle(
            valueFormatter: valueFormatter,
          ),
        )
      ],
    );
  }

  @override
  void draw() {
    double sliderPadding = 10 * window.devicePixelRatio;
    double sliderWidths =
        _playoutBufferSizeSlider.size.width + sliderPadding + _meanNetworkRateSlider.size.width + sliderPadding + _networkRateVarianceSlider.size.width;
    double sliderHeight = max(max(_playoutBufferSizeSlider.size.height, _meanNetworkRateSlider.size.height), _networkRateVarianceSlider.size.height);

    _drawSliders(sliderWidths, sliderHeight, sliderPadding);
  }

  /// Draw the sliders to control the animation.
  void _drawSliders(double width, double height, double padding) {
    double offsetX = (size.width - width) / 2;

    _playoutBufferSizeSlider.render(ctx, lastPassTimestamp, x: offsetX);

    _meanNetworkRateSlider.render(ctx, lastPassTimestamp, x: offsetX + _playoutBufferSizeSlider.size.width + padding);

    _networkRateVarianceSlider.render(ctx, lastPassTimestamp,
        x: offsetX + _playoutBufferSizeSlider.size.width + padding + _meanNetworkRateSlider.size.width + padding);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }
}
