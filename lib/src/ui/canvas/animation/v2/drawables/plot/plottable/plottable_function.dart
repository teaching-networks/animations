/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/plottable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/plottable_style.dart';

typedef double Fct(double x);

/// Function which is plottable.
class PlottableFunction extends Plottable {
  /// Function used to process values.
  final Fct fct;

  PlottableStyle _style;

  /// Create a plottable function.
  PlottableFunction({
    this.fct,
    PlottableStyle style = const PlottableStyle(),
  }) : _style = style;

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

  @override
  void draw(CanvasRenderingContext2D ctx, List<Point<double>> coordinates) {
    ctx.setStrokeColorRgb(_style.color.red, _style.color.green, _style.color.blue, _style.color.alpha);

    ctx.lineWidth = _style.lineWidth * window.devicePixelRatio;
    ctx.lineJoin = _style.lineJoin;
    ctx.lineCap = _style.lineCap;

    super.draw(ctx, coordinates);
  }
}
