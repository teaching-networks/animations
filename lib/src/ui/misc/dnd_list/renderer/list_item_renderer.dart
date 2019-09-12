/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// List item renderer used to show a list item.
abstract class ListItemRenderer<T> {
  /// Set the [item] to render.
  void setItem(T item);
}
