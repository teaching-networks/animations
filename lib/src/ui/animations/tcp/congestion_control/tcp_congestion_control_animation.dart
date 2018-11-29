import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/graph/2d/graph2d.dart';

/// Animation showing the TCP congestion control mechanism.
@Component(
    selector: "tcp-congestion-control-animation",
    templateUrl: "tcp_congestion_control_animation.html",
    styleUrls: ["tcp_congestion_control_animation.css"],
    directives: [coreDirectives, CanvasComponent, MaterialSliderComponent],
    pipes: [I18nPipe])
class TCPCongestionControlAnimation extends CanvasAnimation implements OnInit, OnDestroy {
  final I18nService _i18n;

  double xPerSecond = 3.0;
  num lastTimestamp;

  Graph2D test = Graph2D(precision: 5.0, minX: -4, maxX: 4, minY: -2, maxY: 2);

  TCPCongestionControlAnimation(this._i18n) {
    test.addFunction((x) => max(-1, min(1, x)));
    //test.addFunction((x) => pow(x, 2));
    test.addFunction((x) => sin(x));
  }

  @override
  void ngOnInit() {
  }

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

      test.translate(add, 0.0);
    }

    test.render(context, toRect(0.0, 0.0, size));

    lastTimestamp = timestamp;
  }

  /// Aspect ratio of the canvas.
  double get aspectRatio => 2.0;

}
