import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_checkbox/material_checkbox.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_components/material_list/material_list.dart';
import 'package:angular_components/material_list/material_list_item.dart';
import 'package:angular_components/material_select/material_select_item.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/routes.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/group_service/group_service.dart';
import 'package:hm_animations/src/services/group_service/model/group.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/misc/dnd_list/dnd_list_component.dart';
import 'package:hm_animations/src/ui/view/group-management/animation_list_item/animation_list_item_component.dart';
import 'package:hm_animations/src/ui/view/group-management/animation_list_item/animation_list_item_component.template.dart' as animationListItemRenderer;
import 'package:hm_animations/src/ui/view/group-management/selected_group.service.dart';
import 'package:hm_animations/src/util/name_util.dart';
import 'package:hm_animations/src/util/network/network_util.dart';

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
    materialInputDirectives,
    MaterialButtonComponent,
    MaterialCheckboxComponent,
    DnDListComponent,
    AnimationListItemComponent,
  ],
  pipes: [
    I18nPipe,
  ],
  providers: [
    ClassProvider(SelectedGroupService),
  ],
)
class GroupManagementComponent implements OnInit, OnDestroy {
  /// Duration to wait before updating the button labels after saving or deleting a group.
  static const _waitDuration = Duration(seconds: 2);

  /// Service to get translations from.
  final I18nService _i18n;

  /// Service to get groups from.
  final GroupService _groupService;

  /// Service to get animations from.
  final AnimationService _animationService;

  /// Service to get authentication details from.
  final AuthenticationService _authenticationService;

  /// Router to navigate to other pages.
  final Router _router;

  /// Available routes in the app.
  final Routes _routes;

  /// Change detector reference used to update the component.
  final ChangeDetectorRef _cd;

  /// Group allowing communication with the animation items in the drag and drop list.
  final SelectedGroupService _selectedGroupService;

  /// Groups to display.
  List<Group> _groups;

  /// Whether currently loading groups.
  bool _isLoadingGroups = true;

  /// Descriptors of available animations.
  List<AnimationDescriptor<dynamic>> _animationDescriptors;

  /// View of the animation descriptors which will be sorted by the drag and drop list.
  List<AnimationDescriptor<dynamic>> currentAnimationsDescriptorsView;

  /// Whether animations are currently loading.
  bool _isLoadingAnimations = true;

  /// Whether currently deleting.
  bool _deleteInProgress = false;

  /// Whether an error happened during deleting.
  bool _hasDeleteError = false;

  /// Whether currently saving.
  bool _saveInProgress = false;

  /// Whether an error happened during saving.
  bool _hasSaveError = false;

  /// Whether a group has recently been saved.
  bool _recentlySaved = false;

  /// Whether a group has recently been deleted.
  bool _recentlyDeleted = false;

  LanguageLoadedListener _languageLoadedListener;

  Message _errorLabel;
  Message _saveLabel;
  Message _savedLabel;
  Message _deleteLabel;
  Message _deletedLabel;
  Message _newGroupLabel;
  Message _emptyNameLabel;

  StreamSubscription<bool> _loggedInSub;

  /// Create new group management component.
  GroupManagementComponent(
    this._cd,
    this._i18n,
    this._groupService,
    this._animationService,
    this._authenticationService,
    this._router,
    this._routes,
    this._selectedGroupService,
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
    _loadGroups();
    _loadAnimationDescriptors();
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
    _loggedInSub.cancel();
  }

  /// Initialize the translation messages.
  void _initTranslations() {
    _errorLabel = _i18n.get("group-management.error");
    _saveLabel = _i18n.get("group-management.save");
    _savedLabel = _i18n.get("group-management.saved");
    _deleteLabel = _i18n.get("group-management.delete");
    _deletedLabel = _i18n.get("group-management.deleted");
    _newGroupLabel = _i18n.get("group-management.new-group");
    _emptyNameLabel = _i18n.get("group-management.empty-name");
  }

  /// Load groups from server.
  Future<void> _loadGroups() async {
    _isLoadingGroups = true;
    _cd.markForCheck();

    try {
      _groups = await _groupService.getAll();
    } finally {
      _isLoadingGroups = false;
      _cd.markForCheck();
    }
  }

  /// Load available animation descriptors.
  Future<void> _loadAnimationDescriptors() async {
    _isLoadingAnimations = true;
    _cd.markForCheck();

    try {
      Map<String, AnimationDescriptor<dynamic>> animationDescriptorLookup = await _animationService.getAnimationDescriptors();
      _animationDescriptors = animationDescriptorLookup.values.toList(growable: false);
    } finally {
      _isLoadingAnimations = false;
      _cd.markForCheck();
    }
  }

  /// Check if a group is selected.
  bool get hasGroupSelected => _selectedGroupService.selectedGroup != null;

  /// Whether we are currently loading groups.
  bool get isLoadingGroups => _isLoadingGroups;

  /// Whether animations are currently loading.
  bool get isLoadingAnimations => _isLoadingAnimations;

  /// Whether a delete is currently in progress.
  bool get deleteInProgress => _deleteInProgress;

  /// Whether the last delete operation had an error.
  bool get hasDeleteError => _hasDeleteError;

  /// Whether currently saving.
  bool get saveInProgress => _saveInProgress;

  /// Whether the last save action hat an error.
  bool get hasSaveError => _hasSaveError;

  /// Whether there has been a save recently.
  bool get recentlySaved => _recentlySaved;

  /// Whether there has been a deletion recently.
  bool get recentlyDeleted => _recentlyDeleted;

  /// Get the currently selected group.
  Group get selectedGroup => _selectedGroupService.selectedGroup;

  /// Get all groups to display.
  List<Group> get groups => _groups;

  /// Get all animation descriptors to display.
  List<AnimationDescriptor<dynamic>> get animationDescriptors => _animationDescriptors;

  /// Get the item renderer for the animation descriptor items.
  ComponentFactory<AnimationListItemComponent> get animationItemRenderer => animationListItemRenderer.AnimationListItemComponentNgFactory;

  /// Select the passed [group] in the list.
  void selectGroup(Group group) {
    // First and foremost save the current animation order.
    if (hasGroupSelected) {
      group.animationIdOrder = currentAnimationsDescriptorsView.map((descriptor) => descriptor.id).toList();
    }

    _selectedGroupService.selectedGroup = group;

    if (group != null) {
      currentAnimationsDescriptorsView = _animationDescriptors.sublist(0);

      // Sort descriptors by the order stored in the group.
      currentAnimationsDescriptorsView.sort((descriptor1, descriptor2) {
        if (!group.animationIdOrder.contains(descriptor1.id) || !group.animationIdOrder.contains(descriptor2.id)) {
          return 0;
        } else {
          return group.animationIdOrder.indexOf(descriptor1.id) - group.animationIdOrder.indexOf(descriptor2.id);
        }
      });
    }
  }

  /// Check if group is selected.
  bool isGroupSelected(Group group) => group == _selectedGroupService.selectedGroup;

  /// Get a groups name for a list item.
  String getItemLabel(Group group) => group.name != null && group.name.length > 0 ? group.name : _emptyNameLabel.toString();

  /// Get the URL format of the passed groups name.
  String getExampleUrl(Group group) {
    String encodedGroupName = group.name != null && group.name.length > 0 ? NameUtil.makeUrlCompliant(group.name) : group.id.toString();
    return NetworkUtil.baseUri.toString() + "#/group/" + encodedGroupName;
  }

  /// Get the animation name of the passed [descriptor].
  Message getAnimationName(AnimationDescriptor<dynamic> descriptor) => _i18n.get("${descriptor.baseTranslationKey}.name");

  /// Add or remove an animation from the passed [group].
  toggleAnimationInGroup(Group group, int animationId) {
    if (groupContainsAnimation(group, animationId)) {
      group.animationIds.remove(animationId);
    } else {
      group.animationIds.add(animationId);
    }
  }

  /// Check whether the passed [animationId] is already part of the passed group.
  bool groupContainsAnimation(Group group, int animationId) => group.animationIds.contains(animationId);

  /// Create a new group.
  void createGroup() {
    final newGroup = Group(
      name: _newGroupLabel.toString(),
      animationIds: [],
    );

    groups.add(newGroup);

    selectGroup(newGroup);
  }

  /// Delete the passed group.
  void deleteGroup(Group group) async {
    _hasDeleteError = false;

    if (group.id != null) {
      // Has real id -> Is already saved on server-side -> Delete on server-side as well.
      _deleteInProgress = true;
      _cd.markForCheck();

      try {
        bool success = await _groupService.delete(group.id);

        if (!success) {
          _hasDeleteError = true;
        } else {
          groups.remove(group);
          selectGroup(null);
        }
      } catch (e) {
        _hasDeleteError = true;
      } finally {
        _deleteInProgress = false;
        _cd.markForCheck();
      }
    } else {
      groups.remove(group);
      selectGroup(null);
    }
  }

  /// Save all groups.
  void saveGroup(Group group) async {
    _hasSaveError = false;
    _saveInProgress = true;
    _cd.markForCheck();

    int index = groups.indexOf(group);

    // First and foremost save the current animation order.
    if (hasGroupSelected) {
      group.animationIdOrder = currentAnimationsDescriptorsView.map((descriptor) => descriptor.id).toList();
    }

    try {
      bool success = false;
      if (group.id == null) {
        // Not saved on server-side -> Create instead of update.
        Group newGroup = await _groupService.create(group);
        if (newGroup != null) {
          groups[index] = newGroup;
          success = true;
        }
      } else {
        // Already saved on server-side -> Update.
        success = await _groupService.update(group);
      }

      if (success) {
        _recentlySaved = true;
        Future.delayed(_waitDuration).then((_) {
          _recentlySaved = false;
          _cd.markForCheck();
        });
      } else {
        _hasSaveError = true;
      }
    } catch (e) {
      _hasSaveError = true;
    } finally {
      _saveInProgress = false;
      _cd.markForCheck();
    }
  }

  /// Get the label for the delete button.
  String getDeleteButtonLabel() {
    if (_recentlyDeleted) {
      return _deletedLabel.toString();
    } else if (hasDeleteError) {
      return _errorLabel.toString();
    } else if (hasGroupSelected) {
      return "${_deleteLabel.toString()} \"${selectedGroup.name}\"";
    } else {
      return _deleteLabel.toString();
    }
  }

  /// Get the label for the save button.
  String getSaveButtonLabel() {
    if (_recentlySaved) {
      return _savedLabel.toString();
    } else if (hasSaveError) {
      return _errorLabel.toString();
    } else if (hasGroupSelected) {
      return "${_saveLabel.toString()} \"${selectedGroup.name}\"";
    } else {
      return _saveLabel.toString();
    }
  }
}
