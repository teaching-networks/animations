/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/app_component.template.dart' as ng;
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/group_service/group_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/network_service/network_service.dart';
import 'package:hm_animations/src/services/settings_service/settings_service.dart';
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
    ClassProvider(SettingsService),
  ],
)
final InjectorFactory injector = self.injector$Injector;

/// Entry point of the application
void main() {
  runApp(
    ng.AppComponentNgFactory,
    createInjector: injector,
  );
}
