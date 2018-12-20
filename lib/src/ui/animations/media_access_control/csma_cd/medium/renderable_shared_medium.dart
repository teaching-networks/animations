import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/packet/shared_medium_packet.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/shared_medium_peer.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';

/// Renderable shared medium.
class RenderableSharedMedium extends CanvasDrawable implements SharedMedium {
  /// Wrapped shared medium which will be rendered.
  final SharedMedium _delegate;

  /// Create renderable shared medium.
  RenderableSharedMedium(this._delegate);

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    // TODO: implement render
  }

  @override
  List<SharedMediumPeer> createPeersList() => _delegate.createPeersList();

  @override
  double getLength() => _delegate.getLength();

  @override
  List<SharedMediumPeer> getPeers() => _delegate.getPeers();

  @override
  double getSpeed() => _delegate.getSpeed();

  @override
  void registerPeer(SharedMediumPeer peer) => _delegate.registerPeer(peer);

  @override
  void sendPacket(SharedMediumPeer peer, SharedMediumPacket packet) => _delegate.sendPacket(peer, packet);

  @override
  void unregisterAll() => _delegate.unregisterAll();

  @override
  void unregisterPeer(SharedMediumPeer peer) => _delegate.unregisterPeer(peer);
}
