import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/shared_medium_peer.dart';

/// A shared medium is for example a bus.
abstract class SharedMedium {
  /// Peers listening and sending on the medium.
  List<SharedMediumPeer> _peers;

  /// Register a peer listening and sending on the medium.
  void registerPeer(SharedMediumPeer peer) {
    getPeers().add(peer);
  }

  /// Unregister a peer formerly listening and sending on the medium.
  void unregisterPeer(SharedMediumPeer peer) => getPeers().remove(peer);

  /// Unregister all peers on the medium.
  void unregisterAll() => getPeers().clear();

  /// Get peers listening and sending on the medium.
  List<SharedMediumPeer> getPeers() {
    if (_peers == null) {
      _peers = createPeersList();
    }

    return _peers;
  }

  /// Create list holding peers.
  List<SharedMediumPeer> createPeersList() => new List<SharedMediumPeer>();

  /// Propagation speed of the medium in m/s.
  double getSpeed();

  /// Length of the medium in m.
  double getLength();
}
