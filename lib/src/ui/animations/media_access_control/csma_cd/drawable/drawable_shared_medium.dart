import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/drawable_shared_medium_peer.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/shared_medium.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/mutable_progress.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';
import 'package:meta/meta.dart';

/// A drawable medium.
class DrawableSharedMedium extends CanvasDrawable {
  /// Color for lines between peers.
  static const Color _lineColor = Color.hex(0xFFDDDDDD);

  /// Background color for the lanes.
  static const Color _laneBackgroundColor = Color.hex(0xFFEAEAEA);

  /// Width of the line between peers.
  static const int _lineWidth = 3;

  /// Width of a shared medium lane.
  static const int _laneWidth = 20;

  /// Medium to draw.
  final SharedMedium medium;

  /// Drawable peers from medium.
  List<DrawableSharedMediumPeer> _peers;

  /// Create drawable medium.
  DrawableSharedMedium({
    @required this.medium,
  }) {
    _init();
  }

  /// Init drawable medium.
  void _init() {
    int idCounter = 1;
    _peers = medium.getPeers().map((peer) => DrawableSharedMediumPeer(id: idCounter++, peer: peer)).toList(growable: false);
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    context.translate(rect.left, rect.top);

    _drawPeers(context, _peers, rect.height);

    context.restore();
  }

  /// Draw all peers with connection lines.
  void _drawPeers(CanvasRenderingContext2D context, List<DrawableSharedMediumPeer> peers, double height) {
    double peerSize = height / peers.length / 2.5;

    double minY = peerSize / 2;
    double maxY = height - peerSize / 2;

    double yDelta = peers.length > 1 ? (maxY - minY) / (peers.length - 1) : 0;
    double yOffset = (peers.length == 1 ? height / 2 - peerSize / 2 : 0);

    double connectionLineLength = window.devicePixelRatio * 20;
    double lineXOffset = peerSize + connectionLineLength;
    double lineYOffset = yOffset + peerSize / 2;
    double lineWidth = window.devicePixelRatio * _lineWidth;

    setFillColor(context, _lineColor);

    for (final peer in peers) {
      peer.render(context, Rectangle<double>(0, yOffset, peerSize, peerSize));

      context.fillRect(peerSize, yOffset + peerSize / 2, connectionLineLength, lineWidth);

      yOffset += yDelta;
    }

    // Draw connection line
    context.fillRect(lineXOffset, lineYOffset, lineWidth, maxY - minY + lineWidth);

    // Draw lanes.
    setFillColor(context, _laneBackgroundColor);
    context.fillRect(lineXOffset + lineWidth, lineYOffset, peers.length * _laneWidth * window.devicePixelRatio, maxY - minY + lineWidth);

    for (int i = 0; i < peers.length; i++) {}
  }
}
