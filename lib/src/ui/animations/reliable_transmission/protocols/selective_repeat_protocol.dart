import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/window_space.dart';

/// Commonly used protocol for reliable transmission.
class SelectiveRepeatProtocol extends ReliableTransmissionProtocol {
  /// Name of the protocol as key for the translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.selective-repeat";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 5;

  int _outstanding = 0;

  SelectiveRepeatProtocol(I18nService i18n) : super(NAME_KEY, INITIAL_WINDOW_SIZE);

  @override
  bool canEmitPacket(List<PacketSlot> packetSlots) {
    return _outstanding < windowSize;
  }

  @override
  Packet senderSendPacket(int index, bool timeout, TransmissionWindow window) {
    if (!timeout) {
      _outstanding++;
    }

    return new Packet(number: index % windowSize);
  }

  @override
  bool receiverReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (packet == null) {
      messageStreamController.add("PKT_${movingPacket.number} has already been received. Resending ACK");
    } else {
      messageStreamController.add("PKT_${movingPacket.number} has been received. Sending ACK");
    }

    return false;
  }

  @override
  bool senderReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (packet == null) {
      messageStreamController.add("Sender received ACK_${movingPacket.number} which it already received");
    } else {
      _outstanding--;
      messageStreamController.add("Sender received ACK_${movingPacket.number}");
    }

    return false;
  }

  @override
  bool canChangeWindowSize() {
    return true;
  }

  @override
  void reset() {
    _outstanding = 0;
  }

  @override
  bool showTimeoutForAllSlots() => true;
}
