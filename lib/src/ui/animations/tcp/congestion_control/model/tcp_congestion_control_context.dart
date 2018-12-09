import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_state.dart';

/// Context for TCP congestion control.
class TCPCongestionControlContext {
  /// Slow start threshold (ssthresh).
  int slowStartThreshold = -1;

  /// Congestion window size (cwnd).
  int congestionWindow = 1;

  /// Current state of the congestion control.
  TCPCongestionControlState state = TCPCongestionControlState.SLOW_START;
}
