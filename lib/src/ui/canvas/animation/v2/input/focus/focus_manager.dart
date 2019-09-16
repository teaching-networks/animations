/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/animation/v2/input/focus/focusable.dart';

/// Class managing the focus within a focused canvas.
class FocusManager {
  /// List of focusable drawables to manage.
  List<FocusableDrawable> _focusables = [];

  /// Index of the currently focused drawable.
  int _focusedIndex = null;

  /// Whether the canvas is currently holding focus.
  bool _isFocused = false;

  /// Check whether the passed [focusable] is already contained in the focus manager.
  bool hasFocusable(FocusableDrawable focusable) {
    return _focusables.contains(focusable);
  }

  /// Add a focusable drawable to the manager.
  void addFocusable(FocusableDrawable focusable) {
    _focusables.add(focusable);

    if (_focusables.length == 1 && _isFocused) {
      _focusedIndex = 0;
      _focusables[_focusedIndex].requestFocus();
    }
  }

  /// Remove a focusable drawable from the manager.
  void removeFocusable(FocusableDrawable focusable) {
    if (_isFocused) {
      int index = _focusables.indexOf(focusable);

      if (_focusedIndex != null && index == _focusedIndex) {
        if (_focusables.length > 1) {
          focusNext();
        } else {
          _focusedIndex = null;
        }
      }
    }

    _focusables.remove(focusable);
  }

  /// Focus the canvas.
  void onCanvasFocused() {
    _isFocused = true;

    // Focus the first focusable drawable (if any).
    if (_focusables.isNotEmpty) {
      focusNext();
    }
  }

  /// Take focus away from the canvas.
  void onCanvasBlurred() {
    if (_focusables.isNotEmpty && _focusedIndex != null) {
      _focusables[_focusedIndex].onBlur();
    }

    _focusedIndex = null;
    _isFocused = false;
  }

  /// Whether the canvas is currently focused.
  bool hasCanvasFocus() {
    return _isFocused;
  }

  /// Focus the next focusable drawable.
  void focusNext() {
    if (_focusables.isNotEmpty && _isFocused && _focusables.length > 1) {
      if (_focusedIndex == null) {
        _focusedIndex = _focusables.length - 1;
      }

      int startIndex = _focusedIndex;
      _focusables[_focusedIndex].onBlur();

      do {
        _focusedIndex++;
        if (_focusedIndex >= _focusables.length) {
          _focusedIndex = 0;
        }

        if (_focusedIndex == startIndex) {
          _focusedIndex = null;
          break;
        }
      } while (!_focusables[_focusedIndex].requestFocus());
    }
  }

  /// Focus the previous focusable drawable.
  void focusPrev() {
    if (_focusables.isNotEmpty && _isFocused && _focusables.length > 1) {
      if (_focusedIndex == null) {
        _focusedIndex = 0;
      }

      int startIndex = _focusedIndex;
      _focusables[_focusedIndex].onBlur();

      do {
        _focusedIndex--;
        if (_focusedIndex < 0) {
          _focusedIndex = _focusables.length - 1;
        }

        if (_focusedIndex == startIndex) {
          _focusedIndex = null;
          break;
        }
      } while (!_focusables[_focusedIndex].requestFocus());
    }
  }
}
