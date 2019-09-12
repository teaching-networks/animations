/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

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

      return true;
    }),
    TCPCongestionControlState.CONGESTION_AVOIDANCE: ConfigurableTCPCongestionControlAlgorithm(onAck: (context) {
      context.congestionWindow += 1;

      return false;
    })
  };

  @override
  bool onDuplicateACK(TCPCongestionControlContext context, int numberOfDuplicateACKs) {
    if (numberOfDuplicateACKs == 3) {
      _changeToSlowStart(context);
      return true;
    }

    return false;
  }

  @override
  bool onTimeout(TCPCongestionControlContext context) {
    _changeToSlowStart(context);
    return true;
  }

  @override
  bool onACK(TCPCongestionControlContext context) {
    ConfigurableTCPCongestionControlAlgorithm algorithm = _states[context.state];

    if (algorithm == null || algorithm.onAckMethod == null) {
      throw Exception("State $context.state is unknown to the TCP Tahoe congestion control algorithm.");
    }

    return algorithm.onACK(context);
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
