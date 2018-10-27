import 'dart:html';
import 'dart:math';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:vector_math/vector_math.dart' as vec;

class RouteDrawable extends CanvasDrawable {
  final Progress progress;
  Color color;
  bool curved;

  RouteDrawable(this.progress, {
    this.color = Colors.SLATE_GREY,
    this.curved = true
  });

  void renderLine(CanvasRenderingContext2D context, Point<double> start, Point<double> end) {
    context.save();

    if (color != null) {
      setStrokeColor(context, color);
    }

    var gradient = context.createLinearGradient(start.x, start.y, end.x, end.y);
    gradient.addColorStop(0.0, color.toCSSColorString());
    gradient.addColorStop(progress.progress, color.toCSSColorString());
    gradient.addColorStop(progress.progress, "transparent");
    gradient.addColorStop(1.0, "transparent");

    context.strokeStyle = gradient;

    var startX = start.x;
    var startY = start.y;

    var endX = end.x;
    var endY = end.y;

    if (curved) {
      var lineVector = vec.Vector2(endX - startX, endY - startY);
      var perpendicular = lineVector.scaleOrthogonalInto(0.05, vec.Vector2.all(0.0));

      var midX = (startX + endX) / 2;
      var midY = (startY + endY) / 2;

      perpendicular.add(vec.Vector2(midX, midY));

      var controlPointX = perpendicular.x;
      var controlPointY = perpendicular.y;


      context.beginPath();

      context.moveTo(startX, startY);
      context.bezierCurveTo(controlPointX, controlPointY, controlPointX, controlPointY, endX, endY);

      context.stroke();
    } else {
      context.beginPath();

      context.moveTo(startX, startY);
      context.lineTo(endX, endY);

      context.stroke();
    }

    context.restore();
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    renderLine(context, Point(rect.left, rect.top), Point(rect.left + rect.width, rect.top + rect.height));
  }
}
