/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

/// Something that the [Plotter] is able to plot.
abstract class Plottable {
  /// Calculate or provide the samples of the graph to plot.
  /// You can just return all points if the plottable is for example a series of fixed points.
  /// The passed attributes [xStart], [xEnd], [count], ... are just recommendations and used
  /// to continuously sample a function.
  List<Point<double>> sample({
    double xStart = 0.0,
    double xEnd = 1.0,
    int count = 10,
  });

  /// Draw the plottable.
  void draw(CanvasRenderingContext2D ctx, List<Point<double>> coordinates) {
    ctx.beginPath();

    Point<double> p = coordinates.first;
    ctx.moveTo(p.x, p.y);
    for (int i = 1; i < coordinates.length; i++) {
      p = coordinates[i];
      ctx.lineTo(p.x, p.y);
    }

    ctx.stroke();
  }
}
