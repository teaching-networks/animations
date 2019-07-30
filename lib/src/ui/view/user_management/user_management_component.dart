/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/routes.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/user_service/model/user.dart';
import 'package:hm_animations/src/services/user_service/user_service.dart';
import 'package:hm_animations/src/ui/view/management/management.component.dart';
import 'package:hm_animations/src/ui/view/user_management/content/user_management_content.component.dart';
import 'package:hm_animations/src/ui/view/user_management/content/user_management_content.component.template.dart' as userManagementContentComponent;

/// Component for managing users.
@Component(
  selector: "user-management-component",
  templateUrl: "user_management_component.html",
  styleUrls: ["user_management_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    routerDirectives,
    coreDirectives,
    ManagementComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class UserManagementComponent implements OnInit, OnDestroy {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Service managing users.
  final UserService _userService;

  /// Service to route to another route.
  final Router _router;

  /// All available routes in the application.
  final Routes _routes;

  /// Service to get authentication information from.
  final AuthenticationService _authenticationService;

  /// Where to get translations from.
  final I18nService _i18n;

  /// Subscription to login/logout events.
  StreamSubscription<bool> _loggedInSub;

  /// Future loading all users.
  Future<List<User>> _loadFuture;

  /// Listener emitting events when the language changed.
  LanguageLoadedListener _languageChangedListener;

  /// Create component.
  UserManagementComponent(
    this._cd,
    this._userService,
    this._router,
    this._routes,
    this._authenticationService,
    this._i18n,
  );

  @override
  void ngOnInit() {
    if (!_authenticationService.isLoggedIn) {
      _router.navigateByUrl("/"); // Redirect to start page because user cannot see user management.
    }

    _loggedInSub = _authenticationService.loggedIn.listen((loggedIn) {
      if (!loggedIn) {
        // If logged out while on user management page.
        _router.navigate(_routes.groups.path);
      }
    });

    _languageChangedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageChangedListener);

    _loadFuture = _loadUsers();
  }

  @override
  void ngOnDestroy() {
    _loggedInSub.cancel();
    _i18n.removeLanguageLoadedListener(_languageChangedListener);
  }

  /// Load users to be shown in the management component.
  Future<List<User>> _loadUsers() {
    return _userService.getUsers();
  }

  /// Factory for user entities.
  EntityFactory<User> get userFactory => () => User.empty();

  /// Factory for the content component showing user objects.
  ComponentFactory<UserManagementContentComponent> get contentComponentFactory => userManagementContentComponent.UserManagementContentComponentNgFactory;

  /// The future loading all users.
  Future<List<User>> get loadFuture => _loadFuture;
}
