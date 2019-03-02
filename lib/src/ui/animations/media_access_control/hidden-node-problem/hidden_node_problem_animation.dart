import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_icon/material_icon_toggle.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/client/hidden_node_problem_client.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/medium_status_type.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/node/wireless_node.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/signal_type.dart';
import 'package:hm_animations/src/ui/animations/shared/medium_allocation_chart/medium_allocation_chart.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';
import 'package:vector_math/vector_math.dart' as v;

/// Animation showing the hidden node problem (RTS/CTS).
@Component(
  selector: "hidden-node-problem-animation",
  styleUrls: [
    "hidden_node_problem_animation.css",
  ],
  templateUrl: "hidden_node_problem_animation.html",
  directives: [
    coreDirectives,
    CanvasComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialIconToggleDirective,
  ],
  pipes: [
    I18nPipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class HiddenNodeProblemAnimation extends CanvasAnimation with CanvasPausableMixin implements OnInit, OnDestroy {
  /// Color of the range circle around nodes.
  static const Color _rangeCircleColor = Color.rgba(100, 100, 100, 0.4);

  /// Distance from clients to access point (Relative).
  static const double _clientToAccessPointDistance = 0.2;

  /// Count of clients around the access point.
  static const int _clientCount = 3;

  /// Coordinates of the access point;
  static const Point<double> _accessPointCoordinates = Point<double>(0.5, 0.5);

  /// Relative size of a nodes radius.
  static const double _relativeRadiusSize = 0.25;

  /// Delay due to an interframe spacing.
  static const Duration _interframeSpacingDelay = Duration(milliseconds: 100);

  /// The duration the clients will wait after not receiving an answer for their signal.
  static const Duration _timeoutDuration = Duration(seconds: 2);

  /// Service to get translations from.
  final I18nService _i18n;

  /// Change detector to update angular component with.
  final ChangeDetectorRef changeDetector;

  HiddenNodeProblemClient _accessPoint;

  List<HiddenNodeProblemClient> _clients;

  /// The radius of nodes in the last render cycle.
  double _lastRenderRadius;

  /// The x offset of the map in the last rendering cycle.
  double _lastMapRenderXOffset;

  /// The currently hovered node.
  WirelessNode _hoveredNode;

  /// Boolean used to debounce the mouse move events.
  bool _canConsumeMoreMouseMoveEvents = true;

  /// Style to apply on the canvas.
  Map<String, String> _style = {
    "cursor": "default",
  };

  LanguageChangedListener _languageChangedListener;

  Message _valueBarLabel;
  Message _statusBarLabel;
  Message _accessPointLabel;

  List<_ScheduledFunction> _scheduled = List<_ScheduledFunction>();

  /// Create animation.
  HiddenNodeProblemAnimation(this._i18n, this.changeDetector);

  @override
  void ngOnInit() {
    _languageChangedListener = (_) {
      changeDetector.markForCheck(); // Update labels.
    };
    this._i18n.addLanguageChangedListener(_languageChangedListener);

    _initTranslations();

    _accessPoint = HiddenNodeProblemClient(
      wirelessNode: WirelessNode<SignalType>(
        nodeName: "X",
        initialCoordinates: _accessPointCoordinates,
        scale: 300000000,
        nodeCircleColor: Colors.PINK_RED,
        rangeCircleColor: Colors.LIME,
      ),
      chart: MediumAllocationChart(id: "X", valueBarLabel: _accessPointLabel, statusBarLabel: _statusBarLabel),
    );

    v.Vector3 vector = v.Vector3(0.0, -1.0, 0.0);
    double radiusOffset = 2 * pi / _clientCount;
    v.Quaternion quaternion = v.Quaternion.axisAngle(v.Vector3(0.0, 0.0, 1.0), radiusOffset);

    final Point<double> client1Pos =
        Point<double>(_accessPointCoordinates.x + vector.x * _clientToAccessPointDistance, _accessPointCoordinates.y + vector.y * _clientToAccessPointDistance);
    quaternion.rotate(vector);
    final Point<double> client2Pos =
        Point<double>(_accessPointCoordinates.x + vector.x * _clientToAccessPointDistance, _accessPointCoordinates.y + vector.y * _clientToAccessPointDistance);
    quaternion.rotate(vector);
    final Point<double> client3Pos =
        Point<double>(_accessPointCoordinates.x + vector.x * _clientToAccessPointDistance, _accessPointCoordinates.y + vector.y * _clientToAccessPointDistance);

    _clients = <HiddenNodeProblemClient>[
      HiddenNodeProblemClient(
        wirelessNode: WirelessNode<SignalType>(
          nodeName: "A",
          initialCoordinates: client1Pos,
          scale: 300000000,
          nodeCircleColor: Colors.BLUE_GRAY,
          rangeCircleColor: _rangeCircleColor,
        ),
        chart: MediumAllocationChart(id: "A", valueBarLabel: _valueBarLabel, statusBarLabel: _statusBarLabel),
      ),
      HiddenNodeProblemClient(
        wirelessNode: WirelessNode<SignalType>(
          nodeName: "B",
          initialCoordinates: client2Pos,
          scale: 300000000,
          nodeCircleColor: Colors.GREY_GREEN,
          rangeCircleColor: _rangeCircleColor,
        ),
        chart: MediumAllocationChart(id: "B", valueBarLabel: _valueBarLabel, statusBarLabel: _statusBarLabel),
      ),
      HiddenNodeProblemClient(
        wirelessNode: WirelessNode<SignalType>(
          nodeName: "C",
          initialCoordinates: client3Pos,
          scale: 300000000,
          nodeCircleColor: Colors.BORDEAUX,
          rangeCircleColor: _rangeCircleColor,
        ),
        chart: MediumAllocationChart(id: "C", valueBarLabel: _valueBarLabel, statusBarLabel: _statusBarLabel),
      ),
    ];

    // Set start color for the status bar of the clients.
    for (final client in _clients) {
      client.chart.setStateColor(Colors.GREY_GREEN);
    }
  }

  /// Initialize translations needed for the animation.
  void _initTranslations() {
    _valueBarLabel = _i18n.get("hidden-node-problem-animation.value-bar-label");
    _statusBarLabel = _i18n.get("hidden-node-problem-animation.status-bar-label");
    _accessPointLabel = _i18n.get("hidden-node-problem-animation.access-point");
  }

  @override
  ngOnDestroy() {
    this._i18n.removeLanguageChangedListener(_languageChangedListener);

    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    double mapOffset = size.height * 0.6;

    _drawMap(timestamp, size.width / 2 - mapOffset / 2, 0.0, mapOffset, mapOffset);
    _drawChartTable(timestamp, 0.0, mapOffset, size.width, size.height - mapOffset);

    if (!isPaused) {
      _executeScheduledFunctions(timestamp);
    }
  }

  /// Draw the actual map of senders/receivers.
  void _drawMap(num timestamp, double left, double top, double width, double height) {
    context.save();

    context.translate(left, top);

    double radius = min(width, height) * _relativeRadiusSize;
    _accessPoint.wirelessNode.render(context, Rectangle<double>(width, height, radius, radius), timestamp);

    for (final client in _clients) {
      client.wirelessNode.render(context, Rectangle<double>(width, height, radius, radius), timestamp);
    }

    _lastRenderRadius = radius;
    _lastMapRenderXOffset = left;

    context.restore();
  }

  /// Draw the chart table.
  void _drawChartTable(num timestamp, double left, double top, double width, double height) {
    context.save();

    context.translate(left, top);

    final double heightPerChart = height / (_clients.length + 1);
    double offset = 0.0;

    for (final client in _clients) {
      client.chart.render(context, Rectangle<double>(0.0, offset, width, heightPerChart), timestamp);

      offset += heightPerChart;
    }

    _accessPoint.chart.render(context, Rectangle<double>(0.0, offset, width, heightPerChart), timestamp);

    context.restore();
  }

  /// Get the height of the canvas.
  int get canvasHeight => 800;

  /// How to react to a mouse up event.
  void onMouseUp(Point<double> pos) {
    HiddenNodeProblemClient client = _checkHoveredClient(pos);

    if (client != null) {
      _sendRequestToSend(client);
    }
  }

  /// Send an RTS signal (Request to send) to the access point.
  void _sendRequestToSend(HiddenNodeProblemClient client) {
    _emitSignalFrom(client, SignalType.RTS, answerSignalType: SignalType.CTS);
  }

  void _emitSignalFrom(HiddenNodeProblemClient client, SignalType type, {SignalType answerSignalType}) {
    client.anticipatedSignalType = answerSignalType;

    Color color = _getColorForSignalType(type);
    List<HiddenNodeProblemClient> nodesInRange = _getAllNodesInRangeOf(client);

    if (client.isChannelIdle()) {
      // Wait for the interframe spacing delay and then try again!
      _schedule(window.performance.now() + _interframeSpacingDelay.inMilliseconds, () {
        // Recheck if channel still idle.
        if (!client.isChannelIdle()) {
          _backoff(client, type);
          return;
        }

        client.setChannelIdle(false);

        client.chart.setValueColor(color);
        client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.BUSY));

        // Set all nodes in range to busy.
        for (final clientInRange in nodesInRange) {
          clientInRange.setChannelIdle(false);
          clientInRange.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.BUSY));
        }

        Duration signalDuration = _getDurationForSignalType(type);

        // Emit signal just for visuals.
        client.wirelessNode.emitSignal(signalDuration, Color.opacity(color, 0.6), data: type);
        if (isPaused) {
          client.wirelessNode.switchPause();
        }

        _schedule(window.performance.now() + signalDuration.inMilliseconds, () {
          // Reset chart and client
          client.setChannelIdle(true);
          client.chart.setValueColor(Colors.WHITE);
          if (client == _accessPoint) {
            client.chart.setStateColor(Colors.WHITE);
          } else {
            client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
          }

          // Set all nodes in range to free.
          for (final anotherClient in nodesInRange) {
            anotherClient.setChannelIdle(true);
            if (anotherClient == _accessPoint) {
              anotherClient.chart.setStateColor(Colors.WHITE);
            } else {
              anotherClient.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
            }
          }

          // Emit signal for real.
          for (final clientInRange in nodesInRange) {
            if (clientInRange == _accessPoint) {
              _onReceivedAtAccessPoint(type);
            } else {
              _onReceivedAtClient(clientInRange, type);
            }
          }

          if (answerSignalType != null) {
            // Schedule timeout for the signal.
            _schedule(window.performance.now() + _timeoutDuration.inMilliseconds, () {
              if (client.anticipatesSignal) {
                _onTimeoutAtNode(client, type);
              }
            });
          }
        });
      });
    } else {
      _backoff(client, type);
    }
  }

  /// What should happen in case a timeout happened on the passed [client] node.
  void _onTimeoutAtNode(HiddenNodeProblemClient client, SignalType type) {
    print("Timeout happened at client ${client.wirelessNode.nodeName}");
  }

  /// Backoff the passed [client].
  void _backoff(HiddenNodeProblemClient client, SignalType type) {
    print("Now ${client.wirelessNode.nodeName} should backoff!"); // TODO
  }

  /// Schedule a function to be executed later.
  void _schedule(num atTimestamp, Function toExecute) {
    _scheduled.add(
      _ScheduledFunction(
        atTimestamp: isPaused ? pauseTimestamp : atTimestamp,
        toExecute: toExecute,
      ),
    );
  }

  /// Get all functions which are scheduled to be executed now (or in the past).
  List<_ScheduledFunction> _takeDueScheduledFunctions(num nowTimestamp) {
    List<_ScheduledFunction> dueScheduledFunctions = List<_ScheduledFunction>();

    for (final function in _scheduled.sublist(0)) {
      if (function.atTimestamp <= nowTimestamp) {
        dueScheduledFunctions.add(function);
        _scheduled.remove(function);
      }
    }

    return dueScheduledFunctions;
  }

  /// Execute scheduled functions (if any) for the passed [timestamp].
  void _executeScheduledFunctions(num timestamp) async {
    List<_ScheduledFunction> dueFunctions = _takeDueScheduledFunctions(timestamp);

    if (dueFunctions.isNotEmpty) {
      for (_ScheduledFunction function in dueFunctions) {
        function.toExecute();
      }
    }
  }

  /// Get all the nodes in the range of the passed [client].
  List<HiddenNodeProblemClient> _getAllNodesInRangeOf(HiddenNodeProblemClient client) {
    WirelessNode node = client.wirelessNode;

    List<HiddenNodeProblemClient> nodesInRange = List<HiddenNodeProblemClient>();

    for (final otherClient in _clients) {
      if (otherClient != client && node.coordinates.distanceTo(otherClient.wirelessNode.coordinates) <= _relativeRadiusSize) {
        nodesInRange.add(otherClient);
      }
    }

    // Test with access point.
    if (client != _accessPoint && node.coordinates.distanceTo(_accessPoint.wirelessNode.coordinates) <= _relativeRadiusSize) {
      nodesInRange.add(_accessPoint);
    }

    return nodesInRange;
  }

  /// How to react to a mouse move event.
  void onMouseMove(Point<double> pos) {
    if (_canConsumeMoreMouseMoveEvents) {
      _canConsumeMoreMouseMoveEvents = false;

      window.animationFrame.then((timestamp) {
        HiddenNodeProblemClient client = _checkHoveredClient(pos);

        if (client != null) {
          setCursorType("pointer");
        } else {
          setCursorType("default");
        }

        _canConsumeMoreMouseMoveEvents = true;
      });
    }
  }

  /// Check whether there is a node hovered.
  HiddenNodeProblemClient _checkHoveredClient(Point<double> pos) {
    if (_lastRenderRadius == null || _lastMapRenderXOffset == null) {
      return null;
    }

    pos = Point<double>(pos.x - _lastMapRenderXOffset, pos.y);

    if (_hoveredNode != null) {
      _hoveredNode.hovered = false;
      _hoveredNode = null;
    }

    double threshold = _lastRenderRadius / WirelessNode.rangeToHoverCircleRatio;
    for (final client in _clients) {
      WirelessNode node = client.wirelessNode;
      if (node.distanceFromCenter(pos) < threshold) {
        node.hovered = true;
        _hoveredNode = node;
        return client;
      }
    }

    return null;
  }

  /// Get the cursor css style.
  Map<String, String> get style => _style;

  /// Set the cursor type to show.
  void setCursorType(String cursorType) {
    _style["cursor"] = cursorType;
    changeDetector.markForCheck();
  }

  /// When a signal has been received at access point.
  void _onReceivedAtAccessPoint(SignalType type) {
    print("Received with $type at access point ${_accessPoint.signalsToIgnore}");

    // Ignore collided signals.
    if (_accessPoint.signalsToIgnore > 0) {
      _accessPoint.signalsToIgnore--;
      return;
    }

    if (type == SignalType.RTS) {
      _emitSignalFrom(_accessPoint, SignalType.CTS);
    } else if (type == SignalType.DATA) {
      _emitSignalFrom(_accessPoint, SignalType.ACK);
    }
  }

  /// When a signal has been received at a client.
  void _onReceivedAtClient(HiddenNodeProblemClient client, SignalType type) {
    print("Received with $type at client");

    // Ignore collided signals.
    if (client.signalsToIgnore > 0) {
      client.signalsToIgnore--;
      return;
    }

    final SignalType anticipated = client.anticipatedSignalType;

    if (anticipated != null && anticipated == type) {
      client.anticipatedSignalType = null;

      if (type == SignalType.CTS) {
        _emitSignalFrom(client, SignalType.DATA);
      } else if (type == SignalType.ACK) {
        client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
      }
    } else {
      if (type == SignalType.CTS) {
        client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.NAV));
      } else if (type == SignalType.ACK) {
        client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
      }
    }
  }

  Color _getColorForSignalType(SignalType type) {
    switch (type) {
      case SignalType.RTS:
        return Colors.SLATE_GREY;
      case SignalType.CTS:
        return Colors.CORAL;
      case SignalType.DATA:
        return Colors.GREY;
      case SignalType.ACK:
        return Colors.LIME;
      default:
        throw Exception("Unknown signal type");
    }
  }

  Color _getColorForMediumStatusType(MediumStatusType type) {
    switch (type) {
      case MediumStatusType.FREE:
        return Colors.GREY_GREEN;
      case MediumStatusType.BUSY:
        return Colors.PINK_RED;
      case MediumStatusType.NAV:
        return Colors.ORANGE;
      default:
        throw Exception("Medium status type unknown");
    }
  }

  Duration _getDurationForSignalType(SignalType type) {
    /// TODO Scale by factor for controlling the animation speed.
    switch (type) {
      case SignalType.RTS:
        return Duration(milliseconds: 400);
      case SignalType.CTS:
        return Duration(milliseconds: 400);
      case SignalType.DATA:
        return Duration(seconds: 3);
      case SignalType.ACK:
        return Duration(milliseconds: 400);
      default:
        throw Exception("Unknown signal type");
    }
  }

  @override
  void switchPauseSubAnimations() {
    _accessPoint.wirelessNode.switchPause();
    _accessPoint.chart.switchPause();

    for (final client in _clients) {
      client.wirelessNode.switchPause();
      client.chart.switchPause();
    }
  }

  @override
  void unpaused(num timestampDifference) {
    // Update timestamps in scheduled functions.
    for (_ScheduledFunction function in _scheduled) {
      function.atTimestamp += timestampDifference;
    }
  }

  void test() {
    setCursorType("pointer");
  }
}

class _ScheduledFunction {
  static int counter = 0;

  final int id;
  num atTimestamp;
  Function toExecute;

  _ScheduledFunction({
    @required this.atTimestamp,
    @required this.toExecute,
  }) : id = counter++;

  @override
  bool operator ==(Object other) => identical(this, other) || other is _ScheduledFunction && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
