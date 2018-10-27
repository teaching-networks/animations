import 'dart:html';

import 'package:hm_animations/src/ui/canvas/canvas_context_base.dart';
import 'package:hm_animations/src/util/size.dart';

/**
 * Defines a object which is drawable on a canvas.
 */
abstract class CanvasDrawable extends CanvasContextBase {
  /**
   * Render your graphics on the canvas.
   *
   * @param context to draw on
   * @param rect which defines the offset and size of the drawable
   * @param timestamp of the rendering process
   */
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]);

  /**
   * Get rectangle.
   */
  Rectangle<double> toRect(double left, double top, Size size) {
    return new Rectangle(left, top, size.width, size.height);
  }
}
