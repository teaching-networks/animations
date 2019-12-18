/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Simple box filled with a color.
/// Mind setting the size of the box by yourself.
class ColorBox extends Drawable {
  /// Color to fill box with.
  final Color color;

  /// Create color box.
  ColorBox({
    Drawable parent,
    this.color = Colors.BLACK,
  }) : super(parent: parent);

  @override
  void draw() {
    setFillColor(color);
    ctx.fillRect(0, 0, size.width, size.height);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Do nothing.
  }
}
