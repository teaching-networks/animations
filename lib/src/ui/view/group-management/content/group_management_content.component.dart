import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_checkbox/material_checkbox.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/group_service/group_service.dart';
import 'package:hm_animations/src/services/group_service/model/group.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/misc/dnd_list/dnd_list_component.dart';
import 'package:hm_animations/src/ui/view/group-management/animation_list_item/animation_list_item_component.dart';
import 'package:hm_animations/src/ui/view/group-management/animation_list_item/animation_list_item_component.template.dart' as animationListItemRenderer;
import 'package:hm_animations/src/ui/view/group-management/selected_group.service.dart';
import 'package:hm_animations/src/ui/view/management/content/management_component_content.dart';
import 'package:hm_animations/src/util/name_util.dart';
import 'package:hm_animations/src/util/network/network_util.dart';

/// The group management content (form).
@Component(
  selector: "group-management-content-component",
  templateUrl: "group_management_content.component.html",
  styleUrls: ["group_management_content.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
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
)
class GroupManagementContentComponent implements ManagementComponentContent<Group>, OnInit, OnDestroy {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Where to get translations from.
  final I18nService _i18n;

  /// Service allowing communication with the animation items in the drag and drop list.
  final SelectedGroupService _selectedGroupService;

  /// Service to get groups from.
  final GroupService _groupService;

  /// Service to get animations from.
  final AnimationService _animationService;

  /// Group to show.
  Group _group;

  LanguageLoadedListener _languageLoadedListener;

  /// Descriptors of available animations.
  List<AnimationDescriptor<dynamic>> _animationDescriptors;

  /// View of the animation descriptors which will be sorted by the drag and drop list.
  List<AnimationDescriptor<dynamic>> currentAnimationsDescriptorsView;

  /// Whether animations are currently loading.
  bool _isLoadingAnimations = true;

  /// Create component.
  GroupManagementContentComponent(
    this._cd,
    this._i18n,
    this._groupService,
    this._animationService,
    this._selectedGroupService,
  );

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);

    _loadAnimationDescriptors();
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
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

  @override
  Future<bool> onDelete() async {
    if (group.id != null) {
      // Has real id -> Is already saved on server-side -> Delete on server-side as well.
      try {
        return await _groupService.delete(group.id);
      } catch (e) {
        return false;
      }
    } else {
      return true;
    }
  }

  @override
  Future<Group> onSave() async {
    // First and foremost save the current animation order.
    if (_group != null) {
      group.animationIdOrder = currentAnimationsDescriptorsView.map((descriptor) => descriptor.id).toList();
    }

    try {
      bool success = false;
      if (group.id == null) {
        // Not saved on server-side -> Create instead of update.
        return await _groupService.create(group);
      } else {
        // Already saved on server-side -> Update.
        success = await _groupService.update(group);
      }

      if (success) {
        return group;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  void setEntity(Group entity) {
    // First and foremost save the current animation order.
    if (group != null) {
      group.animationIdOrder = currentAnimationsDescriptorsView.map((descriptor) => descriptor.id).toList();
    }

    _group = entity;
    _selectedGroupService.selectedGroup = entity;

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

    _cd.markForCheck();
  }

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

  /// Whether animations are currently loading.
  bool get isLoadingAnimations => _isLoadingAnimations;

  /// Get the group to display.
  Group get group => _group;

  /// Get the item renderer for the animation descriptor items.
  ComponentFactory<AnimationListItemComponent> get animationItemRenderer => animationListItemRenderer.AnimationListItemComponentNgFactory;
}
