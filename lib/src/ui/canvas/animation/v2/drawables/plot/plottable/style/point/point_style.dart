/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

import 'point_painter.dart';

/// Style of the points in a plottable.
class PointStyle {
  /// Color of the points.
  final Color color;

  /// Size of the points.
  final int size;

  /// Painter to use to draw the points.
  final PointPainter painter;

  /// Create point style.
  PointStyle({
    this.color = Colors.BLACK,
    this.size = 4,
    @required this.painter,
  });
}
