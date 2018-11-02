import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/horizontal_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/progress_rect.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/lazy_progress/lazy_progress.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

abstract class BufferWindow extends CanvasDrawable {
  final int dataSize;
  final int bufferSize;

  /// Progress of the data bar.
  LazyProgress dataProgress;

  /// Progress of the buffer bar.
  LazyProgress bufferProgress;

  /// Progress bar visualizing the data to send or received.
  ProgressRect _dataBar;

  /// Progress bar visualizing the buffer fill state.
  ProgressRect _bufferBar;

  /// Create new buffer window.
  BufferWindow({this.dataSize = 4096, this.bufferSize = 2048, double startDataProgress = 1.0, double startBufferProgress = 0.0}) {
    dataProgress = createDataProgress();
    bufferProgress = createBufferProgress();

    _dataBar = createDataBar();
    _bufferBar = createBufferBar();
  }

  /// Create the data progress.
  LazyProgress createDataProgress();

  /// Craete the buffer progress.
  LazyProgress createBufferProgress();

  /// Create the data bar.
  VerticalProgressBar createDataBar();

  /// Create the buffer bar.
  HorizontalProgressBar createBufferBar();

  /// Fill the buffer again.
  void fillBuffer();

  /// Clear the buffer.
  void clearBuffer();

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    context.translate(rect.left, rect.top);

    double bufferBarHeight = rect.height / 5;

    context.lineWidth = window.devicePixelRatio * 3;
    double i = context.lineWidth / 2;
    double ii = i * 2;

    setStrokeColor(context, Color.rgb(240, 240, 240));

    context.strokeRect(i, i, rect.width - ii, rect.height - bufferBarHeight - i);
    _dataBar.render(context, Rectangle(0.0, 0.0, rect.width, rect.height - bufferBarHeight));

    context.strokeRect(i, rect.height - bufferBarHeight, rect.width - ii, bufferBarHeight - i);
    _bufferBar.render(context, Rectangle(0.0, rect.height - bufferBarHeight, rect.width, bufferBarHeight));

    context.restore();
  }
}
