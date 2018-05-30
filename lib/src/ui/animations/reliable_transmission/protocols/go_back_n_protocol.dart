import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';

/// Popular implementation of a reliable transmission protocol, the Go-Back-N Protocol.
class GoBackNProtocol extends ReliableTransmissionProtocol {
  /// Name key of the protocol used for translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.go-back-n";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 3;

  GoBackNProtocol() : super(NAME_KEY, INITIAL_WINDOW_SIZE);

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
