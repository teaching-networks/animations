import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';

@Component(
    selector: "language-item-component",
    template: '''
      <div class="lang-comp-item-label">
        <img src="{{flagImagePath}}" class="flagImage" /><span>{{displayName}}</span>
      </div>
    ''',
    styles: const ["div.lang-comp-item-label > * {vertical-align: middle} img.flagImage {height: 1.0em; margin-right: 8px;}"],
    directives: const [MaterialIconComponent])
class LanguageItemComponent implements RendersValue<Language> {
  String flagImagePath = "";
  String displayName = "";

  @override
  set value(Language lang) {
    flagImagePath = lang.flagImagePath;
    displayName = lang.name;
  }
}
