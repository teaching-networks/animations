import 'dart:html';
import 'dart:math';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_drawable.dart';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_pausable.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/edges.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/size_type.dart';
import 'package:netzwerke_animationen/src/ui/canvas/util/colors.dart';
import 'package:netzwerke_animationen/src/util/size.dart';

typedef int LabelSupplier(int index);

/**
 * Receive or Send window for reliable transmission.
 */
class TransmissionWindow extends CanvasDrawable with CanvasPausableMixin {

  /**
   * Default length for the window array.
   */
  static const int DEFAULT_LENGTH = 20;

  /**
   * Default window size for the window.
   */
  static const int DEFAULT_WINDOW_SIZE = 1;

  /**
   * Padding between window slots.
   */
  static const double SLOT_PADDING = 5.0;

  /**
   * Timeout finished constant used to determine whether a timeout is not used anymore.
   */
  static const num TIMEOUT_FINISHED = -123;

  /**
   * Actual length of the window array.
   */
  final int _length;

  /**
   * Actual size of the window.
   */
  final int _windowSize;

  /**
   * Sender label.
   */
  final Message senderLabel;

  /**
   * Receiver label.
   */
  final Message receiverLabel;

  /**
   * Protocol to use.
   */
  final ReliableTransmissionProtocol protocol;

  /**
   * Place of a packet.
   */
  final RoundRectangle _packetPlaceRect = new RoundRectangle(radius: new Edges.all(0.2), radiusSizeType: SizeType.PERCENT, paintMode: PaintMode.FILL, color: Colors.LIGHTGREY);

  /**
   * List of packets currently in the window.
   */
  final List<List<Packet>> _packetSlots = new List<List<Packet>>();

  /**
   * Timers of the transmission.
   */
  final List<num> _timeouts = new List<num>();

  /**
   * Last timeout countdowns are saved here (used to display the old countdown while animation is paused).
   */
  final Map<int, int> _timeoutLabelCache = new Map<int, int>();

  /**
   * Packets currently being sent.
   */
  int _packetsInProgress = 0;

  /**
   * Create new transmission window.
   */
  TransmissionWindow({
    int length = DEFAULT_LENGTH,
    int windowSize = DEFAULT_WINDOW_SIZE,
    this.protocol,
    this.senderLabel,
    this.receiverLabel
  }) : _length = length,
        _windowSize = windowSize;

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();
    context.translate(rect.left, rect.top);

    context.textBaseline = "middle";
    context.textAlign = "right";

    double maxLabelWidth = max(context.measureText(senderLabel.toString()).width, context.measureText(receiverLabel.toString()).width);

    context.translate(maxLabelWidth, 0.0);

    Size windowSize = new Size(rect.width - maxLabelWidth, rect.height / 10);

    // Draw sender and receiver labels
    context.setFillColorRgb(0, 0, 0);
    context.fillText(senderLabel.toString(), 0.0, windowSize.height / 2);
    context.fillText(receiverLabel.toString(), 0.0, rect.height - windowSize.height / 2);

    // Draw sender window array
    _drawWindowArray(context, windowSize, (index) {
      int timeout = null;

      if (isPaused && _timeoutLabelCache[index] != null) {
        timeout = _timeoutLabelCache[index];
      } else if (_timeouts.length > index) {
        timeout = ((_timeouts[index] - timestamp) / 1000).round();
        _timeoutLabelCache[index] = timeout;
      }

      if (timeout != null && timeout < 0) {
        timeout = max(0, timeout);

        if (timeout != TIMEOUT_FINISHED) {
          _timeoutHitZero(index);
        }
      }

      return timeout;
    });

    context.save();
    {
      context.translate(0.0, rect.height - windowSize.height);
      // Draw receiver window array
      _drawWindowArray(context, windowSize);
    }
    context.restore();

    // Draw packets (if any)
    double slotWidth = windowSize.width / _length;
    Size packetSize = new Size(windowSize.width / _length - SLOT_PADDING * 2, windowSize.height);
    Point<double> target = new Point(0.0, rect.height - windowSize.height);

    for (int i = 0; i < _packetSlots.length; i++) {
      List<Packet> packets = _packetSlots[i];

      context.save();
      {
        context.translate(i * slotWidth + SLOT_PADDING, 0.0);

        double actualOffsetX = maxLabelWidth + i * slotWidth + SLOT_PADDING;
        double actualOffsetY = 0.0;

        for (Packet p in packets) {
          p.setActualOffset(actualOffsetX, actualOffsetY);
          p.draw(context, packetSize, target, timestamp);
        }
      }
      context.restore();
    }

    context.restore();
  }

  /**
   * Draw window array.
   */
  void _drawWindowArray(CanvasRenderingContext2D context, Size size, [LabelSupplier labelSupplier]) {
    double width = size.width / _length;
    double height = size.height;

    context.setFillColorRgb(0, 0, 0);
    for (int i = 0; i < _length; i++) {
      context.save();
      {
        context.translate(i * width + SLOT_PADDING, 0.0);
        Rectangle<double> r = new Rectangle(0.0, 0.0, width - SLOT_PADDING * 2, height);

        _packetPlaceRect.render(context, r, 0);

        // Draw label if any
        if (labelSupplier != null) {
          int label = labelSupplier.call(i);

          if (label != null) {
            context.save();
            {
              setFillColor(context, Colors.BLACK);
              context.textAlign = "center";
              context.textBaseline = "middle";
              context.fillText("${labelSupplier.call(i)}", r.width / 2, r.height / 2);
            }
            context.restore();
          }
        }
      }
      context.restore();
    }
  }

  /**
   * Emit packet from sender to receiver.
   */
  void emitPacket() {
    _emitPacket(_packetSlots.length);
  }

  void _emitPacket(int index) {
    List<Packet> packets;
    if (_packetSlots.length <= index) {
      packets = new List<Packet>();
      _packetSlots.add(packets);
    } else {
      packets = _packetSlots[index];
    }

    Packet p = new Packet(number: index);

    _packetsInProgress++;

    p.addStateChangeListener((newState) {
      if (newState == PacketState.AT_RECEIVER && !_receiverReceivedPKT(index)) {
        packets.add(new Packet(number: p.number, startState: PacketState.END_AT_RECEIVER));
      } else if (newState == PacketState.END) {
        _packetsInProgress--;
      }
    });

    packets.add(p);

    num timeout = window.performance.now() + p.duration.inMilliseconds * 2;
    if (_timeouts.length <= index) {
      _timeouts.add(timeout);
    } else {
      _timeouts[index] = timeout;
    }
  }

  /**
   * Whether window is able to transmit another packet.
   */
  bool canEmitPacket() => _packetsInProgress < _windowSize;

  /**
   * On click on the transmission window.
   */
  void onClick(Point<double> pos) {
    for (var pair in _packetSlots) {
      var bounds = pair.first.getActualBounds();

      if (bounds.containsPoint(pos)) {
        pair.first.destroy();
        break;
      }
    }
  }

  @override
  void switchPauseSubAnimations() {
    for (var packets in _packetSlots) {
      for (var packet in packets) {
        packet.switchPause();
      }
    }
  }

  @override
  void unpaused(num timestampDifference) {
    // Recalculate timestamps.
    for (int i = 0; i < _timeouts.length; i++) {
      _timeouts[i] += timestampDifference;
    }
  }

  /**
   * Check is sender received ack for the passed packet slot index.
   */
  bool _senderReceivedACK(index) {
    for (Packet p in _packetSlots[index]) {
      if (p.state == PacketState.END) {
        return true;
      }
    }

    return false;
  }

  /**
   * Check whether receiver received packet from sender in the passed slot index.
   */
  bool _receiverReceivedPKT(index) {
    for (Packet p in _packetSlots[index]) {
      if (p.state == PacketState.END_AT_RECEIVER) {
        return true;
      }
    }

    return false;
  }

  /**
   * Called when the timeout hit zero.
   * Index of the timeout in the timeouts list is passed.
   */
  void _timeoutHitZero(int index) {
    _timeouts[index] = TIMEOUT_FINISHED;

    if (!_senderReceivedACK(index)) {
      // Resend the packet.
      _resendPacket(index);
    }
  }

  /**
   * Resend packet with the passed index.
   */
  void _resendPacket(int index) {
    _emitPacket(index);
  }

}
