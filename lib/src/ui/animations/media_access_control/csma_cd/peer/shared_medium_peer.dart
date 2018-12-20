import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/packet/shared_medium_packet.dart';

/// A participant on a shared medium.
abstract class SharedMediumPeer {
  /// Medium the peer is sending and listening on.
  SharedMedium _medium;

  /// Whether the peer is listening to the medium.
  bool _listening = false;

  /// Whether from the peers perception the medium is currently occupied.
  bool _mediumOccupied = false;

  /// Send on the medium.
  void sendSafe(SharedMediumPacket packet) {
    assert(_medium != null);

    send(packet);
  }

  /// Emit the JAM signal on the medium.
  void emitJAMSignalSafe() {
    assert(_medium != null);

    emitJAMSignal();
  }

  /// Set shared medium peer is sending and listing on.
  void setMedium(SharedMedium medium) => _medium = medium;

  /// Get shared medium peer is sending and listing on.
  SharedMedium getMedium() => _medium;

  /// Set the peer to listening mode.
  void setListening(bool listening) => _listening = listening;

  /// Check if the peer is currently listening.
  bool isListening() => _listening;

  /// Set mediums occupied state from the peers perception.
  void setMediumOccupied(bool occupied) => _mediumOccupied = occupied;

  /// Whether the medium is occupied from the peers perception.
  bool isMediumOccupied() => _mediumOccupied;

  /// Send packet on the medium.
  void send(SharedMediumPacket packet);

  /// Emit the JAM signal on the medium.
  void emitJAMSignal();

  /// What to do when a collision has been detected.
  void onCollisionDetected();
}
