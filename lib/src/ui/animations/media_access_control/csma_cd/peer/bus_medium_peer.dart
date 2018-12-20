import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/packet/shared_medium_packet.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/shared_medium_peer.dart';

/// Bus peer (peer on a shared medium).
class BusPeer extends SharedMediumPeer {
  @override
  void emitJAMSignal() {
    // TODO: implement emitJAMSignal
  }

  @override
  void onCollisionDetected() => emitJAMSignalSafe();

  @override
  void send(SharedMediumPacket packet) => getMedium().sendPacket(this, packet);
}
