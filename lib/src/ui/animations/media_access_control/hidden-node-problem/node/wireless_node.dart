import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/shared/signal_emitter/impl/circular_signal_emitter.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

/// A node capable of emitting and receiving signals wirelessly.
class WirelessNode extends CanvasDrawable {
  /// Signal emission propagation speed of the underlying signal emitter.
  static const double _signalEmissionPropagationSpeed = 300000000.0;

  /// The ratio of the nodes range to its node circle size.
  static const double _rangeToNodeCircleRatio = 10.0;

  /// Name of the node to display.
  final String nodeName;

  /// The scale to use.
  /// For example 10 is only 10% of the original speed.
  final int scale;

  /// The color of the range circle.
  final Color rangeCircleColor;

  /// The color of the node circle.
  final Color nodeCircleColor;

  /// Signal emitter currently displaying a signal.
  CircularSignalEmitter _signalEmitter;

  /// Create node.
  WirelessNode({
    @required this.nodeName,
    this.scale = 100000000,
    this.rangeCircleColor = Colors.BLACK,
    this.nodeCircleColor = Colors.SLATE_GREY,
  });

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    if (_signalEmitter != null) {
      _signalEmitter.render(context, rect, timestamp);
    }

    context.translate(rect.left, rect.top);

    double radius = min(rect.width, rect.height);

    // Draw range circle
    setStrokeColor(context, rangeCircleColor);
    context.lineWidth = 2 * window.devicePixelRatio;
    context.beginPath();
    context.arc(0.0, 0.0, radius, 0, 2 * pi);
    context.stroke();

    // Draw node circle
    setFillColor(context, nodeCircleColor);
    context.beginPath();
    context.arc(0.0, 0.0, radius / _rangeToNodeCircleRatio, 0, 2 * pi);
    context.fill();

    // Draw node name
    setFillColor(context, Color.brighten(nodeCircleColor, 0.5));
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.fillText(nodeName, 0.0, 0.0);

    context.restore();
  }

  /// Emit signal with the passed [duration] and [color].
  void emitSignal(Duration duration, Color color) {
    _signalEmitter = CircularSignalEmitter(
      signalDuration: duration,
      propagationSpeed: _signalEmissionPropagationSpeed / scale,
      color: color,
    );
  }
}
