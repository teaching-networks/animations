import 'dart:html';

import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/util/pair.dart';

typedef void ArrivalListener(bool isAtSender);

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
   * List of arrival listeners being notified when a pkt arrives at sender or receiver.
   */
  List<ArrivalListener> _arrivalListener;

  /**
   * Whether the sender has received an ACK yet.
   */
  bool get isFinished => _packets.isFilled;

  /**
   * Whether the receiver has received an PKT yet.
   */
  bool get atReceiver => _packets.second != null;

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
        _notifyArrivalListeners(false);
      } else if (newState == PacketState.END && _packets.first == null) {
        if (_packets.first == null) {
          _packets.first = p;
          _notifyArrivalListeners(true);
        }

        // Schedule for cleanup.
        _obsolete.add(p);
      }
    });

    timeout = window.performance.now() + p.duration.inMilliseconds * 2;
  }

  void addArrivalListener(ArrivalListener l) {
    if (_arrivalListener == null) {
      _arrivalListener = new List<ArrivalListener>();
    }

    _arrivalListener.add(l);
  }

  void removeArrivalListener(ArrivalListener l) {
    if (_arrivalListener != null) {
      _arrivalListener.remove(l);
    }
  }

  void _notifyArrivalListeners(bool arrivedAtSender) {
    if (_arrivalListener != null) {
      for (var l in _arrivalListener) {
        l.call(arrivedAtSender);
      }
    }
  }
}