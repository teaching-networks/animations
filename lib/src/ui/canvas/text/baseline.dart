/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Text baseline modes.
enum TextBaseline {
  TOP,
  HANGING,
  MIDDLE,
  ALPHABETIC,
  IDEOGRAPHIC,
  BOTTOM,
}

const Map<TextBaseline, String> textBaselineNames = {
  TextBaseline.TOP: "TOP",
  TextBaseline.HANGING: "HANGING",
  TextBaseline.MIDDLE: "MIDDLE",
  TextBaseline.ALPHABETIC: "ALPHABETIC",
  TextBaseline.IDEOGRAPHIC: "IDEOGRAPHIC",
  TextBaseline.BOTTOM: "BOTTOM",
};
