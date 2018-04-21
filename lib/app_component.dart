import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/src/services/animation_service/animation_service.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_pipe.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/view/animation-view/default/default_animation_view_component.dart';
import 'package:netzwerke_animationen/src/ui/view/animation-view/detail/detail_animation_view_component.dart';
import 'package:netzwerke_animationen/src/ui/view/notfound/notfound_component.dart';
import 'package:netzwerke_animationen/src/ui/view/overview/overview_component.dart';

@Component(
  selector: 'net-app',
  styleUrls: const ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, ROUTER_DIRECTIVES],
  providers: const [materialProviders, AnimationService],
  pipes: const [I18nPipe]
)
@RouteConfig(const [
  const Route(path: "/overview", name: OverviewComponent.NAME, component: OverviewComponent),
  const Route(path: "/animation/:id", name: DefaultAnimationViewComponent.NAME, component: DefaultAnimationViewComponent),
  const Route(path: "/detail/:id", name: DetailAnimationViewComponent.NAME, component: DetailAnimationViewComponent),
  const Redirect(path: "/", redirectTo: const [OverviewComponent.NAME]),
  const Route(path: "/**", name: NotFoundComponent.NAME, component: NotFoundComponent)
])
class AppComponent implements OnInit {

  /**
   * Router used to navigate to other routes.
   */
  final Router _router;

  /**
   * Service used to get translations.
   */
  final I18nService _i18n;

  final ItemRenderer<Language> languageItemRenderer = new CachingItemRenderer<Language>((language) => "${language.name}");
  SelectionModel<Language> languageSelectionModel;
  LanguageSelectionOptions languageSelectionOptions;

  AppComponent(this._router, this._i18n);

  @override
  ngOnInit() {
    languageSelectionModel = new SelectionModel.withList(selectedValues: [_i18n.getLanguages()[0]]);
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
   * Navigate the router to the passed page.
   */
  void goTo(String to) {
    _router.navigate([to]);
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

}

class LanguageSelectionOptions extends StringSelectionOptions<Language> implements Selectable {
  LanguageSelectionOptions(List<Language> options) : super(options, toFilterableString: (Language option) => option.toString());

  @override
  SelectableOption getSelectable(item) => SelectableOption.Selectable;
}