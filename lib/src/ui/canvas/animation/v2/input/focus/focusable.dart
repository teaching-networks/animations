/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Interface representing something that can get focus (and lose it).
abstract class FocusableDrawable {
  /// Called when the focusable gets focused.
  /// Returns whether the focus request has been accepted.
  bool requestFocus();

  /// Called when the focus is lost.
  void onBlur();

  /// Whether the focusable is currently focused.
  bool hasFocus();
}
