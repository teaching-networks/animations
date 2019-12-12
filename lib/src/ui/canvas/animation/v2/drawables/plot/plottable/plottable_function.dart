/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/line_plottable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/plottable_style.dart';

typedef double Fct(double x);

/// Function which is plottable.
class PlottableFunction extends LinePlottable {
  /// Function used to process values.
  final Fct fct;

  /// Create a plottable function.
  PlottableFunction({
    this.fct,
    PlottableStyle style = const PlottableStyle(),
  }) : super(style: style);

  @override
  List<Point<double>> sample({
    double xStart = 0.0,
    double xEnd = 1.0,
    int count = 10,
  }) {
    final xInc = (xEnd - xStart) / count;
    var curX = xStart;

    return List.generate(count, (index) {
      final p = Point<double>(curX, fct(curX));
      curX += xInc;
      return p;
    });
  }
}
