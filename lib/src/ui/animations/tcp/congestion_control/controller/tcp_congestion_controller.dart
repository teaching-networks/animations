import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/impl/tcp_reno.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/tcp_congestion_control_algorithm.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_context.dart';

/// Controller controlling TCP congestion.
class TCPCongestionController {
  /// Algorithm for congestion control.
  TCPCongestionControlAlgorithm _algorithm = TCPReno();

  /// Context needed to control congestion.
  TCPCongestionControlContext _context = TCPCongestionControlContext();

  set algorithm(TCPCongestionControlAlgorithm value) {
    _algorithm = value;
  }

  void onDuplicateACK(int numberOfDuplicateACKs) {
    _algorithm.onDuplicateACK(_context, numberOfDuplicateACKs);
  }

  void onTimeout() {
    _algorithm.onTimeout(_context);
  }

  void onACKReceived() {

  }
}
