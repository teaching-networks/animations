import 'dart:async';

import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/packet/packet_drawable.dart';

/// Protocol for reliable transmission.
abstract class ReliableTransmissionProtocol {
  /// Name key (translation property key).
  final String nameKey;

  /// Window size.
  int _windowSize;

  /// Stream controller for the window size.
  StreamController<int> _windowSizeStream = new StreamController<int>.broadcast();

  /// The protocol is able to emit messages on specific events for logging.
  /// These are provided through this message stream controller.
  StreamController<String> messageStreamController = new StreamController<String>.broadcast();

  /// Create new reliable transmission protocol.
  ReliableTransmissionProtocol(this.nameKey, this._windowSize);

  /// Called when the sender should send a packet.
  /// Returns a packet to be sent.
  Packet senderSendPacket(int index);

  /// Receiver received [packet], can be null if the packet has already been received. This handles what should happen next.
  /// The method should return the answer packet or null if no packet will be sent.
  Packet receiverReceivedPacket(Packet packet);

  /// Sender received [packet] can be null if the packet has already been received. This handles the following behaviour.
  void senderReceivedPacket(Packet packet);

  /// Whether a new packet can be emitted.
  bool canEmitPacket();

  /// Whether window size can be changed.
  bool canChangeWindowSize();

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
