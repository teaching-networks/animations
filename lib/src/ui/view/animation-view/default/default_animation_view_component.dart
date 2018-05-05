import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/src/router/routes.dart';
import 'package:netzwerke_animationen/src/services/animation_service/animation_service.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_pipe.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/dynamic/dynamic_content_component.dart';
import 'package:netzwerke_animationen/src/router/route_paths.dart' as paths;

/**
 * Default animation view component showing an animation in default mode.
 */
@Component(
    selector: "default-animation-view-component",
    templateUrl: "default_animation_view_component.html",
    styleUrls: const ["default_animation_view_component.css"],
    directives: const [coreDirectives, materialDirectives, routerDirectives, DynamicContentComponent],
    providers: const [const ClassProvider(Routes)],
    pipes: const [I18nPipe]
)
class DefaultAnimationViewComponent implements OnActivate {
  String _id = "";

  dynamic componentToShow;

  final AnimationService _animationService;
  final Routes routes;

  DefaultAnimationViewComponent(this._animationService, this.routes);

  @override
  void onActivate(RouterState previous, RouterState current) {
   _id = paths.getId(current.parameters);

    if (_id != null) {
      _animationService.getAnimationDescriptors().then((animations) {
        AnimationDescriptor descriptor = animations[_id];

        if (descriptor != null) {
          componentToShow = descriptor.componentFactory;
        }
      });
    }
  }

  String get detailUrl => paths.detail.toUrl(parameters: {
    paths.idParam: _id
  });

}
