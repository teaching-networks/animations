import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/impl/tcp_reno.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/algorithm/impl/tcp_tahoe.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/controller/tcp_congestion_controller.dart';
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
  /// Scale of one ACK on the graph.
  /// 100 means 1:100 which means 1 on the x-axis of the graph is 100 ACKs.
  static const int ACK_ON_GRAPH_SCALE = 100;

  /// Maximum possible bandwidth in MSS (Maximum segment size).
  static const int MAX_BANDWIDTH = 100;

  /// Service for translations.
  final I18nService _i18n;

  /// How many ACKs are simulated in a second.
  double acksPerSecond = 1.0;

  /// The progress of receiving the next ACK.
  /// 0.5 means for example that the next ACK is halfway there!
  double ackProgress = 0.0;

  /// Timestamp needed for animating.
  num lastTimestamp;

  /// Current bandwidth to simulate (in MSS - Maximum segment size).
  int bandwidth = MAX_BANDWIDTH ~/ 2;

  /// Current bandwidth shown in the graph (y-value).
  double displayBandwidth = 0.5;

  /// Graph to show the network traffic.
  Graph2D graph = Graph2D(precision: 5.0 * window.devicePixelRatio, minX: 0, maxX: 1, minY: 0, maxY: 1);

  /// Temporary last mouse position (used for example to determine graph drags).
  Point<double> _lastMousePos;

  TCPCongestionController _controller;

  List<Point<double>> test;

  TCPCongestionControlAnimation(this._i18n) {
    _controller = TCPCongestionController(bandwidth);
    _controller.algorithm = TCPReno();

    test = [Point(graph.maxX, 0.0)];

    graph.add(Graph2DFunction(processor: (x) => displayBandwidth, style: Graph2DStyle(color: Colors.CORAL)));
    graph.add(Graph2DSeries(series: test, style: Graph2DStyle(color: Colors.GREY_GREEN, fillArea: true)));
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

    if (lastTimestamp != null && !isPaused) {
      num diff = timestamp - lastTimestamp;

      double add = acksPerSecond * (diff / 1000);
      ackProgress += add;

      graph.translate(add / ACK_ON_GRAPH_SCALE, 0.0);

      if (ackProgress >= 1.0) {
        int packets = ackProgress.floor();
        ackProgress = ackProgress - packets;

        // Mostly this is only 1 packet.
        // But for slow computers or extremely high [acksPerSecond]
        // packets might be lost otherwise.
        for (int i = 0; i < packets; i++) {
          _controller.onACKReceived();

          _nextTestPoint();
        }
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
    displayBandwidth = newBandwidth / MAX_BANDWIDTH;

    _controller.availableBandwidth = bandwidth;

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

  void testTimeout() {
    _controller.onTimeout();
    _nextTestPoint();
  }

  void test3Acks() {
    _controller.onDuplicateACK(3);
    _nextTestPoint();
  }

  void _nextTestPoint() {
    Point next = Point<double>(graph.maxX, _controller.getCwndTest() / MAX_BANDWIDTH);

    // Check if linear line by checking the last two points vector.
    Point p1 = test.last;
    Point p2 = test[test.length - 1];

    double xInc1 = p1.x - p2.x;
    double yInc1 = p1.y - p2.y;

    p2 = p1;
    p1 = next;

    double xInc2 = p1.x - p2.x;
    double yInc2 = p1.y - p2.y;

    if (xInc1 == xInc2 && yInc1 == yInc2) {
      test.last = Point(p2.x + xInc2, p2.y + yInc2);
    } else {
      test.add(next);
    }
  }
}
