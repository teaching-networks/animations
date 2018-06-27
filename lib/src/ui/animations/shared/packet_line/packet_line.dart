import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/shared/packet_line/packet_line_packet.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

typedef void PacketArrivalListener(int packetId);

/// A packet line is a representation for a connection between two points. Packets
/// are sent between the two points, always from A to B.
class PacketLine extends CanvasDrawable {
  /// Default duration a packet is on the line.
  static const Duration DEFAULT_DURATION = const Duration(seconds: 3);

  /// Counter to generate ids for packets.
  int _packetIdGenerator = 0;

  /// Listener called when a packet arrives.
  final PacketArrivalListener onArrival;

  /// Packets currently in the line.
  List<PacketLinePacket> _packets = new List<PacketLinePacket>();

  /// Duration the packet is on the line.
  final Duration duration;

  /// Create new packet line.
  PacketLine({this.duration = DEFAULT_DURATION, this.onArrival});

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    {
      context.translate(rect.left, rect.top);

      _drawLine(context, rect);
      _drawPackets(context, rect, timestamp);
    }

    context.restore();
  }

  /// Draw line the packets are on.
  void _drawLine(CanvasRenderingContext2D context, Rectangle<double> rect) {
    context.save();

    {
      setFillColor(context, Colors.WHITE);
      setStrokeColor(context, Colors.BLACK);
      context.lineWidth = 1;

      context.fillRect(0.0, 0.0, rect.width, rect.height);
      context.strokeRect(0.0, 0.0, rect.width, rect.height);
    }

    context.restore();
  }

  /// Draw packets currently on the line.
  void _drawPackets(CanvasRenderingContext2D context, Rectangle<double> rect, num timestamp) {
    double packetWidth = rect.width / 20;

    Set<int> packetsScheduledForRemoval;
    for (PacketLinePacket packet in _packets) {
      if (packet.alive) {
        double progress = (timestamp - packet.birth) / duration.inMilliseconds;

        // Transform progress interval [0.0; 1.0] to real interval [0.0 - packetWidth; width]
        double offset = -packetWidth + (rect.width + packetWidth) * progress;

        packet.render(context, new Rectangle(offset, 0.0, packetWidth, rect.height));
      } else {
        if (packetsScheduledForRemoval == null) {
          packetsScheduledForRemoval = new Set<int>();
        }

        packetsScheduledForRemoval.add(packet.id);
      }
    }

    if (packetsScheduledForRemoval != null) {
      _packets.removeWhere((packet) => packetsScheduledForRemoval.contains(packet.id));
    }
  }

  /// Emit a packet on the line.
  /// Returns id of the new packet.
  /// The Id can be used to later determine which packet arrived using the arrival callback.
  int emit() {
    var id = _packetIdGenerator++;

    PacketLinePacket packet = new PacketLinePacket(id);
    _packets.add(packet);

    new Future.delayed(duration, () {
      print("Packet ${packet.id} arrived.");

      packet.kill();

      onArrival?.call(packet.id);
    });

    print("Emitted packet ${packet.id}");

    return id;
  }
}
