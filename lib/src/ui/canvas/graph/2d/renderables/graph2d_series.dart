import 'dart:math';

import 'package:hm_animations/src/ui/canvas/graph/2d/interfaces/graph2d_renderable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/style/graph2d_style.dart';
import 'package:meta/meta.dart';

/// A series of points being shown as a function in the Graph2D component.
class Graph2DSeries implements Graph2DRenderable {
  /// Series of points to show.
  final List<Point<double>> _series;

  /// Style of the series plot.
  final Graph2DStyle _style;

  Graph2DSeries({@required List<Point<double>> series, Graph2DStyle style = const Graph2DStyle()})
      : _series = series,
        _style = style;

  @override
  Graph2DStyle getStyle() => _style;

  @override
  List<Point<double>> getSamples() => _series;
}
