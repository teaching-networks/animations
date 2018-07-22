import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/progress/progress.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress_rect.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

/// Horizontal progress bar.
class HorizontalProgressBar extends ProgressRect {

  static const Color DEFAULT_COLOR = Colors.BLUE_GRAY;

  /// Direction the progress bar should run. Either to west or east.
  final Direction direction;

  HorizontalProgressBar(Progress progress, this.direction, [ColorSupplier colorSupplier]) : super(progress, colorSupplier) {
    if (direction != Direction.EAST && direction != Direction.WEST) {
      throw new Exception("Horizontal Progress Bar can only have EAST or WEST direction.");
    }
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    {
      setFillColor(context, colorSupplier != null ? colorSupplier(progress.progress) : DEFAULT_COLOR);

      if (direction == Direction.WEST) {
        context.fillRect(rect.left, rect.top, rect.width * progress.progress, rect.height);
      } else {
        double width = rect.width * progress.progress;
        context.fillRect(rect.left + rect.width - width, rect.top, width, rect.height);
      }
    }

    context.restore();
  }

}