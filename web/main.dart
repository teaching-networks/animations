import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/app_component.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';

void main() {
  bootstrap(AppComponent, [
    ROUTER_PROVIDERS,
    I18nService,
    // Remove next line in production
    provide(LocationStrategy, useClass: HashLocationStrategy)
  ]);
}
