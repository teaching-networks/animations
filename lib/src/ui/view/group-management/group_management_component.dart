import 'package:angular/angular.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_components/material_select/material_select_item.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/services/group_service/group_service.dart';
import 'package:hm_animations/src/services/group_service/model/group.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';

/// Component to manage animation groups.
@Component(
  selector: "group-management-component",
  templateUrl: "group_management_component.html",
  styleUrls: ["group_management_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    routerDirectives,
    coreDirectives,
    MaterialListComponent,
    MaterialListItemComponent,
    MaterialSelectItemComponent,
    MaterialIconComponent,
    MaterialSpinnerComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class GroupManagementComponent implements OnInit {
  /// Service to get groups from.
  final GroupService _groupService;

  /// Change detector reference used to update the component.
  final ChangeDetectorRef _cd;

  /// Groups to display.
  List<Group> _groups;

  /// Whether currently loading groups.
  bool _isLoadingGroups = true;

  /// Create new group management component.
  GroupManagementComponent(this._groupService, this._cd);

  @override
  void ngOnInit() {
    _loadGroups();
  }

  /// Load groups from server.
  Future<void> _loadGroups() async {
    _isLoadingGroups = true;
    _cd.markForCheck();

    try {
      _groups = await _groupService.getAll();
    } finally {
      _isLoadingGroups = false;
    }

    _cd.markForCheck();
  }

  /// The currently selected group.
  Group _selectedGroup;

  /// Check if a group is selected.
  bool get hasGroupSelected => _selectedGroup != null;

  /// Get all groups to display.
  List<Group> get groups => _groups;

  /// Select the passed [group] in the list.
  void selectGroup(Group group) {
    _selectedGroup = group;
  }

  /// Check if group is selected.
  bool isGroupSelected(Group group) => group == _selectedGroup;

  /// Whether we are currently loading groups.
  bool get isLoadingGroups => _isLoadingGroups;
}
