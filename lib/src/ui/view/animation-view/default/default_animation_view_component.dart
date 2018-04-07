import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/src/services/animation_service/animation_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/dynamic/dynamic_content_component.dart';
import 'package:netzwerke_animationen/src/ui/view/animation-view/detail/detail_animation_view_component.dart';
import 'package:netzwerke_animationen/src/ui/view/overview/overview_component.dart';

/**
 * Default animation view component showing an animation in default mode.
 */
@Component(
    selector: "default-animation-view-component",
    templateUrl: "default_animation_view_component.html",
    styleUrls: const ["default_animation_view_component.css"],
    directives: const [CORE_DIRECTIVES, materialDirectives, DynamicContentComponent])
class DefaultAnimationViewComponent implements OnInit {
  static const String NAME = "Default";

  String _id;

  Type componentToShow;

  final AnimationService _animationService;
  final RouteParams _routeParams;
  final Router _router;

  DefaultAnimationViewComponent(this._animationService, this._router, this._routeParams);

  @override
  ngOnInit() {
    _id = _routeParams.get("id");

    _animationService.getAnimationDescriptors().then((animations) {
      AnimationDescriptor descriptor = animations[_id];

      if (descriptor != null) {
        componentToShow = descriptor.type;
      }
    });
  }

  void back() => _router.navigate([OverviewComponent.NAME]);

  void detail() => _router.navigate([
        DetailAnimationViewComponent.NAME,
        {"id": _id}
      ]);

}
