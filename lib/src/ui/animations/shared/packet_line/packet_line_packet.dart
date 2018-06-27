import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';

/// Packet on a packet line.
class PacketLinePacket extends CanvasDrawable {
  /// Id of the packet.
  final int id;

  /// Timestamp of the birth of the packet.
  num _birthTimestamp;

  /// Whether the packet is still running.
  bool _alive = true;

  /// Create new packet line packet.
  PacketLinePacket(this.id) {
    _birthTimestamp = window.performance.now();
  }

  /// Get the birth timestamp of the packet.
  /// Can be used to calculate the progress of the packet in an animation.
  num get birth => _birthTimestamp;

  /// Whether the packet is still running.
  bool get alive => _alive;

  /// Kill the packet (in case it is not moving anymore).
  void kill() {
    _alive = false;
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    {
      context.setFillColorRgb(0, 0, 0);
      context.fillRect(rect.left, rect.top, rect.width, rect.height);
    }

    context.restore();
  }
}
