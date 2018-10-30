import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/horizontal_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/progress_rect.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/lazy_progress/lazy_progress.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

class BufferWindow extends CanvasDrawable {
  final int dataSize;
  final int bufferSize;

  /// Progress of the data bar.
  LazyProgress _dataProgress = LazyProgress(startProgress: 1.0);

  /// Progress of the buffer bar.
  LazyProgress _bufferProgress = LazyProgress(startProgress: 0.0);

  /// Progress bar visualizing the data to send or received.
  ProgressRect _dataBar;

  /// Progress bar visualizing the buffer fill state.
  ProgressRect _bufferBar;

  /// Create new buffer window.
  BufferWindow({this.dataSize = 4096, this.bufferSize = 2048}) {
    _dataBar = VerticalProgressBar(_dataProgress, Direction.NORTH);
    _bufferBar = HorizontalProgressBar(_dataProgress, Direction.EAST);
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    context.translate(rect.left, rect.top);

    double bufferBarHeight = rect.height / 5;
    _dataBar.render(context, Rectangle(0.0, 0.0, rect.width, rect.height - bufferBarHeight));
    _bufferBar.render(context, Rectangle(0.0, rect.height - bufferBarHeight, rect.width, bufferBarHeight));

    context.restore();
  }

  /// Fill the buffer again.
  void fillBuffer() {
    if (_dataProgress.actual > 0.0) {
      int remainingBufferSize = (bufferSize * _bufferProgress.actual).round();

      double percentageOfData = remainingBufferSize / dataSize;

      _dataProgress.progress = _dataProgress.actual - percentageOfData;
      _bufferProgress.progress = 1.0;
    }
  }
}
