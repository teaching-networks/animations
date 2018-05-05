import "package:angular/angular.dart";
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/src/services/animation_service/animation_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/dynamic/dynamic_content_component.dart';
import 'package:netzwerke_animationen/src/router/route_paths.dart' as paths;

/**
 * Detail component showing an animation in detail (Fullscreen).
 */
@Component(
    selector: "detail-animation-view-component",
    templateUrl: "detail_animation_view_component.html",
    styleUrls: const ["detail_animation_view_component.css"],
    directives: const [coreDirectives, DynamicContentComponent],
    providers: const [const ClassProvider(AnimationService)])
class DetailAnimationViewComponent implements OnActivate {
  dynamic componentToShow;

  final AnimationService _animationService;

  DetailAnimationViewComponent(this._animationService);

  @override
  void onActivate(RouterState previous, RouterState current) {
    final String id = paths.getId(current.parameters);

    if (id != null) {
      _animationService.getAnimationDescriptors().then((animations) {
        AnimationDescriptor descriptor = animations[id];

        if (descriptor != null) {
          componentToShow = descriptor.componentFactory;
        }
      });
    }
  }
}
