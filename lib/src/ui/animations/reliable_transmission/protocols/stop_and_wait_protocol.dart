/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/window/window_space.dart';
import 'package:hm_animations/src/util/str/message.dart';

/// Slow but reliable protocol for the reliable transmission.
class StopAndWaitProtocol extends ReliableTransmissionProtocol {
  /// Name of the protocol as key for translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.stop-and-wait";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 1;

  int _currentIndex;

  I18nService _i18n;

  IdMessage<String> _senderSendsPktLabel;
  IdMessage<String> _senderResendsPktLabel1;
  IdMessage<String> _senderResendsPktLabel2;
  IdMessage<String> _receiverReceivedPktLabel;
  IdMessage<String> _receiverReceivedPktDupLabel1;
  IdMessage<String> _receiverReceivedPktDupLabel2;
  IdMessage<String> _senderReceivedAckLabel;
  IdMessage<String> _senderReceivedAckDupLabel1;
  IdMessage<String> _senderReceivedAckDupLabel2;

  StopAndWaitProtocol(this._i18n) : super(NAME_KEY, INITIAL_WINDOW_SIZE) {
    _loadTranslations();
  }

  void _loadTranslations() {
    _senderSendsPktLabel = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.send-packet");
    _senderResendsPktLabel1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.resend-packet.1");
    _senderResendsPktLabel2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.resend-packet.2");
    _receiverReceivedPktLabel = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.receiver-received-packet");
    _receiverReceivedPktDupLabel1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.receiver-received-dup-packet.1");
    _receiverReceivedPktDupLabel2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.receiver-received-dup-packet.2");
    _senderReceivedAckLabel = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.received-ack");
    _senderReceivedAckDupLabel1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.received-ack-dup.1");
    _senderReceivedAckDupLabel2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.stop-and-wait.received-ack-dup.2");
  }

  @override
  bool canEmitPacket(List<PacketSlot> packetSlots) =>
      packetSlots == null || packetSlots.isEmpty || (packetSlots.isNotEmpty && packetSlots[_currentIndex].isFinished);

  @override
  Packet senderSendPacket(int index, bool timeout, TransmissionWindow window) {
    int packetNumber = index.isEven ? 0 : 1;

    bool packetSlotFinished = window.packetSlots[index].isFinished;

    if (!packetSlotFinished) {
      _currentIndex = index;

      messageStreamController.add("$_senderSendsPktLabel $packetNumber");
    } else {
      messageStreamController.add("$_senderResendsPktLabel1 $packetNumber $_senderResendsPktLabel2");
    }

    Packet packet = new Packet(number: packetNumber);

    return packet;
  }

  @override
  bool receiverReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (packet != null) {
      messageStreamController.add("$_receiverReceivedPktLabel ${movingPacket.number}");
    } else {
      messageStreamController.add("$_receiverReceivedPktDupLabel1 ${movingPacket.number} $_receiverReceivedPktDupLabel2");
    }

    return false;
  }

  @override
  bool senderReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (packet != null) {
      messageStreamController.add("$_senderReceivedAckLabel ${movingPacket.number}");
    } else {
      messageStreamController.add("$_senderReceivedAckDupLabel1 ${movingPacket.number} $_senderReceivedAckDupLabel2");
    }

    return false;
  }

  @override
  bool canChangeWindowSize() {
    return false;
  }

  @override
  void reset() {
    _currentIndex = 0;
  }

  @override
  bool showTimeoutForAllSlots() => true;
}
