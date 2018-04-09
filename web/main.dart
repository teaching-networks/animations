import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/app_component.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';

void main() {
  bool isDev = false;

  List customProviders = [
    ROUTER_PROVIDERS,
    I18nService
  ];

  // Add development providers, which will get removed when in production.
  if (isDev) {
    customProviders.add(provide(LocationStrategy, useClass: HashLocationStrategy));
  }

  bootstrap(AppComponent, customProviders);
}
