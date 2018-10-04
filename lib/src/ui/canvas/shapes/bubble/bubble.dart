import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

class Bubble extends CanvasDrawable {
  /// Text to show in the bubble.
  final String text;

  /// At which string length to wrap the text.
  final int wrapAtLength;

  RoundRectangle _bubbleRect =
      new RoundRectangle(color: Colors.SLATE_GREY, paintMode: PaintMode.FILL, radius: Edges.all(0.2), radiusSizeType: SizeType.PERCENT, strokeWidth: 1.0);

  List<String> _lines;

  Bubble(this.text, this.wrapAtLength) {
    _lines = _buildLines(text, wrapAtLength);
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    Rectangle<double> bubbleRect = _getBubbleSize(context);

    context.save();

    {
      context.translate(rect.left, rect.top);

      _bubbleRect.render(context, bubbleRect);

      setFillColor(context, Colors.BLACK);
      context.fillText(text, rect.left, rect.top);
    }

    context.restore();
  }

  Rectangle<double> _getBubbleSize(CanvasRenderingContext2D context) {
    int length = text.length;

    int lines = 1;
    if (length > wrapAtLength) {

    }
    context.measureText(text).width;
  }

  List<String> _buildLines(String text, int wrapAtLength) {
    List<String> words = text.split(" ");

    var lines = List<String>();

    var lineBuffer = new StringBuffer();
    int lineLength = 0;
    for (var word in words) {
      if (lineLength > wrapAtLength) {
        lines.add(lineBuffer.toString());
        lineBuffer.clear();
        lineLength = 0;
      }

      lineBuffer.write(word + " ");

      lineLength += word.length;
    }

    lines.add(lineBuffer.toString());

    return lines;
  }
}
