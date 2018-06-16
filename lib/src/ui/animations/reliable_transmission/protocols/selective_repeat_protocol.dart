import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/window_space.dart';
import 'package:sprintf/sprintf.dart';

/// Commonly used protocol for reliable transmission.
class SelectiveRepeatProtocol extends ReliableTransmissionProtocol {
  /// Name of the protocol as key for the translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.selective-repeat";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 5;

  int _outstanding = 0;

  I18nService _i18n;

  Message _receiverReceivedPktDup;
  Message _receiverReceivedPkt;
  Message _senderReceivedAckDup;
  Message _senderReceivedAck;

  SelectiveRepeatProtocol(this._i18n) : super(NAME_KEY, INITIAL_WINDOW_SIZE) {
    _initTranslations();
  }

  void _initTranslations() {
    _receiverReceivedPktDup = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.receiver-received-pkt-dup");
    _receiverReceivedPkt = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.receiver-received-pkt");
    _senderReceivedAckDup = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.sender-received-ack-dup");
    _senderReceivedAck = _i18n.get("reliable-transmission-animation.protocol.log-messages.selective-repeat.sender-received-ack");
  }

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
      messageStreamController.add(sprintf(_receiverReceivedPktDup.toString(), [movingPacket.number]));
    } else {
      messageStreamController.add(sprintf(_receiverReceivedPkt.toString(), [movingPacket.number]));
    }

    return false;
  }

  @override
  bool senderReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (packet == null) {
      messageStreamController.add(sprintf(_senderReceivedAckDup.toString(), [movingPacket.number]));
    } else {
      _outstanding--;
      messageStreamController.add(sprintf(_senderReceivedAck.toString(), [movingPacket.number]));
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
