import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/shared/signal_emitter/impl/circular_signal_emitter.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';

/// Animation showing the hidden node problem (RTS/CTS).
@Component(
  selector: "hidden-node-problem-animation",
  styleUrls: [
    "hidden_node_problem_animation.css",
  ],
  templateUrl: "hidden_node_problem_animation.html",
  directives: [
    coreDirectives,
    CanvasComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class HiddenNodeProblemAnimation extends CanvasAnimation implements OnInit, OnDestroy {
  /// Service to get translations from.
  final I18nService _i18n;

  CircularSignalEmitter _test = CircularSignalEmitter();

  /// Create animation.
  HiddenNodeProblemAnimation(this._i18n);

  @override
  void ngOnInit() {}

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    double radius = 200.0;
    _test.render(context, Rectangle<double>(size.width / 2, size.height / 2, radius, radius), timestamp);
  }

  /// Get the height of the canvas.
  int get canvasHeight => 500;
}
