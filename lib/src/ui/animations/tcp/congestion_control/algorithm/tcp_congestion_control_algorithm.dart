import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_context.dart';

/// Algorithm dealing with TCP congestion control.
/// It mainly decides what should happen on a timeout or three duplicate ACK packets (4 ACKs for the same packet).
abstract class TCPCongestionControlAlgorithm {
  /// What should happen if a timeout happens.
  void onTimeout(TCPCongestionControlContext context);

  /// What should happen if duplicate ACKs have been received.
  void onDuplicateACK(TCPCongestionControlContext context, int numberOfDuplicateACKs);

  /// What should happen if an ACK has been received (non-duplicate).
  void onACK(TCPCongestionControlContext context);
}

typedef void OnAck(TCPCongestionControlContext context);
typedef void OnTimeout(TCPCongestionControlContext context);
typedef void OnDuplicateAck(TCPCongestionControlContext context, int numberOfDuplicateACKs);

/// From outside configurable congestion control algorithm.
class ConfigurableTCPCongestionControlAlgorithm implements TCPCongestionControlAlgorithm {
  final OnAck onAckMethod;
  final OnTimeout onTimeoutMethod;
  final OnDuplicateAck onDuplicateAckMethod;

  ConfigurableTCPCongestionControlAlgorithm({OnAck onAck, OnTimeout onTimeout, OnDuplicateAck onDuplicateAck})
      : onAckMethod = onAck,
        onTimeoutMethod = onTimeout,
        onDuplicateAckMethod = onDuplicateAck;

  @override
  void onACK(TCPCongestionControlContext context) {
    onAckMethod(context);
  }

  @override
  void onDuplicateACK(TCPCongestionControlContext context, int numberOfDuplicateACKs) {
    onDuplicateAckMethod(context, numberOfDuplicateACKs);
  }

  @override
  void onTimeout(TCPCongestionControlContext context) {
    onTimeoutMethod(context);
  }
}
