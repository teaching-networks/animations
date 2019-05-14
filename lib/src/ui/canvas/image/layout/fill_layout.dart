import 'dart:math';

import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/image/layout/image_layout.dart';

/// Lays out the image according to its aspect ratio.
class FillImageLayout implements ImageLayout {
  const FillImageLayout();

  @override
  Rectangle<double> layout({
    double width,
    double height,
    double x = 0,
    double y = 0,
    double aspectRatio,
    ImageAlignment alignment = ImageAlignment.START,
  }) {
    // Try to fill missing information (width, height & aspectRatio).
    bool align = false; // Whether alignment is needed
    if (aspectRatio == null) {
      aspectRatio = width / height;
    } else {
      if (width == null) {
        width = height * aspectRatio;
      } else if (height == null) {
        height = width / aspectRatio;
      } else if (width == null && height == null) {
        throw Exception("Missing information when laying out an image. Missing width or height.");
      } else {
        align = true;
      }
    }

    if (align) {
      // Check if image needs to be scaled
      double iW = height * aspectRatio;
      double iH = width / aspectRatio;

      if (iW > width) {
        double shrink = width / iW;
        iW = iW * shrink;
      }

      if (iH > height) {
        double shrink = height / iH;
        iH = iH * shrink;
      }

      var vertical = height >= iH;

      // Align
      switch (alignment) {
        case ImageAlignment.START:
          return Rectangle<double>(x, y, iW, iH);
        case ImageAlignment.MID:
          return vertical ? Rectangle<double>(x, y + (height - iH) / 2, iW, iH) : Rectangle<double>(x + (width - iW) / 2, y, iW, iH);
        case ImageAlignment.END:
          return vertical ? Rectangle<double>(x, y + height - iH, iW, iH) : Rectangle<double>(x + width - iW, y, iW, iH);
        default:
          throw Exception("Image alignment not supported");
      }
    }

    return Rectangle<double>(x, y, width, height);
  }
}
