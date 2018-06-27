import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/window/window_space.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';

typedef int LabelSupplier(int index);

/**
 * Receive or Send window for reliable transmission.
 */
class TransmissionWindow extends CanvasDrawable with CanvasPausableMixin {
  /**
   * Default speed for the packet animation (in milliseconds).
   */
  static const int DEFAULT_PACKET_ANIMATION_SPEED = 6000;

  /**
   * Default length for the window array.
   */
  static const int DEFAULT_LENGTH = 20;

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
   * Sender label.
   */
  Message senderLabel;

  /**
   * Receiver label.
   */
  Message receiverLabel;

  /**
   * Protocol to use.
   */
  ReliableTransmissionProtocol _protocol;

  /**
   * Place of a packet.
   */
  final RoundRectangle _packetPlaceRect =
      new RoundRectangle(radius: new Edges.all(0.2), radiusSizeType: SizeType.PERCENT, paintMode: PaintMode.FILL, color: Colors.LIGHTGREY);

  /**
   * List of packets currently in the window.
   */
  final List<PacketSlot> _packetSlots = new List<PacketSlot>();

  /**
   * Last timeout countdowns are saved here (used to display the old countdown while animation is paused).
   */
  final Map<int, int> _timeoutLabelCache = new Map<int, int>();

  WindowSpaceDrawable _senderSpace;
  WindowSpaceDrawable _receiverSpace;

  /**
   * Speed in milliseconds for the packet animation.
   */
  int speed = DEFAULT_PACKET_ANIMATION_SPEED;

  /// Stream used to listen to window size changes.
  StreamSubscription<int> _windowSizeSubscription;

  /**
   * Create new transmission window.
   */
  TransmissionWindow(
      {int length = DEFAULT_LENGTH, ReliableTransmissionProtocol protocol, this.senderLabel, this.receiverLabel})
      : _length = length {
    _senderSpace = new WindowSpaceDrawable(1);
    _receiverSpace = new WindowSpaceDrawable(1);

    setProtocol(protocol);
  }

  void setProtocol(ReliableTransmissionProtocol protocol) {
    if (_windowSizeSubscription != null) {
      _windowSizeSubscription.cancel();
      _windowSizeSubscription = null;
    }

    this._protocol = protocol;

    if (protocol != null) {
      _senderSpace.windowSize = protocol.getSenderWindowSize();
      _receiverSpace.windowSize = protocol.getReceiverWindowSize();

      _windowSizeSubscription = this._protocol.windowSizeStream.listen((newWindowSize) {
        _senderSpace.windowSize = _protocol.getSenderWindowSize();
        _receiverSpace.windowSize = _protocol.getReceiverWindowSize();
      });
    }
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    double padding = 25.0;
    double h = rect.height - padding * 2;
    double w = rect.width;

    context.save();
    context.translate(rect.left, rect.top + padding);

    context.textBaseline = "middle";
    context.textAlign = "right";

    double maxLabelWidth = max(context.measureText(senderLabel.toString()).width, context.measureText(receiverLabel.toString()).width);

    context.translate(maxLabelWidth, 0.0);

    Size windowSize = new Size(w - maxLabelWidth, h / 10);

    // Draw sender and receiver labels
    context.setFillColorRgb(0, 0, 0);
    context.fillText(senderLabel.toString(), 0.0, windowSize.height / 2);
    context.fillText(receiverLabel.toString(), 0.0, h - windowSize.height / 2);

    // Draw sender window array
    _drawWindowArray(context, windowSize, _senderSpace, timestamp, (index) {
      int timeout = null;

      if (isPaused && _timeoutLabelCache[index] != null) {
        timeout = _timeoutLabelCache[index];
      } else if (_packetSlots.length > index) {
        timeout = ((_packetSlots[index].timeout - timestamp) / 1000).round();
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
      context.translate(0.0, h - windowSize.height);
      // Draw receiver window array
      _drawWindowArray(context, windowSize, _receiverSpace, timestamp);
    }
    context.restore();

    // Draw packets (if any)
    double slotWidth = windowSize.width / _length;
    Size packetSize = new Size(windowSize.width / _length - SLOT_PADDING * 2, windowSize.height);
    Point<double> target = new Point(0.0, h - windowSize.height);

    for (int i = 0; i < _packetSlots.length; i++) {
      PacketSlot slot = _packetSlots[i];
      slot.cleanup(); // Cleanup not used packets which are obsolete in slot first.

      context.save();
      {
        context.translate(i * slotWidth + SLOT_PADDING, 0.0);

        double actualOffsetX = maxLabelWidth + i * slotWidth + SLOT_PADDING;
        double actualOffsetY = 0.0;

        slot.packets.first?.setActualOffset(actualOffsetX, actualOffsetY);
        slot.packets.first?.draw(context, packetSize, target, timestamp);

        slot.packets.second?.setActualOffset(actualOffsetX, actualOffsetY);
        slot.packets.second?.draw(context, packetSize, target, timestamp);

        for (Packet p in slot.activePackets) {
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
  void _drawWindowArray(CanvasRenderingContext2D context, Size size, WindowSpaceDrawable windowSpace, num timestamp, [LabelSupplier labelSupplier]) {
    double width = size.width / _length;
    double height = size.height;
    double slotWidth = width - SLOT_PADDING * 2;

    context.setFillColorRgb(0, 0, 0);
    for (int i = 0; i < _length; i++) {
      context.save();
      {
        context.translate(i * width + SLOT_PADDING, 0.0);
        Rectangle<double> r = new Rectangle(0.0, 0.0, slotWidth, height);

        _packetPlaceRect.render(context, r, 0);

        // Draw label if any
        if (labelSupplier != null && (_protocol.showTimeoutForAllSlots() || i == windowSpace.getOffset())) {
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

    // Draw window space indicator.
    windowSpace.draw(context, width, height, SLOT_PADDING, timestamp);
  }

  /**
   * Emit new packet from sender to receiver.
   */
  void emitPacket() {
    emitPacketByIndex(_packetSlots.length, false);
  }

  void emitPacketByIndex(int index, bool timeout) {
    PacketSlot slot;
    if (_packetSlots.length <= index) {
      slot = new PacketSlot(index, (p) {
        if (_protocol.isCustomTimeoutEnabled) {
          return _protocol.customTimeout * 1000;
        } else {
          return p.durationSupplier.call() * 4;
        }
      });
      slot.addArrivalListener((isAtSender, packet, movingPacket) {
        if (isAtSender) {
          _onSenderReceivedACK(packet, movingPacket, slot);
        } else {
          _onReceiverReceivedPKT(packet, movingPacket, slot);
        }
      });
      _packetSlots.add(slot);
    } else {
      slot = _packetSlots[index];
    }

    Packet p = _protocol.senderSendPacket(index, timeout, this);

    if (p != null) {
      p.durationSupplier = () => this.speed;

      slot.addPacket(p);
    }
  }

  /**
   * Whether window is able to transmit another packet.
   */
  bool canEmitPacket() => _protocol.canEmitPacket(_packetSlots) && !isPaused;

  /**
   * On click on the transmission window.
   */
  void onClick(Point<double> pos) {
    for (var slot in _packetSlots) {
      for (var p in slot.activePackets) {
        if (p.getActualBounds().containsPoint(pos)) {
          p.destroy();
          break;
        }
      }
    }
  }

  @override
  void switchPauseSubAnimations() {
    for (var slot in _packetSlots) {
      for (var packet in slot.activePackets) {
        packet.switchPause();
      }
    }
  }

  @override
  void unpaused(num timestampDifference) {
    // Recalculate timestamps.
    for (var slot in _packetSlots) {
      slot.timeout += timestampDifference;
    }
  }

  /**
   * Called when the timeout hit zero.
   * Index of the timeout in the timeouts list is passed.
   */
  void _timeoutHitZero(int index) {
    PacketSlot slot = _packetSlots[index];

    slot.timeout = TIMEOUT_FINISHED;

    if (!slot.isFinished) {
      // Resend the packet.
      emitPacketByIndex(index, true);
    }
  }

  /**
   * Called when the sender received an ACK.
   */
  void _onSenderReceivedACK(Packet packet, Packet movingPacket, PacketSlot slot) {
    if (_protocol.senderReceivedPacket(packet, movingPacket, slot, _senderSpace, this)) {
      slot.packets.first = null;
      movingPacket.destroy();
      return;
    }

    if (packet != null) {
      int count = 0;
      for (PacketSlot slot in _packetSlots) {
        if (slot.isFinished) {
          count++;
        } else {
          break;
        }
      }

      _senderSpace.setOffset(count);
    }
  }

  /**
   * Called when the receiver received a PKT.
   */
  void _onReceiverReceivedPKT(Packet packet, Packet movingPacket, PacketSlot slot) {
    if (_protocol.receiverReceivedPacket(packet, movingPacket, slot, _receiverSpace, this)) {
      slot.packets.second = null;
      movingPacket.destroy();
      return;
    }

    if (packet != null) {
      int count = 0;
      for (PacketSlot slot in _packetSlots) {
        if (slot.atReceiver) {
          count++;
        } else {
          break;
        }
      }

      _receiverSpace.setOffset(count);
    }
  }

  void reset() {
    _packetSlots.clear();
    _timeoutLabelCache.clear();
    _protocol.reset();
    _senderSpace = new WindowSpaceDrawable(_protocol.getSenderWindowSize());
    _receiverSpace = new WindowSpaceDrawable(_protocol.getReceiverWindowSize());
  }

  List<PacketSlot> get packetSlots => _packetSlots;

}
