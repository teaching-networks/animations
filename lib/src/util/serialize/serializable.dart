/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

abstract class Serializable<T> {
  /// Deserialize type T.
  T fromJson(Map<String, dynamic> json);

  /// Serialize from type T.
  Map<String, dynamic> toJson();
}
