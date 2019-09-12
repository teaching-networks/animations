/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:angular_router/angular_router.dart';
import 'package:hm_animations/src/router/route_paths.dart' as paths;
import 'package:hm_animations/src/router/routes.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/animation_service/model/animation.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animation_property_keys.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/base/animation_base_component.dart';
import 'package:hm_animations/src/ui/dynamic/dynamic_content_component.dart';

/**
 * Default animation view component showing an animation in default mode.
 */
@Component(
  selector: "default-animation-view-component",
  templateUrl: "default_animation_view_component.html",
  styleUrls: ["default_animation_view_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    MaterialButtonComponent,
    MaterialIconComponent,
    routerDirectives,
    DynamicContentComponent,
    MaterialSpinnerComponent,
    AnimationBaseComponent,
  ],
  providers: [ClassProvider(Routes)],
  pipes: [
    I18nPipe,
  ],
)
class DefaultAnimationViewComponent implements OnActivate, OnInit, OnDestroy {
  final ChangeDetectorRef _cd;
  final AnimationService _animationService;
  final Routes routes;
  final I18nService _i18n;

  String _id = "";

  String animationTitle;
  dynamic componentToShow;

  bool isLoading = true;
  bool notVisible = false;
  bool isError = false;

  Animation _animation;
  AnimationDescriptor<dynamic> _descriptor;

  LanguageLoadedListener _languageLoadedListener;

  DefaultAnimationViewComponent(
    this._animationService,
    this.routes,
    this._i18n,
    this._cd,
  );

  @override
  void onActivate(RouterState previous, RouterState current) {
    _id = paths.getId(current.parameters);

    if (_id != null) {
      int idNum = int.tryParse(_id, radix: 10);
      bool isLookupByIdNumber = idNum != null;

      _animationService.getAnimations().then((animations) async {
        for (final anim in animations) {
          if (isLookupByIdNumber ? anim.id == idNum : anim.url == _id) {
            _animation = anim;
            break;
          }
        }

        Map<int, AnimationDescriptor<dynamic>> descriptors = _animationService.getAnimationDescriptors();

        if (_animation == null) {
          // Maybe not yet saved on the server-side -> check all animation descriptors
          for (final descriptor in descriptors.values) {
            if (isLookupByIdNumber ? descriptor.id == idNum : descriptor.path == _id) {
              _descriptor = descriptor;
              break;
            }
          }
        } else {
          _descriptor = _animationService.getAnimationDescriptors()[_animation.id];
        }

        if (_descriptor != null) {
          _loadAnimationTitle();
          componentToShow = _descriptor.componentFactory;
        } else {
          notVisible = true;
        }
      }).catchError((e) {
        isError = true;
        return null;
      }).whenComplete(() {
        isLoading = false;
        _cd.markForCheck();
      });
    }
  }

  bool get loaded => _descriptor != null;

  int get version => _descriptor.version;

  /// Load the animation title.
  void _loadAnimationTitle() async {
    if (_descriptor == null) {
      return;
    }

    final animTitleProp = await _animationService.getProperty(
      locale: _i18n.getCurrentLocale(),
      animationId: _descriptor.id,
      key: AnimationPropertyKeys.titleKey,
    );

    if (animTitleProp == null || animTitleProp.value.isEmpty) {
      // Fallback to translations.
      animationTitle = _i18n.get("${_descriptor.baseTranslationKey}.name").toString();
    } else {
      animationTitle = animTitleProp.value;
    }

    _cd.markForCheck();
  }

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _loadAnimationTitle();

      _cd.markForCheck();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
  }

  String get detailUrl => paths.detail.toUrl(parameters: {paths.idParam: _id});

  /// What to do when the animation component has been loaded.
  void onAnimationComponentLoaded(dynamic loadedAnimationComponent) {
    if (loadedAnimationComponent is AnimationUI) {
      loadedAnimationComponent.descriptor = _descriptor;
    }
  }
}
