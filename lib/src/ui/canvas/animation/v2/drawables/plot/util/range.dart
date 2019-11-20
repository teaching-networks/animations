/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:meta/meta.dart';

/// A range representation between two values.
class Range<T extends num> {
  /// The current minimum value.
  T _min;

  /// The current maximum value.
  T _max;

  /// Create range.
  Range({
    @required T min,
    @required T max,
  })  : _min = min,
        _max = max;

  /// Get the current minimum value.
  T get min => _min;

  /// Set the current minimum value.
  void set min(T newMin) => _min = newMin;

  /// Get the current maximum value.
  T get max => _max;

  /// Set the new maximum value.
  void set max(T newMax) => _max = newMax;

  /// Get the length of the range.
  T get length => max - min;
}
