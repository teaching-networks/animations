import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
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
  MaterialToggleComponent,
  MaterialSpinnerComponent,
  MaterialIconComponent,
  MaterialButtonComponent,
  ModalComponent,
  MaterialDialogComponent
], pipes: [
  I18nPipe
])
class UserManagementComponent implements OnInit {
  final UserService _userService;

  List<User> users;

  bool showUserDialog = false;
  String username = "";
  String password = "";

  bool isDialogLoading = false;
  bool showDialogError = false;

  User userToEdit;

  UserDialogType dialogType;

  UserManagementComponent(this._userService);

  @override
  void ngOnInit() {
    _loadUsers();
  }

  void _loadUsers() async {
    users = await _userService.getUsers();
  }

  void openUserCreateDialog() {
    username = "";
    password = "";

    dialogType = UserDialogType.CREATE;
    showUserDialog = true;
  }

  void createUser(String username, String password) async {
    isDialogLoading = true;

    var user = User(-1, username, password);

    var newUser = await _userService.createUser(user);

    isDialogLoading = false;

    if (newUser != null) {
      _loadUsers();

      showUserDialog = false;
    } else {
      showDialogError = true;
    }
  }

  void openEditDialog(User user) {
    this.userToEdit = user;

    username = userToEdit.name;
    password = "";

    dialogType = UserDialogType.EDIT;
    showUserDialog = true;
  }

  void editUser(String username, String password) async {
    isDialogLoading = true;

    userToEdit.name = username;

    if (password != null && password.isNotEmpty) {
      userToEdit.password = password;
    }

    var success = await _userService.updateUser(userToEdit);

    isDialogLoading = false;

    if (success) {
      _loadUsers();

      showUserDialog = false;
    } else {
      showDialogError = true;
    }
  }

  void deleteUser(int id) async {
    var success = await _userService.deleteUser(id);

    // TODO show error or success
  }

  UserDialogType get createType => UserDialogType.CREATE;
  UserDialogType get editType => UserDialogType.EDIT;
}

enum UserDialogType { CREATE, EDIT }
