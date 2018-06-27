import 'dart:async';
import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;

/**
 * Overview component should give an overview over all available animations.
 */
@Component(
    selector: "overview-component",
    templateUrl: "overview_component.html",
    styleUrls: const ["overview_component.css"],
    directives: const [routerDirectives, coreDirectives, materialDirectives],
    providers: const [const ClassProvider(AnimationService)],
    pipes: const [I18nPipe])
class OverviewComponent implements OnInit {
  Map<String, AnimationDescriptor> animations;

  /**
   * Service to get animation components from.
   */
  AnimationService _animationService;

  /**
   * Service used to get translations.
   */
  I18nService _i18n;

  OverviewComponent(this._animationService, this._i18n);

  @override
  ngOnInit() {
    getAnimations();
  }

  Future<Null> getAnimations() async {
    animations = await _animationService.getAnimationDescriptors();
  }

  /**
   * Get animation url to navigate to.
   */
  String animationUrl(String animationPath) {
    return paths.animation.toUrl(parameters: {paths.idParam: animationPath});
  }

  Message getAnimationName(String key) => _i18n.get(key);
}
