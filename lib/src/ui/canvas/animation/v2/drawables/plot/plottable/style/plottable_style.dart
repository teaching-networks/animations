/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/line/line_style.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/point/point_style.dart';

/// Style of a plottable.
class PlottableStyle {
  /// Style of the plottable line or null if no line should be drawn.
  final LineStyle line;

  /// Style of the plottable points or null if no points should be drawn.
  final PointStyle points;

  /// Create style.
  const PlottableStyle({
    this.line = const LineStyle(),
    this.points = null,
  });
}
