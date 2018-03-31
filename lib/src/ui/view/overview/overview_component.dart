import 'dart:async';
import "package:angular/angular.dart";
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/src/services/animation_service/animation_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/view/animation-view/default/default_animation_view_component.dart';

/**
 * Overview component should give an overview over all available animations.
 */
@Component(
  selector: "overview-component",
  templateUrl: "overview_component.html",
  styleUrls: const ["overview_component.css"],
  directives: const [ROUTER_DIRECTIVES, CORE_DIRECTIVES]
)
class OverviewComponent implements OnInit {

  static const String NAME = "Overview";

  Map<String, AnimationDescriptor> animations;

  /**
   * Service to get animation components from.
   */
  AnimationService _animationService;

  /**
   * Router used to navigate to other routes.
   */
  Router _router;

  OverviewComponent(this._animationService, this._router);

  @override
  ngOnInit() {
    getAnimations();
  }

  Future<Null> getAnimations() async {
    animations = await _animationService.getAnimationDescriptors();
  }

  /**
   * Called when an animation has been selected.
   */
  void onAnimationSelected(String animationName) {
    goToAnimationView(animationName);
  }

  /**
   * Go to animation view and show the passed animation.
   */
  Future goToAnimationView(String animationName) => _router.navigate([
    DefaultAnimationViewComponent.NAME,
    {
      "id": animationName
    }
  ]);

}