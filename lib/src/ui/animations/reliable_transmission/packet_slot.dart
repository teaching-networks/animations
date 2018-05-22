import 'dart:html';

import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet_drawable.dart';
import 'package:netzwerke_animationen/src/util/pair.dart';

/**
 * Slot for packets is a representation of a connection from sender to receiver.
 */
class PacketSlot {

  /**
   * Packet pair, one for sender, one for receiver.
   * Once this is filled, the transmission was successful.
   */
  final Pair<Packet, Packet> _packets = new Pair<Packet, Packet>();

  /**
   * Packets being actively send (in progress);
   */
  final List<Packet> _activePackets = new List<Packet>();

  /**
   * When the packet slot times out and sends a new packet.
   */
  num timeout;

  /**
   * Whether the sender has not received an ACK yet.
   */
  bool get isFinished => _packets.isFilled;

  /**
   * Get packets at sender and at receiver (can be null).
   */
  Pair<Packet, Packet> get packets => _packets;

  /**
   * get list of active packets (Currently being moved around).
   */
  List<Packet> get activePackets => _activePackets;

  /**
   * Packets which are waiting for removal are stored in here.
   */
  List<Packet> _obsolete = new List<Packet>();

  /**
   * Clean obsolete objects.
   * NOTE: Only call this if you know that no other threads are currently using this, otherwise
   * you might get a concurrent modification error.
   */
  void cleanup() {
    for (Packet p in _obsolete) {
      _activePackets.remove(p);
    }

    _obsolete.clear();
  }

  /**
   * Add packet to the slot.
   */
  void addPacket(Packet p) {
    _activePackets.add(p);

    p.addStateChangeListener((newState) {
      if (newState == PacketState.AT_RECEIVER && _packets.second == null) {
        _packets.second = new Packet(number: p.number, startState: PacketState.END_AT_RECEIVER);
      } else if (newState == PacketState.END && _packets.first == null) {
        if (_packets.first == null) {
          _packets.first = p;
        }

        // Schedule for cleanup.
        _obsolete.add(p);
      }
    });

    timeout = window.performance.now() + p.duration.inMilliseconds * 2;
  }
}