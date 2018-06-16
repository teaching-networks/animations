import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/window_space.dart';
import 'package:sprintf/sprintf.dart';

/// Slow but reliable protocol for the reliable transmission.
class StopAndWaitProtocol extends ReliableTransmissionProtocol {
  /// Name of the protocol as key for translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.stop-and-wait";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 1;

  int _lastPacketSequenceNumber = 1;
  bool _received = true;

  I18nService _i18n;

  Message _senderSendsPktLabel;
  Message _senderResendsPktLabel;
  Message _receiverReceivedPktLabel;
  Message _receiverReceivedPktDupLabel;
  Message _senderReceivedAckLabel;
  Message _senderReceivedAckDupLabel;

  StopAndWaitProtocol(this._i18n) : super(NAME_KEY, INITIAL_WINDOW_SIZE) {
    _loadTranslations();
  }

  void _loadTranslations() {
    _senderSendsPktLabel = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.send-packet");
    _senderResendsPktLabel = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.resend-packet");
    _receiverReceivedPktLabel = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.receiver-received-packet");
    _receiverReceivedPktDupLabel = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.receiver-received-dup-packet");
    _senderReceivedAckLabel = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.received-ack");
    _senderReceivedAckDupLabel = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.received-ack-dup");
  }

  @override
  bool canEmitPacket(List<PacketSlot> packetSlots) {
    return _received;
  }

  @override
  Packet senderSendPacket(int index, bool timeout, TransmissionWindow window) {
    if (_received) {
      _received = false;
      _lastPacketSequenceNumber = _lastPacketSequenceNumber == 0 ? 1 : 0;

      messageStreamController.add(sprintf(_senderSendsPktLabel.toString(), [_lastPacketSequenceNumber]));
    } else {
      messageStreamController.add(sprintf(_senderResendsPktLabel.toString(), [_lastPacketSequenceNumber]));
    }

    Packet packet = new Packet(number: _lastPacketSequenceNumber);

    return packet;
  }

  @override
  bool receiverReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (packet != null) {
      messageStreamController.add(sprintf(_receiverReceivedPktLabel.toString(), [movingPacket.number]));
    } else {
      messageStreamController.add(sprintf(_receiverReceivedPktDupLabel.toString(), [_lastPacketSequenceNumber]));
    }

    return false;
  }

  @override
  bool senderReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    _received = true;

    if (packet != null) {
      messageStreamController.add(sprintf(_senderReceivedAckLabel.toString(), [movingPacket.number]));
    } else {
      messageStreamController.add(sprintf(_senderReceivedAckDupLabel.toString(), [_lastPacketSequenceNumber]));
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
