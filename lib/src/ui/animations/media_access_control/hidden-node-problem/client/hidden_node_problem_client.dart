import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/medium_status_type.dart';
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

  SignalType _backoffSignalType;
  SignalType _backoffAnticipatedSignalType;

  /// Amount of milliseconds to wait in case of backoff or null if no backoff.
  int _backoffMilliseconds;

  /// Id of the scheduled backoff end.
  int _scheduledBackoffEndId;

  int _numberOfCollisions = 0;

  /// Signal type the client awaits as answer to a previously sent signal.
  SignalType _anticipatedSignalType;

  MediumStatusType _mediumStatusType = MediumStatusType.FREE;

  /// Since when the channel is idle.
  num _channelIdleSince;

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

  int get backoffMilliseconds => _backoffMilliseconds;

  set backoffMilliseconds(int value) {
    _backoffMilliseconds = value;
  }

  MediumStatusType get mediumStatusType => _mediumStatusType;

  set mediumStatusType(MediumStatusType value) {
    _mediumStatusType = value;
  }

  num get channelIdleSince => _channelIdleSince;

  set channelIdleSince(num value) {
    _channelIdleSince = value;
  }

  SignalType get backoffSignalType => _backoffSignalType;

  set backoffSignalType(SignalType value) {
    _backoffSignalType = value;
  }

  /// Whether from the nodes perception the channel is idle.
  bool isChannelIdle() => _signalCount == 0;

  /// Set whether the channel is idle.
  void setChannelIdle(bool isIdle) {
    if (isIdle) {
      _signalCount = max(0, _signalCount - 1);

      if (isChannelIdle()) {
        _channelIdleSince = window.performance.now();
      }
    } else {
      _signalCount++;

      if (hasCollision) {
        _signalsToIgnore = max(_signalsToIgnore, _signalCount);
      }

      _channelIdleSince = null;
    }
  }

  /// Whether the channel is visually idle.
  bool isChannelVisuallyIdle() => _channelIdleVisually;

  /// Set whether the channel is visually idle.
  bool setChannelVisuallyIdle(bool isIdle) => _channelIdleVisually = isIdle;

  SignalType get backoffAnticipatedSignalType => _backoffAnticipatedSignalType;

  set backoffAnticipatedSignalType(SignalType value) {
    _backoffAnticipatedSignalType = value;
  }

  int get scheduledBackoffEndId => _scheduledBackoffEndId;

  set scheduledBackoffEndId(int value) {
    _scheduledBackoffEndId = value;
  }

  bool get inBackoff => _scheduledBackoffEndId != null;

  int get numberOfCollisions => _numberOfCollisions;

  set numberOfCollisions(int value) {
    _numberOfCollisions = value;
  }
}
