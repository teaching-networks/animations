/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_select/material_dropdown_select.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:angular_components/material_tooltip/material_tooltip.dart';
import 'package:angular_components/model/selection/selection_model.dart';
import 'package:angular_components/model/selection/selection_options.dart';
import 'package:angular_components/model/ui/has_renderer.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/impl/tcp_reno.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/impl/tcp_tahoe.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/tcp_congestion_control_algorithm.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/controller/congestion_window_provider.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/controller/tcp_congestion_controller.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/graph2d.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/renderables/graph2d_function.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/renderables/graph2d_series.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/style/graph2d_style.dart';
import 'package:hm_animations/src/ui/canvas/mouse/canvas_mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/size_type.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/misc/description/description.component.dart';
import 'package:hm_animations/src/util/str/message.dart';

/// Animation showing the TCP congestion control mechanism.
@Component(
  selector: "tcp-congestion-control-animation",
  templateUrl: "tcp_congestion_control_animation.html",
  styleUrls: ["tcp_congestion_control_animation.css"],
  directives: [
    coreDirectives,
    CanvasComponent,
    MaterialSliderComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
    MaterialTooltipDirective,
    MaterialDropdownSelectComponent,
    DescriptionComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class TCPCongestionControlAnimation extends CanvasAnimation with CanvasPausableMixin, AnimationUI implements OnInit, OnDestroy, CanvasMouseListener {
  /// How many ACKs fit on the x-axis of the graph.
  static const int ACKS_ON_GRAPH_X = 500;

  /// Maximum possible bandwidth in MSS (Maximum segment size).
  static const int MAX_BANDWIDTH = 1000;

  /// Maximum size of a series list.
  static const int MAX_SERIES_SIZE = 250;

  /// Background color of the graph.
  static const Color BACKGROUND_COLOR = Color.hex(0xFFF9F9F9);

  /// Colors for the TCP entities.
  static const List<Color> TCP_ENTITY_COLORS = const [Colors.ORANGE, Colors.PURPLE, Colors.PINK_RED, Colors.TEAL];

  /// Maximum amount of TCP entities.
  static const int MAX_TCP_ENTITIES = 4;

  /// Service for translations.
  final I18nService _i18n;

  /// How many ACKs are simulated in a second.
  int acksPerSecond = 100;

  /// The progress of receiving the next ACK.
  /// 0.5 means for example that the next ACK is halfway there!
  double _ackProgress;

  /// Number of the last ACK packet.
  double _lastAck;

  /// Timestamp needed for animating.
  num _lastAnimTimestamp;

  /// Current bandwidth to simulate (in MSS - Maximum segment size).
  int bandwidth;

  /// The currently available bandwidth.
  AvailableBandwidth _availableBandwidth;

  /// Graph to show the network traffic.
  Graph2D _graph;

  /// Temporary last mouse position (used for example to determine graph drags).
  Point<double> _lastMousePos;

  /// Min x before pause.
  double _beforePauseMinX;

  /// Max x before pause.
  double _beforePauseMaxX;

  /// List of tcp entities in the simulation.
  List<TCPEntity> _tcpEntities;

  /// Plot of the total congestion window size.
  List<Point<double>> _totalCongestionWindowPlot;

  /// Rectangle forming the background of the canvas.
  RoundRectangle _backgroundRect =
      RoundRectangle(color: BACKGROUND_COLOR, paintMode: PaintMode.FILL, radius: Edges.all(0.02), radiusSizeType: SizeType.PERCENT);

  /// Algorithms for TCP congestion control.
  List<TCPCongestionControlAlgorithm> _algorithms = [TCPReno(), TCPTahoe()];

  SelectionOptions<TCPCongestionControlAlgorithm> algorithmOptions;
  static ItemRenderer<TCPCongestionControlAlgorithm> algorithmItemRenderer = (dynamic algorithm) => algorithm.getName();

  IdMessage<String> pauseTooltip;
  IdMessage<String> addWorkstationTooltip;
  IdMessage<String> removeWorkstationTooltip;
  IdMessage<String> algorithmTooltip;
  IdMessage<String> timeoutTooltip;
  IdMessage<String> threeAcksTooltip;
  IdMessage<String> resetTooltip;

  /// Whether it is the first unpause action.
  bool _isResetting;

  /// Whether it is the first time the animation is paused.
  bool _isFirstPause;

  TCPCongestionControlAnimation(this._i18n) {
    reset();
  }

  @override
  void ngOnInit() {
    algorithmOptions = SelectionOptions.fromList(_algorithms);

    _initTranslations();
  }

  /// Reset the animation.
  void reset() {
    // First and foremost reset all values.
    _isResetting = true;
    _lastAnimTimestamp = null;
    _ackProgress = 0.0;
    _lastAck = ACKS_ON_GRAPH_X + 1.0;
    _tcpEntities = List<TCPEntity>();
    _graph = Graph2D(precision: 5.0 * window.devicePixelRatio, minX: 0, maxX: ACKS_ON_GRAPH_X, minY: 0, maxY: MAX_BANDWIDTH);
    _availableBandwidth = AvailableBandwidth(bandwidth);

    // Now configure them.
    onBandwidthChange(MAX_BANDWIDTH ~/ 2);

    addTCPEntity(); // Add initial TCP entity.

    // Add line graph for the maximum bandwidth.
    _graph.add(Graph2DFunction(processor: (x) => bandwidth, style: Graph2DStyle(color: Colors.CORAL)));

    // Add area plot for the total congestion window.
    _totalCongestionWindowPlot = [Point(_graph.maxX, 0.0)];
    _graph.add(Graph2DSeries(series: _totalCongestionWindowPlot, style: Graph2DStyle(color: Colors.GREY_GREEN, fillArea: true, drawLine: false)));

    // Start animation paused.
    switchPause(pauseAnimation: true);
    _isResetting = false;
    _isFirstPause = true;
  }

  /// Initialize all translations for the animation.
  void _initTranslations() {
    pauseTooltip = _i18n.get("tcp-congestion-control-animation.control.pause.tooltip");
    addWorkstationTooltip = _i18n.get("tcp-congestion-control-animation.control.add-workstation.tooltip");
    removeWorkstationTooltip = _i18n.get("tcp-congestion-control-animation.control.remove-workstation.tooltip");
    algorithmTooltip = _i18n.get("tcp-congestion-control-animation.control.workstation.algorithmTooltip");
    timeoutTooltip = _i18n.get("tcp-congestion-control-animation.control.workstation.timeout.tooltip");
    threeAcksTooltip = _i18n.get("tcp-congestion-control-animation.control.workstation.3acks.tooltip");
    resetTooltip = _i18n.get("tcp-congestion-control-animation.control.reset.tooltip");
  }

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0.0, 0.0, size.width, size.height);

    _backgroundRect.render(context, toRect(0.0, 0.0, size));

    num diff = -1;

    if (_lastAnimTimestamp != null) {
      diff = timestamp - _lastAnimTimestamp;
    }
    _lastAnimTimestamp = timestamp;

    if (diff != -1 && !isPaused) {
      double add = acksPerSecond * (diff / 1000);
      _ackProgress += add;

      _graph.translate(add, 0.0);

      if (_ackProgress >= MAX_BANDWIDTH / 200) {
        int packets = _ackProgress.floor();
        _ackProgress = _ackProgress - packets;

        _addAcks(packets);
      }
    }

    _graph.render(context, toRect(0.0, 0.0, size));
  }

  /// Add acks to the plot.
  void _addAcks(int packetCount) {
    // Mostly this is only 1 packet.
    // But for slow computers or extremely high [acksPerSecond]
    // packets might be lost otherwise.
    for (int i = 0; i < packetCount; i++) {
      int totalCongestionWindow = 0;
      _lastAck++;

      for (TCPEntity entity in _tcpEntities) {
        var stateBefore = entity.controller.context.state;
        bool important = entity.controller.onACKReceived();

        if (stateBefore == entity.controller.context.state) {
          entity.controller.context.cyclesInState++;
        }

        int currentCongestionWindow = entity.controller.getCongestionWindow();
        totalCongestionWindow += currentCongestionWindow;

        _nextPoint(_lastAck, currentCongestionWindow, entity.plot, entity.maxCacheCount,
            replaceLast: !important && entity.controller.context.cyclesInState > 1);
      }

      // Total congestion window plot.
      _nextPoint(_lastAck, totalCongestionWindow, _totalCongestionWindowPlot, MAX_SERIES_SIZE * 2, reduce: true, reducePrecision: ACKS_ON_GRAPH_X / 200);
    }
  }

  /// What to do on mouse down on the canvas.
  @override
  void onMouseDown(CanvasMouseEvent event) {
    _lastMousePos = event.pos;
  }

  /// What to do on mouse up on the canvas.
  @override
  void onMouseUp(CanvasMouseEvent event) {
    _lastMousePos = null;
  }

  /// What to do on mouse move on the canvas.
  @override
  void onMouseMove(CanvasMouseEvent event) {
    if (_lastMousePos != null && isPaused) {
      double xLength = _graph.maxX - _graph.minX;

      double xDiff = (event.pos.x - _lastMousePos.x) / size.width * xLength;

      _graph.translate(-xDiff, 0.0);

      _lastMousePos = event.pos;
    }
  }

  /// What to do if the bandwidth is changed.
  void onBandwidthChange(int newBandwidth) {
    bandwidth = newBandwidth;
    _availableBandwidth.maxBandwidth = bandwidth;

    // Tell graph to recalculate.
    _graph.invalidate();
  }

  /// What to do if the algorithm for a [tcpEntity] changes.
  void onAlgorithmChange(TCPEntity tcpEntity, TCPCongestionControlAlgorithm newSelection) {
    tcpEntity.controller.algorithm = newSelection;
  }

  /// Aspect ratio of the canvas.
  double get aspectRatio => 2.0;

  @override
  void switchPauseSubAnimations() {
    if (_isResetting) {
      return;
    }

    if (_isFirstPause) {
      _isFirstPause = false;
      return;
    }

    if (isPaused) {
      _beforePauseMinX = _graph.minX;
      _beforePauseMaxX = _graph.maxX;
    } else {
      _graph.minX = _beforePauseMinX;
      _graph.maxX = _beforePauseMaxX;
    }
  }

  @override
  void unpaused(num timestampDifference) {
    // Nothing to adjust.
  }

  /// Simulate a timeout on the entity with the passed [entityIndex].
  void doTimeout(TCPEntity entity) {
    entity.controller.onTimeout();
    _nextPoint(_lastAck, entity.controller.getCongestionWindow(), entity.plot, entity.maxCacheCount);
  }

  /// Simulate 3 ACK packets on the entity with the passed [entityIndex].
  void do3Acks(TCPEntity entity) {
    entity.controller.onDuplicateACK(3);
    _nextPoint(_lastAck, entity.controller.getCongestionWindow(), entity.plot, entity.maxCacheCount);
  }

  /// Remove a TCP entity from the scenario.
  void removeTCPEntity() {
    if (_tcpEntities.length > 1) {
      var entity = _tcpEntities.removeLast();

      _availableBandwidth.deregister(entity.controller);
      _nextPoint(_lastAck, 0, entity.plot, entity.maxCacheCount);
    }
  }

  /// Add a TCP entity to the scenario.
  void addTCPEntity() {
    if (_tcpEntities.length < MAX_TCP_ENTITIES) {
      var plotSeries = [Point<double>(_graph.maxX, 0.0)];
      var color = TCP_ENTITY_COLORS[_tcpEntities.length];

      var graph = Graph2DSeries(series: plotSeries, style: Graph2DStyle(color: color, fillArea: false));
      var selectionModel = SelectionModel.single(selected: _algorithms.first, keyProvider: (dnsQueryType) => dnsQueryType.getName());
      var controller = TCPCongestionController(_availableBandwidth)..algorithm = _algorithms.first;

      _tcpEntities.add(TCPEntity(controller, plotSeries, color, graph, selectionModel, MAX_SERIES_SIZE));
      _graph.add(graph);
    }
  }

  /// Add a new point to the passed [plot] showing the passed [congestionWindow].
  void _nextPoint(double ackNumber, int congestionWindow, List<Point<double>> plot, int maxCacheCount,
      {bool replaceLast = false, bool reduce = false, double reducePrecision = 1.0}) {
    Point<double> next = Point<double>(ackNumber, congestionWindow.toDouble());

    if (reduce && plot.length > 1) {
      // Try to reduce the amount of points added by reducing the density of points.
      if (next.x - plot[plot.length - 2].x < reducePrecision) {
        replaceLast = true;
      }
    }

    if (replaceLast) {
      plot.last = next;
    } else {
      plot.add(next);

      _trimSeries(plot, maxCacheCount);
    }
  }

  /// Trim [series] to the passed [maxSize].
  void _trimSeries(List<Point<double>> series, int maxSize) {
    int removeCount = series.length - maxSize;
    if (removeCount > 0) {
      series.removeRange(0, removeCount);
    }
  }

  /// Get the tcp entities list.
  List<TCPEntity> get tcpEntities => _tcpEntities;

  /// Get maximum amount of tcp entities.
  int get maxTCPEntities => MAX_TCP_ENTITIES;

  /// Get a brighter color.
  Color getBrighterColor(Color color) => Color.brighten(color, 0.9);
}

class AvailableBandwidth {
  int _maxBandwidth;

  List<CongestionWindowProvider> _congestionWindowProvider = List<CongestionWindowProvider>();

  AvailableBandwidth(this._maxBandwidth);

  void register(CongestionWindowProvider provider) {
    _congestionWindowProvider.add(provider);
  }

  void deregister(CongestionWindowProvider provider) {
    _congestionWindowProvider.remove(provider);
  }

  void set maxBandwidth(int maxBandwidth) => _maxBandwidth = maxBandwidth;

  int get availableBandwidth =>
      _maxBandwidth - _congestionWindowProvider.map((provider) => provider.getCongestionWindow()).reduce((value, element) => value + element);
}

class TCPEntity {
  final TCPCongestionController controller;
  final List<Point<double>> plot;
  final Color color;
  final Graph2DSeries graph;
  final SelectionModel<TCPCongestionControlAlgorithm> selectionModel;

  /// Maximum amount of nodes to cache.
  final int maxCacheCount;

  TCPEntity(this.controller, this.plot, this.color, this.graph, this.selectionModel, this.maxCacheCount);
}
