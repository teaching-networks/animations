/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';

/// Packet on a packet line.
class PacketLinePacket extends CanvasDrawable with CanvasPausableMixin {
  /// Id of the packet.
  final int id;

  /// Color of the packet.
  final Color color;

  /// Direction of the packet. Either forward or backward.
  final bool forward;

  /// Data to transmit.
  final Object data;

  /// Timestamp of the birth of the packet.
  num _birthTimestamp;

  /// Whether the packet is still running.
  bool _alive = true;

  double lastProgress = 0.0;

  /// Create new packet line packet.
  PacketLinePacket(this.id, this.color, this.forward, this.data) {
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
      setFillColor(context, color);
      context.fillRect(rect.left, rect.top, rect.width, rect.height);
    }

    context.restore();
  }

  @override
  void switchPauseSubAnimations() {
    // Do nothing
  }

  @override
  void unpaused(num timestampDifference) {
    _birthTimestamp += timestampDifference;
  }
}
