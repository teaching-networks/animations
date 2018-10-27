import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';

/// Animation showing the TCP flow control mechanism.
@Component(
    selector: "tcp-flow-control-animation",
    templateUrl: "tcp_flow_control_animation.html",
    styleUrls: ["tcp_flow_control_animation.css"],
    directives: [coreDirectives, CanvasComponent],
    pipes: [I18nPipe])
class TCPFlowControlAnimation extends CanvasAnimation {
  final I18nService _i18n;

  TCPFlowControlAnimation(this._i18n);

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    context.fillText("Nothing to see here!", size.width / 2, size.height / 2);
  }

  /// Get the canvas height.
  int get canvasHeight => (windowHeight * 0.8).round();
}
