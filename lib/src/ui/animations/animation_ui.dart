/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';

mixin AnimationUI {
  /// Descriptor of the animation.
  AnimationDescriptor<dynamic> _descriptor;

  /// Get the animation descriptor of the animation.
  AnimationDescriptor<dynamic> get descriptor => _descriptor;

  /// Set the animation descriptor of the animation.
  void set descriptor(AnimationDescriptor<dynamic> value) => _descriptor = value;
}
