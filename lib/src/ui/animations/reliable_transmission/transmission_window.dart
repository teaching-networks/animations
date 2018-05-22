import 'dart:html';
import 'dart:math';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet_slot.dart';
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
  static const int DEFAULT_WINDOW_SIZE = 3;

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
  final List<PacketSlot> _packetSlots = new List<PacketSlot>();

  /**
   * Last timeout countdowns are saved here (used to display the old countdown while animation is paused).
   */
  final Map<int, int> _timeoutLabelCache = new Map<int, int>();

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
      PacketSlot slot = _packetSlots[i];

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
    PacketSlot slot;
    if (_packetSlots.length <= index) {
      slot = new PacketSlot();
      _packetSlots.add(slot);
    } else {
      slot = _packetSlots[index];
    }

    Packet p = new Packet(number: index);
    slot.addPacket(p);
  }

  /**
   * Whether window is able to transmit another packet.
   */
  bool canEmitPacket() => _packetSlots.where((slot) => !slot.isFinished).length < _windowSize;

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
      _emitPacket(index);
    }
  }

}
