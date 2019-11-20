/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/plottable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/plottable_style.dart';
import 'package:meta/meta.dart';

/// A plottable series of points.
class PlottableSeries implements Plottable {
  /// Series of points to plot.
  final List<Point<double>> points;

  /// Style of the plot.
  final PlottableStyle _style;

  /// Create a plottable series.
  PlottableSeries({
    @required this.points,
    PlottableStyle style = const PlottableStyle(),
  }) : _style = style;

  @override
  List<Point<double>> sample({double xStart = 0.0, double xEnd = 1.0, int count = 10}) => points;

  @override
  PlottableStyle get style => _style;
}
