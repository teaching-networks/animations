import 'package:hm_animations/src/ui/animations/tcp/congestion_control/controller/tcp_congestion_controller.dart';

/// Entity communicating with TCP.
class TCPEntity {
  /// Controller for congestion.
  final TCPCongestionController _controller = TCPCongestionController();

  TCPEntity();

  void receiveACK() {
    _controller.onACKReceived();
  }

  void receiveDuplicateACK(int numberOfDuplicateACKs) {

  }

  void timeoutACK() {

  }
}
