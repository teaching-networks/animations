import 'dart:math';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/buffer/buffer_window.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/progress_rect.dart';
import 'package:hm_animations/src/ui/canvas/progress/bar/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/progress/lazy_progress/lazy_progress.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

/// Animation showing the TCP flow control mechanism.
@Component(
    selector: "tcp-flow-control-animation",
    templateUrl: "tcp_flow_control_animation.html",
    styleUrls: ["tcp_flow_control_animation.css"],
    directives: [coreDirectives, CanvasComponent],
    pipes: [I18nPipe])
class TCPFlowControlAnimation extends CanvasAnimation implements OnInit {
  final I18nService _i18n;

  final BufferWindow window = BufferWindow();

  TCPFlowControlAnimation(this._i18n);

  @override
  void ngOnInit() {
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    window.render(context, toRect(0.0, 0.0, size));
  }

  /// Get the canvas height.
  int get canvasHeight => (windowHeight * 0.8).round();

  void test() {
    window.fillBuffer();
  }

}
