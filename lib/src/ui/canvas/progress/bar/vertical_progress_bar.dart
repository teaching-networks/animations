/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/progress/progress.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/progress_rect.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

/// Vertical progress bar.
class VerticalProgressBar extends ProgressRect {

  static const Color DEFAULT_COLOR = Colors.BLUE_GRAY;

  /// Direction of the progress bar (either north or south).
  final Direction direction;

  VerticalProgressBar(Progress progress, this.direction, [ColorSupplier colorSupplier]) : super(progress, colorSupplier) {
    if (direction != Direction.NORTH && direction != Direction.SOUTH) {
      throw new Exception("Vertical Progress Bar can only have NORTH or SOUTH direction.");
    }
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    {
      setFillColor(context, colorSupplier != null ? colorSupplier(progress.progress) : DEFAULT_COLOR);

      if (direction == Direction.NORTH) {
        context.fillRect(rect.left, rect.top, rect.width, rect.height * progress.progress);
      } else {
        double height = rect.height * progress.progress;
        context.fillRect(rect.left, rect.top + rect.height - height, rect.width, height);
      }
    }

    context.restore();
  }
  
}
