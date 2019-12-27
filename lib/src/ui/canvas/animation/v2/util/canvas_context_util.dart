/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/image/layout/fill_layout.dart';
import 'package:hm_animations/src/ui/canvas/image/layout/image_layout.dart';
import 'package:hm_animations/src/ui/canvas/image/layout/stretch_layout.dart';
import 'package:hm_animations/src/ui/canvas/text/alignment.dart';
import 'package:hm_animations/src/ui/canvas/text/baseline.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';

abstract class CanvasContextUtil {
  /// Default font size - will be scaled using window.devicePixelRatio.
  static const double DEFAULT_FONT_SIZE_PX = 16;

  static const ImageLayout _stretchLayout = StretchImageLayout();
  static const ImageLayout _fillLayout = FillImageLayout();

  /// Context to apply canvas context modifications on.
  CanvasRenderingContext2D _ctx;

  /// Get the default font size of a canvas (e. g. 1.0em) in pixel.
  double get defaultFontSize => window.devicePixelRatio * DEFAULT_FONT_SIZE_PX;

  /// Set the canvas context to apply utility modifications on.
  void setUtilCanvasContext(CanvasRenderingContext2D context) {
    _ctx = context;
  }

  /// Check whether the current context is available to apply modifications on.
  void _checkContextAvailable() {
    if (_ctx == null) {
      throw Exception("Could not apply context modification, since the context of the utility instance has not been set.");
    }
  }

  /// Set a color as the current fill color.
  void setFillColor(Color color) {
    _checkContextAvailable();

    if (color != null) {
      _ctx.setFillColorRgb(color.red, color.green, color.blue, color.alpha);
    } else {
      _ctx.setFillColorRgb(0, 0, 0, 0.0); // Transparent
    }
  }

  /// Convenience method to set a color as stroke color of a context.
  void setStrokeColor(Color color) {
    _checkContextAvailable();

    if (color != null) {
      _ctx.setStrokeColorRgb(color.red, color.green, color.blue, color.alpha);
    } else {
      _ctx.setStrokeColorRgb(0, 0, 0, 0.0); // Transparent
    }
  }

  /// Draw image on the canvas.
  Rectangle<double> drawImageOnCanvas(
    CanvasImageSource src, {
    double width,
    double height,
    double aspectRatio,
    double x = 0,
    double y = 0,
    ImageDrawMode mode = ImageDrawMode.STRETCH,
    ImageAlignment alignment = ImageAlignment.START,
  }) {
    _checkContextAvailable();

    Rectangle<double> bounds = layoutImage(
      mode: mode,
      alignment: alignment,
      width: width,
      height: height,
      aspectRatio: aspectRatio,
      x: x,
      y: y,
    );

    _ctx.drawImageToRect(
      src,
      bounds,
    );

    return bounds;
  }

  /// Layout an image correctly using the provided parameters.
  Rectangle<double> layoutImage({
    ImageDrawMode mode = ImageDrawMode.STRETCH,
    ImageAlignment alignment = ImageAlignment.START,
    double width,
    double height,
    double aspectRatio,
    double x = 0,
    double y = 0,
  }) {
    switch (mode) {
      case ImageDrawMode.STRETCH:
        return _stretchLayout.layout(width: width, height: height, aspectRatio: aspectRatio, x: x, y: y, alignment: alignment);
        break;
      case ImageDrawMode.FILL:
        return _fillLayout.layout(width: width, height: height, aspectRatio: aspectRatio, x: x, y: y, alignment: alignment);
        break;
      default:
        throw Exception("Image draw mode unknown");
    }
  }

  /// Set the font settings for the current canvas context.
  void setFont({
    double size = DEFAULT_FONT_SIZE_PX,
    List<String> fontFamilies = const ["sans-serif"],
    TextAlignment alignment = TextAlignment.LEFT,
    TextBaseline baseline = TextBaseline.ALPHABETIC,
  }) {
    _ctx.textAlign = textAlignmentNames[alignment].toLowerCase();
    _ctx.textBaseline = textBaselineNames[baseline].toLowerCase();
    _ctx.font = "${size * window.devicePixelRatio}px ${fontFamilies.join(", ")}";
  }
}

/// Modes how to draw an image.
enum ImageDrawMode {
  FILL,
  STRETCH,
}
