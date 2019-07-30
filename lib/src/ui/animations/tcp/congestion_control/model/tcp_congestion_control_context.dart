/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_state.dart';

/// Context for TCP congestion control.
class TCPCongestionControlContext {
  /// Slow start threshold (ssthresh).
  int slowStartThreshold = -1;

  /// Congestion window size (cwnd).
  int congestionWindow = 1;

  /// Current state of the congestion control.
  TCPCongestionControlState _state = TCPCongestionControlState.SLOW_START;

  /// How many cycles the context is in the same state.
  int cyclesInState = 0;

  TCPCongestionControlState get state => _state;

  void set state(TCPCongestionControlState newState) {
    cyclesInState = 0;
    _state = newState;
  }
}
