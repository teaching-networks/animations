/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/line_plottable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/plottable_style.dart';
import 'package:meta/meta.dart';

/// A plottable series of points.
class PlottableSeries extends LinePlottable {
  /// Series of points to plot.
  final List<Point<double>> points;

  /// Create a plottable series.
  PlottableSeries({
    @required this.points,
    PlottableStyle style = const PlottableStyle(),
  }) : super(style: style);

  @override
  List<Point<double>> sample({double xStart = 0.0, double xEnd = 1.0, int count = 10}) => points;
}
