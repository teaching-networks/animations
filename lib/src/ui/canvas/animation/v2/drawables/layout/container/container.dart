/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/layout.dart';

/// A container is a layout which only lays out a single drawable.
abstract class Container extends Layout {
  /// Create container.
  Container({
    Drawable parent,
  }) : super(parent: parent);

  /// Get the child drawable to layout in the container.
  Drawable get child;

  @override
  List<Drawable> get children => [child];
}
