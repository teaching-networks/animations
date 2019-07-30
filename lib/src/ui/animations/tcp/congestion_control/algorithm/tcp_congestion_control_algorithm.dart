/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_context.dart';

/// Algorithm dealing with TCP congestion control.
/// It mainly decides what should happen on a timeout or three duplicate ACK packets (4 ACKs for the same packet).
abstract class TCPCongestionControlAlgorithm {
  /// What should happen if a timeout happens.
  /// Return whether it is an important event.
  bool onTimeout(TCPCongestionControlContext context);

  /// What should happen if duplicate ACKs have been received.
  /// Return whether it is an important event.
  bool onDuplicateACK(TCPCongestionControlContext context, int numberOfDuplicateACKs);

  /// What should happen if an ACK has been received (non-duplicate).
  /// Return whether it is an important event.
  bool onACK(TCPCongestionControlContext context);

  /// Get the name of the algorithm.
  String getName();
}

typedef bool OnAck(TCPCongestionControlContext context);
typedef bool OnTimeout(TCPCongestionControlContext context);
typedef bool OnDuplicateAck(TCPCongestionControlContext context, int numberOfDuplicateACKs);

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
  bool onACK(TCPCongestionControlContext context) {
    return onAckMethod(context);
  }

  @override
  bool onDuplicateACK(TCPCongestionControlContext context, int numberOfDuplicateACKs) {
    return onDuplicateAckMethod(context, numberOfDuplicateACKs);
  }

  @override
  bool onTimeout(TCPCongestionControlContext context) {
    return onTimeoutMethod(context);
  }

  @override
  String getName() {
    return "Custom";
  }
}
