import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/util/curves.dart';

/// Class to deal easily with canvas animations.
abstract class Anim {
  /// Default duration of an animation.
  static const Duration _defaultDuration = Duration(seconds: 42);

  /// Start timestamp of the animation.
  num _startTS;

  /// Whether the animation is reversed.
  bool _reversed = false;

  /// Progress of the animation in range [0.0; 1.0].
  double _progress = 0.0;

  /// Duration of the animation.
  Duration _duration;

  /// Create animation.
  Anim({
    Duration duration = _defaultDuration,
  }) : _duration = duration;

  /// Check whether the animation is currently running.
  bool get running => _startTS != null;

  /// Get the current progress of the animation in range [0.0, 1.0].
  double get progress => _progress;

  /// Whether the animation is currently reversed.
  bool get reversed => _reversed;

  /// Get the animations duration.
  Duration get duration => _duration;

  /// Set the animations duration.
  void set duration(Duration value) {
    if (running) {
      throw Exception("Cannot set the animation duration if it is running");
    }

    _duration = duration;
  }

  /// Get the animations curve.
  Curve get curve;

  /// What should happen if the animation ends.
  void onEnd(num timestamp);

  /// What should happen on resetting the animation.
  void onReset();

  /// Start the animation.
  void start({
    num timestamp,
    Duration duration,
  }) {
    if (timestamp == null) {
      timestamp = window.performance.now();
    }

    if (duration != null) {
      _duration = duration;
    }

    reset();

    _startTS = timestamp;
  }

  /// Reset the animation.
  /// Will be called at the beginning of an animation.
  void reset() {
    _progress = _reversed ? 1.0 : 0.0;
    _startTS = null;

    onReset();
  }

  /// End the animation.
  void _end(num timestamp) {
    _progress = _reversed ? 0.0 : 1.0;
    _startTS = null;

    onEnd(timestamp);
  }

  /// Reverse the animation.
  /// Can only be called when the animation is not running.
  void reverse() {
    if (running) {
      throw Exception("Cannot reverse animation in running state");
    }

    _reversed = !_reversed;
  }

  /// Update the animation.
  /// Returns whether the animation changed.
  bool update(num timestamp) {
    if (!running) {
      return false;
    }

    _progress = _getProgress(timestamp: timestamp, curve: curve);

    return true;
  }

  /// Get the current progress of the animation.
  double _getProgress({
    num timestamp,
    Curve curve,
  }) {
    if (timestamp == null) {
      timestamp = window.performance.now();
    }

    double p = max(min((timestamp - _startTS) / duration.inMilliseconds, 1.0), 0.0);

    if (p >= 1.0) {
      _end(timestamp);
      return _progress;
    }

    if (_reversed) {
      p = 1.0 - p;
    }

    if (curve != null) {
      p = curve(p);
    }

    return p;
  }
}
