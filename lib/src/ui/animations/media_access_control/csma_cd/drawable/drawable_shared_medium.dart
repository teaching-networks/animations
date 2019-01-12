import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/drawable_shared_medium_peer.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/signal_emitter/impl/vertical_signal_emitter.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/shared_medium_peer.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

/// A drawable medium.
class DrawableSharedMedium extends CanvasDrawable implements SharedMedium {
  /// Slow down the animation by a factor of ...
  static const int _slowDownRate = 500 * 1000;

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
  List<SharedMediumPeer> _peers;

  /// Peer which is currently highlighted.
  DrawableSharedMediumPeer _highlightedPeer;

  /// Timestamp of the start of the animation.
  num _startTimestamp;

  /// Bandwidth signals are sent with.
  final int bandwidth;

  /// Size of signals sent on the medium.
  final int signalSize;

  /// Create drawable medium.
  DrawableSharedMedium({
    @required this.medium,
    @required this.bandwidth,
    @required this.signalSize,
  }) {
    _init();
  }

  /// Init drawable medium.
  void _init() {
    _peers = medium.getPeers();
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (_startTimestamp == null) {
      _startTimestamp = timestamp;
    }

    context.save();

    context.translate(rect.left, rect.top);

    _drawPeers(context, _peers, rect, timestamp);

    context.textBaseline = "top";
    context.textAlign = "left";
    setFillColor(context, Colors.DARK_GRAY);
    context.fillText("Time (in µs): ${((timestamp - _startTimestamp) / (_slowDownRate / 1000)).toStringAsFixed(0)}", 0, 0); // TODO Position correctly

    context.restore();
  }

  /// Draw all peers with connection lines.
  void _drawPeers(CanvasRenderingContext2D context, List<SharedMediumPeer> peers, Rectangle<double> rect, timestamp) {
    double peerSize = rect.height / peers.length / 2.5;

    double minY = peerSize / 2;
    double maxY = rect.height - peerSize / 2;

    double yDelta = peers.length > 1 ? (maxY - minY) / (peers.length - 1) : 0;
    double yOffset = (peers.length == 1 ? rect.height / 2 - peerSize / 2 : 0);

    double halfWidth = rect.width / 2;
    double halfPeerSize = peerSize / 2;

    double connectionLineLength = window.devicePixelRatio * 20;
    double lineXOffset = halfWidth + halfPeerSize + connectionLineLength;
    double lineYOffset = yOffset + halfPeerSize;
    double lineWidth = window.devicePixelRatio * _lineWidth;

    // Draw connection line
    setFillColor(context, _lineColor);
    context.fillRect(lineXOffset, lineYOffset, lineWidth, maxY - minY + lineWidth);

    double laneWidth = _laneWidth * window.devicePixelRatio;

    // Draw lanes.
    setFillColor(context, _laneBackgroundColor);
    context.fillRect(lineXOffset + lineWidth, lineYOffset, peers.length * laneWidth, maxY - minY + lineWidth);

    for (int i = 0; i < peers.length; i++) {
      final peer = peers[i] as DrawableSharedMediumPeer;

      peer.render(context, Rectangle<double>(0, yOffset, rect.width, peerSize));
      peer.setActualBounds(Rectangle<double>(rect.left + halfWidth - halfPeerSize, rect.top + yOffset, peerSize, peerSize));

      setFillColor(context, _lineColor);
      context.fillRect(halfWidth + halfPeerSize, yOffset + peerSize / 2, connectionLineLength, lineWidth);

      if (peer.signalEmitter != null) {
        peer.signalEmitter.render(context, Rectangle<double>(lineXOffset + i * laneWidth, lineYOffset, laneWidth, maxY - minY + lineWidth), timestamp);
      }

      yOffset += yDelta;
    }

    _updateOccupiedState();
  }

  /// What to do on mouse up on the shared medium drawable.
  void onMouseUp(Point<double> pos) {
    DrawableSharedMediumPeer peer = _getPeerForMousePos(pos);

    if (peer != null && peer.signalEmitter == null) {
      _sendSignal(peer);
    }
  }

  /// Let the passed peer send a signal on the medium.
  void _sendSignal(DrawableSharedMediumPeer peer) {
    double signalTime = _calculateSignalDuration(bandwidth, signalSize) * _slowDownRate;

    peer.signalEmitter = VerticalSignalEmitter(
      start: peer.position,
      signalDuration: Duration(milliseconds: (signalTime * 1000).round()),
      propagationSpeed: 1.0 / medium.getLength() * (medium.getSpeed() / _slowDownRate),
      color: Color.brighten(peer.color, 0.3),
      onEnd: () {
        peer.signalEmitter = null;
        peer.clearNotes();
      },
    );

    peer.setNotes(["Transmitting"]);
  }

  /// Update the medium occupied state on the peers.
  void _updateOccupiedState() {
    for (final peer in _peers) {
      peer.setMediumOccupied(_checkMediumOccupied(peer));
    }
  }

  /// Check whether the passed [peer] is currently occupied and update its occupied state.
  bool _checkMediumOccupied(DrawableSharedMediumPeer peer) {
    for (var p in _peers) {
      final drawablePeer = p as DrawableSharedMediumPeer;
      if (drawablePeer != peer && drawablePeer.signalEmitter != null) {
        final signalRanges = drawablePeer.signalEmitter.getSignalRanges();

        if (signalRanges.item1 != null && signalRanges.item2 != null) {
          if (_inRange(peer.position, signalRanges.item1) || _inRange(peer.position, signalRanges.item2)) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// Check if passed [value] is in passed [range].
  bool _inRange(double value, Tuple2<double, double> range) => value >= range.item1 && value <= range.item2;

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
      final bounds = (peer as DrawableSharedMediumPeer).getActualBounds();
      if (bounds != null && bounds.containsPoint(pos)) {
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
  void unregisterAll() {
    medium.unregisterAll();
  }

  @override
  void unregisterPeer(SharedMediumPeer peer) {
    medium.unregisterPeer(peer);
  }
}
