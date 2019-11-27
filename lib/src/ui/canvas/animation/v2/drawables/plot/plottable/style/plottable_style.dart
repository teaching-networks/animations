/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Style of a plottable.
class PlottableStyle {
  /// Color of the plottable.
  final Color color;

  /// Width of the line.
  final int lineWidth;

  /// The join type of the line.
  final String lineJoin;

  /// Line cap type.
  final String lineCap;

  /// Create style.
  const PlottableStyle({
    this.color = Colors.BLACK,
    this.lineWidth = 1,
    this.lineJoin = "round",
    this.lineCap = "round",
  });
}
