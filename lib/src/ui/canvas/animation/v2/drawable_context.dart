/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

import 'input/focus/focus_manager.dart';

/// Context being shared between dependent drawables.
abstract class DrawableContext {
  /// Get the size of the root canvas.
  Size get rootSize;

  /// Get the focus manager of the drawable hierarchy.
  FocusManager get focusManager;
}

/// Immutable context object that can safely be shared between multiple dependent drawables.
class ImmutableDrawableContext implements DrawableContext {
  /// Size of the root canvas.
  final Size _rootSize;

  /// Focus manager of the drawable hierarchy.
  final FocusManager _focusManager;

  /// Create unmodifiable context.
  ImmutableDrawableContext({
    @required Size rootSize,
    @required FocusManager focusManager,
  })  : _rootSize = rootSize,
        _focusManager = focusManager;

  @override
  Size get rootSize => _rootSize;

  @override
  FocusManager get focusManager => _focusManager;
}

/// Context object that can be modified.
class MutableDrawableContext implements DrawableContext {
  /// Size of the root canvas.
  Size _rootSize;

  /// Focus manager of the drawable hierarchy.
  FocusManager _focusManager;

  /// Create context.
  MutableDrawableContext({
    Size rootSize = const Size.empty(),
    FocusManager focusManager,
  })  : _rootSize = rootSize,
        _focusManager = focusManager;

  @override
  Size get rootSize => _rootSize;

  set rootSize(Size value) {
    _rootSize = value;
  }

  /// Get a immutable instance of this context.
  DrawableContext getImmutableInstance() {
    return ImmutableDrawableContext(
      rootSize: rootSize,
      focusManager: focusManager,
    );
  }

  @override
  FocusManager get focusManager => _focusManager;

  set focusManager(FocusManager focusManager) {
    _focusManager = focusManager;
  }
}
