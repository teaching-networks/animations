/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// Item description of the combo box.
class ComboBoxItem<T> {
  /// Label of the item.
  final String label;

  /// The held item object.
  final T obj;

  /// Create item.
  ComboBoxItem({
    this.label,
    this.obj,
  });
}
