import 'dart:async';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/animations/shared/packet_line/packet_line.dart';
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

  PacketLine _preRouterLine = new PacketLine();

  QueueSimulationAnimation() {
    _emitLoop();
  }

  void _emitLoop() {
    new Future.delayed(new Duration(seconds: 1), () {
      _preRouterLine.emit();

      _emitLoop();
    });
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    double lineHeight = size.height / 10;
    double lineY = size.height / 2 - lineHeight / 2;

    _preRouterLine.render(context, new Rectangle<double>(0.0, lineY, size.width, lineHeight), timestamp);
  }

}