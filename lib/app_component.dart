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
import 'package:hm_animations/src/ui/misc/language/language_item_component.template.dart' as languageItemComponent;
import 'package:hm_animations/src/util/component.dart';

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
      AutoFocusDirective,
      materialInputDirectives,
      routerDirectives,
      formDirectives,
      coreDirectives,
    ],
    providers: [
      materialProviders,
      ClassProvider(AnimationService),
      ClassProvider(Routes)
    ],
    pipes: [I18nPipe])
class AppComponent implements OnInit {
  /**
   * All routes we can navigate to.
   */
  final Routes routes;

  /**
   * Service used to get translations.
   */
  final I18nService _i18n;

  SelectionModel<Language> languageSelectionModel;
  LanguageSelectionOptions languageSelectionOptions;

  final AuthenticationService _authenticationService;
  bool showLoginDialog = false;
  bool isCheckingCredentials = false;
  bool showLoginError = false;
  bool isLoggedIn = false;
  StreamSubscription<bool> loggedInStreamSub;
  String username = "";
  String password = "";

  AppComponent(this._i18n, this.routes, this._authenticationService);

  @override
  ngOnInit() {
    languageSelectionModel = new SelectionModel.single(selected: _i18n.getLanguages()[0], keyProvider: (language) => language.locale);
    languageSelectionOptions = new LanguageSelectionOptions(_i18n.getLanguages());

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
    loggedInStreamSub = _authenticationService.loggedIn.listen((loggedIn) => this.isLoggedIn = loggedIn);
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
      showLoginError = true;
    }
  }

  /**
   * Get current year.
   */
  int get year => new DateTime.now().year;

  String get languageSelectionLabel => _i18n.get("languageSelectionLabel").toString();

  /**
   * Get component factory for components that display the language items in the language selection dropdown.
   */
  ComponentFactorySupplier get componentLabelFactory => (_) => languageItemComponent.LanguageItemComponentNgFactory;
}

class LanguageSelectionOptions extends StringSelectionOptions<Language> implements Selectable {
  LanguageSelectionOptions(List<Language> options) : super(options, toFilterableString: (Language option) => option.toString());

  @override
  SelectableOption getSelectable(item) => SelectableOption.Selectable;
}
