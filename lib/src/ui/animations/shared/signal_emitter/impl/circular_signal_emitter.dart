/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

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

  /// Default opacity at the border of the emitted signal.
  static const double _defaultEndOpacity = 0.2;

  /// The default color in case none is provided.
  static const Color _defaultColor = Colors.BLACK;

  /// The color of the signal.
  final Color color;

  /// Opacity of the color at the border of the emitted signal.
  final double endOpacity;

  /// End color is the color at the border of the signal emitter.
  final Color _endColor;

  /// Create signal emitter.
  CircularSignalEmitter({
    Duration signalDuration = _defaultSignalDuration,
    double propagationSpeed = _defaultPropagationSpeed,
    this.color = _defaultColor,
    this.endOpacity = _defaultEndOpacity,
    RangeListener listener,
    Function onEnd,
  })  : _endColor = Color.opacity(color, endOpacity),
        super(
          start: 0.0,
          signalDuration: signalDuration,
          propagationSpeed: propagationSpeed,
          listen: listener,
          onEnd: onEnd,
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
    gradient.addColorStop(range.item2, _endColor.toCSSColorString());
    gradient.addColorStop(range.item2, "transparent");
    gradient.addColorStop(1.0, "transparent");
    context.fillStyle = gradient;

    context.beginPath();
    context.arc(0.0, 0.0, radius, 0, 2 * pi);
    context.fill();

    context.restore();
  }
}
