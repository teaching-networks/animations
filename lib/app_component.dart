import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:netzwerke_animationen/src/services/animation_service/animation_service.dart';
import 'package:netzwerke_animationen/src/ui/view/animation-view/default/default_animation_view_component.dart';
import 'package:netzwerke_animationen/src/ui/view/animation-view/detail/detail_animation_view_component.dart';
import 'package:netzwerke_animationen/src/ui/view/notfound/notfound_component.dart';
import 'package:netzwerke_animationen/src/ui/view/overview/overview_component.dart';

@Component(
  selector: 'net-app',
  styleUrls: const ['app_component.css'],
  templateUrl: 'app_component.html',
  directives: const [materialDirectives, ROUTER_DIRECTIVES],
  providers: const [materialProviders, AnimationService]
)
@RouteConfig(const [
  const Route(path: "/overview", name: OverviewComponent.NAME, component: OverviewComponent),
  const Route(path: "/animation/:id", name: DefaultAnimationViewComponent.NAME, component: DefaultAnimationViewComponent),
  const Route(path: "/detail/:id", name: DetailAnimationViewComponent.NAME, component: DetailAnimationViewComponent),
  const Redirect(path: "/", redirectTo: const [OverviewComponent.NAME]),
  const Route(path: "/**", name: NotFoundComponent.NAME, component: NotFoundComponent)
])
class AppComponent {
  final String title = "Networks Animations";

  /**
   * Router used to navigate to other routes.
   */
  Router _router;

  AppComponent(this._router);

  void goTo(String to) {
    _router.navigate([to]);
  }

  /**
   * Get current year.
   */
  int get year {
    return new DateTime.now().year;
  }

}
