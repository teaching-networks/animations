import 'dart:html';

import 'package:hm_animations/src/ui/canvas/util/color.dart';

abstract class CanvasContextBase {
  /// Default font size - will be scaled using window.devicePixelRatio.
  static const DEFAULT_FONT_SIZE_PX = 16;

  /// Convenience method to set a color as fill color of a context.
  void setFillColor(CanvasRenderingContext2D context, Color color) {
    context.setFillColorRgb(color.red, color.green, color.blue, color.alpha);
  }

  /// Convenience method to set a color as stroke color of a context.
  void setStrokeColor(CanvasRenderingContext2D context, Color color) {
    context.setStrokeColorRgb(color.red, color.green, color.blue, color.alpha);
  }

  /// Get the default font size of a canvas (e. g. 1.0em) in pixel.
  double get defaultFontSize => window.devicePixelRatio * DEFAULT_FONT_SIZE_PX;

  /// Draw image on the canvas.
  void drawImageOnCanvas(
    CanvasRenderingContext2D context,
    CanvasImageSource src, {
    double x = 0,
    double y = 0,
    double width,
    double height,
    double aspectRatio = 1.0,
  }) {
    double w = 0;
    double h = 0;
    if (width != null && height != null) {
      w = width;
      h = height;
    } else if (width != null) {
      w = width;
      h = width / aspectRatio;
    } else if (height != null) {
      h = height;
      w = height * aspectRatio;
    }

    context.drawImageToRect(src, Rectangle<double>(x, y, w, h));
  }
}
