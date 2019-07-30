/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import "package:angular/angular.dart";
import 'package:angular_components/material_spinner/material_spinner.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/animation_service/model/animation.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/base/animation_base_component.dart';
import 'package:hm_animations/src/ui/dynamic/dynamic_content_component.dart';

/**
 * Detail component showing an animation in detail (Fullscreen).
 */
@Component(selector: "detail-animation-view-component", templateUrl: "detail_animation_view_component.html", styleUrls: [
  "detail_animation_view_component.css"
], directives: [
  coreDirectives,
  DynamicContentComponent,
  MaterialSpinnerComponent,
  AnimationBaseComponent,
], pipes: [
  I18nPipe
])
class DetailAnimationViewComponent implements OnActivate {
  final AnimationService _animationService;

  dynamic componentToShow;

  bool isLoading = true;
  bool notVisible = false;
  bool isError = false;

  AnimationDescriptor<dynamic> _descriptor;
  Animation _animation;

  /// Create component.
  DetailAnimationViewComponent(this._animationService);

  @override
  void onActivate(RouterState previous, RouterState current) {
    final String id = paths.getId(current.parameters);

    if (id != null) {
      int idNum = int.tryParse(id, radix: 10);
      bool isLookupByIdNumber = idNum != null;

      _animationService.getAnimations().then((animations) async {
        for (final anim in animations) {
          if (isLookupByIdNumber ? anim.id == idNum : anim.url == id) {
            _animation = anim;
            break;
          }
        }

        Map<int, AnimationDescriptor<dynamic>> descriptors = _animationService.getAnimationDescriptors();

        if (_animation == null) {
          // Maybe not yet saved on the server-side -> check all animation descriptors
          for (final descriptor in descriptors.values) {
            if (isLookupByIdNumber ? descriptor.id == idNum : descriptor.path == id) {
              _descriptor = descriptor;
              break;
            }
          }
        } else {
          _descriptor = _animationService.getAnimationDescriptors()[_animation.id];
        }

        if (_descriptor != null) {
          componentToShow = _descriptor.componentFactory;
        } else {
          notVisible = true;
        }
      }).catchError((e) {
        isError = true;
        return null;
      }).whenComplete(() {
        isLoading = false;
      });
    }
  }

  /// What to do when the animation component has been loaded.
  void onAnimationComponentLoaded(dynamic loadedAnimationComponent) {
    if (loadedAnimationComponent is AnimationUI) {
      loadedAnimationComponent.descriptor = _descriptor;
    }
  }

  bool get loaded => _descriptor != null;

  int get version => _descriptor.version;
}
