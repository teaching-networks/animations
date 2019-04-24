import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/routes.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/group_service/group_service.dart';
import 'package:hm_animations/src/services/group_service/model/group.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/view/group-management/content/group_management_content.component.dart';
import 'package:hm_animations/src/ui/view/group-management/content/group_management_content.component.template.dart' as groupManagementContentComponent;
import 'package:hm_animations/src/ui/view/group-management/selected_group.service.dart';
import 'package:hm_animations/src/ui/view/management/management.component.dart';

/// Component to manage animation groups.
@Component(
  selector: "group-management-component",
  templateUrl: "group_management_component.html",
  styleUrls: ["group_management_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    routerDirectives,
    coreDirectives,
    ManagementComponent,
  ],
  pipes: [
    I18nPipe,
  ],
  providers: [
    ClassProvider(SelectedGroupService),
  ],
)
class GroupManagementComponent implements OnInit, OnDestroy {
  /// Service to get translations from.
  final I18nService _i18n;

  /// Service to get groups from.
  final GroupService _groupService;

  /// Service to get authentication details from.
  final AuthenticationService _authenticationService;

  /// Router to navigate to other pages.
  final Router _router;

  /// Available routes in the app.
  final Routes _routes;

  /// Change detector reference used to update the component.
  final ChangeDetectorRef _cd;

  LanguageLoadedListener _languageLoadedListener;

  StreamSubscription<bool> _loggedInSub;

  Future<List<Group>> _loadFuture;

  Message _newGroupLabel;

  /// Create new group management component.
  GroupManagementComponent(
    this._cd,
    this._i18n,
    this._groupService,
    this._authenticationService,
    this._router,
    this._routes,
  );

  @override
  void ngOnInit() {
    if (!_authenticationService.isLoggedIn) {
      _router.navigateByUrl("/"); // Redirect to start page because user cannot see group management.
    }

    _loggedInSub = _authenticationService.loggedIn.listen((loggedIn) {
      if (!loggedIn) {
        // If logged out while on group management page.
        _router.navigate(_routes.groups.path);
      }
    });

    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);

    _initTranslations();
    _loadFuture = _loadGroups();
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
    _loggedInSub.cancel();
  }

  /// Initialize the translation messages.
  void _initTranslations() {
    _newGroupLabel = _i18n.get("group-management.new-group");
  }

  /// Load groups from server.
  Future<List<Group>> _loadGroups() async {
    try {
      return await _groupService.getAll();
    } catch (e) {
      return null;
    }
  }

  /// The future loading all groups.
  Future<List<Group>> get loadFuture => _loadFuture;

  /// Factory producing the content component showing a group.
  ComponentFactory<GroupManagementContentComponent> get contentComponentFactory => groupManagementContentComponent.GroupManagementContentComponentNgFactory;

  /// Factory producing groups.
  EntityFactory<Group> get groupFactory => () => Group(
        name: _newGroupLabel.toString(),
        animationIds: [],
        animationIdOrder: [],
      );
}
