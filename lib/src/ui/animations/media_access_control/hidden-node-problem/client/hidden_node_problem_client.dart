import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/node/wireless_node.dart';
import 'package:hm_animations/src/ui/animations/shared/medium_allocation_chart/medium_allocation_chart.dart';
import 'package:meta/meta.dart';

/// Client in the hidden node problem animation.
class HiddenNodeProblemClient {
  /// Node of the client.
  final WirelessNode wirelessNode;

  /// Medium allocation chart of the client.
  final MediumAllocationChart chart;

  /// Whether, from the nodes perception, the channel is idle.
  bool _channelIdle = true;

  /// Wether the client is visually idle.
  bool _channelIdleVisually = true;

  /// Create client.
  HiddenNodeProblemClient({
    @required this.wirelessNode,
    @required this.chart,
  });

  /// Whether from the nodes perception the channel is idle.
  bool isChannelIdle() => _channelIdle;

  /// Set whether the channel is idle.
  bool setChannelIdle(bool isIdle) => _channelIdle = isIdle;

  /// Whether the channel is visually idle.
  bool isChannelVisuallyIdle() => _channelIdleVisually;

  /// Set whether the channel is visually idle.
  bool setChannelVisuallyIdle(bool isIdle) => _channelIdleVisually = isIdle;
}
