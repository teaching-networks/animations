import "package:angular/angular.dart";
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/src/services/animation_service/animation_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/dynamic/dynamic_content_component.dart';

/**
 * Detail component showing an animation in detail (Fullscreen).
 */
@Component(
  selector: "detail-animation-view-component",
  templateUrl: "detail_animation_view_component.html",
  styleUrls: const ["detail_animation_view_component.css"],
  directives: const [CORE_DIRECTIVES, DynamicContentComponent]
)
class DetailAnimationViewComponent implements OnInit {

  static const String NAME = "Detail";

  Type componentToShow;

  final AnimationService _animationService;
  final RouteParams _routeParams;

  DetailAnimationViewComponent(this._animationService, this._routeParams);

  @override
  ngOnInit() {
    String id = _routeParams.get("id");

    _animationService.getAnimationDescriptors().then((animations) {
      AnimationDescriptor descriptor = animations[id];

      if (descriptor != null) {
        componentToShow = descriptor.type;
      }
    });
  }

}