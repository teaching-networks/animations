import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress.dart';

/// Modifier modifies progress.
/// You can make cool curves using this.
typedef double Modifier(double p);

/// A lazy progress is a progress which changes by time on change.
/// It is best explained by an example:
///
/// var progress = LazyProgress(duration: Duration(seconds: 1));
/// progress.change = 1.0;
///
/// It now will take the lazy progress a second to change its progress to 1.0.
///
/// This may be tremendously useful with animations.
class LazyProgress extends CanvasPausableMixin implements Progress {
  /// Progress in range [0.0; 1.0]
  double _progress;

  /// The old progress before the last change.
  double _oldProgress;

  /// The last calculated progress from the last progress retrieval call.
  double _tmpProgress;

  /// Duration the progress change takes.
  final Duration duration;

  /// Modifier with which to modify the progress curve.
  Modifier _modifier;

  /// Start timestamp of the animation.
  num _startTimestamp;

  /// Create new lazy progress.
  LazyProgress({double startProgress = 0.0, this.duration = const Duration(milliseconds: 500), Modifier modifier = null})
      : _progress = startProgress,
        _oldProgress = startProgress,
        _tmpProgress = startProgress,
        _modifier = modifier {
    if (_modifier == null) {
      _modifier = (p) => p; // Just a linear curve
    }
  }

  /// Set the current progress.
  void set progress(double p) {
    if (p < 0.0 || p > 1.0) {
      throw new Exception("Unexpected progress $p. Progress must be in range [0.0; 1.0].");
    }

    if (isChanging()) {
      _progress = _tmpProgress;
    }

    _oldProgress = _progress;
    _progress = p;

    _startTimestamp = window.performance.now();
  }

  @override
  double get progress {
    if (!isPaused && isChanging()) {
      _tmpProgress = _oldProgress + (_progress - _oldProgress) * _animationProgress;
    }

    return _tmpProgress;
  }

  /// Get the actual progress (Not animated).
  double get actual {
    return _progress;
  }

  /// Whether the progress is currently changing (animating).
  bool isChanging() => _tmpProgress != _progress;

  /// Get the progress [0.0; 1.0] of the current animation.
  double get _animationProgress => min(_modifier((window.performance.now() - _startTimestamp) / duration.inMilliseconds), 1.0);

  @override
  void switchPauseSubAnimations() {
    // Do nothing
  }

  @override
  void unpaused(num timestampDifference) {
    if (_startTimestamp != null) {
      _startTimestamp += timestampDifference;
    }
  }
}
