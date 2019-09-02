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
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Graph displaying signals for the CDMA animation.
class SignalGraph extends Drawable {
  /// Whether the quadrants should have the same size.
  final bool equalQuadrants;

  /// Signal pattern to display.
  List<double> _signal;

  /// Graph drawable used to draw the signal graph.
  Graph2D _graph2d;

  /// Color of the signal line.
  Color signalColor;

  /// Round rectangle for the background of the signal graph.
  RoundRectangle _roundRect = RoundRectangle(
    paintMode: PaintMode.FILL,
    radiusSizeType: SizeType.PIXEL,
    radius: Edges.all(5),
    color: Color.hex(0xFF555555),
  );

  /// Create signal graph.
  SignalGraph({
    this.equalQuadrants = true,
    Drawable parent,
    List<double> signal,
    this.signalColor = Colors.WHITE,
  }) : super(parent: parent) {
    this.signal = signal;
  }

  List<double> get signal => _signal;

  void set signal(List<double> value) {
    if (value == null) {
      value = [0, 0];
    }
    _signal = value;

    _initGraph();
  }

  /// Initialize the graph.
  _initGraph() {
    List<Point<double>> series = [Point<double>(0, 0)];
    double minY = 0;
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
    double offsetPadding = yOffset * 0.5;
    if (equalQuadrants) {
      maxY = yOffset;
      minY = -yOffset;
    }

    _graph2d = Graph2D(minX: 0, maxX: signal.length, minY: minY - offsetPadding, maxY: maxY + offsetPadding, preCalculationFactor: 0.0);

    // Add x axis
    _graph2d.add(Graph2DSeries(series: [Point<double>(_graph2d.minX, 0), Point<double>(_graph2d.maxX, 0)], style: Graph2DStyle(color: Colors.DARKER_GRAY)));

    // Add grid lines
    for (int x = 0; x < signal.length; x++) {
      _graph2d.add(Graph2DSeries(
          series: [Point<double>(x.toDouble(), _graph2d.minY), Point<double>(x.toDouble(), _graph2d.maxY)], style: Graph2DStyle(color: Colors.GRAY_444)));
    }
    for (int y = minY.toInt(); y < maxY; y++) {
      _graph2d.add(Graph2DSeries(
          series: [Point<double>(_graph2d.minX, y.toDouble()), Point<double>(_graph2d.maxX, y.toDouble())], style: Graph2DStyle(color: Colors.GRAY_444)));
    }

    // Add signal
    _graph2d.add(Graph2DSeries(series: series, style: Graph2DStyle(color: signalColor)));

    invalidate();
  }

  @override
  void draw() {
    _roundRect.render(ctx, Rectangle<double>(0, 0, size.width, size.height));
    _graph2d.render(ctx, Rectangle<double>(0, 0, size.width, size.height));
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update
  }
}
