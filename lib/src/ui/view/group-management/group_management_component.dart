import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';

@Component(
  selector: "group-management-component",
  templateUrl: "group_management_component.html",
  styleUrls: ["group_management_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    routerDirectives,
    coreDirectives,
  ],
  pipes: [
    I18nPipe,
  ],
)
class GroupManagementComponent {}
