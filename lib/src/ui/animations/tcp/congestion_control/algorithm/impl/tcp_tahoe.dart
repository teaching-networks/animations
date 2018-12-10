import 'dart:math';

import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/tcp_congestion_control_algorithm.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_context.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_state.dart';

/// Tahoe algorithm for TCP congestion control.
class TCPTahoe implements TCPCongestionControlAlgorithm {
  /// Name of the algorithm.
  static const String NAME = "Tahoe";

  Map<TCPCongestionControlState, TCPCongestionControlAlgorithm> _states = {
    TCPCongestionControlState.SLOW_START: ConfigurableTCPCongestionControlAlgorithm(onAck: (context) {
      context.congestionWindow *= 2;

      if (context.slowStartThreshold != -1 && context.congestionWindow >= context.slowStartThreshold) {
        context.congestionWindow = context.slowStartThreshold;
        context.state = TCPCongestionControlState.CONGESTION_AVOIDANCE;
      }
    }),
    TCPCongestionControlState.CONGESTION_AVOIDANCE: ConfigurableTCPCongestionControlAlgorithm(onAck: (context) {
      context.congestionWindow += 1;
    })
  };

  @override
  void onDuplicateACK(TCPCongestionControlContext context, int numberOfDuplicateACKs) {
    if (numberOfDuplicateACKs == 3) {
      _changeToSlowStart(context);
    }
  }

  @override
  void onTimeout(TCPCongestionControlContext context) {
    _changeToSlowStart(context);
  }

  @override
  void onACK(TCPCongestionControlContext context) {
    ConfigurableTCPCongestionControlAlgorithm algorithm = _states[context.state];

    if (algorithm == null || algorithm.onAckMethod == null) {
      throw Exception("State $context.state is unknown to the TCP Tahoe congestion control algorithm.");
    }

    _states[context.state].onACK(context);
  }

  void _changeToSlowStart(TCPCongestionControlContext context) {
    context.state = TCPCongestionControlState.SLOW_START;
    context.slowStartThreshold = context.congestionWindow ~/ 2;
    context.congestionWindow = 1;
  }

  @override
  String getName() {
    return NAME;
  }
}
