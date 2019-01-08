import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/packet/shared_medium_signal.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/shared_medium_peer.dart';

/// Bus peer (peer on a shared medium).
class BusPeer extends SharedMediumPeer {
  @override
  void onCollisionDetected() {
    // TODO Implement
  }

  @override
  void send(SharedMediumSignal packet) => getMedium().sendSignal(this, packet);
}
