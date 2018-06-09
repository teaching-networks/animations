import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/window_space.dart';

/// Slow but reliable protocol for the reliable transmission.
class StopAndWaitProtocol extends ReliableTransmissionProtocol {
  /// Name of the protocol as key for translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.stop-and-wait";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 1;

  int _lastPacketSequenceNumber = 1;
  bool _received = true;

  StopAndWaitProtocol() : super(NAME_KEY, INITIAL_WINDOW_SIZE);

  @override
  bool canEmitPacket(List<PacketSlot> packetSlots) {
    return _received;
  }

  @override
  Packet senderSendPacket(int index, bool timeout, TransmissionWindow window) {
    if (_received) {
      _received = false;
      _lastPacketSequenceNumber = _lastPacketSequenceNumber == 0 ? 1 : 0;

      messageStreamController.add("Sender sends PKT_$_lastPacketSequenceNumber");
    } else {
      messageStreamController.add("Sender resends PKT_$_lastPacketSequenceNumber");
    }

    Packet packet = new Packet(number: _lastPacketSequenceNumber);

    return packet;
  }

  @override
  bool receiverReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (packet != null) {
      messageStreamController.add("Receiver received PKT_${packet.number}");
    } else {
      messageStreamController.add("Receiver received PKT_$_lastPacketSequenceNumber which has already been received");
    }

    return false;
  }

  @override
  bool senderReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    _received = true;

    if (packet != null) {
      messageStreamController.add("Sender received ACK_${packet.number}");
    } else {
      messageStreamController.add("Sender received ACK_$_lastPacketSequenceNumber which has already been received");
    }

    return false;
  }

  @override
  bool canChangeWindowSize() {
    return false;
  }

  @override
  void reset() {
    _received = true;
    _lastPacketSequenceNumber = 1;
  }

  @override
  bool showTimeoutForAllSlots() => true;
}
