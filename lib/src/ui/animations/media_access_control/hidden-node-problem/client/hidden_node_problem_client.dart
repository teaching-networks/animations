import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/node/wireless_node.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/signal_type.dart';
import 'package:hm_animations/src/ui/animations/shared/medium_allocation_chart/medium_allocation_chart.dart';
import 'package:meta/meta.dart';

/// Client in the hidden node problem animation.
class HiddenNodeProblemClient {
  /// Node of the client.
  final WirelessNode wirelessNode;

  /// Medium allocation chart of the client.
  final MediumAllocationChart chart;

  /// Wether the client is visually idle.
  bool _channelIdleVisually = true;

  /// Number of signals currently sensing from this client.
  int _signalCount = 0;

  /// Number of signals to ignore due to collisions.
  int _signalsToIgnore = 0;

  /// Signal type the client awaits as answer to a previously sent signal.
  SignalType _anticipatedSignalType;

  /// Create client.
  HiddenNodeProblemClient({
    @required this.wirelessNode,
    @required this.chart,
  });

  bool get hasCollision => _signalCount > 1;

  SignalType get anticipatedSignalType => _anticipatedSignalType;

  void set anticipatedSignalType(SignalType type) => _anticipatedSignalType = type;

  bool get anticipatesSignal => _anticipatedSignalType != null;

  int get signalsToIgnore => _signalsToIgnore;

  void set signalsToIgnore(int value) => _signalsToIgnore = value;

  /// Whether from the nodes perception the channel is idle.
  bool isChannelIdle() => _signalCount == 0;

  /// Set whether the channel is idle.
  void setChannelIdle(bool isIdle) {
    if (isIdle) {
      _signalCount = max(0, _signalCount - 1);
    } else {
      _signalCount++;

      if (hasCollision) {
        _signalsToIgnore = max(_signalsToIgnore, _signalCount);
      }
    }
  }

  /// Whether the channel is visually idle.
  bool isChannelVisuallyIdle() => _channelIdleVisually;

  /// Set whether the channel is visually idle.
  bool setChannelVisuallyIdle(bool isIdle) => _channelIdleVisually = isIdle;
}
