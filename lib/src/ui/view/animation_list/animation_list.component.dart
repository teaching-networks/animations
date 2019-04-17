import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/group_service/group_service.dart';
import 'package:hm_animations/src/services/group_service/model/group.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/misc/directives/restricted_directive.dart';
import 'package:hm_animations/src/util/name_util.dart';

/// Component listing all available animations.
@Component(
  selector: "animation-list-component",
  templateUrl: "animation_list.component.html",
  styleUrls: [
    "animation_list.component.css",
    "package:angular_components/css/mdc_web/card/mdc-card.scss.css",
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    routerDirectives,
    RestrictedDirective,
    MaterialToggleComponent,
    MaterialSpinnerComponent,
    MaterialIconComponent,
    MaterialButtonComponent
  ],
  pipes: [
    I18nPipe,
  ],
)
class AnimationListComponent implements OnInit, OnDestroy, OnActivate {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Service to get groups from.
  final GroupService _groupService;

  /// Service to get animations from.
  final AnimationService _animationService;

  /// Get authentication information from this service.
  final AuthenticationService _authService;

  /// State of the component.
  _CompState state = _CompState.LOADING;

  /// Group to display.
  Group group;

  /// Available animations in group.
  Set<int> _animationsInGroup;

  /// All animations.
  List<AnimationDescriptor<dynamic>> animationDescriptors;

  LanguageLoadedListener _languageLoadedListener;

  /// Subscription to the loggedIn stream.
  StreamSubscription<bool> _loggedInSub;

  /// Whether user is currently logged in.
  bool _isLoggedIn = false;

  /// Create component.
  AnimationListComponent(
    this._cd,
    this._i18n,
    this._groupService,
    this._animationService,
    this._authService,
  );

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);

    _loggedInSub = _authService.loggedIn.listen((loggedIn) {
      _isLoggedIn = loggedIn;
      _cd.markForCheck();
    });
    _isLoggedIn = _authService.isLoggedIn;
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
    _loggedInSub.cancel();
  }

  @override
  void onActivate(RouterState previous, RouterState current) {
    String groupId = paths.getId(current.parameters);

    _loadGroup(groupId);
  }

  /// Load group and animations.
  Future<void> _loadGroup(String groupId) async {
    state = _CompState.LOADING;
    _cd.markForCheck();

    try {
      List<Group> groups = await _groupService.getAll();

      if (groups == null) {
        state = _CompState.ERROR;
        return;
      }

      group = _getGroupById(groups, groupId);
      _animationsInGroup = Set.of(group.animationIds);

      Map<int, AnimationDescriptor<dynamic>> descriptors = _animationService.getAnimationDescriptors();
      if (descriptors == null) {
        state = _CompState.ERROR;
        return;
      }

      // Sort animation descriptors by the group order.
      List<AnimationDescriptor<dynamic>> descriptorList = descriptors.values.toList();
      descriptorList.sort((descriptor1, descriptor2) {
        if (!group.animationIdOrder.contains(descriptor1.id) || !group.animationIdOrder.contains(descriptor2.id)) {
          return 0;
        } else {
          return group.animationIdOrder.indexOf(descriptor1.id) - group.animationIdOrder.indexOf(descriptor2.id);
        }
      });

      animationDescriptors = descriptorList;

      state = _CompState.SUCCESS;
    } catch (e) {
      state = _CompState.ERROR;
    } finally {
      _cd.markForCheck();
    }
  }

  /// Get a group by its [groupId].
  Group _getGroupById(List<Group> groups, String groupId) {
    if (groupId == null || groupId.isEmpty) {
      return null;
    }

    int id = int.tryParse(groupId);
    if (id != null) {
      for (Group group in groups) {
        if (group.id == id) {
          return group;
        }
      }
    } else {
      Map<String, Group> nameLookup = Map<String, Group>();
      for (Group group in groups) {
        if (NameUtil.makeUrlCompliant(group.name) == groupId) {
          return group;
        }
      }
    }

    return null;
  }

  /// Get animation url to navigate to.
  String animationUrl(AnimationDescriptor<dynamic> descriptor) => paths.animation.toUrl(parameters: {
        paths.idParam: descriptor.path,
      });

  Message getAnimationName(String baseKey) => _i18n.get("${baseKey}.name");

  Message getAnimationDescription(String baseKey) => _i18n.get("${baseKey}.short-description");

  /// Check if animation is visible.
  bool isAnimationVisible(int id) => _animationsInGroup.contains(id);

  /// What to do on a visibility change of a animation [id].
  void onVisibilityChange(int id, bool visible) async {
    if (visible) {
      group.animationIds.add(id);
      _animationsInGroup.add(id);
    } else {
      group.animationIds.remove(id);
      _animationsInGroup.remove(id);
    }

    // Update group on server-side.
    _groupService.update(group);
  }

  Iterable<AnimationDescriptor<dynamic>> get animationDescriptorsToShow =>
      !_isLoggedIn ? animationDescriptors.where((descriptor) => _animationsInGroup.contains(descriptor.id)) : animationDescriptors;

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
