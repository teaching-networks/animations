/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/line_plottable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/plot/plottable/style/plottable_style.dart';
import 'package:tuple/tuple.dart';

/// An animated series plottable.
class AnimatedPlottableSeries extends LinePlottable {
  /// Generator of the series to plot.
  final Iterator<Tuple2<Iterable<Point<double>>, Duration>> seriesGenerator;

  /// Grow series by 1 every elapsed [_growDuration].
  Duration _growDuration;

  /// Timestamp of the last series point generation.
  num _lastGenerateTimestamp;

  /// Next point in the series. But not yet in the series!
  Iterable<Point<double>> _tmpNext;

  /// Series to plot.
  List<Point<double>> _series = new List<Point<double>>();

  /// Number of generator calls up to now.
  int _generatedCount = 0;

  /// Create plottable.
  AnimatedPlottableSeries({
    this.seriesGenerator,
    PlottableStyle style = const PlottableStyle(),
  }) : super(style: style) {
    _init();
  }

  /// Initialize the series.
  void _init() {
    num currentTimestamp = window.performance.now();

    // Generate the first two points of the series (one added to the series, the other one still yet to be added).
    var firstTuple = _generateNext(currentTimestamp: currentTimestamp);
    _series.addAll(firstTuple.item1);
    _series.add(_series.last); // Add fake point to animate

    var nextTuple = _generateNext(currentTimestamp: currentTimestamp);
    _tmpNext = nextTuple.item1;
    _growDuration = nextTuple.item2;
  }

  @override
  List<Point<double>> sample({double xStart = 0.0, double xEnd = 1.0, int count = 10}) => _series;

  @override
  bool get animated => true;

  @override
  bool update(num timestamp) {
    num diff = timestamp - _lastGenerateTimestamp;
    double progress = diff / _growDuration.inMilliseconds;

    if (progress >= 1.0) {
      if (progress.isInfinite) {
        progress = 1.0;
      }

      // Generate new point in series
      int count = progress.toInt();
      progress -= count; // Adjust progress for later last point adjustments

      _series.removeLast();
      _series.addAll(_tmpNext);
      var nextTuple = _generateNext(currentTimestamp: timestamp);
      _tmpNext = nextTuple.item1;
      _growDuration = nextTuple.item2;
      _series.add(_series.last); // Add fake point again
    }

    _adjustLastPoint(progress);

    return true;
  }

  /// Generate the next point in the series.
  Tuple2<Iterable<Point<double>>, Duration> _generateNext({num currentTimestamp}) {
    _lastGenerateTimestamp = currentTimestamp;

    seriesGenerator.moveNext();
    _generatedCount++;
    return seriesGenerator.current;
  }

  /// Adjust the last point in the series.
  void _adjustLastPoint(double progress) {
    Point<double> lastCorrect = _series[_series.length - 2];

    _series.last = Point<double>(
      lastCorrect.x + (_tmpNext.first.x - lastCorrect.x) * progress,
      lastCorrect.y + (_tmpNext.first.y - lastCorrect.y) * progress,
    );
  }

  /// Get the next point of the series currently in animation.
  Iterable<Point<double>> get next => _tmpNext;

  /// Get the current count of generator calls.
  int get generatedCount => _generatedCount;
}
