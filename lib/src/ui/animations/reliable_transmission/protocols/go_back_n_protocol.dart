import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/window_space.dart';
import 'package:sprintf/sprintf.dart';

/// Popular implementation of a reliable transmission protocol, the Go-Back-N Protocol.
class GoBackNProtocol extends ReliableTransmissionProtocol {
  /// Name key of the protocol used for translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.go-back-n";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 5;

  List<int> _received = new List<int>();
  int _outstanding = 0;

  I18nService _i18n;

  Message _senderRetransmitts;
  Message _receiverReceivedOutOfOrder;
  Message _receiverReceivedInOrder;
  Message _senderReceivedResetTimeout;

  GoBackNProtocol(this._i18n) : super(NAME_KEY, INITIAL_WINDOW_SIZE) {
    _loadTranslations();
  }

  void _loadTranslations() {
    _senderRetransmitts = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.retransmitt");
    _receiverReceivedOutOfOrder = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.received-out-of-order");
    _receiverReceivedInOrder = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.received-in-order");
    _senderReceivedResetTimeout = _i18n.get("reliable-transmission-animation.protocol.log-messages.go-back-n.reset-timeout");
  }

  @override
  bool canEmitPacket(List<PacketSlot> packetSlots) {
    return _outstanding < windowSize;
  }

  @override
  Packet senderSendPacket(int index, bool timeout, TransmissionWindow window) {
    if (timeout) {
      // Resend all outstanding packets.
      int maxIndex = index + _outstanding;

      messageStreamController.add(sprintf(_senderRetransmitts.toString(), [_outstanding]));

      _outstanding--; // For the current packet.

      for (int i = index + 1; i < maxIndex; i++) {
        _outstanding--;
        window.emitPacketByIndex(i, false);
      }
    }

    _outstanding++;

    return new Packet(number: index % windowSize);
  }

  @override
  bool receiverReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    if (slot.index > windowSpace.getOffset()) {
      messageStreamController.add(sprintf(_receiverReceivedOutOfOrder.toString(), [movingPacket.number]));

      movingPacket.number = windowSpace.getOffset() % windowSize;
      movingPacket.overlayNumber = (movingPacket.number - 1) % windowSize;

      if (windowSpace.getOffset() == 0) {
        // Special case, no packets yet received -> send no acumulated ACK.
        return true;
      }
    } else {
      messageStreamController.add(sprintf(_receiverReceivedInOrder.toString(), [movingPacket.number]));
    }

    return false;
  }

  @override
  bool senderReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window) {
    // Cumulative ACK will accept all pending packet acks until the received one.
    for (int i = windowSpace.getOffset(); i < windowSpace.getOffset() + windowSize; i++) {
      if (i % windowSize == packet.number) {
        break;
      }

      PacketSlot s = window.packetSlots[i];

      if (s.packets.first == null) {
        s.packets.first = new Packet(number: i % windowSize, startState: PacketState.END);
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
      messageStreamController.add(sprintf(_senderReceivedResetTimeout.toString(), [packet.overlayNumber != null ? packet.overlayNumber : packet.number]));
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
}
