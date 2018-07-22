import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress.dart';
import 'package:hm_animations/src/ui/canvas/progress/vertical_progress_bar.dart';
import 'package:hm_animations/src/ui/canvas/util/direction.dart';

@Component(
  selector: "http-delay-animation",
  styleUrls: ["http_delay_animation.css"],
  templateUrl: "http_delay_animation.html",
  directives: [coreDirectives, MaterialButtonComponent, MaterialSliderComponent, MaterialIconComponent, CanvasComponent],
  pipes: [I18nPipe]
)
class HttpDelayAnimation extends CanvasAnimation implements OnDestroy {

  Progress progress = new Progress();
  VerticalProgressBar test;
  VerticalProgressBar test2;

  num startTimestamp;

  HttpDelayAnimation() {
    test = new VerticalProgressBar(progress, Direction.NORTH);
    test2 = new VerticalProgressBar(progress, Direction.SOUTH);
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    if (startTimestamp == null) {
      startTimestamp = timestamp;
    }

    progress.progressSave = (timestamp - startTimestamp) / 5000;

    test.render(context, new Rectangle<double>(0.0, 0.0, size.width / 2, size.height));
    test2.render(context, new Rectangle<double>(size.width / 2, 0.0, size.width / 2, size.height));
  }

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

}