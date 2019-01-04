import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/packet/shared_medium_signal.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/shared_medium_peer.dart';
import 'package:meta/meta.dart';

/// Bus as shared medium.
class BusSharedMedium extends SharedMedium {
  /// Length of the bus.
  final double _length;

  /// Propagation speed of the bus.
  final double _speed;

  /// Create bus shared medium.
  BusSharedMedium({@required double length, @required double speed})
      : _length = length,
        _speed = speed;

  @override
  double getLength() => _length;

  @override
  double getSpeed() => _speed;

  @override
  void sendSignal(SharedMediumPeer peer, SharedMediumSignal signal) {
    // TODO: implement sendPacket
  }
}
