import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';

@Component(
  selector: "queue-simulation-animation",
  styleUrls: const ["queue_simulation_animation.css"],
  templateUrl: "queue_simulation_animation.html",
  directives: const [coreDirectives, materialDirectives, CanvasComponent],
  pipes: const [I18nPipe]
)
class QueueSimulationAnimation extends CanvasAnimation {

  @override
  void render(num timestamp) {
    // TODO: implement render
  }

}