import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
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
  RestrictedDirective,
  MaterialToggleComponent,
  MaterialSpinnerComponent,
  MaterialIconComponent,
  MaterialButtonComponent
], pipes: [
  I18nPipe
])
class UserManagementComponent implements OnInit {
  final UserService _userService;

  List<User> users;

  UserManagementComponent(this._userService);

  @override
  void ngOnInit() {
    _userService.getUsers().then((newUsers) {
      users = newUsers;
    });
  }

  void createUser() {

  }

  void editUser(User user) {

  }

  void deleteUser(int id) async {
    // await _userService.deleteUser(id);
  }
}
