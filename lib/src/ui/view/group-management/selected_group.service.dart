import 'dart:async';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/group_service/model/group.dart';

/// Service used to communicate between the animation list items and the group management component.
@Injectable()
class SelectedGroupService implements OnDestroy {
  /// The currently selected group.
  Group _selectedGroup;

  /// Stream controller emitting events in case the selected group changes.
  StreamController<Group> _selectedGroupStreamController = StreamController<Group>.broadcast(sync: false);

  @override
  void ngOnDestroy() {
    _selectedGroupStreamController.close();
  }

  /// Set the currently selected group.
  void set selectedGroup(Group group) {
    _selectedGroup = group;
    _selectedGroupStreamController.add(_selectedGroup);
  }

  /// Get the currently selected group.
  Group get selectedGroup => _selectedGroup;

  /// Check whether the passed [animationId] is in the currenty selected group.
  bool isAnimationInGroup(int animationId) {
    if (_selectedGroup == null) {
      return false;
    }

    return _selectedGroup.animationIds.contains(animationId);
  }

  /// Toggle the animation in the selected group (enable/disable).
  void toggleAnimation(int animationId) {
    if (_selectedGroup == null) {
      return;
    }

    if (isAnimationInGroup(animationId)) {
      _selectedGroup.animationIds.remove(animationId);
    } else {
      _selectedGroup.animationIds.add(animationId);
    }
  }

  /// Get a stream of selected group changes.
  Stream<Group> get selectedGroupChanges => _selectedGroupStreamController.stream;
}
