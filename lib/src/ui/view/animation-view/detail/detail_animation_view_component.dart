import "package:angular/angular.dart";
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/dynamic/dynamic_content_component.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;

/**
 * Detail component showing an animation in detail (Fullscreen).
 */
@Component(
    selector: "detail-animation-view-component",
    templateUrl: "detail_animation_view_component.html",
    styleUrls: ["detail_animation_view_component.css"],
    directives: [coreDirectives, DynamicContentComponent, MaterialSpinnerComponent],
    pipes: [I18nPipe]
)
class DetailAnimationViewComponent implements OnActivate {
  final AnimationService _animationService;

  dynamic componentToShow;

  bool isLoading = true;
  bool notVisible = false;

  DetailAnimationViewComponent(this._animationService);

  @override
  void onActivate(RouterState previous, RouterState current) {
    final String id = paths.getId(current.parameters);

    if (id != null) {
      _animationService.getAnimationDescriptors().then((animations) {
        isLoading = false;

        AnimationDescriptor descriptor = animations[id];

        if (descriptor != null) {
          componentToShow = descriptor.componentFactory;
        } else {
          notVisible = true;
        }
      });
    }
  }
}
