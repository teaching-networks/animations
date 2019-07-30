/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/graph/2d/interfaces/graph2d_calculatable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/interfaces/graph2d_renderable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/style/graph2d_style.dart';
import 'package:meta/meta.dart';

/// Simple function displayable in a Graph2D.
class Graph2DFunction extends Graph2DCalculatable implements Graph2DRenderable {
  /// [processor] is calculating the y values by a x value.
  final ValueProcessor _processor;

  /// [style] of the graph (color, etc.).
  final Graph2DStyle _style;

  Graph2DFunction({@required ValueProcessor processor, Graph2DStyle style = const Graph2DStyle()})
      : _processor = processor,
        _style = style;

  @override
  Graph2DStyle getStyle() => _style;

  @override
  ValueProcessor getProcessor() => _processor;

  @override
  List<Point<double>> getSamples() => cached;
}
