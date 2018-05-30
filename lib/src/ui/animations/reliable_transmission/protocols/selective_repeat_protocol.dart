import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';

/// Commonly used protocol for reliable transmission.
class SelectiveRepeatProtocol extends ReliableTransmissionProtocol {
  /// Name of the protocol as key for the translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.selective-repeat";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 5;

  SelectiveRepeatProtocol() : super(NAME_KEY, INITIAL_WINDOW_SIZE);

  @override
  bool canEmitPacket() {
    return false;
  }

  @override
  Packet senderSendPacket(int index) {
    return new Packet(number: index);
  }

  @override
  Packet receiverReceivedPacket(Packet packet) {
    if (packet != null) {
      messageStreamController.add("Receiver received packet");
    } else {
      messageStreamController.add("Receiver received packet which has already been received");
    }

    return null;
  }

  @override
  void senderReceivedPacket(Packet packet) {
    if (packet != null) {
      messageStreamController.add("Sender received packet");
    } else {
      messageStreamController.add("Sender received packet which has already been received");
    }
  }

  @override
  bool canChangeWindowSize() {
    return true;
  }
}
