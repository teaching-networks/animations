/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Style of the axis of a coordinate system for a plot.
class AxisStyle {
  /// Color of the axis.
  final Color color;

  /// Label of the axis.
  final String label;

  /// Color of the label.
  final Color labelColor;

  /// Width of the axis line.
  final double lineWidth;

  /// Size of the arrow head.
  final double arrowHeadSize;

  /// Create axis style.
  const AxisStyle({
    this.color = Colors.BLACK,
    this.label = "",
    this.labelColor = Colors.BLACK,
    this.lineWidth = 1,
    this.arrowHeadSize = 16,
  });
}
