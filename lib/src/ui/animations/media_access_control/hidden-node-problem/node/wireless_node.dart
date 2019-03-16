import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/shared/signal_emitter/impl/circular_signal_emitter.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

typedef void NodeSignalRangeListener<T>(Tuple2<double, double> range, T data);

/// A node capable of emitting and receiving signals wirelessly.
class WirelessNode<T> extends CanvasDrawable {
  /// Signal emission propagation speed of the underlying signal emitter.
  static const double _signalEmissionPropagationSpeed = 300000000.0;

  /// The ratio of the nodes range to its node circle size.
  static const double _rangeToNodeCircleRatio = 10.0;

  /// The ratio of the nodes range to its node hover circle size.
  static const double rangeToHoverCircleRatio = _rangeToNodeCircleRatio / 2;

  /// Color shown as hover circle.
  static const Color _hoverColor = Color.rgba(100, 100, 100, 0.2);

  /// Name of the node to display.
  final String nodeName;

  /// The scale to use.
  /// For example 10 is only 10% of the original speed.
  final int scale;

  /// The color of the range circle.
  final Color rangeCircleColor;

  /// The color of the node circle.
  final Color nodeCircleColor;

  /// Range listener to listen for signal emission range changes.
  final NodeSignalRangeListener<T> rangeListener;

  /// Signal emitter currently displaying a signal.
  CircularSignalEmitter _signalEmitter;

  /// The last rendered center point.
  Point<double> _lastRenderedCenter;

  /// Whether the node is currently hovered.
  bool _isHovered = false;

  /// Coordinates of the point (relative).
  Point<double> _coordinates;

  /// Create node.
  WirelessNode({
    @required this.nodeName,
    @required Point<double> initialCoordinates,
    this.scale = 100000000,
    this.rangeCircleColor = Colors.BLACK,
    this.nodeCircleColor = Colors.SLATE_GREY,
    this.rangeListener,
  }) : _coordinates = initialCoordinates;

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    double canvasWidth = rect.left;
    double canvasHeight = rect.top;

    double radius = min(rect.width, rect.height);

    double xPos = canvasWidth * _coordinates.x;
    double yPos = canvasHeight * _coordinates.y;

    context.translate(xPos, yPos);

    // Render signal emitter in the background.
    if (_signalEmitter != null) {
      _signalEmitter.render(context, Rectangle<double>(0.0, 0.0, rect.width, rect.height), timestamp);
    }

    // Draw range circle
    setStrokeColor(context, rangeCircleColor);
    context.lineWidth = window.devicePixelRatio;
    context.beginPath();
    context.arc(0.0, 0.0, radius, 0, 2 * pi);
    context.stroke();

    if (_isHovered) {
      // Draw hover circle
      setFillColor(context, _hoverColor);
      context.beginPath();
      context.arc(0.0, 0.0, radius / rangeToHoverCircleRatio, 0, 2 * pi);
      context.fill();
    }

    // Draw node circle
    setFillColor(context, nodeCircleColor);
    context.beginPath();
    context.arc(0.0, 0.0, radius / _rangeToNodeCircleRatio, 0, 2 * pi);
    context.fill();

    // Draw node name
    setFillColor(context, Color.brighten(nodeCircleColor, 0.7));
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.fillText(nodeName, 0.0, 0.0);

    context.restore();

    _lastRenderedCenter = Point<double>(xPos, yPos);
  }

  /// Emit signal with the passed [duration] and [color].
  void emitSignal(
    Duration duration,
    Color color, {
    T data,
    Function onEnd,
  }) {
    _signalEmitter = CircularSignalEmitter(
      signalDuration: duration,
      propagationSpeed: _signalEmissionPropagationSpeed / scale,
      color: color,
      listener: (_, range) {
        if (rangeListener != null) {
          rangeListener(range, data);
        }
      },
      onEnd: () {
        _signalEmitter = null;

        if (onEnd != null) {
          onEnd();
        }
      },
    );
  }

  /// Get the distance from the passed [pos] to the center of the last rendered wireless node or null if not yet rendered.
  double distanceFromCenter(Point<double> pos) => _lastRenderedCenter != null ? _lastRenderedCenter.distanceTo(pos) : null;

  /// Set whether the node is hovered.
  void set hovered(bool value) => _isHovered = value;

  /// Get whether the node is currently hovered.
  bool get hovered => _isHovered;

  /// Get the nodes coordinates.
  Point<double> get coordinates => _coordinates;

  /// Switch pause of the signal emitter.
  void switchPause() {
    if (_signalEmitter != null) {
      _signalEmitter.switchPause();
    }
  }
}
