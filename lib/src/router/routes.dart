import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;
import 'package:hm_animations/src/ui/view/animation-view/default/default_animation_view_component.template.dart' as defaultAnimationComp;
import 'package:hm_animations/src/ui/view/animation-view/detail/detail_animation_view_component.template.dart' as detailAnimationComp;
import 'package:hm_animations/src/ui/view/notfound/notfound_component.template.dart' as notFoundComp;
import 'package:hm_animations/src/ui/view/overview/overview_component.template.dart' as overviewComp;
import 'package:hm_animations/src/ui/view/user-management/user_management_component.template.dart' as userManagementComp;
import 'package:hm_animations/src/ui/view/group-management/group_management_component.template.dart' as groupManagementComp;

@Injectable()
class Routes {
  static final RouteDefinition _overview = new RouteDefinition(
    routePath: paths.overview,
    component: overviewComp.OverviewComponentNgFactory,
    useAsDefault: true,
  );

  static final RouteDefinition _animation = new RouteDefinition(
    routePath: paths.animation,
    component: defaultAnimationComp.DefaultAnimationViewComponentNgFactory,
  );

  static final RouteDefinition _detail = new RouteDefinition(
    routePath: paths.detail,
    component: detailAnimationComp.DetailAnimationViewComponentNgFactory,
  );

  static final RouteDefinition _user = new RouteDefinition(
    routePath: paths.user,
    component: userManagementComp.UserManagementComponentNgFactory,
  );

  static final RouteDefinition _groupManagement = new RouteDefinition(
    routePath: paths.groupManagement,
    component: groupManagementComp.GroupManagementComponentNgFactory,
  );

  static final RouteDefinition _notFound = new RouteDefinition(
    routePath: paths.notFound,
    component: notFoundComp.NotFoundComponentNgFactory,
  );

  RouteDefinition get overview => _overview;

  RouteDefinition get animation => _animation;

  RouteDefinition get detail => _detail;

  RouteDefinition get user => _user;

  RouteDefinition get notFound => _notFound;

  RouteDefinition get groupManagement => _groupManagement;

  final List<RouteDefinition> all = [_overview, _animation, _detail, _user, _groupManagement, _notFound];
}
