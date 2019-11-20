/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/util/range.dart';
import 'package:meta/meta.dart';

/// Representation of a 2-dimensional coordinate system.
class CoordinateSystem2D {
  /// The x axis range.
  final Range<double> xRange;

  /// The y axis range.
  final Range<double> yRange;

  /// Create coordinate system.
  CoordinateSystem2D({
    @required this.xRange,
    @required this.yRange,
  });
}
