/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/image/layout/fill_layout.dart';
import 'package:hm_animations/src/ui/canvas/image/layout/image_layout.dart';
import 'package:hm_animations/src/ui/canvas/image/layout/stretch_layout.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';

abstract class CanvasContextBase {
  /// Default font size - will be scaled using window.devicePixelRatio.
  static const DEFAULT_FONT_SIZE_PX = 16;

  static const ImageLayout _stretchLayout = StretchImageLayout();
  static const ImageLayout _fillLayout = FillImageLayout();

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
  Rectangle<double> drawImageOnCanvas(
    CanvasRenderingContext2D context,
    CanvasImageSource src, {
    double width,
    double height,
    double aspectRatio,
    double x = 0,
    double y = 0,
    ImageDrawMode mode = ImageDrawMode.STRETCH,
    ImageAlignment alignment = ImageAlignment.START,
  }) {
    Rectangle<double> bounds;
    switch (mode) {
      case ImageDrawMode.STRETCH:
        bounds = _stretchLayout.layout(width: width, height: height, aspectRatio: aspectRatio, x: x, y: y, alignment: alignment);
        break;
      case ImageDrawMode.FILL:
        bounds = _fillLayout.layout(width: width, height: height, aspectRatio: aspectRatio, x: x, y: y, alignment: alignment);
        break;
      default:
        throw Exception("Image draw mode unknown");
    }

    context.drawImageToRect(src, bounds);

    return bounds;
  }
}

/// Modes how to draw an image.
enum ImageDrawMode {
  FILL,
  STRETCH,
}
