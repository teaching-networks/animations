/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/buffer_window.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/horizontal_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/lazy_progress/lazy_progress.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

class ReceiverBufferWindow extends BufferWindow {
  /// When to consume the next package at the receiver.
  num _nextConsumeTimestamp = -1;

  Random _rng = new Random();

  ReceiverBufferWindow({int dataSize = 4096, int bufferSize = 2048, int speed = 1500, Message bufferLabel = null, Message dataLabel = null})
      : super(dataSize: dataSize, bufferSize: bufferSize, speed: speed, dataLabel: dataLabel, bufferLabel: bufferLabel);

  int get maxConsumeDuration => speed * 5;

  int get minConsumeDuration => speed * 2;

  @override
  void clearBuffer() {
    int currentBufferSize = (bufferSize * bufferProgress.actual).round();
    bufferProgress.progress = 0.0;

    // Add to data.
    double currentBufferSizeFraction = currentBufferSize / dataSize;
    double newProgress = min(dataProgress.actual + currentBufferSizeFraction, 1.0);
    dataProgress.progress = newProgress;

    _nextConsumeTimestamp = -1; // Reset consume timestamp.
  }

  @override
  void fillBuffer([double p = 1.0]) {
    bufferProgress.progress = p;

    if (_nextConsumeTimestamp == -1) {
      _nextConsumeTimestamp = window.performance.now() + minConsumeDuration + (maxConsumeDuration - minConsumeDuration) * _rng.nextDouble();
    }
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (_nextConsumeTimestamp != -1) {
      bool shouldConsume = _nextConsumeTimestamp < timestamp;

      if (shouldConsume) {
        showTooltip("Data consumed", Duration(seconds: 3));

        clearBuffer();

        _nextConsumeTimestamp = -1;
      }
    }

    super.render(context, rect, timestamp);
  }

  @override
  HorizontalProgressBar createBufferBar() {
    return HorizontalProgressBar(bufferProgress, Direction.WEST, (p) => Colors.CORAL);
  }

  @override
  LazyProgress createBufferProgress() {
    return LazyProgress(startProgress: 0.0, modifier: (p) => Curves.easeInOutCubic(p), duration: Duration(milliseconds: speed ~/ 2));
  }

  @override
  VerticalProgressBar createDataBar() {
    return VerticalProgressBar(dataProgress, Direction.SOUTH, (p) => Color.opacity(Colors.SLATE_GREY, 0.6));
  }

  @override
  LazyProgress createDataProgress() {
    return LazyProgress(startProgress: 0.0, modifier: (p) => Curves.easeInOutCubic(p), duration: Duration(milliseconds: speed ~/ 2));
  }

  @override
  void unpaused(num timestampDifference) {
    super.unpaused(timestampDifference);

    _nextConsumeTimestamp += timestampDifference;
  }
}
