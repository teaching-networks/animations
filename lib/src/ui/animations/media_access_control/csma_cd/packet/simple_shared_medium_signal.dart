import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/packet/shared_medium_signal.dart';
import 'package:meta/meta.dart';

/// Simple implementation of a shared medium packet sent on a shared medium.
class SimpleSharedMediumSignal implements SharedMediumSignal {
  /// Bandwidth the packet is sent on the medium.
  final int bandwidth;

  /// Size of the packet.
  final int size;

  /// Create shared medium packet.
  SimpleSharedMediumSignal({
    @required this.bandwidth,
    @required this.size,
  });

  @override
  int getBandwidth() => bandwidth;

  @override
  int getSize() => size;
}
