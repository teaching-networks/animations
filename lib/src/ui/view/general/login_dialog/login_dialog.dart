import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/misc/dialog/dialog_component/dialog_component.dart';

/// Login dialog of the app.
@Component(
  selector: "login-dialog-component",
  templateUrl: "login_dialog.html",
  styleUrls: ["login_dialog.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    MaterialButtonComponent,
    MaterialDialogComponent,
    AutoFocusDirective,
    materialInputDirectives,
    formDirectives,
    MaterialProgressComponent,
  ],
  pipes: [I18nPipe],
)
class LoginDialog extends DialogComponent<bool, LoginDialog, void> {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Service to fetch translations from.
  final I18nService _i18n;

  /// Authentication service used to authenticate a user with the server.
  final AuthenticationService _authService;

  /// Whether the dialog is currently checking credentials.
  bool isCheckingCredentials = false;

  /// Current username typed in.
  String username = "";

  /// Current password typed in.
  String password = "";

  /// A error message to show.
  Message errorMessageToShow;

  /// Default error message for the login dialog.
  Message _loginFailedMessage;

  /// Create the dialog component.
  LoginDialog(
    this._cd,
    this._i18n,
    this._authService,
  ) {
    _init();
  }

  /// Initialize the dialog.
  void _init() {
    _initTranslations();
  }

  /// Initialize needed translations.
  void _initTranslations() {
    _loginFailedMessage = _i18n.get("login.error");
  }

  /// Try to login.
  Future<void> login() async {
    errorMessageToShow = null;
    isCheckingCredentials = true;
    _cd.markForCheck();

    final bool success = await _authService.login(username, password);

    isCheckingCredentials = false;

    if (success) {
      instance.close(true);
    } else {
      errorMessageToShow = _loginFailedMessage;
    }

    _cd.markForCheck();
  }

  /// Cancel the dialog.
  void cancel() {
    instance.close(false);
  }
}
