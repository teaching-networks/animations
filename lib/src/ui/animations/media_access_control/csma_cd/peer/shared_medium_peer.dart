import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/shared_medium.dart';

/// A participant on a shared medium.
abstract class SharedMediumPeer {
  /// Get shared medium peer is sending and listing on.
  SharedMedium getMedium();

  /// Check if the peer is currently listening.
  bool isListening();

  /// Set whether the medium is occupied.
  void setMediumOccupied(bool isOccupied);

  /// Whether the medium is occupied from the peers perception.
  bool isMediumOccupied();

  /// Whether the peer is currently sending.
  bool isSending();

  /// Send packet on the medium.
  void send();

  /// What to do when a collision has been detected.
  void onCollisionDetected();
}
