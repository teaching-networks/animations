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
import 'package:hm_animations/src/ui/misc/dialog/dialog_service.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/info/info_dialog_data.dart';
import 'package:hm_animations/src/ui/misc/dialog/impl/option/option_dialog_data.dart';
import 'package:hm_animations/src/ui/view/management/content/management_component_content.dart';
import 'package:hm_animations/src/util/options/save_options.dart';
import 'package:hm_animations/src/util/str/message.dart';

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

  /// Service displaying dialogs.
  final DialogService _dialogService;

  /// Original user which may be modified.
  User _originalUser;

  /// User to currently display.
  User _user;

  /// Listener emitting events when the language has been changed.
  LanguageLoadedListener _languageChangedListener;

  IdMessage<String> _passwordNotChangedLabel;

  /// Create component.
  UserManagementContentComponent(
    this._cd,
    this._i18n,
    this._userService,
    this._dialogService,
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

      String promptUsername = await _dialogService.prompt(_i18n.get("user-management.delete.prompt").toString()).result();
      if (promptUsername == null) {
        return false;
      } else if (promptUsername != user.name) {
        await _dialogService.info(InfoDialogData(
          title: _i18n.get("user-management.error-message").toString(),
          message: _i18n.get("user-management.delete.error").toString(),
        ));
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
      final newUser = await _userService.createUser(User(
        -1,
        _user.name,
        _user.password,
      ));

      _originalUser = newUser;
      _user = User(
        newUser.id,
        newUser.name,
        newUser.password,
      );

      return newUser;
    } else {
      if (user.password != null && user.password.isEmpty) {
        user.password = null;
      }

      // User already exists in database -> Update.
      bool success = await _userService.updateUser(user);

      if (success) {
        _originalUser = user;
        _user = User(
          user.id,
          user.name,
          user.password,
        );

        return user;
      } else {
        return null;
      }
    }
  }

  /// Check whether the current user contains unsaved changes.
  /// Returns whether to proceed.
  Future<SaveOption> _checkIfUnsaved() async {
    if (!isModified) {
      return SaveOption.LOSE;
    }

    final option = await _dialogService
        .option(OptionDialogData(
          title: Msg("Unsaved changes"),
          message: Msg("The currently selected user contains unsaved changes. What do you want to do?"),
          options: [
            LabeledOption("Save unsaved changes...", SaveOption.SAVE),
            LabeledOption("Lose unsaved changes...", SaveOption.LOSE),
            LabeledOption("Keep editing...", SaveOption.CANCEL),
          ],
        ))
        .result();

    if (option == null) {
      return SaveOption.CANCEL;
    } else {
      return option.value;
    }
  }

  @override
  Future<SaveOption> setEntity(User entity) async {
    final option = await _checkIfUnsaved();

    if (option != SaveOption.CANCEL) {
      _originalUser = entity;
      _user = User(
        entity.id,
        entity.name,
        entity.password,
      );

      _cd.markForCheck();
    }

    return option;
  }

  /// Get the user to display.
  User get user => _user;

  /// Whether the current user is rather edited than created.
  bool get isEditing => _user.id != null;

  /// Label of the password field.
  String get passwordLabel => isEditing ? _passwordNotChangedLabel.toString() : "";

  /// Whether the current user has been modified.
  bool get isModified =>
      _user != null &&
      _originalUser != null &&
      (!isEditing || _originalUser.id != _user.id || _originalUser.name != _user.name || _originalUser.password != _user.password);
}
