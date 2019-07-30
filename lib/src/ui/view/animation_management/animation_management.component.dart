/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/routes.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/view/animation_management/content/animation_management_content.component.dart';
import 'package:hm_animations/src/ui/view/animation_management/content/animation_management_content.component.template.dart'
    as animationManagementContent;
import 'package:hm_animations/src/ui/view/management/management.component.dart';

/// Component used to manage animation details.
@Component(
  selector: "animation-management-component",
  templateUrl: "animation_management.component.html",
  styleUrls: ["animation_management.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    routerDirectives,
    ManagementComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class AnimationManagementComponent implements OnInit, OnDestroy {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Where to get translations from.
  final I18nService _i18n;

  /// Service managing animations.
  final AnimationService _animationService;

  /// Service to get authentication details from.
  final AuthenticationService _authenticationService;

  /// Router to navigate to other pages.
  final Router _router;

  /// Available routes in the app.
  final Routes _routes;

  /// Listener getting notified when the language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// Subscription to login/logout events.
  StreamSubscription<bool> _loggedInSub;

  /// Future loading animation descriptors to manage.
  Future<List<AnimationDescriptor<dynamic>>> _loadFuture;

  /// Create component.
  AnimationManagementComponent(
    this._cd,
    this._i18n,
    this._animationService,
    this._authenticationService,
    this._router,
    this._routes,
  );

  @override
  void ngOnInit() {
    if (!_authenticationService.isLoggedIn) {
      _router.navigateByUrl(
          "/"); // Redirect to start page because user cannot see group management.
    }

    _loggedInSub = _authenticationService.loggedIn.listen((loggedIn) {
      if (!loggedIn) {
        // If logged out while on group management page.
        _router.navigate(_routes.groups.path);
      }
    });

    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);

    _loadFuture = _loadAnimations();
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
    _loggedInSub.cancel();
  }

  /// Load all available animations.
  Future<List<AnimationDescriptor<dynamic>>> _loadAnimations() async {
    final map = _animationService.getAnimationDescriptors();

    return map.values.toList();
  }

  /// Retrieve the future loading all animation descriptors.
  Future<List<AnimationDescriptor<dynamic>>> get loadFuture => _loadFuture;

  /// Get the component factory producing the content component to display the animation info.
  ComponentFactory<AnimationManagementContentComponent>
      get contentComponentFactory => animationManagementContent
          .AnimationManagementContentComponentNgFactory;

  /// Get the label factory producing item labels.
  LabelFactory<dynamic> get labelFactory =>
      (animDesc) => _i18n.get("${animDesc.baseTranslationKey}.name").toString();
}
