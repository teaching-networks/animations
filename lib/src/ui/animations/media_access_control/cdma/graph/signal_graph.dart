/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/graph2d.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/renderables/graph2d_series.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/style/graph2d_style.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

/// Graph displaying signals for the CDMA animation.
class SignalGraph extends Drawable {
  /// Signal pattern to display.
  final List<double> signal;

  /// Graph drawable used to draw the signal graph.
  Graph2D _graph2d;

  /// Create signal graph.
  SignalGraph({
    Drawable parent,
    @required this.signal,
  }) : super(parent: parent) {
    _initGraph();

    setSize(width: 600, height: 300);
  }

  /// Initialize the graph.
  _initGraph() {
    List<Point<double>> series = [Point<double>(0, 0)];
    double minY = -1;
    double maxY = 1;
    for (int i = 0; i < signal.length; i++) {
      double v = signal[i];

      series.add(Point<double>(i.toDouble(), v));
      series.add(Point<double>((i + 1).toDouble(), v));

      if (v > maxY) {
        maxY = v;
      }
      if (v < minY) {
        minY = v;
      }
    }
    series.add(Point<double>(signal.length.toDouble(), 0));
    double yOffset = (minY.abs() > maxY.abs() ? minY : maxY).abs();
    double offsetPadding = yOffset * 0.05;

    _graph2d = Graph2D(minX: 0, maxX: signal.length, minY: -yOffset - offsetPadding, maxY: yOffset + offsetPadding, preCalculationFactor: 0.0);

    // Add x and y axis
    _graph2d.add(Graph2DSeries(series: [Point<double>(_graph2d.minX, 0), Point<double>(_graph2d.maxX, 0)], style: Graph2DStyle(color: Colors.LIGHTGREY)));
    _graph2d.add(Graph2DSeries(
        series: [Point<double>(_graph2d.maxX / 2, _graph2d.maxY), Point<double>(_graph2d.maxX / 2, _graph2d.minY)],
        style: Graph2DStyle(color: Colors.LIGHTGREY)));

    // Add signal
    _graph2d.add(Graph2DSeries(series: series));
  }

  @override
  void draw() {
    double borderSize = 2;
    _graph2d.render(ctx, Rectangle<double>(borderSize, borderSize, size.width - borderSize * 2, size.height - borderSize * 2));

    ctx.lineWidth = borderSize;
    ctx.strokeRect(0, 0, size.width, size.height);
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update
  }
}
