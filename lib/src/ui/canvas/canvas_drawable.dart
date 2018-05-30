import 'dart:html';

import 'package:netzwerke_animationen/src/ui/canvas/util/color.dart';
import 'package:netzwerke_animationen/src/util/size.dart';

/**
 * Defines a object which is drawable on a canvas.
 */
abstract class CanvasDrawable {
  /**
   * Render your graphics on the canvas.
   *
   * @param context to draw on
   * @param rect which defines the offset and size of the drawable
   * @param timestamp of the rendering process
   */
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]);

  /**
   * Convenience method to set a color as fill color of a context.
   */
  void setFillColor(CanvasRenderingContext2D context, Color color) {
    context.setFillColorRgb(color.red, color.green, color.blue, color.alpha);
  }

  /**
   * Convenience method to set a color as stroke color of a context.
   */
  void setStrokeColor(CanvasRenderingContext2D context, Color color) {
    context.setStrokeColorRgb(color.red, color.green, color.blue, color.alpha);
  }

  /**
   * Get rectangle.
   */
  Rectangle<double> toRect(double left, double top, Size size) {
    return new Rectangle(left, top, size.width, size.height);
  }
}
