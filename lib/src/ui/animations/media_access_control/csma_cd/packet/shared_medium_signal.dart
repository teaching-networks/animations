/// Packet on a shared medium.
abstract class SharedMediumSignal {
  /// Size of the packet in bytes.
  int getSize();

  /// Get the bandwidth this packet is sent with.
  int getBandwidth();
}
