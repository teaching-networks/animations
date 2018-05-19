import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/src/router/routes.dart';
import 'package:netzwerke_animationen/src/services/animation_service/animation_service.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_pipe.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/misc/language/language_item_component.template.dart' as languageItemComponent;
import 'package:netzwerke_animationen/src/util/component.dart';

@Component(
    selector: 'net-app',
    styleUrls: const ['app_component.css'],
    templateUrl: 'app_component.html',
    directives: const [materialDirectives, routerDirectives],
    providers: const [materialProviders, const ClassProvider(AnimationService), const ClassProvider(Routes), const ClassProvider(I18nService)],
    pipes: const [I18nPipe]
)
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

  AppComponent(this._i18n, this.routes);

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