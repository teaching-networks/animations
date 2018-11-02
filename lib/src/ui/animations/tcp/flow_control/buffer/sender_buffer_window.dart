import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/buffer_window.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/horizontal_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/lazy_progress/lazy_progress.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

class SenderBufferWindow extends BufferWindow {
  @override
  void clearBuffer() {
    bufferProgress.progress = 0.0;
  }

  @override
  void fillBuffer() {
    if (dataProgress.actual > 0.0) {
      int remainingBufferSize = (bufferSize * (1 - bufferProgress.actual)).round();

      double percentageOfData = remainingBufferSize / dataSize;

      dataProgress.progress = dataProgress.actual - percentageOfData;
      bufferProgress.progress = 1.0;
    }
  }

  @override
  HorizontalProgressBar createBufferBar() {
    return HorizontalProgressBar(bufferProgress, Direction.EAST);
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
    return LazyProgress(startProgress: 1.0, modifier: (p) => Curves.easeInOutCubic(p));
  }
}
