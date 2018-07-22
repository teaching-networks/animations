import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/window/window_space.dart';

/// Popular implementation of a reliable transmission protocol, the Go-Back-N Protocol.
class GoBackNProtocol extends ReliableTransmissionProtocol {
  /// Name key of the protocol used for translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.go-back-n";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 5;

  List<int> _received = new List<int>();
  int _outstanding = 0;

  I18nService _i18n;

  Message _senderRetransmitts1;
  Message _senderRetransmitts2;
  Message _receiverReceivedOutOfOrder1;
  Message _receiverReceivedOutOfOrder2;
  Message _receiverReceivedInOrder1;
  Message _receiverReceivedInOrder2;
  Message _senderReceivedResetTimeout1;
  Message _senderReceivedResetTimeout2;

  GoBackNProtocol(this._i18n) : super(NAME_KEY, INITIAL_WINDOW_SIZE) {
    _loadTranslations();
  }

  void _loadTranslations() {
    _senderRetransmitts1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.retransmitt.1");
    _senderRetransmitts2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.retransmitt.2");
    _receiverReceivedOutOfOrder1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.received-out-of-order.1");
    _receiverReceivedOutOfOrder2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.received-out-of-order.2");
    _receiverReceivedInOrder1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.received-in-order.1");
    _receiverReceivedInOrder2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.received-in-order.2");
    _senderReceivedResetTimeout1 = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.reset-timeout.1");
    _senderReceivedResetTimeout2 = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.reset-timeout.2");
  }

  @override
  bool canEmitPacket(List<PacketSlot> packetSlots) {
    return _outstanding < windowSize;
  }

  @override
  Packet senderSendPacket(int index, bool timeout, TransmissionWindow window) {
    List<Packet> sentConcurrently;
    if (timeout) {
      sentConcurrently = List<Packet>();

      // Resend all outstanding packets.
      int maxIndex = index + _outstanding;
      
      messageStreamController.add("$_senderRetransmitts1 $_outstanding $_senderRetransmitts2");

      _outstanding--; // For the current packet.

      for (int i = index + 1; i < maxIndex; i++) {
        _outstanding--;
        Packet newPacket = window.emitPacketByIndex(i, false, true);
        sentConcurrently.add(newPacket);
      }
    }

    _outstanding++;

    Packet p = new Packet(number: index % _getMaxSequenceNum());

    if (timeout) {
      sentConcurrently.insert(0, p);

      for (Packet packet in sentConcurrently) {
        packet.sentConcurrently = sentConcurrently;
      }
    }

    return p;
  }

  @override
  bool receiverReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (slot.index > windowSpace.getOffset()) {
      messageStreamController.add("$_receiverReceivedOutOfOrder1 ${movingPacket.number} $_receiverReceivedOutOfOrder2");

      movingPacket.number = windowSpace.getOffset() % _getMaxSequenceNum();
      movingPacket.overlayNumber = (movingPacket.number - 1) % _getMaxSequenceNum();

      if (windowSpace.getOffset() == 0) {
        // Special case, no packets yet received -> send no acumulated ACK.
        return true;
      }

      slot.packets.second = null;
    } else {
      if (slot.index == windowSpace.getOffset()) {
        messageStreamController.add("$_receiverReceivedInOrder1 ${movingPacket.number} $_receiverReceivedInOrder2");
      }

      if (movingPacket.sentConcurrently != null) {
        int overlayNumber = movingPacket.number;
        for (Packet packet in movingPacket.sentConcurrently) {
          if (packet.isDestroyed) {
            break;
          } else {
            overlayNumber = packet.number;
          }
        }
        movingPacket.overlayNumber = overlayNumber;
      }
    }

    return false;
  }

  @override
  bool senderReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (windowSpace.getOffset() > slot.index) {
      movingPacket.destroy();
      return false;
    }

    // Cumulative ACK will accept all pending packet acks until the received one.
    for (int i = windowSpace.getOffset(); i < windowSpace.getOffset() + windowSize; i++) {
      if (i % _getMaxSequenceNum() == packet.number) {
        break;
      }

      PacketSlot s = window.packetSlots[i];

      if (s.packets.first == null) {
        s.packets.first = new Packet(number: i % _getMaxSequenceNum(), startState: PacketState.END);
        s.packets.first.changeToAck();
        _outstanding--;
        _received.add(s.index);
      }
    }

    _updateWindowSpaceOffset(window, windowSpace);

    bool destroyPacket = false;

    if (slot.index == windowSpace.getOffset() - 1) {
      _outstanding--;
      _received.add(slot.index);
    } else {
      destroyPacket = true;
    }

    _updateWindowSpaceOffset(window, windowSpace);

    if (_outstanding > 0 && window.packetSlots.length > windowSpace.getOffset()) {
      // Reset timer because there are still missing acks.
      window.packetSlots[windowSpace.getOffset()].resetTimeout(packet);
      messageStreamController.add("$_senderReceivedResetTimeout1 ${packet.number} $_senderReceivedResetTimeout2");
    }

    return destroyPacket;
  }

  void _updateWindowSpaceOffset(TransmissionWindow window, WindowSpaceDrawable windowSpace) {
    int count = 0;
    for (PacketSlot slot in window.packetSlots) {
      if (slot.isFinished) {
        count++;
      } else {
        break;
      }
    }

    windowSpace.setOffset(count);
  }

  int _getMaxSequenceNum() => windowSize + 1;

  @override
  bool canChangeWindowSize() {
    return true;
  }

  @override
  void reset() {
    _outstanding = 0;
    _received.clear();
  }

  @override
  bool showTimeoutForAllSlots() => false;

  @override
  int getReceiverWindowSize() => 1;

}
