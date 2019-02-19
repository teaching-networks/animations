import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/shared/signal_emitter/signal_emitter.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:tuple/tuple.dart';

/// Signal emitter which emits its signals circular!
class CircularSignalEmitter extends SignalEmitter {
  /// The default signal duration in case none is provided.
  static const Duration _defaultSignalDuration = Duration(seconds: 5);

  /// The default propagation speed in case none is provided.
  static const double _defaultPropagationSpeed = 0.25;

  /// The default color in case none is provided.
  static const Color _defaultColor = Colors.BLACK;

  /// The color of the signal.
  final Color color;

  /// Create signal emitter.
  CircularSignalEmitter({
    Duration signalDuration = _defaultSignalDuration,
    double propagationSpeed = _defaultPropagationSpeed,
    this.color = _defaultColor,
  }) : super(
          start: 0.0,
          signalDuration: signalDuration,
          propagationSpeed: propagationSpeed,
        );

  @override
  void drawRange(CanvasRenderingContext2D context, Tuple2<double, double> range, Rectangle<double> rect) {
    context.save();

    context.translate(rect.left, rect.top);

    double radius = min(rect.width, rect.height);

    final gradient = context.createRadialGradient(0.0, 0.0, 0.0, 0.0, 0.0, radius);
    gradient.addColorStop(0.0, "transparent");
    gradient.addColorStop(range.item1, "transparent");
    gradient.addColorStop(range.item1, color.toCSSColorString());
    gradient.addColorStop(range.item2, color.toCSSColorString());
    gradient.addColorStop(range.item2, "transparent");
    gradient.addColorStop(1.0, "transparent");
    context.fillStyle = gradient;

    context.beginPath();
    context.arc(0.0, 0.0, radius, 0, 2 * pi);
    context.fill();

    context.restore();
  }
}
