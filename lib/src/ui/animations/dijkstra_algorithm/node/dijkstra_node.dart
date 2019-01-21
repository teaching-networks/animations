import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:meta/meta.dart';

/// Node of the dijkstra animation.
class DijkstraNode extends CanvasDrawable {
  /// Size of the node.
  final double size;

  /// Position of the node on the canvas.
  /// The coordinates are given in range [0.0, 1.0].
  final Point<double> coordinates;

  /// Create node.
  DijkstraNode({
    @required this.size,
    @required this.coordinates,
  });

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();
    context.translate(rect.left, rect.top);

    double x = coordinates.x * rect.width;
    double y = coordinates.y * rect.width;

    context.lineWidth = window.devicePixelRatio * 2;
    context.beginPath();
    context.arc(x, y, size / 2, 0, 2 * pi);
    context.stroke();

    context.beginPath();
    context.arc(x, y, size / 4, 0, 2 * pi);
    context.fill();

    context.restore();
  }
}
