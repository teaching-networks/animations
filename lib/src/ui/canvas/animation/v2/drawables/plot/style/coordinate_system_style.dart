/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/axis_style.dart';

/// Style of a plots coordinate system.
class CoordinateSystemStyle {
  /// Style of the x axis.
  final AxisStyle xAxis;

  /// Style of the y axis.
  final AxisStyle yAxis;

  /// Create coordinate system style.
  const CoordinateSystemStyle({
    this.xAxis = const AxisStyle(),
    this.yAxis = const AxisStyle(),
  });
}
