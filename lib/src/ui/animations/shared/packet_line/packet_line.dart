/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/shared/packet_line/packet_line_packet.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

typedef void PacketArrivalListener(int packetId, Color packetColor, bool forward, Object data);

/// A packet line is a representation for a connection between two points. Packets
/// are sent between the two points, always from A to B.
class PacketLine extends CanvasDrawable with CanvasPausableMixin {
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
      setFillColor(context, Colors.LIGHTER_GRAY);

      context.fillRect(0.0, 0.0, rect.width, rect.height);
    }

    context.restore();
  }

  /// Draw packets currently on the line.
  void _drawPackets(CanvasRenderingContext2D context, Rectangle<double> rect, num timestamp) {
    double packetWidth = rect.width / 20;

    Set<PacketLinePacket> packetsScheduledForRemoval;
    for (PacketLinePacket packet in _packets) {
      if (packet.alive) {
        double progress = packet.lastProgress;

        if (!isPaused) {
          double progress = min((timestamp - packet.birth) / duration.inMilliseconds, 1.0);

          packet.lastProgress = progress;

          if (progress == 1.0) {
            packet.kill();

            if (packetsScheduledForRemoval == null) {
              packetsScheduledForRemoval = new Set<PacketLinePacket>();

              packetsScheduledForRemoval.add(packet);
            }
          }
        }

        if (!packet.forward) {
          progress = 1.0 - progress;
        }

        // Transform progress interval [0.0; 1.0] to real interval [0.0 - packetWidth; width]
        double offset = -packetWidth + (rect.width + packetWidth) * progress;

        double pW = packetWidth;
        if (rect.width < offset + packetWidth) {
          pW = rect.width - offset;
        } else if (offset < 0) {
          pW += offset;
          offset = 0.0;
        }

        packet.render(context, new Rectangle(offset, 0.0, pW, rect.height));
      }
    }

    if (packetsScheduledForRemoval != null) {
      _packets.removeWhere((packet) => packetsScheduledForRemoval.contains(packet));

      packetsScheduledForRemoval.forEach((packet) => onArrival?.call(packet.id, packet.color, packet.forward, packet.data));
    }
  }

  /// Emit a packet on the line.
  /// Returns id of the new packet.
  /// The Id can be used to later determine which packet arrived using the arrival callback.
  int emit({Color color = Colors.BLACK, bool forward = true, Object data = null}) {
    var id = _packetIdGenerator++;

    PacketLinePacket packet = new PacketLinePacket(id, color, forward, data);
    _packets.add(packet);

    return id;
  }

  /// Clear the packet line of packets.
  void clear() {
    _packets.clear();
  }

  @override
  void switchPauseSubAnimations() {
    for (var packet in _packets) {
      packet.switchPause();
    }
  }

  @override
  void unpaused(num timestampDifference) {
    // Do nothing
  }
}
