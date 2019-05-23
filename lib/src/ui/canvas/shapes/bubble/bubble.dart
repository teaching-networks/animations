import 'dart:html';
import 'dart:math';

import 'package:angular_components/laminate/enums/alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/repaintable.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';

class Bubble extends CanvasDrawable with Repaintable {
  /// Text to show in the bubble.
  final String text;

  /// At which string length to wrap the text.
  final int wrapAtLength;
  final Color color;

  final Alignment alignment;

  RoundRectangle _bubbleRect;

  List<String> _lines;
  String _longestLine;

  CanvasElement _cacheCanvas = CanvasElement();
  CanvasRenderingContext2D _cacheContext;
  Rectangle<double> _cacheBounds;

  Bubble(
    this.text,
    this.wrapAtLength, {
    this.color = Colors.SLATE_GREY,
    this.alignment = Alignment.Center,
  }) {
    _lines = _buildLines(text, wrapAtLength);
    _longestLine = _getLongestLine(_lines);

    _bubbleRect = RoundRectangle(color: Color.opacity(this.color, 0.5), paintMode: PaintMode.FILL, radius: Edges.all(0.2), radiusSizeType: SizeType.PERCENT);

    _cacheCanvas.width = 1000;
    _cacheCanvas.height = 1000;
    _cacheContext = _cacheCanvas.getContext("2d");
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (needsRepaint) {
      _cacheBounds = _renderBubble(_cacheContext);
    }

    context.drawImageToRect(
      _cacheCanvas,
      Rectangle<double>(rect.left - _cacheBounds.left, rect.top - _cacheBounds.top, _cacheBounds.width, _cacheBounds.height),
    );
  }

  Rectangle<double> _renderBubble(CanvasRenderingContext2D context) {
    context.font = "${defaultFontSize}px sans-serif";
    final textSize = _calculateTextSize(context, defaultFontSize);

    double paddingX = defaultFontSize * 2;
    double paddingY = defaultFontSize;
    final bubbleBounds = Rectangle<double>(0.0, 0.0, textSize.width + paddingX, textSize.height + paddingY);

    double arrowSize = defaultFontSize;

    _cacheCanvas.width = bubbleBounds.width.toInt();
    _cacheCanvas.height = (bubbleBounds.height + arrowSize).toInt();

    context.textBaseline = "middle";
    context.textAlign = "center";
    context.font = "${defaultFontSize}px sans-serif";

    _bubbleRect.render(context, bubbleBounds);

    // Draw arrow
    Point<double> arrowPoint;
    if (alignment == Alignment.Center) {
      arrowPoint = _drawArrow(context, bubbleBounds.width / 2, paddingY + textSize.height, arrowSize);
    } else if (alignment == Alignment.Before || alignment == Alignment.Start) {
      arrowPoint = _drawArrow(context, paddingY + arrowSize / 2, paddingY + textSize.height, arrowSize);
    } else {
      arrowPoint = _drawArrow(context, bubbleBounds.width - paddingY - arrowSize / 2, paddingY + textSize.height, arrowSize);
    }

    context.translate(bubbleBounds.width / 2, paddingY);
    // Draw text
    setFillColor(context, Colors.WHITE);

    double lineOffset = textSize.height / _lines.length;

    double offsetY = 0.0;
    for (var line in _lines) {
      context.fillText(line, 0.0, offsetY);

      offsetY += lineOffset;
    }

    return Rectangle<double>(arrowPoint.x, arrowPoint.y, bubbleBounds.width, bubbleBounds.height + arrowSize);
  }

  Point<double> _drawArrow(CanvasRenderingContext2D context, double x, double y, double size) {
    Point<double> pointsTo = Point<double>(x, y + size);

    setFillColor(context, _bubbleRect.color);
    context.beginPath();
    context.moveTo(pointsTo.x, pointsTo.y);
    context.lineTo(x - size / 2, y);
    context.lineTo(x + size / 2, y);
    context.fill();

    return pointsTo;
  }

  Size _calculateTextSize(CanvasRenderingContext2D context, double fontSize) {
    var metrics = context.measureText(_longestLine);

    var width = metrics.width;

    var lineHeight = fontSize;
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
