import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

typedef void RangeListener(Tuple2<double, double> range1, Tuple2<double, double> range2);

/// Drawable similar to PacketLine but vertical and emits in both directions from the starting point.
abstract class SignalEmitter extends CanvasDrawable {
  /// From which point to start the signal emitting.
  final double start;

  /// Duration until the signal stops.
  final Duration signalDuration;

  /// Speed of the propagation of the signal in percent per second (e. g. 1.0 == 100% per second).
  final double propagationSpeed;

  /// Callback which is called when the signal emitting finished.
  final Function onEnd;

  /// Listen to range changes.
  final RangeListener listen;

  /// Start timestamp of the animation.
  num _startTimestamp = -1;

  /// Whether the end of the animation has been reached.
  bool _isEnd = false;

  Tuple2<double, double> _lastRange1;
  Tuple2<double, double> _lastRange2;

  /// When the emitting has been cancelled.
  num _cancelledTimestamp = -1;

  /// Create signal emitter.
  SignalEmitter({
    @required this.start,
    @required this.signalDuration,
    @required this.propagationSpeed,
    this.onEnd,
    this.listen,
  });

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (_isEnd) {
      return; // Do not do anything.
    }

    if (_startTimestamp == -1) {
      _startTimestamp = timestamp;

      return;
    }

    final diff = timestamp - _startTimestamp;

    bool cancelled = _cancelledTimestamp != -1;

    final propagationProgress = diff / 1000 * propagationSpeed;
    final signalProgress = cancelled ? 1.1 : diff / signalDuration.inMilliseconds;

    double propagationProgressSinceSignalEnd = 0.0;
    if (signalProgress >= 1.0) {
      propagationProgressSinceSignalEnd =
          (diff - (cancelled ? (_cancelledTimestamp - _startTimestamp) : signalDuration.inMilliseconds)) / 1000 * propagationSpeed;
    }

    Tuple2<double, double> range1 = _calculateSignalRange(
      propagationProgress: propagationProgress,
      signalProgress: signalProgress,
      extrema: 0.0,
      propagationProgressSinceSignalEnd: propagationProgressSinceSignalEnd,
    );

    Tuple2<double, double> range2 = _calculateSignalRange(
      propagationProgress: propagationProgress,
      signalProgress: signalProgress,
      extrema: 1.0,
      propagationProgressSinceSignalEnd: propagationProgressSinceSignalEnd,
    );

    _lastRange1 = range1;
    _lastRange2 = range2;

    bool isEnd = _isOutOfVisible(range1) && _isOutOfVisible(range2) && signalProgress >= 1.0;

    if (!isEnd) {
      if (listen != null) {
        listen(range1, range2);
      }

      // Draw ranges.
      if (range1.item2 == range2.item1) {
        // Merge range.
        drawRange(context, Tuple2<double, double>(range1.item1, range2.item2), rect);
      } else {
        drawRange(context, range1, rect);
        drawRange(context, range2, rect);
      }
    } else if (onEnd != null) {
      _isEnd = true;
      onEnd();
    }
  }

  /// Check if passed [range] is out of visible area.
  bool _isOutOfVisible(Tuple2<double, double> range) => (range.item1 <= 0.0 || range.item1 >= 1.0) && (range.item2 <= 0.0 || range.item2 >= 1.0);

  /// Draw the passed range.
  void drawRange(CanvasRenderingContext2D context, Tuple2<double, double> range, Rectangle<double> rect);

  /// Calculate a signal range.
  Tuple2<double, double> _calculateSignalRange({
    @required final double propagationProgress,
    @required final double signalProgress,
    @required final double extrema,
    @required final double propagationProgressSinceSignalEnd,
  }) {
    double inner = _calculateInner(
      signalProgress: signalProgress,
      extrema: extrema,
      propagationProgressSinceSignalEnd: propagationProgressSinceSignalEnd,
    );

    double outer = _calculateOuter(
      propagationProgress: propagationProgress,
      extrema: extrema,
    );

    return Tuple2<double, double>(min(max(min(inner, outer), 0.0), 1.0), max(min(max(inner, outer), 1.0), 0.0));
  }

  /// Calculate the inner point in range.
  double _calculateInner({
    @required final double propagationProgressSinceSignalEnd,
    @required final double signalProgress,
    @required final double extrema,
  }) =>
      signalProgress <= 1.0 ? start : (extrema > start ? start + propagationProgressSinceSignalEnd : start - propagationProgressSinceSignalEnd);

  /// Calculate the outer point in range.
  double _calculateOuter({
    @required final double propagationProgress,
    @required final double extrema,
  }) =>
      extrema > start ? start + propagationProgress : start - propagationProgress;

  /// Get the current signal ranges.
  Tuple2<Tuple2<double, double>, Tuple2<double, double>> getSignalRanges() => Tuple2(_lastRange1, _lastRange2);

  /// Cancel the signal emitting.
  void cancelSignal() {
    final currentTimestamp = window.performance.now();
    final diff = currentTimestamp - _startTimestamp;
    final signalProgress = diff / signalDuration.inMilliseconds;

    // Only cancel if signal not already ended.
    if (signalProgress < 1.0) {
      _cancelledTimestamp = window.performance.now();
    }
  }
}
