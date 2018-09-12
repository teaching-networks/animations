import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/app_component.template.dart' as ng;
import 'package:http/browser_client.dart';
import 'package:http/http.dart';

import 'main.template.dart' as self;

@GenerateInjector([
  routerProvidersHash,
  Provider(Client, useClass: BrowserClient)
])
final InjectorFactory injector = self.injector$Injector;

void main() {
  runApp(ng.AppComponentNgFactory, createInjector: injector);
}
