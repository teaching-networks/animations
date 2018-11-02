import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/buffer_window.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/horizontal_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/lazy_progress/lazy_progress.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

class ReceiverBufferWindow extends BufferWindow {
  static const Duration MAX_CONSUME_DURATION = const Duration(seconds: 3);
  static const Duration MIN_CONSUME_DURATION = const Duration(seconds: 1);

  /// When to consume the next package at the receiver.
  num nextConsumeTimestamp = -1;

  Random _rng = new Random();

  @override
  void clearBuffer() {
    int currentBufferSize = (bufferSize * bufferProgress.actual).round();
    bufferProgress.progress = 0.0;

    // Add to data.
    double currentBufferSizeFraction = currentBufferSize / dataSize;
    double newProgress = min(dataProgress.actual + currentBufferSizeFraction, 1.0);
    dataProgress.progress = newProgress;

    nextConsumeTimestamp = -1; // Reset consume timestamp.
  }

  @override
  void fillBuffer() {
    bufferProgress.progress = 1.0;

    if (nextConsumeTimestamp == -1) {
      nextConsumeTimestamp = window.performance.now() +
          MIN_CONSUME_DURATION.inMilliseconds +
          (MAX_CONSUME_DURATION.inMilliseconds - MIN_CONSUME_DURATION.inMilliseconds) * _rng.nextDouble();
    }
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (nextConsumeTimestamp != -1) {
      bool shouldConsume = nextConsumeTimestamp < timestamp;

      if (shouldConsume) {
        clearBuffer();

        nextConsumeTimestamp = -1;
      }
    }

    super.render(context, rect);
  }

  @override
  HorizontalProgressBar createBufferBar() {
    return HorizontalProgressBar(bufferProgress, Direction.WEST);
  }

  @override
  LazyProgress createBufferProgress() {
    return LazyProgress(startProgress: 0.0, modifier: (p) => Curves.easeInOutCubic(p));
  }

  @override
  VerticalProgressBar createDataBar() {
    return VerticalProgressBar(dataProgress, Direction.SOUTH);
  }

  @override
  LazyProgress createDataProgress() {
    return LazyProgress(startProgress: 0.0, modifier: (p) => Curves.easeInOutCubic(p));
  }
}
