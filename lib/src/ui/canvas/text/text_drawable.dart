import 'dart:html';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';

/// Drawable displaying text.
class TextDrawable extends Drawable {
  /// Text to show in the drawable.
  String _text;

  /// At which string length to wrap the text.
  final int wrapAtLength;

  /// Text size of the text to draw.
  final double textSize;

  /// Line height factor of the text to draw.
  final double lineHeight;

  /// Font families to use (separated by comma).
  /// For example: "Arial, sans-serif".
  final String fontFamilies;

  /// Color of the text.
  final Color color;

  /// Alignment of the text.
  final TextAlignment alignment;

  List<String> _lines;
  String _longestLine;

  /// Create drawable.
  TextDrawable(
    Drawable parent, {
    String text = "[No Text provided]",
    this.wrapAtLength = 50,
    this.fontFamilies = "sans-serif",
    this.textSize,
    this.lineHeight = 1.2,
    this.color = Colors.BLACK,
    this.alignment = TextAlignment.CENTER,
  })  : _text = text,
        super(parent) {
    _init();
  }

  /// Initializing drawable.
  void _init() {
    _lines = _buildLines(_text, wrapAtLength);
    _longestLine = _getLongestLine(_lines);

    _calculateSize();

    invalidate();
  }

  String get text => _text;

  set text(String value) {
    _text = value;

    _init();
  }

  void _initFont(double fontSize) {
    ctx.textBaseline = "top";
    ctx.textAlign = _getTextAlignmentString(alignment);
    ctx.font = "${fontSize}px $fontFamilies";
  }

  String _getTextAlignmentString(TextAlignment alignment) {
    switch (alignment) {
      case TextAlignment.LEFT:
        return "left";
      case TextAlignment.RIGHT:
        return "right";
      case TextAlignment.CENTER:
        return "center";
      default:
        return "center";
    }
  }

  /// Calculate the size of the drawable.
  void _calculateSize() {
    double fontSize = textSize != null ? this.textSize : defaultFontSize;

    _initFont(fontSize);

    final textBoundsSize = _calculateTextSize(ctx, defaultFontSize);

    setSize(
      width: textBoundsSize.width,
      height: textBoundsSize.height,
    );
  }

  @override
  void draw() {
    double xOffset = _getXOffsetForAlignment(alignment);

    _initFont(textSize != null ? this.textSize : defaultFontSize);
    setFillColor(color);

    double lineOffset = size.height / _lines.length;

    double offsetY = 0;
    for (final line in _lines) {
      ctx.fillText(line, xOffset, offsetY);

      offsetY += lineOffset;
    }
  }

  double _getXOffsetForAlignment(TextAlignment alignment) {
    switch (alignment) {
      case TextAlignment.LEFT:
        return 0;
      case TextAlignment.RIGHT:
        return size.width;
      case TextAlignment.CENTER:
        return size.width / 2;
      default:
        return size.width / 2;
    }
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // Nothing to update
  }

  Size _calculateTextSize(CanvasRenderingContext2D context, double fontSize) {
    var metrics = context.measureText(_longestLine);

    var width = metrics.width;

    var lineH = fontSize * lineHeight;
    var height = lineH * _lines.length;

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

enum TextAlignment {
  LEFT,
  CENTER,
  RIGHT,
}
