/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'package:hm_animations/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:hm_animations/src/util/pair.dart';

typedef void ArrivalListener(bool isAtSender, Packet packet, Packet movingPacket);
typedef num TimeoutSupplier(Packet packet);

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
   * Index of the slot.
   */
  num index;

  /// Whether addPacket has been called at least once.
  bool _hadPacket = false;

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

  /// Supplier for timeouts.
  TimeoutSupplier timeoutSupplier;

  PacketSlot(this.index, this.timeoutSupplier);

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
    _hadPacket = true;

    _activePackets.add(p);

    p.addStateChangeListener((newState) {
      if (newState == PacketState.AT_RECEIVER) {
        if (_packets.second == null) {
          _packets.second = new Packet(number: p.number, startState: PacketState.END_AT_RECEIVER);
          _notifyArrivalListeners(false, _packets.second, p);
        } else {
          _notifyArrivalListeners(false, null, p);
        }
      } else if (newState == PacketState.END) {
        if (_packets.first == null) {
          _packets.first = p;
          _notifyArrivalListeners(true, _packets.first, p);
        } else {
          _notifyArrivalListeners(true, null, p);
        }

        // Schedule for cleanup.
        _obsolete.add(p);
      }
    });

    timeout = window.performance.now() + timeoutSupplier(p);
  }

  void resetTimeout(Packet p) {
    timeout = window.performance.now() + timeoutSupplier(p);
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

  void _notifyArrivalListeners(bool arrivedAtSender, Packet packet, Packet movingPacket) {
    if (_arrivalListener != null) {
      for (var l in _arrivalListener) {
        l.call(arrivedAtSender, packet, movingPacket);
      }
    }
  }

  /// Whether addPacket has been called at least once.
  bool get hadPacket => _hadPacket;
}
