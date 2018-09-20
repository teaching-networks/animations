import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/routes.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/user_service/model/user.dart';
import 'package:hm_animations/src/services/user_service/user_service.dart';
import 'package:hm_animations/src/ui/misc/directives/restricted_directive.dart';

@Component(selector: "user-management-component", templateUrl: "user_management_component.html", styleUrls: [
  "user_management_component.css"
], directives: [
  routerDirectives,
  coreDirectives,
  materialInputDirectives,
  formDirectives,
  RestrictedDirective,
  AutoFocusDirective,
  MaterialToggleComponent,
  MaterialSpinnerComponent,
  MaterialIconComponent,
  MaterialButtonComponent,
  ModalComponent,
  MaterialDialogComponent
], pipes: [
  I18nPipe
])
class UserManagementComponent implements OnInit, OnDestroy {
  final UserService _userService;
  final Router _router;
  final Routes _routes;
  final AuthenticationService _authenticationService;

  StreamSubscription<bool> _loggedInSub;

  List<User> users;

  /*
  LOADING DIALOG PROPERTIES
   */
  bool showLoadingDialog = false;
  bool isLoading = false;

  /*
  USER DIALOG PROPERTIES
   */
  User userToEdit;
  UserDialogType dialogType;

  String username = "";
  String password = "";

  bool showUserDialog = false;
  bool userDialogLoading = false;
  String userDialogErrorMessage;

  /*
  ERROR DIALOG PROPERTIES
   */
  bool showErrorDialog = false;

  UserManagementComponent(this._userService, this._router, this._routes, this._authenticationService);

  @override
  void ngOnInit() {
    if (!_authenticationService.isLoggedIn) {
      _router.navigateByUrl("/"); // Redirect to start page because user cannot see user management.
    }

    _loggedInSub = _authenticationService.loggedIn.listen((loggedIn) {
      if (!loggedIn) {
        // If logged out while on user management page.
        _router.navigate(_routes.overview.path);
      }
    });

    _loadUsers(); // Initially load all users.
  }

  @override
  void ngOnDestroy() {
    _loggedInSub.cancel();
  }

  void _loadUsers() async {
    users = await _userService.getUsers();
  }

  void openUserCreateDialog() {
    username = "";
    password = "";

    dialogType = UserDialogType.CREATE;
    userDialogErrorMessage = null;
    showUserDialog = true;
  }

  void createUser(String username, String password) async {
    userDialogLoading = true;

    var user = User(-1, username, password);

    var newUser = await _userService.createUser(user);

    userDialogLoading = false;

    if (newUser != null) {
      _loadUsers();

      showUserDialog = false;
    } else {
      userDialogErrorMessage = "An error occurred";
    }
  }

  void openEditDialog(User user) {
    this.userToEdit = user;

    username = userToEdit.name;
    password = "";

    dialogType = UserDialogType.EDIT;
    userDialogErrorMessage = null;
    showUserDialog = true;
  }

  void editUser(String username, String password) async {
    userDialogLoading = true;

    userToEdit.name = username;

    if (password != null && password.isNotEmpty) {
      userToEdit.password = password;
    }

    var success = await _userService.updateUser(userToEdit);

    userDialogLoading = false;

    if (success) {
      _loadUsers();

      showUserDialog = false;
    } else {
      userDialogErrorMessage = "An error occurred";
    }
  }

  void deleteUser(int id) async {
    showLoadingDialog = true;

    var success = await _userService.deleteUser(id);

    showLoadingDialog = false;

    if (success) {
      _loadUsers();
    } else {
      showErrorDialog = true;
    }
  }

  UserDialogType get createType => UserDialogType.CREATE;

  UserDialogType get editType => UserDialogType.EDIT;
}

enum UserDialogType { CREATE, EDIT }
