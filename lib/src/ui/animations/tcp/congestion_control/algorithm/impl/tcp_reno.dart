import 'dart:math';

import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/tcp_congestion_control_algorithm.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_context.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_state.dart';

/// Reno algorithm for TCP congestion control.
class TCPReno implements TCPCongestionControlAlgorithm {
  /// Name of the algorithm.
  static const String NAME = "Reno";

  Map<TCPCongestionControlState, TCPCongestionControlAlgorithm> _states = {
    TCPCongestionControlState.SLOW_START: ConfigurableTCPCongestionControlAlgorithm(onAck: (context) {
      context.congestionWindow *= 2;

      if (context.slowStartThreshold != -1 && context.congestionWindow >= context.slowStartThreshold) {
        context.congestionWindow = context.slowStartThreshold;
        context.state = TCPCongestionControlState.CONGESTION_AVOIDANCE;
      }

      return true;
    }),
    TCPCongestionControlState.FAST_RECOVERY: ConfigurableTCPCongestionControlAlgorithm(onAck: (context) {
      context.state = TCPCongestionControlState.CONGESTION_AVOIDANCE;
      context.congestionWindow += 1;

      return true;
    })
  };

  @override
  bool onDuplicateACK(TCPCongestionControlContext context, int numberOfDuplicateACKs) {
    ConfigurableTCPCongestionControlAlgorithm algorithm = _states[context.state];

    if (algorithm != null && algorithm.onDuplicateAckMethod != null) {
      return algorithm.onDuplicateACK(context, numberOfDuplicateACKs);
    } else {
      if (numberOfDuplicateACKs == 3) {
        context.state = TCPCongestionControlState.FAST_RECOVERY;
        context.slowStartThreshold = context.congestionWindow ~/ 2;
        context.congestionWindow = context.slowStartThreshold;

        return true;
      }

      return false;
    }
  }

  @override
  bool onTimeout(TCPCongestionControlContext context) {
    context.state = TCPCongestionControlState.SLOW_START;
    context.slowStartThreshold = context.congestionWindow ~/ 2;
    context.congestionWindow = 1;

    return true;
  }

  @override
  bool onACK(TCPCongestionControlContext context) {
    ConfigurableTCPCongestionControlAlgorithm algorithm = _states[context.state];

    if (algorithm != null && algorithm.onAckMethod != null) {
      return algorithm.onACK(context);
    } else {
      context.congestionWindow += 1; // Congestion avoidance mode
      return false;
    }
  }

  @override
  String getName() {
    return NAME;
  }
}