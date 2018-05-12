import 'dart:html';

import 'dart:math';

import 'package:netzwerke_animationen/src/ui/canvas/canvas_drawable.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/edges.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/size_type.dart';
import 'package:netzwerke_animationen/src/ui/canvas/util/colors.dart';
import 'package:netzwerke_animationen/src/ui/canvas/util/curves.dart';
import 'package:netzwerke_animationen/src/util/size.dart';

typedef void StateChangeListener(PacketState newState);

class Packet extends CanvasDrawable {

  /**
   * Default duration until the packet reaches its destination.
   */
  static const Duration DEFAULT_DURATION = const Duration(seconds: 4);

  String text = "PKT";
  int number;
  Duration duration;
  PacketState _state = PacketState.START;
  num startTimestamp;
  RoundRectangle rectangle = new RoundRectangle(paintMode: PaintMode.FILL, radius: new Edges.all(0.2), color: Colors.CORAL, radiusSizeType: SizeType.PERCENT);

  List<StateChangeListener> _stateListeners;

  /*
  Attributes needed to determine the actual bounds of the packet.
   */
  Point<double> _actualOffset;
  Size _actualSize;
  Point<double> _lastPos;

  Packet({this.number, this.duration = DEFAULT_DURATION});

  void draw(CanvasRenderingContext2D context, Size size, Point<double> target, num timestamp) {
    _actualSize = size;

    if (_state == PacketState.END) {
      render(context, toRect(0.0, 0.0, size));
      return;
    }

    if (_state == PacketState.START) {
      startTimestamp = timestamp;
      changeState(PacketState.MOVING_FROM_SENDER);
    } else if (_state == PacketState.AT_RECEIVER) {
      startTimestamp = timestamp;
      text = "ACK";
      rectangle.color = Colors.LIME;
      changeState(PacketState.MOVING_FROM_RECEIVER);
    }

    // Calculate progress
    num delta = timestamp - startTimestamp;
    double progress = min(1 / duration.inMilliseconds * delta, 1.0);

    if (_state == PacketState.MOVING_FROM_SENDER) {
      if (progress == 1.0) {
        changeState(PacketState.AT_RECEIVER);
      }
    } else if (_state == PacketState.MOVING_FROM_RECEIVER) {
      progress = max(1.0 - progress, 0.0); // Progress the other way round!

      if (progress == 0.0) {
        changeState(PacketState.END);
      }
    }

    // Transform to cool curve!
    progress = Curves.easeInOutCubic(progress);

    _lastPos = target * progress;

    // Draw packet
    render(context, toRect(_lastPos.x, _lastPos.y, size));
  }

  void changeState(PacketState newState) {
    _state = newState;

    notifyStateChangeListener(_state);
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    context.translate(rect.left, rect.top);

    // Draw packet rect
    rectangle.render(context, new Rectangle(0.0, 0.0, rect.width, rect.height));

    // Draw text
    context.save();
    context.translate(rect.width / 2, rect.height / 2);
    context.rotate(pi / 2);

    context.textBaseline = "middle";
    context.textAlign = "center";
    setFillColor(context, Colors.BLACK);
    context.fillText("${text}_$number", 0.0, 0.0, rect.height);

    context.restore();

    context.restore();
  }

  bool get inProgress => _state != PacketState.END;

  void addStateChangeListener(StateChangeListener listener) {
    if (_stateListeners == null) {
      _stateListeners = new List<StateChangeListener>();
    }

    _stateListeners.add(listener);
  }

  void removeStateChangeListener(StateChangeListener listener) {
    if (_stateListeners != null) {
      _stateListeners.remove(listener);
    }
  }

  void notifyStateChangeListener(PacketState newState) {
    if (_stateListeners != null) {
      for (StateChangeListener listener in _stateListeners) {
        listener.call(newState);
      }
    }
  }

  /**
   * Set actual offset on the main canvas so that a mouse click can be directed to the packet.
   */
  void setActualOffset(double x, double y) {
    _actualOffset = new Point(x, y);
  }

  /**
   * Get the actual bounds of the packet on the canvas.
   */
  Rectangle<double> getActualBounds() {
    return new Rectangle(_actualOffset.x + _lastPos.x, _actualOffset.y + _lastPos.y, _actualSize.width, _actualSize.height);
  }

}

enum PacketState {
  START,
  END,
  MOVING_FROM_SENDER,
  AT_RECEIVER,
  MOVING_FROM_RECEIVER
}
