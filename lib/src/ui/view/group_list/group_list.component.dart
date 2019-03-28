import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;
import 'package:hm_animations/src/services/group_service/group_service.dart';
import 'package:hm_animations/src/services/group_service/model/group.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/util/name_util.dart';

/// Component listing all groups.
@Component(
  selector: "group-list-component",
  templateUrl: "group_list.component.html",
  styleUrls: [
    "group_list.component.css",
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    routerDirectives,
    MaterialSpinnerComponent,
    MaterialButtonComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class GroupListComponent implements OnInit, OnDestroy {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Service to get groups from.
  final GroupService _groupService;

  /// All available groups.
  List<Group> groups;

  /// State of the component.
  _CompState state = _CompState.LOADING;

  LanguageLoadedListener _languageLoadedListener;

  /// Create component.
  GroupListComponent(
    this._cd,
    this._i18n,
    this._groupService,
  );

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);

    _loadGroups();
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
  }

  /// Load all available groups.
  Future<void> _loadGroups() async {
    state = _CompState.LOADING;
    _cd.markForCheck();

    try {
      List<Group> allGroups = await _groupService.getAll();

      if (allGroups != null) {
        groups = allGroups;
        state = _CompState.SUCCESS;
      } else {
        state = _CompState.ERROR;
      }
    } catch (e) {
      state = _CompState.ERROR;
    } finally {
      _cd.markForCheck();
    }
  }

  /// Get the url to the passed [group].
  String groupUrl(Group group) {
    String groupId = group.name != null && group.name.isNotEmpty ? NameUtil.makeUrlCompliant(group.name) : group.id.toString();

    return paths.group.toUrl(parameters: {
      paths.idParam: groupId,
    });
  }

  _CompState get loadingState => _CompState.LOADING;

  _CompState get errorState => _CompState.ERROR;

  _CompState get successState => _CompState.SUCCESS;
}

/// State of the component.
enum _CompState {
  LOADING,
  ERROR,
  SUCCESS,
}
