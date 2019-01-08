import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/drawable_shared_medium_peer.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/signal_emitter/impl/vertical_signal_emitter.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/packet/shared_medium_signal.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/packet/simple_shared_medium_signal.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/shared_medium_peer.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

/// A drawable medium.
class DrawableSharedMedium extends CanvasDrawable implements SharedMedium {
  /// Slow down the animation by a factor of ...
  static const int _slowDownRate = 1000 * 1000;

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

  /// Peer which is currently highlighted.
  DrawableSharedMediumPeer _highlightedPeer;

  /// Timestamp of the start of the animation.
  num _startTimestamp;

  /// TODO Make the next two attributes adjustable
  int bandwidth = 100 * 1000 * 1000;
  int signalSize = 50;

  /// Create drawable medium.
  DrawableSharedMedium({
    @required this.medium,
  }) {
    _init();
  }

  /// Init drawable medium.
  void _init() {
    int idCounter = 1;

    double offset = 1.0 / (medium.getPeers().length - 1);
    int i = 0;

    _peers = medium.getPeers().map((peer) => DrawableSharedMediumPeer(id: idCounter++, peer: peer, position: i++ * offset)).toList(growable: false);
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (_startTimestamp == null) {
      _startTimestamp = timestamp;
    }

    context.save();

    context.translate(rect.left, rect.top);

    _drawPeers(context, _peers, rect, timestamp);

    setFillColor(context, Colors.BLACK);
    context.fillText("Time (in µs): ${((timestamp - _startTimestamp) / (_slowDownRate / 1000)).toStringAsFixed(0)}", 200, 0); // TODO Position correctly

    context.restore();
  }

  /// Draw all peers with connection lines.
  void _drawPeers(CanvasRenderingContext2D context, List<DrawableSharedMediumPeer> peers, Rectangle<double> rect, timestamp) {
    double peerSize = rect.height / peers.length / 2.5;

    double minY = peerSize / 2;
    double maxY = rect.height - peerSize / 2;

    double yDelta = peers.length > 1 ? (maxY - minY) / (peers.length - 1) : 0;
    double yOffset = (peers.length == 1 ? rect.height / 2 - peerSize / 2 : 0);

    double connectionLineLength = window.devicePixelRatio * 20;
    double lineXOffset = peerSize + connectionLineLength;
    double lineYOffset = yOffset + peerSize / 2;
    double lineWidth = window.devicePixelRatio * _lineWidth;

    // Draw connection line
    setFillColor(context, _lineColor);
    context.fillRect(lineXOffset, lineYOffset, lineWidth, maxY - minY + lineWidth);

    double laneWidth = _laneWidth * window.devicePixelRatio;

    // Draw lanes.
    setFillColor(context, _laneBackgroundColor);
    context.fillRect(lineXOffset + lineWidth, lineYOffset, peers.length * laneWidth, maxY - minY + lineWidth);

    for (int i = 0; i < peers.length; i++) {
      final peer = peers[i];

      peer.render(context, Rectangle<double>(0, yOffset, peerSize, peerSize));
      peer.setActualBounds(Rectangle<double>(rect.top, rect.left + yOffset, peerSize, peerSize));

      setFillColor(context, _lineColor);
      context.fillRect(peerSize, yOffset + peerSize / 2, connectionLineLength, lineWidth);

      if (peer.signalEmitter != null) {
        peer.signalEmitter.render(context, Rectangle<double>(lineXOffset + i * laneWidth, lineYOffset, laneWidth, maxY - minY + lineWidth), timestamp);
      }

      yOffset += yDelta;
    }
  }

  /// What to do on mouse up on the shared medium drawable.
  void onMouseUp(Point<double> pos) {
    DrawableSharedMediumPeer peer = _getPeerForMousePos(pos);

    if (peer != null && peer.signalEmitter == null) {
      _sendSignal(peer, SimpleSharedMediumSignal());
    }
  }

  /// Let the passed peer send a signal on the medium.
  void _sendSignal(DrawableSharedMediumPeer peer, SharedMediumSignal signal) {
    double signalTime = _calculateSignalDuration(bandwidth, signalSize) * _slowDownRate;

    peer.signalEmitter = VerticalSignalEmitter(
      start: peer.position,
      signalDuration: Duration(milliseconds: (signalTime * 1000).round()),
      propagationSpeed: 1.0 / medium.getLength() * (medium.getSpeed() / _slowDownRate),
      onEnd: () {
        print("Signal end reached!");
      },
    );

    sendSignal(peer.peer, signal);
  }

  /// Calculate the signal duration in seconds.
  double _calculateSignalDuration(int bandwidth, int signalSize) => signalSize / bandwidth;

  /// What to do on mouse move on the shared medium drawable.
  void onMouseMove(Point<double> pos) {
    DrawableSharedMediumPeer peer = _getPeerForMousePos(pos);

    if (_highlightedPeer != null) {
      _highlightedPeer.setHighlighted(false);
    }

    if (peer != null) {
      // Mouse over peers bounding box.
      peer.setHighlighted(true);
      _highlightedPeer = peer;
    }
  }

  /// Get the peer on the passed mouse [pos] or null if not found.
  DrawableSharedMediumPeer _getPeerForMousePos(Point<double> pos) {
    for (final peer in _peers) {
      if (peer.getActualBounds().containsPoint(pos)) {
        return peer;
      }
    }

    return null;
  }

  @override
  List<SharedMediumPeer> createPeersList() {
    return medium.createPeersList();
  }

  @override
  double getLength() {
    return medium.getLength();
  }

  @override
  List<SharedMediumPeer> getPeers() {
    return medium.getPeers();
  }

  @override
  double getSpeed() {
    return medium.getSpeed();
  }

  @override
  void registerPeer(SharedMediumPeer peer) {
    medium.registerPeer(peer);
  }

  @override
  void sendSignal(SharedMediumPeer peer, SharedMediumSignal signal) {
    medium.sendSignal(peer, signal);
  }

  @override
  void unregisterAll() {
    medium.unregisterAll();
  }

  @override
  void unregisterPeer(SharedMediumPeer peer) {
    medium.unregisterPeer(peer);
  }
}
