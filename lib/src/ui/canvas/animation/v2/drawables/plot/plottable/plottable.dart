/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/plottable_style.dart';

/// Something that the [Plotter] is able to plot.
abstract class Plottable {
  /// Get the style of the plottable.
  PlottableStyle get style;

  /// Calculate or provide the samples of the graph to plot.
  /// You can just return all points if the plottable is for example a series of fixed points.
  /// The passed attributes [xStart], [xEnd], [count], ... are just recommendations and used
  /// to continuously sample a function.
  List<Point<double>> sample({
    double xStart = 0.0,
    double xEnd = 1.0,
    int count = 10,
  });
}
