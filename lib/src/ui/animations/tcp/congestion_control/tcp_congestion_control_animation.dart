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
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/model/tcp_congestion_control_state.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/canvas_pausable.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/renderables/graph2d_function.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/graph2d.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/renderables/graph2d_series.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/style/graph2d_style.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

/// Animation showing the TCP congestion control mechanism.
@Component(
    selector: "tcp-congestion-control-animation",
    templateUrl: "tcp_congestion_control_animation.html",
    styleUrls: ["tcp_congestion_control_animation.css"],
    directives: [coreDirectives, CanvasComponent, MaterialSliderComponent, MaterialButtonComponent, MaterialIconComponent],
    pipes: [I18nPipe])
class TCPCongestionControlAnimation extends CanvasAnimation with CanvasPausableMixin implements OnInit, OnDestroy {
  /// How many ACKs fit on the x-axis of the graph.
  static const int ACKS_ON_GRAPH_X = 100;

  /// Maximum possible bandwidth in MSS (Maximum segment size).
  static const int MAX_BANDWIDTH = 100;

  /// Maximum size of a series list.
  static const int MAX_SERIES_SIZE = 250;

  /// Service for translations.
  final I18nService _i18n;

  /// How many ACKs are simulated in a second.
  int acksPerSecond = 15;

  /// The progress of receiving the next ACK.
  /// 0.5 means for example that the next ACK is halfway there!
  double ackProgress = 0.0;

  /// Timestamp needed for animating.
  num lastTimestamp;

  /// Current bandwidth to simulate (in MSS - Maximum segment size).
  int bandwidth = MAX_BANDWIDTH ~/ 2;

  /// Graph to show the network traffic.
  Graph2D graph = Graph2D(precision: 5.0 * window.devicePixelRatio, minX: 0, maxX: ACKS_ON_GRAPH_X, minY: 0, maxY: MAX_BANDWIDTH);

  /// Temporary last mouse position (used for example to determine graph drags).
  Point<double> _lastMousePos;

  /// Min x before pause.
  double _beforePauseMinX;

  /// Max x before pause.
  double _beforePauseMaxX;

  TCPCongestionController _controller;

  List<Point<double>> test;

  TCPCongestionControlAnimation(this._i18n) {
    _controller = TCPCongestionController(bandwidth);
    _controller.algorithm = TCPTahoe();

    test = [Point(graph.maxX, 0.0)];

    graph.add(Graph2DFunction(processor: (x) => bandwidth, style: Graph2DStyle(color: Colors.CORAL)));
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

    num diff = -1;

    if (lastTimestamp != null) {
      diff = timestamp - lastTimestamp;
    }
    lastTimestamp = timestamp;

    if (diff != -1 && !isPaused) {
      double add = acksPerSecond * (diff / 1000);
      ackProgress += add;

      graph.translate(add, 0.0);

      if (ackProgress >= 1.0) {
        int packets = ackProgress.floor();
        ackProgress = ackProgress - packets;

        // Mostly this is only 1 packet.
        // But for slow computers or extremely high [acksPerSecond]
        // packets might be lost otherwise.
        for (int i = 0; i < packets; i++) {
          bool stateChanged = _controller.onACKReceived();

          _nextTestPoint(!stateChanged && _controller.context.state == TCPCongestionControlState.CONGESTION_AVOIDANCE);
        }
      }
    }

    graph.render(context, toRect(0.0, 0.0, size));
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

    _controller.availableBandwidth = bandwidth;

    // Tell graph to recalculate.
    graph.invalidate();
  }

  /// Aspect ratio of the canvas.
  double get aspectRatio => 2.0;

  @override
  void switchPauseSubAnimations() {
    if (isPaused) {
      _beforePauseMinX = graph.minX;
      _beforePauseMaxX = graph.maxX;
    } else {
      graph.minX = _beforePauseMinX;
      graph.maxX = _beforePauseMaxX;
    }
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

  void _nextTestPoint([bool checkIfContinuesLinear = false]) {
    Point<double> next = Point<double>(graph.maxX + 1, _controller.context.congestionWindow.toDouble());

    if (checkIfContinuesLinear && _pointContinuesLinear(next, test, precision: 1.0)) {
      test.last = next;
    } else {
      test.add(next);

      _trimSeries(test, MAX_SERIES_SIZE);
    }
  }

  /// Trim [series] to the passed [maxSize].
  void _trimSeries(List<Point<double>> series, int maxSize) {
    int removeCount = series.length - maxSize;
    if (removeCount > 0) {
      series.removeRange(0, removeCount);
    }
  }

  /// Check if the passed [nextPoint] continues the passed series [history] of points lineary.
  /// Adjust the [precision] to your needs.
  bool _pointContinuesLinear(Point<double> nextPoint, List<Point<double>> history, {double precision = 0.1}) {
    if (history.length < 2) {
      return false;
    }

    Point<double> last = history.last;
    Point<double> beforeLast = history[history.length - 2];

    double xDiff = last.x - beforeLast.x;
    var oldDiff = vector.Vector2(xDiff, last.y - beforeLast.y) / xDiff;

    xDiff = nextPoint.x - last.x;
    var newDiff = vector.Vector2(xDiff, nextPoint.y - last.y) / xDiff;

    return newDiff.y >= oldDiff.y - precision && newDiff.y <= oldDiff.y + precision;
  }
}
