/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/slider/slider_drawable.dart';

/// The root drawable of the buffering animation.
class BufferingAnimationDrawable extends Drawable {
  SliderDrawable test;

  BufferingAnimationDrawable() {
    test = SliderDrawable(parent: this);
  }

  @override
  void draw() {
    test.render(ctx, lastPassTimestamp, x: 100, y: 100);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update.
  }
}
