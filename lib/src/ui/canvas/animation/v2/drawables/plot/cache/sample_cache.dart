/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/plottable.dart';
import 'package:meta/meta.dart';

/// Cache for samples.
class SampleCache extends Plottable {
  /// Plottable to cache samples for.
  final Plottable plottable;

  /// Minimum x value which is currently cached or null if none is cached.
  double _xMin;

  /// Maximum x value which is currently cached or null if none is cached.
  double _xMax;

  /// Cached amount of samples.
  int _cachedCount = 0;

  /// Currently cached samples.
  List<Point<double>> _cached;

  /// Create the sample cache.
  SampleCache({
    @required this.plottable,
  });

  @override
  List<Point<double>> sample({double xStart = 0.0, double xEnd = 1.0, int count = 10}) {
    bool refresh = plottable.animated || xStart != _xMin || xEnd != _xMax || count != _cachedCount;

    if (refresh) {
      _cached = plottable.sample(
        xStart: xStart,
        xEnd: xEnd,
        count: count,
      );

      _xMin = xStart;
      _xMax = xEnd;
      _cachedCount = count;
    }

    return _cached;
  }

  /// Clear the cache.
  void clear() {
    _xMin = null;
    _xMax = null;
    _cachedCount = 0;
    _cached = null;
  }

  @override
  void draw(CanvasRenderingContext2D ctx, List<Point<double>> coordinates) {
    plottable.draw(ctx, coordinates);
  }

  @override
  bool get animated => super.animated;

  @override
  bool requestUpdate(num timestamp) {
    return plottable.requestUpdate(timestamp);
  }
}
