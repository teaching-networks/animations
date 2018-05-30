import 'dart:html';

import 'dart:math';

import 'package:netzwerke_animationen/src/ui/canvas/canvas_drawable.dart';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_pausable.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/edges.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/size_type.dart';
import 'package:netzwerke_animationen/src/ui/canvas/util/color.dart';
import 'package:netzwerke_animationen/src/ui/canvas/util/colors.dart';
import 'package:netzwerke_animationen/src/util/size.dart';

/**
 * Change listener listening for the packets state.
 */
typedef void StateChangeListener(PacketState newState);

/**
 * Supplier for the packet animation duration.
 */
typedef int DurationSupplier();

/**
 * A packet drawable on a canvas.
 */
class Packet extends CanvasDrawable with CanvasPausableMixin {
  /**
   * Default duration until the packet reaches its destination.
   */
  static const Duration DEFAULT_DURATION = const Duration(seconds: 6);

  /**
   * Duration of the fade animation in case a packet gets destroyed.
   */
  static const Duration DESTROY_FADE_DURATION = const Duration(seconds: 1);

  /**
   * Text written on the packet.
   */
  String text = "PKT";

  /**
   * Packet number.
   */
  int number;

  /**
   * Current state of the packet.
   */
  PacketState _state;

  /**
   * Time the animation was started.
   */
  num startTimestamp = 0;

  /**
   * Last timestamp difference.
   */
  num _lastDelta;

  /**
   * Current animation progress [0.0, 1.0].
   */
  double _currentOpacity = 1.0;

  /**
   * Packet rectangle (Body of the packet).
   */
  RoundRectangle rectangle = new RoundRectangle(paintMode: PaintMode.FILL, radius: new Edges.all(0.2), color: Colors.CORAL, radiusSizeType: SizeType.PERCENT);

  /**
   * Listeners listening the state changes.
   */
  List<StateChangeListener> _stateListeners;

  /**
   * Supplier for the packet animation duration.
   */
  DurationSupplier durationSupplier = () => DEFAULT_DURATION.inMilliseconds;

  /*
  Attributes needed to determine the actual bounds of the packet.
   */
  Point<double> _actualOffset;
  Size _actualSize;
  Point<double> _lastPos;

  /**
   * Create new packet instance.
   */
  Packet({this.number, this.durationSupplier, PacketState startState = PacketState.START}) : _state = startState;

  /**
   * Draw the packet.
   */
  void draw(CanvasRenderingContext2D context, Size size, Point<double> target, num timestamp) {
    _actualSize = size;

    if (_state == PacketState.END) {
      render(context, toRect(0.0, 0.0, size));
      return;
    } else if (_state == PacketState.END_AT_RECEIVER) {
      render(context, toRect(target.x, target.y, size));
      return;
    } else if (_state == PacketState.DESTROYED) {
      return;
    }

    if (_state == PacketState.START) {
      text = "PKT";
      rectangle.color = Colors.CORAL;
      _initAnimationWithState(PacketState.MOVING_FROM_SENDER, timestamp);
    } else if (_state == PacketState.AT_RECEIVER) {
      text = "ACK";
      rectangle.color = Colors.LIME;
      _initAnimationWithState(PacketState.MOVING_FROM_RECEIVER, timestamp);
    } else if (_state == PacketState.DESTROY_START) {
      _initAnimationWithState(PacketState.DESTROYING, timestamp);
    }

    // Calculate progress
    if (!isPaused || _state == PacketState.DESTROYING) {
      _lastDelta = timestamp - startTimestamp;
    }

    if (_state != PacketState.DESTROYING) {
      _lastPos = target * _getCurrentProgress(_lastDelta);
    } else {
      _currentOpacity = 1.0 - min(1 / DESTROY_FADE_DURATION.inMilliseconds * _lastDelta, 1.0);

      if (_currentOpacity == 0.0) {
        changeState(PacketState.DESTROYED);
      }
    }

    // Draw packet
    render(context, toRect(_lastPos.x, _lastPos.y, size));
  }

  /**
   * Initialize animation (start timestamp) with the passed state.
   */
  void _initAnimationWithState(PacketState state, num timestamp) {
    startTimestamp = timestamp;
    changeState(state);
  }

  /**
   * Get current progress of the packet moving animation.
   * Pass timeDifference (The difference between the animation start and end).
   */
  double _getCurrentProgress(num timeDifference) {
    int time = durationSupplier.call();

    double progress = min(1 / time * timeDifference, 1.0);

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

    return progress;
  }

  /**
   * Change the packets state.
   */
  void changeState(PacketState newState) {
    _state = newState;

    notifyStateChangeListener(_state);
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    context.translate(rect.left, rect.top);

    // Draw packet rect
    rectangle.color = Color.opacity(rectangle.color, _currentOpacity);
    rectangle.render(context, new Rectangle(0.0, 0.0, rect.width, rect.height));

    // Draw text
    context.save();
    context.translate(rect.width / 2, rect.height / 2);
    context.rotate(pi / 2);

    context.textBaseline = "middle";
    context.textAlign = "center";
    setFillColor(context, Color.opacity(Colors.BLACK, _currentOpacity));
    context.fillText("${text}_$number", 0.0, 0.0, rect.height);

    context.restore();

    context.restore();
  }

  /**
   * Whether the packet is still transmitting.
   */
  bool get inProgress => _state != PacketState.END;

  /**
   * Add a state change listener to the listener list.
   */
  void addStateChangeListener(StateChangeListener listener) {
    if (_stateListeners == null) {
      _stateListeners = new List<StateChangeListener>();
    }

    _stateListeners.add(listener);
  }

  /**
   * Remove a state change listener from the listener list.
   */
  void removeStateChangeListener(StateChangeListener listener) {
    if (_stateListeners != null) {
      _stateListeners.remove(listener);
    }
  }

  /**
   * Notify all state change listeners that a new state has been set.
   */
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

  /**
   * Destroy the packet.
   */
  void destroy() {
    if (isDestroyable()) {
      _state = PacketState.DESTROY_START;
    }
  }

  /**
   * Check whether packet is destroyable.
   */
  bool isDestroyable() => _state == PacketState.MOVING_FROM_SENDER || _state == PacketState.MOVING_FROM_RECEIVER;

  /**
   * Get current packet state.
   */
  PacketState get state => _state;

  @override
  void switchPauseSubAnimations() {}

  @override
  void unpaused(num timestampDifference) {
    if (_state != PacketState.DESTROYING) {
      startTimestamp += timestampDifference;
    }
  }
}

/**
 * All state a packet can be in.
 */
enum PacketState { START, END, MOVING_FROM_SENDER, AT_RECEIVER, END_AT_RECEIVER, MOVING_FROM_RECEIVER, DESTROY_START, DESTROYING, DESTROYED }
