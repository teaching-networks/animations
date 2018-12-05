import 'dart:math';

import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/tcp_congestion_control_algorithm.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_context.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_state.dart';

/// Reno algorithm for TCP congestion control.
class TCPReno implements TCPCongestionControlAlgorithm {
  Map<TCPCongestionControlState, TCPCongestionControlAlgorithm> _states = {
    TCPCongestionControlState.SLOW_START: ConfigurableTCPCongestionControlAlgorithm(onAck: (context) {
      context.congestionWindow = max(context.congestionWindow * 2, context.slowStartThreshold);

      if (context.congestionWindow == context.slowStartThreshold) {
        context.state = TCPCongestionControlState.CONGESTION_AVOIDANCE;
      }
    }),
    TCPCongestionControlState.FAST_RECOVERY: ConfigurableTCPCongestionControlAlgorithm(onAck: (context) {
      context.state = TCPCongestionControlState.CONGESTION_AVOIDANCE;
      context.congestionWindow = context.slowStartThreshold;
    }, onDuplicateAck: (context, numberOfDuplicateAcks) {
      context.congestionWindow += 1;
    })
  };

  @override
  void onDuplicateACK(TCPCongestionControlContext context, int numberOfDuplicateACKs) {
    ConfigurableTCPCongestionControlAlgorithm algorithm = _states[context.state];

    if (algorithm != null && algorithm.onDuplicateAckMethod != null) {
      algorithm.onDuplicateACK(context, numberOfDuplicateACKs);
    } else {
      if (numberOfDuplicateACKs == 3) {
        context.state = TCPCongestionControlState.FAST_RECOVERY;
        context.slowStartThreshold = context.congestionWindow ~/ 2;
        context.congestionWindow = context.slowStartThreshold + 3; // "Inflating the window", see RFC 2581.
      }
    }
  }

  @override
  void onTimeout(TCPCongestionControlContext context) {
    context.state = TCPCongestionControlState.SLOW_START;
    context.slowStartThreshold = context.congestionWindow ~/ 2;
    context.congestionWindow = 1;
  }

  @override
  void onACK(TCPCongestionControlContext context) {
    ConfigurableTCPCongestionControlAlgorithm algorithm = _states[context.state];

    if (algorithm != null && algorithm.onAckMethod != null) {
      algorithm.onACK(context);
    } else {
      context.congestionWindow += 1; // Congestion avoidance mode
    }
  }
}
