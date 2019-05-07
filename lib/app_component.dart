import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/routes.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/user_service/model/user.dart';
import 'package:hm_animations/src/services/user_service/user_service.dart';
import 'package:hm_animations/src/ui/misc/angular_components/selection_options.dart' as so;
import 'package:hm_animations/src/ui/misc/directives/restricted_directive.dart';
import 'package:hm_animations/src/ui/misc/language/language_item_component.template.dart' as languageItemComponent;
import 'package:hm_animations/src/util/component.dart';
import 'package:hm_animations/version.dart';

import 'version.dart';

@Component(
    selector: 'net-app',
    styleUrls: ['app_component.css'],
    templateUrl: 'app_component.html',
    directives: [
      MaterialButtonComponent,
      MaterialIconComponent,
      MaterialDropdownSelectComponent,
      MaterialDialogComponent,
      ModalComponent,
      MaterialProgressComponent,
      RestrictedDirective,
      AutoFocusDirective,
      materialInputDirectives,
      routerDirectives,
      formDirectives,
      coreDirectives,
    ],
    providers: [materialProviders, ClassProvider(AnimationService), ClassProvider(Routes)],
    pipes: [I18nPipe])
class AppComponent implements OnInit, OnDestroy {
  /**
   * All routes we can navigate to.
   */
  final Routes routes;

  /**
   * Service used to get translations.
   */
  final I18nService _i18n;

  SelectionModel<Language> languageSelectionModel;
  so.SelectionOptions<Language> languageSelectionOptions;

  final AuthenticationService _authenticationService;

  StreamSubscription<bool> _loggedInStreamSub;

  /*
  LOGIN DIALOG PROPERTIES
   */
  bool showLoginDialog = false;
  bool isCheckingCredentials = false;
  bool isLoggedIn = false;
  String username = "";
  String password = "";
  Message loginErrorMessageToShow;
  Message _loginErrorMessageLabel;

  final UserService _userService;
  User authenticatedUser;

  AppComponent(this._i18n, this.routes, this._authenticationService, this._userService);

  @override
  ngOnInit() {
    _initTranslations();

    languageSelectionModel = SelectionModel.single(selected: _i18n.getLanguages()[0], keyProvider: (language) => language.locale);
    languageSelectionOptions = so.SelectionOptions(_i18n.getLanguages());

    // Select currently selected locale.
    _i18n.getLocale().then((locale) {
      for (Language lang in _i18n.getLanguages()) {
        if (lang.locale == locale) {
          languageSelectionModel.select(lang);
          break;
        }
      }
    });

    languageSelectionModel.selectionChanges.listen((changes) {
      SelectionChangeRecord<Language> change = changes[0];

      if (change.added.isEmpty) {
        onLanguageSelected(null);
      } else {
        // Select the new language.
        onLanguageSelected(change.added.first);
      }
    });

    // Initialize login status
    isLoggedIn = _authenticationService.isLoggedIn;

    if (isLoggedIn) {
      this._userService.getAuthenticatedUser().then((user) => authenticatedUser = user);
    }

    _loggedInStreamSub = _authenticationService.loggedIn.listen((loggedIn) {
      isLoggedIn = loggedIn;

      if (isLoggedIn) {
        this._userService.getAuthenticatedUser().then((user) => authenticatedUser = user);
      }
    });
  }

  void _initTranslations() {
    _loginErrorMessageLabel = _i18n.get("login.error");
  }

  /**
   * Called when a language has been selected.
   */
  void onLanguageSelected(Language language) {
    String currentLocale = _i18n.getCurrentLocale();

    if (language == null && _i18n.getDefaultLocale() != currentLocale) {
      _i18n.clearLocale(); // Just use the browsers default locale.
    } else if (language != null && language.locale != currentLocale) {
      _i18n.setLocale(language.locale);
    }
  }

  /**
   * Either login or logout should happen.
   */
  void authenticationChange() {
    if (_authenticationService.isLoggedIn) {
      _authenticationService.logout();
    } else {
      showLoginDialog = true;
      loginErrorMessageToShow = null;
    }
  }

  /**
   * Login process entry.
   */
  void login() async {
    isCheckingCredentials = true;

    var success = await _authenticationService.login(username, password);

    isCheckingCredentials = false;

    if (success) {
      showLoginDialog = false;
    } else {
      loginErrorMessageToShow = _loginErrorMessageLabel;
    }
  }

  /**
   * Get current year.
   */
  int get year => new DateTime.now().year;

  String get languageSelectionLabel => languageSelectionModel.selectedValues.isNotEmpty
      ? languageSelectionModel.selectedValues.first.toString()
      : _i18n.get("languageSelectionLabel").toString();

  /**
   * Get component factory for components that display the language items in the language selection dropdown.
   */
  ComponentFactorySupplier get componentLabelFactory => (_) => languageItemComponent.LanguageItemComponentNgFactory;

  @override
  void ngOnDestroy() {
    _loggedInStreamSub.cancel();
  }

  String get version => Version.version;
}
