/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/shared/signal_emitter/signal_emitter.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

/// Signal emitter emitting signal vertically.
class VerticalSignalEmitter extends SignalEmitter {
  /// Color of the signal.
  Color color;

  /// Create signal emitter.
  VerticalSignalEmitter({
    @required double start,
    @required Duration signalDuration,
    @required double propagationSpeed,
    this.color = Colors.CORAL,
    Function onEnd,
    RangeListener listen,
  }) : super(
          start: start,
          signalDuration: signalDuration,
          propagationSpeed: propagationSpeed,
          onEnd: onEnd,
          listen: listen,
        );

  @override
  void drawRange(CanvasRenderingContext2D context, Tuple2<double, double> range, Rectangle<double> rect) {
    context.save();

    setFillColor(context, color);

    double x = range.item1 * rect.height;
    double y = range.item2 * rect.height;

    context.fillRect(rect.left, rect.top + x, rect.width, y - x);

    context.restore();
  }
}
