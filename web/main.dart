import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';

import 'package:hm_animations/app_component.template.dart' as ng;
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/network_service/network_service.dart';
import 'package:hm_animations/src/services/storage_service/storage_service.dart';
import 'package:hm_animations/src/services/user_service/user_service.dart';
import 'main.template.dart' as self;

@GenerateInjector([
  routerProvidersHash,
  ClassProvider(I18nService),
  ClassProvider(StorageService),
  ClassProvider(AuthenticationService),
  ClassProvider(NetworkService),
  ClassProvider(UserService)
])
final InjectorFactory injector = self.injector$Injector;

void main() {
  runApp(ng.AppComponentNgFactory, createInjector: injector);
}
