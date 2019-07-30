/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:hm_animations/src/ui/canvas/canvas_context_base.dart';
import 'package:hm_animations/src/util/size.dart';

/**
 * Defines a object which is drawable on a canvas.
 */
abstract class CanvasDrawable extends CanvasContextBase {
  /// Before rendering.
  void preRender([num timestamp = -1]) {
    // Do nothing.
  }

  /// Render your graphics on the canvas.
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]);

  /**
   * Get rectangle.
   */
  Rectangle<double> toRect(double left, double top, Size size) {
    return new Rectangle(left, top, size.width, size.height);
  }
}
