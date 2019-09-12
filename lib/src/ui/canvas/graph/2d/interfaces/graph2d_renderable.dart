/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/graph/2d/style/graph2d_style.dart';

/// Graph component which is renderable.
abstract class Graph2DRenderable {
  /// Get the style for the plot.
  Graph2DStyle getStyle();

  /// Get the samples to draw on the Graph2D.
  List<Point<double>> getSamples();
}
