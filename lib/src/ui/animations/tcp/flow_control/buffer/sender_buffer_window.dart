import 'dart:math';

import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/buffer_window.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/horizontal_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/lazy_progress/lazy_progress.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

class SenderBufferWindow extends BufferWindow {
  SenderBufferWindow({int dataSize = 4096, int bufferSize = 2048}) : super(dataSize: dataSize, bufferSize: bufferSize);

  @override
  void clearBuffer() {
    bufferProgress.progress = 0.0;
  }

  @override
  void fillBuffer([double p = 1.0]) {
    if (dataProgress.actual > 0.0) {
      int remainingBufferSize = (bufferSize * (1 - bufferProgress.actual)).round();
      int remainingDataSize = (dataSize * dataProgress.actual).round();

      double percentageOfData = remainingBufferSize / dataSize;
      dataProgress.progress = max(dataProgress.actual - percentageOfData, 0.0);

      double percentageOfBuffer = min(remainingDataSize / bufferSize, 1.0);
      bufferProgress.progress = percentageOfBuffer;
    }
  }

  @override
  HorizontalProgressBar createBufferBar() {
    return HorizontalProgressBar(bufferProgress, Direction.EAST, (p) => Colors.CORAL);
  }

  @override
  LazyProgress createBufferProgress() {
    return LazyProgress(startProgress: 0.0, modifier: (p) => Curves.easeInOutCubic(p));
  }

  @override
  VerticalProgressBar createDataBar() {
    return VerticalProgressBar(dataProgress, Direction.SOUTH, (p) => Color.opacity(Colors.SLATE_GREY, 0.6));
  }

  @override
  LazyProgress createDataProgress() {
    return LazyProgress(startProgress: 1.0, modifier: (p) => Curves.easeInOutCubic(p));
  }
}
