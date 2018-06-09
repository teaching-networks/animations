import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/window_space.dart';

/// Popular implementation of a reliable transmission protocol, the Go-Back-N Protocol.
class GoBackNProtocol extends ReliableTransmissionProtocol {
  /// Name key of the protocol used for translations.
  static const String NAME_KEY = "reliable-transmission-animation.protocol.go-back-n";

  /// Initial window size of the protocol.
  static const int INITIAL_WINDOW_SIZE = 3;

  List<int> _received = new List<int>();
  int _outstanding = 0;

  GoBackNProtocol() : super(NAME_KEY, INITIAL_WINDOW_SIZE);

  @override
  bool canEmitPacket(List<PacketSlot> packetSlots) {
    return _outstanding < windowSize;
  }

  @override
  Packet senderSendPacket(int index, bool timeout, TransmissionWindow window) {
    if (timeout) {
      // Resend all outstanding packets.
      int maxIndex = index + _outstanding;

      messageStreamController.add("Sender retransmitts $_outstanding packets after timeout");

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
      messageStreamController.add("PKT_${packet.number} received out of order. Sending cumulative ACK");

      movingPacket.number = windowSpace.getOffset() % windowSize;

      if (windowSpace.getOffset() == 0) {
        // Special case, no packets yet received -> send no acumulated ACK.
        return true;
      }
    } else {
      messageStreamController.add("PKT_${packet.number} received in order. Sending ACK");
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
      messageStreamController.add("Reset timeout for PKT_${windowSpace.getOffset() % windowSize} because sender received ACK");
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
