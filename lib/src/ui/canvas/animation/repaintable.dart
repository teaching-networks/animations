/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

mixin Repaintable {
  /// Whether the repaintable needs to repaint itself the next rendering cycle.
  bool _invalid = true;

  /// Invalidate the repaintable to repaint itself the next rendering cycle.
  void invalidate() {
    _invalid = true;
  }

  /// Validate the repaintable.
  void validate() {
    _invalid = false;
  }

  /// Whether the repaintable needs to be repainted.
  bool get needsRepaint => _invalid;
}
