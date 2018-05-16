import 'dart:html';
import 'dart:math';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_drawable.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/edges.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/size_type.dart';
import 'package:netzwerke_animationen/src/ui/canvas/util/colors.dart';
import 'package:netzwerke_animationen/src/util/pair.dart';
import 'package:netzwerke_animationen/src/util/size.dart';

/**
 * Receive or Send window for reliable transmission.
 */
class TransmissionWindow extends CanvasDrawable {

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
  final List<Pair<Packet, Packet>> _packets = new List<Pair<Packet, Packet>>();

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
    _drawWindowArray(context, windowSize);

    context.save();
    context.translate(0.0, rect.height - windowSize.height);
    // Draw receiver window array
    _drawWindowArray(context, windowSize);
    context.restore();

    // Draw packets (if any)
    double slotWidth = windowSize.width / _length;
    Size packetSize = new Size(windowSize.width / _length - SLOT_PADDING * 2, windowSize.height);
    Point<double> target = new Point(0.0, rect.height - windowSize.height);

    for (int i = 0; i < _packets.length; i++) {
      Pair<Packet, Packet> pair = _packets[i];

      context.save();
      context.translate(i * slotWidth + SLOT_PADDING, 0.0);

      pair.first.setActualOffset(maxLabelWidth + i * slotWidth + SLOT_PADDING, 0.0);

      pair.second?.render(context, toRect(target.x, target.y, packetSize));
      pair.first.draw(context, packetSize, target, timestamp);

      context.restore();
    }

    context.restore();
  }

  void _drawWindowArray(CanvasRenderingContext2D context, Size size) {
    double width = size.width / _length;
    double height = size.height;

    context.setFillColorRgb(0, 0, 0);
    for (int i = 0; i < _length; i++) {
      Rectangle<double> r = new Rectangle(i * width + SLOT_PADDING, 0.0, width - SLOT_PADDING * 2, height);

      _packetPlaceRect.render(context, r, 0);
    }
  }

  void emitPacket() {
    Packet p = new Packet(number: _packets.length);

    Pair<Packet, Packet> packetPair = new Pair<Packet, Packet>(p, null);

    p.addStateChangeListener((newState) {
      if (newState == PacketState.AT_RECEIVER) {
        packetPair.second = new Packet(number: p.number);
      }
    });

    _packets.add(packetPair);
  }

  bool canEmitPacket() => _packets.where((packet) => packet.first.inProgress).length < _windowSize;

  void onClick(Point<double> pos) {
    for (var pair in _packets) {
      var bounds = pair.first.getActualBounds();

      if (bounds.containsPoint(pos)) {
        pair.first.onClick();
        break;
      }
    }
  }

}
