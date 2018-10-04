import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/shared/location_dot/location_dot.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';

@Component(
    selector: "dns-animation",
    styleUrls: ["dns_animation.css"],
    templateUrl: "dns_animation.html",
    directives: [coreDirectives, MaterialButtonComponent, MaterialIconComponent, CanvasComponent],
    pipes: [I18nPipe])
class DNSAnimation extends CanvasAnimation implements OnDestroy {
  /// Aspect ratio of the world map SVG -> width / height.
  static final double WORLD_MAP_ASPECT_RATIO = 750.0 / 430.0;

  final I18nService _i18n;

  /*
  IMAGES TO DRAW IN THE CANVAS.
   */
  final ImageElement _worldMap = new ImageElement(src: "img/animation/world_map.svg");

  LocationDot _originDot = LocationDot(color: Colors.LIME);
  LocationDot _destinationDot = LocationDot(color: Colors.RED);

  DNSAnimation(this._i18n);

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    _drawBackground();

    _drawOrigin(timestamp);
    _drawDestination(timestamp);
  }

  void _drawBackground() {
    context.drawImageScaled(_worldMap, 0.0, 0.0, size.width, size.height);
  }

  void _drawOrigin(num timestamp) {
    double dotSize = size.height / 50;
    _originDot.render(context, Rectangle<double>(size.width * 0.6, size.height * 0.2, dotSize, dotSize), timestamp);
  }

  void _drawDestination(num timestamp) {
    double dotSize = size.height / 50;
    _destinationDot.render(context, Rectangle<double>(size.width * 0.8, size.height * 0.4, dotSize, dotSize), timestamp);
  }

}
