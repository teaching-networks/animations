import 'dart:html';

abstract class CanvasDrawable {

  /**
   * Render your graphics on the canvas.
   */
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, num timestamp);

}