import 'dart:async';
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

  /// Stream controller of when the buffer is full.
  StreamController<void> _bufferFull = StreamController.broadcast(sync: true);

  /// Stream controller of when the buffer is empty.
  StreamController<void> _bufferEmpty = StreamController.broadcast(sync: true);

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

  /// Stream of when the buffer is full.
  Stream<void> get bufferFull => _bufferFull.stream;

  /// Stream of when the buffer is empty.
  Stream<void> get bufferEmpty => _bufferEmpty.stream;

  bool _bufferProgressWasChanging = false;

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

    context.textAlign = "center";
    context.textBaseline = "middle";
    setFillColor(context, Color.opacity(Colors.BLACK, 0.6));

    // Draw data size label
    double lazyDataKBytes = dataProgress.progress * dataSize / 1024;
    context.fillText("DATA: ${lazyDataKBytes.toStringAsFixed(2)} KB", rect.width / 2, (rect.height - bufferBarHeight) / 2);

    // Draw buffer label
    double lazyBufferKBytes = bufferProgress.progress * bufferSize / 1024;
    context.fillText("BUFFER: ${lazyBufferKBytes.toStringAsFixed(2)} KB", rect.width / 2, rect.height - bufferBarHeight / 2);

    context.restore();

    _bufferProgressNotification();
  }

  /// Notify whether buffer progress is full or empty or do not notify at all.
  void _bufferProgressNotification() {
    if (!bufferProgress.isChanging()) {
      if (_bufferProgressWasChanging) {
        _bufferProgressWasChanging = false;

        if (bufferProgress.actual == 0.0) {
          _bufferEmpty.add(null);
        } else if (bufferProgress.actual == 1.0) {
          _bufferFull.add(null);
        }
      }
    } else {
      _bufferProgressWasChanging = true;
    }
  }
}
