import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/routes.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/dynamic/dynamic_content_component.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;

/**
 * Default animation view component showing an animation in default mode.
 */
@Component(
    selector: "default-animation-view-component",
    templateUrl: "default_animation_view_component.html",
    styleUrls: ["default_animation_view_component.css"],
    directives: [coreDirectives, MaterialButtonComponent, MaterialIconComponent, routerDirectives, DynamicContentComponent, MaterialSpinnerComponent],
    providers: [ClassProvider(Routes)],
    pipes: [I18nPipe])
class DefaultAnimationViewComponent implements OnActivate {
  final AnimationService _animationService;
  final Routes routes;
  final I18nService _i18n;

  String _id = "";

  Message animationTitle;
  dynamic componentToShow;

  bool isLoading = true;
  bool notVisible = false;
  bool isError = false;

  DefaultAnimationViewComponent(this._animationService, this.routes, this._i18n);

  @override
  void onActivate(RouterState previous, RouterState current) {
    _id = paths.getId(current.parameters);

    if (_id != null) {
      _animationService.getAnimationDescriptors().then((animations) {
        AnimationDescriptor descriptor = animations[_id];

        if (descriptor != null) {
          animationTitle = _i18n.get("${descriptor.baseTranslationKey}.name");
          componentToShow = descriptor.componentFactory;
        } else {
          notVisible = true;
        }
      }).catchError((e) {
        isError = true;
        return null;
      }).whenComplete(() => isLoading = false);
    }
  }

  String get detailUrl => paths.detail.toUrl(parameters: {paths.idParam: _id});
}
