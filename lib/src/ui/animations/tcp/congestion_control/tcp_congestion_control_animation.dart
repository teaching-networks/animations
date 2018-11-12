import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';

/// Animation showing the TCP congestion control mechanism.
@Component(
    selector: "tcp-congestion-control-animation",
    templateUrl: "tcp_congestion_control_animation.html",
    styleUrls: ["tcp_congestion_control_animation.css"],
    directives: [coreDirectives, CanvasComponent],
    pipes: [I18nPipe])
class TCPCongestionControlAnimation extends CanvasAnimation implements OnInit, OnDestroy {
  final I18nService _i18n;

  TCPCongestionControlAnimation(this._i18n);

  @override
  void ngOnInit() {
    // TODO: implement ngOnInit
  }

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0.0, 0.0, size.width, size.height);

    context.strokeRect(0.0, 0.0, size.width, size.height);
  }

  /// Aspect ratio of the canvas.
  double get aspectRatio => 2.0;
}
