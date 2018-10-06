import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';

class Bubble extends CanvasDrawable {

  /// Text to show in the bubble.
  final String text;

  /// At which string length to wrap the text.
  final int wrapAtLength;

  RoundRectangle _bubbleRect =
      new RoundRectangle(color: Color.opacity(Colors.SLATE_GREY, 0.5), paintMode: PaintMode.FILL, radius: Edges.all(0.2), radiusSizeType: SizeType.PERCENT);

  List<String> _lines;
  String _longestLine;

  Bubble(this.text, this.wrapAtLength) {
    _lines = _buildLines(text, wrapAtLength);
    _longestLine = _getLongestLine(_lines);
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    var textSize = _calculateTextSize(context);

    double paddingX = defaultFontSize * 2;
    double paddingY = defaultFontSize;
    var bubbleBounds = Rectangle<double>(0.0, 0.0, textSize.width + paddingX, textSize.height + paddingY);

    double arrowSize = defaultFontSize;

    context.save();

    {
      context.translate(rect.left - bubbleBounds.width / 2, rect.top - bubbleBounds.height - arrowSize);

      context.textBaseline = "middle";
      context.textAlign = "center";

      // Draw bubble (background)
      _bubbleRect.render(context, bubbleBounds);

      context.translate(bubbleBounds.width / 2, paddingY);

      // Draw arrow
      setFillColor(context, _bubbleRect.color);
      context.beginPath();
      context.moveTo(0.0, textSize.height + arrowSize);
      context.lineTo(-arrowSize / 2, textSize.height);
      context.lineTo(arrowSize / 2, textSize.height);
      context.fill();

      // Draw text
      setFillColor(context, Colors.WHITE);

      double lineOffset = textSize.height / _lines.length;

      double offsetY = 0.0;
      for (var line in _lines) {
        context.fillText(line, 0.0, offsetY);

        offsetY += lineOffset;
      }
    }

    context.restore();
  }

  Size _calculateTextSize(CanvasRenderingContext2D context) {
    var metrics = context.measureText(_longestLine);

    var width = metrics.width;
    
    var lineHeight = defaultFontSize;
    var height = lineHeight * _lines.length;

    return Size(width, height);
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

  String _getLongestLine(List<String> lines) {
    int maxLength = 0;
    String maxLine;

    for (var line in lines) {
      if (maxLine == null || line.length > maxLength) {
        maxLength = line.length;
        maxLine = line;
      }
    }

    return maxLine;
  }
}
