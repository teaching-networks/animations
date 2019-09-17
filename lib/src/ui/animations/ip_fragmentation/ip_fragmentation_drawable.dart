/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/button/button_drawable.dart';

/// Drawable for the IP fragmentation animation.
class IPFragmentationDrawable extends Drawable {
  ButtonDrawable _test;

  /// Create drawable.
  IPFragmentationDrawable() {
    _init();
  }

  /// Initialize the IP fragmentation drawable.
  void _init() {
    _test = ButtonDrawable(parent: this, text: "HI!");
  }

  @override
  void draw() {
    _test.render(ctx, lastPassTimestamp, x: 100, y: 100);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update
  }
}
