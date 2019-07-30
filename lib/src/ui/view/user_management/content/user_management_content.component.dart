/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/user_service/model/user.dart';
import 'package:hm_animations/src/services/user_service/user_service.dart';
import 'package:hm_animations/src/ui/view/management/content/management_component_content.dart';

/// Component shows content form for editing/creating users.
@Component(
  selector: "user-management-content-component",
  templateUrl: "user_management_content.component.html",
  styleUrls: ["user_management_content.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    materialInputDirectives,
  ],
  pipes: [
    I18nPipe,
  ],
)
class UserManagementContentComponent implements ManagementComponentContent<User>, OnInit, OnDestroy {
  /// Change detection reference.
  final ChangeDetectorRef _cd;

  /// Where to get translations from.
  final I18nService _i18n;

  /// Service managing users.
  final UserService _userService;

  /// User to currently display.
  User _user;

  /// Listener emitting events when the language has been changed.
  LanguageLoadedListener _languageChangedListener;

  Message _passwordNotChangedLabel;

  /// Create component.
  UserManagementContentComponent(
    this._cd,
    this._i18n,
    this._userService,
  );

  @override
  void ngOnInit() {
    _languageChangedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageChangedListener);

    _initTranslations();
  }

  /// Initialize needed translations.
  void _initTranslations() {
    _passwordNotChangedLabel = _i18n.get("user-management.not-changed");
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageChangedListener);
  }

  @override
  Future<bool> onDelete() async {
    if (user.id != null) {
      User authenticatedUser = await _userService.getAuthenticatedUser();

      if (user.id == authenticatedUser.id) {
        return false;
      }

      return await _userService.deleteUser(user.id);
    } else {
      return true;
    }
  }

  @override
  Future<User> onSave() async {
    if (user.id == null) {
      // User does not yet exist in database -> Create.
      return await _userService.createUser(User(
        -1,
        _user.name,
        _user.password,
      ));
    } else {
      if (user.password != null && user.password.isEmpty) {
        user.password = null;
      }

      // User already exists in database -> Update.
      bool success = await _userService.updateUser(user);

      if (success) {
        return user;
      } else {
        return null;
      }
    }
  }

  @override
  void setEntity(User entity) {
    _user = entity;

    _cd.markForCheck();
  }

  /// Get the user to display.
  User get user => _user;

  /// Whether the current user is rather edited than created.
  bool get isEditing => _user.id != null;

  /// Label of the password field.
  String get passwordLabel => isEditing ? _passwordNotChangedLabel.toString() : "";
}
