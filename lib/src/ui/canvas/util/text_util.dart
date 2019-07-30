/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

/// Utility class easing text handling while using canvas 2D.
class TextUtil {
  /// Wrap the passed [text] so that it wraps when it exceeds the passed [maxWidth].
  static List<String> wrapText(CanvasRenderingContext2D context, String text, double maxWidth) {
    double textWidth = context.measureText(text).width;

    int lines = (textWidth / maxWidth).ceil();
    int charsPerLine = (text.length / lines).ceil();

    int startIndex = 0;
    int lastIndexOf = -1;

    List<String> lineStrings = List<String>();

    int indexOf = text.indexOf(" ", startIndex);
    while (indexOf != -1) {
      if (indexOf - startIndex > charsPerLine) {
        // Add new line from startIndex to lastIndexOf
        lineStrings.add(text.substring(startIndex, lastIndexOf).trim());
        startIndex = lastIndexOf;
      }

      lastIndexOf = indexOf;
      indexOf = text.indexOf(" ", indexOf + 1);
    }

    // Append rest of the text
    if (indexOf == -1) {
      lineStrings.add(text.substring(startIndex).trim());
    }

    return lineStrings;
  }
}
