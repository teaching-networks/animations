import 'dart:async';

import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_slot.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/window/window_space.dart';

/// Protocol for reliable transmission.
abstract class ReliableTransmissionProtocol {
  /// Name key (translation property key).
  final String nameKey;

  /// Window size.
  int _windowSize;

  /// Is custom timeout enabled
  bool isCustomTimeoutEnabled = false;

  /// Custom timeout
  num customTimeout = 12;

  /// Stream controller for the window size.
  StreamController<int> _windowSizeStream = new StreamController<int>.broadcast();

  /// The protocol is able to emit messages on specific events for logging.
  /// These are provided through this message stream controller.
  StreamController<String> messageStreamController = new StreamController<String>.broadcast();

  /// Create new reliable transmission protocol.
  ReliableTransmissionProtocol(this.nameKey, this._windowSize);

  /// Called when the sender should send a packet.
  /// Returns a packet to be sent.
  /// [timeout] is true when the packet should be send due to a timeout
  Packet senderSendPacket(int index, bool timeout, TransmissionWindow window);

  /// Receiver received [packet], can be null if the packet has already been received. This handles what should happen next.
  /// The method returns whether to discard the packet.
  bool receiverReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window);

  /// Sender received [packet] can be null if the packet has already been received. This handles the following behaviour.
  /// Returns whether to discard the packet.
  bool senderReceivedPacket(Packet packet, Packet movingPacket, PacketSlot slot, WindowSpaceDrawable windowSpace, TransmissionWindow window);

  /// Whether a new packet can be emitted.
  bool canEmitPacket(List<PacketSlot> packetSlots);

  /// Whether window size can be changed.
  bool canChangeWindowSize();

  /// Reset protocol state.
  void reset();

  /// Whether to show timeout for all slots or just for the first active.
  bool showTimeoutForAllSlots();

  /// Set window size to [newSize].
  void set windowSize(int newSize) {
    if (!canChangeWindowSize()) {
      throw new Exception("Protocol cannot change window size.");
    }

    _windowSize = newSize;

    _windowSizeStream.add(_windowSize); // Emit new window size event to stream
  }

  /// Get current value of the window size.
  /// Note that this may change. You might want to subscribe to changes using
  /// the windowSizeStream.
  int get windowSize => _windowSize;

  /// Get window size stream to subscribe to changes.
  Stream<int> get windowSizeStream => _windowSizeStream.stream;

  /// Important events of the protocol are provided as messages through this stream.
  /// You can use these for example for logging.
  Stream<String> get messageStream => messageStreamController.stream;

}
