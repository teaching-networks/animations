/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Text alignment modes.
enum TextAlignment {
  LEFT,
  CENTER,
  RIGHT,
}

const Map<TextAlignment, String> textAlignmentNames = {
  TextAlignment.LEFT: "LEFT",
  TextAlignment.CENTER: "CENTER",
  TextAlignment.RIGHT: "RIGHT",
};
