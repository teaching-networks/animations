import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/signal_emitter/signal_emitter.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

/// Signal emitter emitting horizontally.
class HorizontalSignalEmitter extends SignalEmitter {
  /// Color of the signal.
  Color color = Colors.CORAL;

  /// Create signal emitter.
  HorizontalSignalEmitter({
    @required double start,
    @required Duration signalDuration,
    @required double propagationSpeed,
    this.color,
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

    double x = range.item1 * rect.width;
    double y = range.item2 * rect.width;

    context.fillRect(rect.left + x, rect.top, y - x, rect.height);

    context.restore();
  }
}
