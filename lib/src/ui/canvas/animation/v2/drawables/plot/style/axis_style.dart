/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/style/tick_style.dart';
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

  /// Padding between axis and graph.
  final double padding;

  /// Style of the ticks to show (or null if no ticks to show).
  final TickStyle ticks;

  /// Create axis style.
  const AxisStyle({
    this.color = Colors.BLACK,
    this.label = "",
    this.labelColor = Colors.BLACK,
    this.lineWidth = 1,
    this.arrowHeadSize = 16,
    this.padding = 10,
    this.ticks,
  });
}
