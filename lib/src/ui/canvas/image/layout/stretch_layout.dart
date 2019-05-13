import 'dart:math';

import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/image/layout/image_layout.dart';
import 'package:meta/meta.dart';

/// Lays the image out as it is.
/// This layout does not take care of an aspect ratio, so the image might be stretched.
class StretchImageLayout implements ImageLayout {
  const StretchImageLayout();

  @override
  Rectangle<double> layout({
    @required double width,
    @required double height,
    double x = 0,
    double y = 0,
    double aspectRatio,
    ImageAlignment alignment,
  }) {
    return Rectangle<double>(x, y, width, height);
  }
}
