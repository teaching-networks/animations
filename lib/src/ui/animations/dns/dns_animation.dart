import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';

@Component(
  selector: "dns-animation",
  styleUrls: ["dns_animation.css"],
  templateUrl: "dns_animation.html",
  directives: [
    coreDirectives,
    MaterialButtonComponent,
    MaterialIconComponent,
    CanvasComponent
  ],
  pipes: [I18nPipe]
)
class DNSAnimation extends CanvasAnimation implements OnDestroy {

  final I18nService _i18n;

  DNSAnimation(this._i18n);
  
  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);
  }

}