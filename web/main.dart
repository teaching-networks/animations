/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/app_component.dart';
import 'package:hm_animations/app_component.template.dart' as ng;
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/group_service/group_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/network_service/network_service.dart';
import 'package:hm_animations/src/services/storage_service/storage_service.dart';
import 'package:hm_animations/src/services/user_service/user_service.dart';

import 'main.template.dart' as self;

@GenerateInjector(
  [
    routerProvidersHash,
    ClassProvider(I18nService),
    ClassProvider(StorageService),
    ClassProvider(AuthenticationService),
    ClassProvider(NetworkService),
    ClassProvider(UserService),
    ClassProvider(GroupService),
  ],
)
final InjectorFactory injector = self.injector$Injector;

/// Angular entry component reference.
ComponentRef<AppComponent> _appComponent;

void main() {
  _appComponent = runApp(ng.AppComponentNgFactory, createInjector: injector);
}

/// Lifecycle hook for hot module reloading.
/// The method will be called on the old module (the module to unload).
/// To use hot reloading run: pub run build_runner serve --hot-reload
/// NOTE THAT THIS IS CURRENTLY NOT WORKING PROPERLY
/// See: https://github.com/dart-lang/build/blob/master/docs/hot_module_reloading.md
Object hot$onDestroy() {
  _appComponent.destroy();

  return null;
}
