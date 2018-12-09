import 'dart:math';

import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/impl/tcp_reno.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/tcp_congestion_control_algorithm.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_context.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_state.dart';

/// Controller controlling TCP congestion.
class TCPCongestionController {
  /// Algorithm for congestion control.
  TCPCongestionControlAlgorithm _algorithm = TCPReno();

  /// Context needed to control congestion.
  TCPCongestionControlContext _context = TCPCongestionControlContext();

  /// Currently available bandwidth (in MSS - Maximum segment size).
  int _availableBandwidth;

  /// Whether to simulate the next ACK receival as lost packet.
  bool _simulateACKLost = false;

  TCPCongestionController(this._availableBandwidth);

  set algorithm(TCPCongestionControlAlgorithm value) {
    _algorithm = value;
  }

  set availableBandwidth(int value) {
    _availableBandwidth = value;
  }

  /// What to do when a duplicate ACK has been received.
  /// Returns whether the state has been changed.
  bool onDuplicateACK(int numberOfDuplicateACKs) {
    TCPCongestionControlState stateBefore = _context.state;

    _algorithm.onDuplicateACK(_context, numberOfDuplicateACKs);

    return stateBefore != _context.state;
  }

  /// What to do when a timeout happened.
  /// Returns whether the state has been changed.
  bool onTimeout() {
    TCPCongestionControlState stateBefore = _context.state;

    _algorithm.onTimeout(_context);

    return stateBefore != _context.state;
  }

  /// What to do when an ACK has been received.
  /// Returns whether the state has been changed.
  bool onACKReceived() {
    TCPCongestionControlState stateBefore = _context.state;

    if (_simulateACKLost) {
      _simulateACKLost = false;
      onDuplicateACK(3);
    } else {
      _algorithm.onACK(_context);

      if (_context.congestionWindow > _availableBandwidth) {
        // Simulate a packet loss as the available bandwidth has been exceeded.
        _simulateACKLost = true;
      }
    }

    return stateBefore != _context.state;
  }

  TCPCongestionControlContext get context => _context;
}
