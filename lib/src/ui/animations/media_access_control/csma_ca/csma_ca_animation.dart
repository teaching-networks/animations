import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_icon/material_icon_toggle.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_ca/client/hidden_node_problem_client.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_ca/medium_status_type.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_ca/node/wireless_node.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_ca/signal_type.dart';
import 'package:hm_animations/src/ui/animations/shared/medium_allocation_chart/medium_allocation_chart.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/shapes/bubble/bubble.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';
import 'package:vector_math/vector_math.dart' as v;

/// Animation showing the hidden node problem (RTS/CTS).
@Component(
  selector: "csma-ca-animation",
  styleUrls: [
    "csma_ca_animation.css",
  ],
  templateUrl: "csma_ca_animation.html",
  directives: [
    coreDirectives,
    CanvasComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialIconToggleDirective,
    MaterialToggleComponent,
    MaterialSliderComponent,
  ],
  pipes: [
    I18nPipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class CSMACAAnimation extends CanvasAnimation with CanvasPausableMixin implements OnInit, OnDestroy {
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
  static const Duration _interframeSpacingDelay = Duration(milliseconds: 150);

  /// The maximum backoff duration.
  static const Duration _maxBackoffDuration = Duration(seconds: 2);

  /// The minimum backoff duration.
  static const Duration _minBackoffDuration = Duration(milliseconds: 200);

  /// Maximum amount of pixels the mouse has to be moved to be recognized as a drag rather than a click.
  static const double _dragDistanceThreshold = 2.0;

  /// Random number generator.
  static Random _rng = Random();

  /// Service to get translations from.
  final I18nService _i18n;

  /// Change detector to update angular component with.
  final ChangeDetectorRef changeDetector;

  CSMACAClient _accessPoint;

  List<CSMACAClient> _clients;

  /// The radius of nodes in the last render cycle.
  double _lastRenderRadius;

  /// The x offset of the map in the last rendering cycle.
  double _lastMapRenderXOffset;

  /// The y offset of the map in the last rendering cycle.
  double _lastMapRenderYOffset;

  /// The size of the map in the last rendering cycle.
  double _lastMapRenderSize;

  /// The currently hovered node.
  WirelessNode _hoveredNode;

  /// The currently dragged node.
  WirelessNode _draggedNode;

  /// Start coordinates of a drag.
  Point<double> _dragStart;

  /// Whether a node if currently dragged.
  bool _isDraggingNode = false;

  /// Boolean used to debounce the mouse move events.
  bool _canConsumeMoreMouseMoveEvents = true;

  /// Style to apply on the canvas.
  Map<String, String> _style = {
    "cursor": "default",
  };

  LanguageLoadedListener _languageChangedListener;

  Message _valueBarLabel;
  Message _statusBarLabel;
  Message _accessPointLabel;
  Message _clickHereTooltipLabel;
  Message _signalRangeTooltipLabel;
  Message _rtsCtsSettingsLabel;

  /// Scheduled functions which will be executed some time in the future.
  List<_ScheduledFunction> _scheduled;

  /// Whether to show the help tooltip.
  bool _showHelpTooltips = true;

  Bubble _clickHereTooltip;
  Bubble _signalRangeTooltip;

  /// Whether RTS/CTS is enabled for CSMA/CD.
  bool rtsCtsOn = true;

  /// Whether the animation is in its initial state.
  bool _isInitState = true;

  List<Tuple2<Message, Color>> _legendItems;

  /// Animation speed factor.
  double animationSpeedFactor = 1.0;

  /// Create animation.
  CSMACAAnimation(this._i18n, this.changeDetector);

  @override
  void ngOnInit() {
    _languageChangedListener = (_) {
      _updateHelpTooltips();

      changeDetector.markForCheck(); // Update labels.
    };
    this._i18n.addLanguageLoadedListener(_languageChangedListener);

    _initTranslations();
    _updateHelpTooltips();
    _initLegendItems();

    reset();
  }

  /// Initialized legend items display in the animations legend.
  void _initLegendItems() {
    _legendItems = [
      Tuple2<Message, Color>(_i18n.get("csma-ca-animation.legend.rts"), _getColorForSignalType(SignalType.RTS)),
      Tuple2<Message, Color>(_i18n.get("csma-ca-animation.legend.cts"), _getColorForSignalType(SignalType.CTS)),
      Tuple2<Message, Color>(_i18n.get("csma-ca-animation.legend.data"), _getColorForSignalType(SignalType.DATA)),
      Tuple2<Message, Color>(_i18n.get("csma-ca-animation.legend.ack"), _getColorForSignalType(SignalType.ACK)),
      Tuple2<Message, Color>(_i18n.get("csma-ca-animation.legend.backoff"), Colors.LIGHTGREY),
      Tuple2<Message, Color>(_i18n.get("csma-ca-animation.legend.free"), _getColorForMediumStatusType(MediumStatusType.FREE)),
      Tuple2<Message, Color>(_i18n.get("csma-ca-animation.legend.busy"), _getColorForMediumStatusType(MediumStatusType.BUSY)),
      Tuple2<Message, Color>(_i18n.get("csma-ca-animation.legend.nav"), _getColorForMediumStatusType(MediumStatusType.NAV)),
    ];
  }

  /// Reset the animation.
  void reset() {
    _scheduled = List<_ScheduledFunction>();
    _showHelpTooltips = true;
    if (isPaused) {
      switchPause(pauseAnimation: false);
    }

    _accessPoint = CSMACAClient(
      wirelessNode: WirelessNode<SignalType>(
        nodeName: "X",
        initialCoordinates: _accessPointCoordinates,
        scale: 100000000 ~/ animationSpeedFactor,
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

    _clients = <CSMACAClient>[
      CSMACAClient(
        wirelessNode: WirelessNode<SignalType>(
          nodeName: "A",
          initialCoordinates: client1Pos,
          scale: 100000000 ~/ animationSpeedFactor,
          nodeCircleColor: Colors.BLUE_GRAY,
          rangeCircleColor: _rangeCircleColor,
        ),
        chart: MediumAllocationChart(id: "A", valueBarLabel: _valueBarLabel, statusBarLabel: _statusBarLabel),
      ),
      CSMACAClient(
        wirelessNode: WirelessNode<SignalType>(
          nodeName: "B",
          initialCoordinates: client2Pos,
          scale: 100000000 ~/ animationSpeedFactor,
          nodeCircleColor: Colors.CORAL,
          rangeCircleColor: _rangeCircleColor,
        ),
        chart: MediumAllocationChart(id: "B", valueBarLabel: _valueBarLabel, statusBarLabel: _statusBarLabel),
      ),
      CSMACAClient(
        wirelessNode: WirelessNode<SignalType>(
          nodeName: "C",
          initialCoordinates: client3Pos,
          scale: 100000000 ~/ animationSpeedFactor,
          nodeCircleColor: Colors.BORDEAUX,
          rangeCircleColor: _rangeCircleColor,
        ),
        chart: MediumAllocationChart(id: "C", valueBarLabel: _valueBarLabel, statusBarLabel: _statusBarLabel),
      ),
    ];

    // Set start color for the status bar of the clients.
    for (final client in _clients) {
      client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
    }
    _accessPoint.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));

    _isInitState = true;
  }

  /// Update the help tooltip.
  void _updateHelpTooltips() {
    _clickHereTooltip = Bubble(_clickHereTooltipLabel.toString(), _clickHereTooltipLabel.toString().length);
    _signalRangeTooltip = Bubble(_signalRangeTooltipLabel.toString(), _signalRangeTooltipLabel.toString().length);
  }

  /// Initialize translations needed for the animation.
  void _initTranslations() {
    _valueBarLabel = _i18n.get("csma-ca-animation.value-bar-label");
    _statusBarLabel = _i18n.get("csma-ca-animation.status-bar-label");
    _accessPointLabel = _i18n.get("csma-ca-animation.access-point");
    _clickHereTooltipLabel = _i18n.get("csma-ca-animation.click-here-tooltip");
    _signalRangeTooltipLabel = _i18n.get("csma-ca-animation.signal-range-tooltip");
    _rtsCtsSettingsLabel = _i18n.get("csma-ca-animation.label.rts-cts");
  }

  @override
  ngOnDestroy() {
    this._i18n.removeLanguageLoadedListener(_languageChangedListener);

    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    double mapOffset = size.height * 0.6;

    _drawMap(timestamp, size.width / 2 - mapOffset / 2, 0.0, mapOffset, mapOffset);
    double legendWidth = _drawLegend(mapOffset, size.height - mapOffset);
    _drawChartTable(timestamp, 0.0, mapOffset, size.width - legendWidth, size.height - mapOffset);

    if (_showHelpTooltips) {
      _renderTooltips(context, size.width / 2 - mapOffset / 2, 0.0, mapOffset, mapOffset);
    }

    if (!isPaused) {
      _executeScheduledFunctions(timestamp);
      _checkForIdleClientChannels(timestamp);
    }
  }

  void _renderTooltips(CanvasRenderingContext2D context, double x, double y, double width, double height) {
    if (_clickHereTooltip.text == null || _signalRangeTooltip.text == null) {
      _updateHelpTooltips();
    }

    Point<double> coordinates = _clients[1].wirelessNode.coordinates;
    _clickHereTooltip.render(
      context,
      Rectangle<double>(
        x + coordinates.x * width,
        y + coordinates.y * height - _lastRenderRadius / WirelessNode.rangeToHoverCircleRatio,
        0,
        0,
      ),
    );

    _signalRangeTooltip.render(
      context,
      Rectangle<double>(
        x + coordinates.x * width,
        y + coordinates.y * height - _lastRenderRadius,
        0,
        0,
      ),
    );
  }

  /// Check for all idle client channels.
  void _checkForIdleClientChannels(num timestamp) {
    _checkForIdleClientChannel(_accessPoint, timestamp);
    for (final client in _clients) {
      _checkForIdleClientChannel(client, timestamp);
    }
  }

  void _checkForIdleClientChannel(CSMACAClient client, num timestamp) {
    if (!client.isChannelIdle() && client.inBackoff) {
      // Pause backing off and continue after the channel is idle again.
      double restMs = _cancelScheduled(client.scheduledBackoffEndId);
      client.scheduledBackoffEndId = null;
      client.backoffMilliseconds = restMs.toInt();
      client.chart.setValueColor(Colors.WHITE);
    }

    if (client.isChannelIdle() && client.channelIdleSince != null && client.mediumStatusType != MediumStatusType.NAV) {
      if (client.channelIdleSince <= timestamp - _interframeSpacingDelay.inMilliseconds) {
        // Check for backoff to make
        if (client.backoffMilliseconds != null && !client.inBackoff) {
          int backoffMs = client.backoffMilliseconds;
          SignalType type = client.backoffSignalType;
          SignalType answerType = client.backoffAnticipatedSignalType;

          client.backoffMilliseconds = null;

          client.chart.setValueColor(Colors.LIGHTGREY);
          client.scheduledBackoffEndId = _schedule(timestamp + backoffMs, () {
            client.scheduledBackoffEndId = null;
            client.chart.setValueColor(Colors.WHITE);
            _emitSignalFrom(client, type, answerSignalType: answerType);
          });
        }
      }
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
    _lastMapRenderSize = width;
    _lastMapRenderYOffset = top;
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

  /// Draw the color legend. Returns the legend width.
  double _drawLegend(double top, double height) {
    context.textAlign = "left";
    context.textBaseline = "middle";

    double fontSize = defaultFontSize;
    context.font = "${fontSize}px sans-serif";

    double offset = fontSize * 1.5;
    double boxSize = offset * 0.8;
    double padding = boxSize * 0.1;

    // Get maximum font length
    double maxItemWidth = 0.0;
    for (final item in _legendItems) {
      double labelWidth = context.measureText(item.item1.toString()).width;
      if (labelWidth > maxItemWidth) {
        maxItemWidth = labelWidth;
      }
    }
    maxItemWidth += boxSize + 3 * padding;

    double yOffset = 0.0;

    for (final item in _legendItems) {
      _drawLegendItem(item.item1.toString(), item.item2, boxSize, padding, size.width - maxItemWidth, top + yOffset, maxItemWidth, offset);

      yOffset += offset;
    }

    return maxItemWidth;
  }

  void _drawLegendItem(String text, Color color, double boxSize, double padding, double left, double top, double width, double height) {
    setFillColor(context, color);
    context.fillRect(left + padding, top + padding, boxSize, boxSize);

    setFillColor(context, Colors.DARK_GRAY);
    context.fillText(text, left + padding * 2 + boxSize, top + height / 2);
  }

  /// Get the height of the canvas.
  int get canvasHeight => 800;

  /// How to react to a mouse up event.
  void onMouseUp(Point<double> pos) {
    if (_isInitState) {
      _isInitState = false;
    }

    CSMACAClient client = _checkHoveredClient(pos);
    double dragDistance = _dragStart != null ? pos.distanceTo(_dragStart) : 0;

    if (client != null && _draggedNode != null && client.wirelessNode == _draggedNode && dragDistance < _dragDistanceThreshold && !_isDraggingNode) {
      _sendRequestToSend(client);
    }

    _dragStart = null;
    _isDraggingNode = false;
  }

  /// How to react to a mouse down event.
  void onMouseDown(Point<double> pos) {
    CSMACAClient client = _checkHoveredClient(pos);

    if (client != null) {
      _draggedNode = client.wirelessNode;
      _dragStart = pos;
    }
  }

  /// Send an RTS signal (Request to send) to the access point.
  void _sendRequestToSend(CSMACAClient client) {
    if (_showHelpTooltips) {
      _showHelpTooltips = false;
    }

    if (rtsCtsOn) {
      _emitSignalFrom(client, SignalType.RTS, answerSignalType: SignalType.CTS);
    } else {
      _emitSignalFrom(client, SignalType.DATA, answerSignalType: SignalType.ACK);
    }
  }

  void _emitSignalFrom(CSMACAClient client, SignalType type, {SignalType answerSignalType}) {
    client.anticipatedSignalType = answerSignalType;

    Color color = _getColorForSignalType(type);
    List<CSMACAClient> nodesInRange = _getAllNodesInRangeOf(client);

    if (client.isChannelIdle() && client.mediumStatusType != MediumStatusType.NAV) {
      // Wait for the interframe spacing delay and then try again!
      _schedule(window.performance.now() + _interframeSpacingDelay.inMilliseconds, () {
        // Recheck if channel still idle.
        if (!client.isChannelIdle()) {
          _backoff(client, type);
          return;
        }

        client.setChannelIdle(false);

        client.chart.setValueColor(color);
        client.mediumStatusType = MediumStatusType.BUSY;
        client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.BUSY));

        // Set all nodes in range to busy.
        for (final clientInRange in nodesInRange) {
          clientInRange.setChannelIdle(false);

          if (clientInRange.mediumStatusType != MediumStatusType.NAV) {
            clientInRange.mediumStatusType = MediumStatusType.BUSY;
            clientInRange.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.BUSY));
          }
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

          client.mediumStatusType = MediumStatusType.FREE;
          client.chart.setStateColor(_getColorForMediumStatusType(client.mediumStatusType));

          // Set all nodes in range to free.
          for (final anotherClient in nodesInRange) {
            anotherClient.setChannelIdle(true);
            if (anotherClient == _accessPoint) {
              anotherClient.mediumStatusType = MediumStatusType.FREE;
              anotherClient.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
            } else {
              if (anotherClient.mediumStatusType != MediumStatusType.NAV) {
                anotherClient.mediumStatusType = MediumStatusType.FREE;
                anotherClient.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
              }
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
            _schedule(window.performance.now() + _getDurationForSignalType(answerSignalType).inMilliseconds * 2, () {
              if (client.anticipatesSignal && client.anticipatedSignalType == answerSignalType) {
                _onTimeoutAtNode(client, type, client.anticipatedSignalType);
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
  void _onTimeoutAtNode(CSMACAClient client, SignalType type, SignalType answerType) {
    if (client != _accessPoint) {
      _backoff(client, type);
    }
  }

  /// Backoff the passed [client].
  void _backoff(CSMACAClient client, SignalType type) {
    if (client == _accessPoint || client.inBackoff || client.backoffMilliseconds != null) {
      return;
    }

    client.numberOfCollisions++;

    client.backoffMilliseconds =
        max(_minBackoffDuration.inMilliseconds, (_rng.nextDouble() * _maxBackoffDuration.inMilliseconds * client.numberOfCollisions).round()) ~/
            animationSpeedFactor;
    client.backoffSignalType = type;
    client.backoffAnticipatedSignalType = client.anticipatedSignalType;

    client.anticipatedSignalType = null; // Clear anticipated signal
  }

  /// Schedule a function to be executed later and return the id of the scheduled function.
  int _schedule(num atTimestamp, Function toExecute) {
    final function = _ScheduledFunction(
      atTimestamp: isPaused ? pauseTimestamp : atTimestamp,
      toExecute: toExecute,
    );

    _scheduled.add(function);

    return function.id;
  }

  /// Cancel a scheduled function by its [id] and return milliseconds left.
  double _cancelScheduled(int id) {
    _ScheduledFunction removed = _scheduled.removeAt(_scheduled.indexWhere((function) => function.id == id));

    return removed.atTimestamp - window.performance.now();
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
  List<CSMACAClient> _getAllNodesInRangeOf(CSMACAClient client) {
    WirelessNode node = client.wirelessNode;

    List<CSMACAClient> nodesInRange = List<CSMACAClient>();

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
        CSMACAClient client = _checkHoveredClient(pos);

        if (client != null) {
          setCursorType("pointer");
        } else {
          setCursorType("default");
        }

        // Check if drag.
        if (!_isDraggingNode) {
          double dragDistance = _dragStart != null ? pos.distanceTo(_dragStart) : 0;

          if (dragDistance > _dragDistanceThreshold) {
            _isDraggingNode = true;
          }
        }

        if (_isDraggingNode) {
          double xCoord = (pos.x - _lastMapRenderXOffset) / _lastMapRenderSize;
          double yCoord = (pos.y - _lastMapRenderYOffset) / _lastMapRenderSize;

          _draggedNode.coordinates = Point<double>(xCoord, yCoord);
        }

        _canConsumeMoreMouseMoveEvents = true;
      });
    }
  }

  /// Check whether there is a node hovered.
  CSMACAClient _checkHoveredClient(Point<double> pos) {
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
    // Ignore collided signals.
    if (_accessPoint.signalsToIgnore > 0) {
      _accessPoint.signalsToIgnore--;
      return;
    }

    if (type == SignalType.RTS) {
      _emitSignalFrom(_accessPoint, SignalType.CTS, answerSignalType: SignalType.DATA);
    } else if (type == SignalType.DATA) {
      _emitSignalFrom(_accessPoint, SignalType.ACK);
    }
  }

  /// When a signal has been received at a client.
  void _onReceivedAtClient(CSMACAClient client, SignalType type) {
    final SignalType anticipated = client.anticipatedSignalType;
    client.anticipatedSignalType = null;

    // Ignore collided signals.
    if (client.signalsToIgnore > 0) {
      client.signalsToIgnore--;
      return;
    }

    if (anticipated != null && anticipated == type) {
      if (type == SignalType.CTS) {
        _emitSignalFrom(client, SignalType.DATA, answerSignalType: SignalType.ACK);
      } else if (type == SignalType.ACK) {
        client.mediumStatusType = MediumStatusType.FREE;
        client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
        client.numberOfCollisions = 0; // Reset number of collisions in case of successful transmission.
      }
    } else {
      if (type == SignalType.CTS) {
        client.mediumStatusType = MediumStatusType.NAV;
        client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.NAV));
        _schedule(window.performance.now() + _getDurationForSignalType(SignalType.DATA).inMilliseconds * 1.15, () {
          if (client.isChannelIdle()) {
            client.mediumStatusType = MediumStatusType.FREE;
            client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
          } else {
            client.mediumStatusType = MediumStatusType.BUSY;
            client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.BUSY));
          }
        });
      } else if (type == SignalType.ACK) {
        if (client.mediumStatusType != MediumStatusType.NAV) {
          client.mediumStatusType = MediumStatusType.FREE;
          client.chart.setStateColor(_getColorForMediumStatusType(MediumStatusType.FREE));
        }
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
    var ms = 0;

    switch (type) {
      case SignalType.RTS:
        ms = 500;
        break;
      case SignalType.CTS:
        ms = 500;
        break;
      case SignalType.DATA:
        ms = 4000;
        break;
      case SignalType.ACK:
        ms = 500;
        break;
      default:
        throw Exception("Unknown signal type");
    }

    return Duration(milliseconds: (ms / animationSpeedFactor).round());
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

    if (_accessPoint.isChannelIdle() && _accessPoint.channelIdleSince != null) {
      _accessPoint.channelIdleSince += timestampDifference;
    }
    for (final client in _clients) {
      if (client.isChannelIdle() && client.channelIdleSince != null) {
        client.channelIdleSince += timestampDifference;
      }
    }
  }

  /// Enable or disable RTS/CTS.
  void setRtsCtsEnabled(bool enable) {
    rtsCtsOn = enable;
  }

  /// Whether the animation is in its initial state.
  bool get isInitState => _isInitState;

  String get rtsCtsLabel => _rtsCtsSettingsLabel.toString();
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
