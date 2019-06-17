import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';

typedef void OnEnd(num timestamp);
typedef void OnReset();

/// Set up animations easily using the animation helper.
class AnimHelper extends Anim {
  /// Curve of the animation.
  final Curve _curve;

  /// Callback to call on end.
  final OnEnd _onEnd;

  /// Callback to call on reset.
  final OnReset _onReset;

  /// Create animation.
  AnimHelper({
    Curve curve,
    Duration duration,
    OnEnd onEnd,
    OnReset onReset,
  })  : _curve = curve,
        _onEnd = onEnd,
        _onReset = onReset,
        super(
          duration: duration,
        );

  @override
  Curve get curve => _curve;

  @override
  void onEnd(num timestamp) {
    if (_onEnd != null) {
      _onEnd(timestamp);
    }
  }

  @override
  void onReset() {
    if (_onReset != null) {
      _onReset();
    }
  }
}
