import 'package:angular/angular.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';

/**
 * I18n pipe used for easy access to the translation service.
 *
 * Usage example (in a HTML template):
 * {{ "myKey" | i18n }}
 * This should be automatically replaced with the right translation.
 */
@Pipe("i18n")
class I18nPipe extends PipeTransform {
  /**
   * Translation service.
   */
  I18nService _i18n;

  I18nPipe(this._i18n);

  /**
   * Transform method is called by the pipe.
   */
  Message transform(String key) => _i18n.get(key);
}
