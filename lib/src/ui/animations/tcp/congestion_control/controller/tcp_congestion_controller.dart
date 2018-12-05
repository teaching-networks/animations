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

  TCPCongestionController(this._availableBandwidth);

  set algorithm(TCPCongestionControlAlgorithm value) {
    _algorithm = value;
  }

  set availableBandwidth(int value) {
    _availableBandwidth = value;
  }

  void onDuplicateACK(int numberOfDuplicateACKs) {
    _algorithm.onDuplicateACK(_context, numberOfDuplicateACKs);
  }

  void onTimeout() {
    _algorithm.onTimeout(_context);
  }

  void onACKReceived() {
    _algorithm.onACK(_context);

    if (_context.congestionWindow > _availableBandwidth) {
      // Simulate a packet loss as the available bandwidth has been exceeded.
      onDuplicateACK(3);
    }
  }

  int getCwndTest() {
    return _context.congestionWindow;
  }
}
