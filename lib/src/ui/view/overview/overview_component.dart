import 'dart:async';
import "package:angular/angular.dart";
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/animation_service/model/animation.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;
import 'package:hm_animations/src/ui/misc/directives/restricted_directive.dart';

/**
 * Overview component should give an overview over all available animations.
 */
@Component(selector: "overview-component", templateUrl: "overview_component.html", styleUrls: [
  "overview_component.css",
  "package:angular_components/css/mdc_web/card/mdc-card.scss.css"
], directives: [
  routerDirectives,
  coreDirectives,
  RestrictedDirective,
  MaterialToggleComponent,
  MaterialSpinnerComponent,
  MaterialIconComponent,
  MaterialButtonComponent
], pipes: [
  I18nPipe
])
class OverviewComponent implements OnInit, OnDestroy {
  Map<String, AnimationDescriptor> animationDescriptors;
  List<Animation> animations;

  /**
   * Service to get animation components from.
   */
  final AnimationService _animationService;

  final AuthenticationService _authService;
  StreamSubscription<bool> _loggedInSub;

  /**
   * Service used to get translations.
   */
  final I18nService _i18n;

  /// Whether to show an error message.
  bool isError = false;

  OverviewComponent(this._animationService, this._authService, this._i18n);

  @override
  ngOnInit() {
    getAnimations();

    _loggedInSub = _authService.loggedIn.listen((isLoggedIn) {
      // Login state changed. Check if user can see all animations.
      getAnimations();
    });
  }

  Future<Null> getAnimations() async {
    try {
      animationDescriptors = await _animationService.getAnimationDescriptors();
      animations = await _animationService.getAnimations();
    } catch (e) {
      isError = true;
    }
  }

  /**
   * Get animation url to navigate to.
   */
  String animationUrl(String animationPath) {
    return paths.animation.toUrl(parameters: {paths.idParam: animationPath});
  }

  Message getAnimationName(String baseKey) => _i18n.get("${baseKey}.name");

  Message getAnimationDescription(String baseKey) => _i18n.get("${baseKey}.short-description");

  bool isAnimationVisible(int id) {
    if (animations != null) {
      for (Animation animation in animations) {
        if (animation.id == id) {
          return animation.visible;
        }
      }
    }

    return true;
  }

  Animation getAnimation(int id) {
    if (animations == null) {
      throw Exception("animations array mustn't be null here!");
    }

    for (Animation animation in animations) {
      if (animation.id == id) {
        return animation;
      }
    }

    return null;
  }

  void onVisibilityChange(int id, bool visible) async {
    var animation = getAnimation(id);

    if (animation != null) {
      animation.visible = visible;

      if (!await _animationService.updateAnimation(animation)) {
        throw Exception("Could not update animation state");
      }
    } else {
      Animation animation = Animation(id, visible);

      animation = await _animationService.createAnimation(animation);

      if (animation != null) {
        animations.add(animation);
      } else {
        throw Exception("Could not update animation state");
      }
    }
  }

  @override
  void ngOnDestroy() {
    _loggedInSub.cancel();
  }
}
