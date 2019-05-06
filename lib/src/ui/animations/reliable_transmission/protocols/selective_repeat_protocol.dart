import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/window/window_space.dart';

/// Commonly used protocol for reliable transmission.
class SelectiveRepeatProtocol extends ReliableTransmissionProtocol {
  /// Name of the protocol as key for the translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.selective-repeat";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 5;

  int _outstanding = 0;

  I18nService _i18n;

  Message _receiverReceivedPktDup1;
  Message _receiverReceivedPktDup2;
  Message _receiverReceivedPkt1;
  Message _receiverReceivedPkt2;
  Message _senderReceivedAckDup1;
  Message _senderReceivedAckDup2;
  Message _senderReceivedAck;

  SelectiveRepeatProtocol(this._i18n) : super(NAME_KEY, INITIAL_WINDOW_SIZE) {
    _initTranslations();
  }

  void _initTranslations() {
    _receiverReceivedPktDup1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.receiver-received-pkt-dup.1");
    _receiverReceivedPktDup2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.receiver-received-pkt-dup.2");
    _receiverReceivedPkt1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.receiver-received-pkt.1");
    _receiverReceivedPkt2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.receiver-received-pkt.2");
    _senderReceivedAckDup1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.sender-received-ack-dup.1");
    _senderReceivedAckDup2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.sender-received-ack-dup.2");
    _senderReceivedAck = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.sender-received-ack");
  }

  @override
  bool canEmitPacket(List<PacketSlot> packetSlots) {
    int diff = 0;
    bool count = false;
    for (final slot in packetSlots) {
      if (count && slot.isFinished) {
        diff++;
      }

      if (!slot.isFinished) {
        count = true;
      }
    }

    return _outstanding + diff < windowSize;
  }

  @override
  Packet senderSendPacket(int index, bool timeout, TransmissionWindow window) {
    if (!timeout) {
      _outstanding++;
    }

    return new Packet(number: index % (windowSize * 2));
  }

  @override
  bool receiverReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (packet == null) {
      messageStreamController.add("$_receiverReceivedPktDup1 ${movingPacket.number} $_receiverReceivedPktDup2");
    } else {
      messageStreamController.add("$_receiverReceivedPkt1 ${movingPacket.number} $_receiverReceivedPkt2");
    }

    return false;
  }

  @override
  bool senderReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (packet == null) {
      messageStreamController.add("$_senderReceivedAckDup1 ${movingPacket.number} $_senderReceivedAckDup2");
    } else {
      _outstanding--;
      messageStreamController.add("$_senderReceivedAck ${movingPacket.number}");
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
