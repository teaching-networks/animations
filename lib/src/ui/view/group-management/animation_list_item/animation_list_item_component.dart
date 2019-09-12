/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_checkbox/material_checkbox.dart';
import 'package:hm_animations/src/services/group_service/model/group.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/misc/dnd_list/renderer/list_item_renderer.dart';
import 'package:hm_animations/src/ui/view/group-management/selected_group.service.dart';

/// Renderer to render animation items in a drag and drop list.
@Component(
  selector: "animation-list-item",
  templateUrl: "animation_list_item.component.html",
  styleUrls: ["animation_list_item.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    MaterialButtonComponent,
    MaterialCheckboxComponent,
  ],
  encapsulation: ViewEncapsulation.None,
)
class AnimationListItemComponent implements ListItemRenderer<AnimationDescriptor<dynamic>>, OnInit, OnDestroy {
  /// Change detection reference.
  final ChangeDetectorRef _cd;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Group allowing communication with the group management component.
  final SelectedGroupService _selectedGroupService;

  /// Animation descriptor to currently display.
  AnimationDescriptor<dynamic> _descriptor;

  /// Subscription to selected group changes.
  StreamSubscription<Group> _groupChangesSub;

  /// Create list item.
  AnimationListItemComponent(this._cd, this._i18n, this._selectedGroupService);

  @override
  void ngOnDestroy() {
    _groupChangesSub.cancel();
  }

  @override
  void ngOnInit() {
    _groupChangesSub = _selectedGroupService.selectedGroupChanges.listen((_) {
      _cd.markForCheck();
    });
  }

  @override
  void setItem(AnimationDescriptor<dynamic> item) {
    _descriptor = item;
    _cd.markForCheck();
  }

  /// Get the current descriptor to display.
  AnimationDescriptor<dynamic> get descriptor => _descriptor;

  /// Get the animation name of the passed [descriptor].
  Message getAnimationName(AnimationDescriptor<dynamic> descriptor) => _i18n.get("${descriptor.baseTranslationKey}.name");

  /// Check whether the passed [animationId] is already part of the currently selected group.
  bool isAnimationEnabled(int animationId) => _selectedGroupService.isAnimationInGroup(animationId);

  /// Add or remove an animation from the currently selected group.
  toggleAnimation(int animationId) {
    _selectedGroupService.toggleAnimation(animationId);
  }
}
