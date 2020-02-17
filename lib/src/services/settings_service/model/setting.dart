/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

/// An app setting.
class Setting<T> {
  /// Key of the setting.
  String key;

  /// Value of the setting.
  T value;

  /// Create empty setting.
  Setting.from(this.key, this.value);
}
