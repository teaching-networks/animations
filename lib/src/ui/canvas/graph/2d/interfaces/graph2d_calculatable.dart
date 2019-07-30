/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:math';

/// The "real" function.
typedef num ValueProcessor(num x);

/// Graph component which is calculatable.
abstract class Graph2DCalculatable {
  /// Cached values (To improve performance since we do not have to always recalculate the values).
  List<Point<double>> _cache;

  /// Get the processor delivering a y-value to each x-value.
  ValueProcessor getProcessor();

  /// Get cached values.
  List<Point<double>> get cached => _cache;

  /// Set cached values.
  void set cached(List<Point<double>> cache) => _cache = cache;
}
