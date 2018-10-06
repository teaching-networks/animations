import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress.dart';

class RouteDrawable extends CanvasDrawable {

  final Progress progress;

  RouteDrawable(this.progress);

  void renderLine(CanvasRenderingContext2D context, Point<double> start, Point<double> end) {
    var startX = start.x;
    var startY = start.y;

    var endX = end.x;
    var endY = end.y;

    // Adjust end coordinates to current progress.
    endX = startX + (endX - startX) * progress.progress;
    endY = startY + (endY - startY) * progress.progress;

    context.beginPath();

    context.moveTo(startX, startY);
    context.lineTo(endX, endY);

    context.stroke();
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    renderLine(context, Point(rect.left, rect.top), Point(rect.left + rect.width, rect.top + rect.height));
  }

}
