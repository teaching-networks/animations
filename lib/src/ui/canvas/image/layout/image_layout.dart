import 'dart:math';

import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';

/// Layout an image with one of these classes.
abstract class ImageLayout {
  /// Lay out the image.
  Rectangle<double> layout({
    double width,
    double height,
    double x,
    double y,
    double aspectRatio,
    ImageAlignment alignment,
  });
}
