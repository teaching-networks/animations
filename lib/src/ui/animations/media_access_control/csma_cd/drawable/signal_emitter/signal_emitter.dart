import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/geometric_location.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

/// Drawable similar to PacketLine but vertical and emits in both directions from the starting point.
class SignalEmitter extends CanvasDrawable {
  /// From which point to start the signal emitting.
  final double start;

  /// Duration until the signal stops.
  final Duration signalDuration;

  /// Speed of the propagation of the signal in percent per second (e. g. 1.0 == 100% per second).
  final double propagationSpeed;

  /// Geometric location
  final GeometricLocation geometricLocation;

  /// Start timestamp of the animation.
  num _startTimestamp = -1;

  /// Create signal emitter.
  SignalEmitter({
    @required this.start,
    @required this.signalDuration,
    @required this.propagationSpeed,
    @required this.geometricLocation,
  });

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (_startTimestamp == -1) {
      _startTimestamp = timestamp;

      return;
    }

    final diff = timestamp - _startTimestamp;

    final propagationProgress = diff / 1000 * propagationSpeed;
    final signalProgress = diff / signalDuration.inMilliseconds;

    Tuple2<double, double> range1 = _calculateSignalRange(
      propagationProgress: propagationProgress,
      signalProgress: signalProgress,
      extrema: 0.0,
    );

    Tuple2<double, double> range2 = _calculateSignalRange(
      propagationProgress: propagationProgress,
      signalProgress: signalProgress,
      extrema: 1.0,
    );
  }

  /// Calculate a signal range.
  Tuple2<double, double> _calculateSignalRange({
    @required final double propagationProgress,
    @required final double signalProgress,
    @required final double extrema,
  }) {
    double inner = signalProgress <= 1.0 ? start : propagationProgress - signalProgress;
  }
}
