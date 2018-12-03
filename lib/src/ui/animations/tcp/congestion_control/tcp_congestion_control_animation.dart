import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/renderables/graph2d_function.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/graph2d.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/renderables/graph2d_series.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/style/graph2d_style.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Animation showing the TCP congestion control mechanism.
@Component(
    selector: "tcp-congestion-control-animation",
    templateUrl: "tcp_congestion_control_animation.html",
    styleUrls: ["tcp_congestion_control_animation.css"],
    directives: [coreDirectives, CanvasComponent, MaterialSliderComponent, MaterialButtonComponent, MaterialIconComponent],
    pipes: [I18nPipe])
class TCPCongestionControlAnimation extends CanvasAnimation with CanvasPausableMixin implements OnInit, OnDestroy {
  /// Service for translations.
  final I18nService _i18n;

  /// x-value increase per second (Transition of the graph).
  double xPerSecond = 1.0;

  /// Timestamp needed for animating.
  num lastTimestamp;

  /// Current bandwidth to simulate (in MBit).
  int bandwidth = 500;

  /// Current bandwidth shown in the graph (y-value).
  double displayBandwidth = 0.5;

  /// Graph to show the network traffic.
  Graph2D graph = Graph2D(precision: 5.0 * window.devicePixelRatio, minX: -2, maxX: 2, minY: 0, maxY: 1);

  /// Temporary last mouse position (used for example to determine graph drags).
  Point<double> _lastMousePos;

  TCPCongestionControlAnimation(this._i18n) {
    graph.add(Graph2DFunction(processor: (x) => 0.3 * sin(x) + 0.5, style: Graph2DStyle(fillArea: true)));
    graph.add(Graph2DFunction(processor: (x) => displayBandwidth, style: Graph2DStyle(color: Colors.CORAL)));
    graph.add(Graph2DSeries(series: [
      Point(-2.0, 0.0),
      Point(-1.0, 0.3),
      Point(0.0, 0.5),
      Point(1.0, 0.0),
      Point(2.0, 0.3)
    ], style: Graph2DStyle(color: Colors.GREY_GREEN, fillArea: true)));
  }

  @override
  void ngOnInit() {}

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0.0, 0.0, size.width, size.height);

    context.strokeRect(0.0, 0.0, size.width, size.height);

    if (lastTimestamp != null) {
      num diff = timestamp - lastTimestamp;
      double add = xPerSecond * (diff / 1000);

      if (!isPaused) {
        graph.translate(add, 0.0);
      }
    }

    graph.render(context, toRect(0.0, 0.0, size));

    lastTimestamp = timestamp;
  }

  /// What to do on mouse down on the canvas.
  void onMouseDown(Point<double> pos) {
    _lastMousePos = pos;
  }

  /// What to do on mouse up on the canvas.
  void onMouseUp(Point<double> pos) {
    _lastMousePos = null;
  }

  /// What to do on mouse move on the canvas.
  void onMouseMove(Point<double> pos) {
    if (_lastMousePos != null && isPaused) {
      double xLength = graph.maxX - graph.minX;

      double xDiff = (pos.x - _lastMousePos.x) / size.width * xLength;

      graph.translate(-xDiff, 0.0);

      _lastMousePos = pos;
    }
  }

  /// What to do if the bandwidth is changed.
  void onBandwidthChange(int newBandwidth) {
    bandwidth = newBandwidth;
    displayBandwidth = newBandwidth / 1000;

    // Tell graph to recalculate.
    graph.invalidate();
  }

  /// Aspect ratio of the canvas.
  double get aspectRatio => 2.0;

  @override
  void switchPauseSubAnimations() {
    // Nothing to switch yet.
  }

  @override
  void unpaused(num timestampDifference) {
    // Nothing to adjust.
  }
}
