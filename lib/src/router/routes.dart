import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;
import 'package:hm_animations/src/ui/view/animation-view/default/default_animation_view_component.template.dart' as defaultAnimationComp;
import 'package:hm_animations/src/ui/view/animation-view/detail/detail_animation_view_component.template.dart' as detailAnimationComp;
import 'package:hm_animations/src/ui/view/group-management/group_management_component.template.dart' as groupManagementComp;
import 'package:hm_animations/src/ui/view/group_list/group_list.component.template.dart' as groupListComponent;
import 'package:hm_animations/src/ui/view/animation_list/animation_list.component.template.dart' as animationListComponent;
import 'package:hm_animations/src/ui/view/notfound/notfound_component.template.dart' as notFoundComp;
import 'package:hm_animations/src/ui/view/user_management/user_management_component.template.dart' as userManagementComp;
import 'package:hm_animations/src/ui/view/animation_management/animation_management.component.template.dart' as animationManagementComponent;

@Injectable()
class Routes {
  static final RouteDefinition _groups = new RouteDefinition(
    routePath: paths.groups,
    component: groupListComponent.GroupListComponentNgFactory,
    useAsDefault: true,
  );

  static final RouteDefinition _group = new RouteDefinition(
    routePath: paths.group,
    component: animationListComponent.AnimationListComponentNgFactory,
  );

  static final RouteDefinition _animation = new RouteDefinition(
    routePath: paths.animation,
    component: defaultAnimationComp.DefaultAnimationViewComponentNgFactory,
  );

  static final RouteDefinition _detail = new RouteDefinition(
    routePath: paths.detail,
    component: detailAnimationComp.DetailAnimationViewComponentNgFactory,
  );

  static final RouteDefinition _userManagement = new RouteDefinition(
    routePath: paths.userManagement,
    component: userManagementComp.UserManagementComponentNgFactory,
  );

  static final RouteDefinition _animationManagement = new RouteDefinition(
    routePath: paths.animationManagement,
    component: animationManagementComponent.AnimationManagementComponentNgFactory,
  );

  static final RouteDefinition _groupManagement = new RouteDefinition(
    routePath: paths.groupManagement,
    component: groupManagementComp.GroupManagementComponentNgFactory,
  );

  static final RouteDefinition _notFound = new RouteDefinition(
    routePath: paths.notFound,
    component: notFoundComp.NotFoundComponentNgFactory,
  );

  RouteDefinition get groups => _groups;

  RouteDefinition get group => _group;

  RouteDefinition get animation => _animation;

  RouteDefinition get detail => _detail;

  RouteDefinition get userManagement => _userManagement;

  RouteDefinition get notFound => _notFound;

  RouteDefinition get groupManagement => _groupManagement;

  RouteDefinition get animationManagement => _animationManagement;

  final List<RouteDefinition> all = [
    _groups,
    _group,
    _animation,
    _detail,
    _userManagement,
    _groupManagement,
    _animationManagement,
    _notFound,
  ];
}
