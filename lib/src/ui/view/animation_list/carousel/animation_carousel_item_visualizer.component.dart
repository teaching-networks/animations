/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/authentication_service/authentication_service.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animation_property_keys.dart';
import 'package:hm_animations/src/ui/view/carousel/service/carousel.service.dart';
import 'package:hm_animations/src/ui/view/carousel/visualizer/carousel_item_visualizier.dart';
import 'package:hm_animations/src/util/size.dart';

/// Carousel item visualizer to visualize animation descriptor items.
@Component(
  selector: "animation-carouse-item-visualizer-component",
  templateUrl: "animation_carousel_item_visualizer.component.html",
  styleUrls: ["animation_carousel_item_visualizer.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
  ],
)
class AnimationCarouselItemVisualizerComponent implements CarouselItemVisualizer<AnimationDescriptor>, OnInit, OnDestroy, AfterViewChecked {
  /// Underlying HTML element of the component.
  final Element _element;

  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Service to get translations from.
  final I18nService _i18n;

  /// Service to fetch animation related stuff from.
  final AnimationService _animationService;

  /// Services used for authentication related stuff.
  final AuthenticationService _authService;

  /// Service used to communicate with the root component of the carousel.
  final CarouselService _carouselService;

  /// Animation descriptor to display.
  AnimationDescriptor _animationDescriptor;

  /// Properties of all animations.
  Map<String, String> _animationProperties;

  /// Listener notified when the selected language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// Subscription to the loggedIn stream.
  StreamSubscription<bool> _loggedInSub;

  /// Whether user is currently logged in.
  bool _isLoggedIn = false;

  /// Current size of the component.
  Size _currentSize;

  /// Create component.
  AnimationCarouselItemVisualizerComponent(
    this._cd,
    this._element,
    this._i18n,
    this._animationService,
    this._authService,
    this._carouselService,
  );

  @override
  void set item(AnimationDescriptor value) {
    _animationDescriptor = value;
    _reloadAnimationProperties();
  }

  /// Get the descriptor to display.
  AnimationDescriptor get anim => _animationDescriptor;

  /// Get the name of the passed animation descriptor.
  String getAnimationName(AnimationDescriptor descriptor) {
    String value = _getPropertyValue(AnimationPropertyKeys.titleKey);

    if (value == null) {
      value = _i18n.get("${descriptor.baseTranslationKey}.name").toString();
    }

    return value;
  }

  /// Get the description for the passed animation descriptor.
  String getAnimationDescription(AnimationDescriptor descriptor) {
    String value = _getPropertyValue(AnimationPropertyKeys.shortDescriptionKey);

    if (value == null) {
      value = _i18n.get("${descriptor.baseTranslationKey}.short-description").toString();
    }

    return value;
  }

  /// Load animation properties needed to display important data of an animation.
  Future<void> _loadAnimationProperties(AnimationDescriptor descriptor) async {
    final animProps = await _animationService.getProperties(
      locale: _i18n.getCurrentLocale(),
      animationId: descriptor.id,
    );

    if (animProps != null) {
      _animationProperties = Map<String, String>();
      for (final animProp in animProps) {
        _animationProperties[animProp.key] = animProp.value;
      }
    }

    _cd.markForCheck();
  }

  /// Reload the animation properties.
  void _reloadAnimationProperties() {
    if (_animationDescriptor != null) {
      _loadAnimationProperties(_animationDescriptor);
    }

    _cd.markForCheck();
  }

  /// Get an animation property value.
  String _getPropertyValue(String key) => _animationProperties != null ? _animationProperties[key] : null;

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _reloadAnimationProperties();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
    _reloadAnimationProperties();

    _loggedInSub = _authService.loggedIn.listen((loggedIn) {
      _isLoggedIn = loggedIn;
      _cd.markForCheck();
    });
    _isLoggedIn = _authService.isLoggedIn;
  }

  @override
  void ngOnDestroy() {
    if (_languageLoadedListener != null) {
      _i18n.removeLanguageLoadedListener(_languageLoadedListener);
    }

    if (_loggedInSub != null) {
      _loggedInSub.cancel();
    }
  }

  /// Whether the user is currently logged in
  bool get isLoggedIn => _isLoggedIn;

  @override
  void ngAfterViewChecked() {
    Size newSize = _getSize();

    if (_currentSize == null || (newSize.width != _currentSize.width && newSize.height != _currentSize.height)) {
      _currentSize = newSize;
      _carouselService.informAboutSize(anim, newSize);
    }
  }

  /// Get the size of the component.
  Size _getSize() {
    return Size(
      _element.clientWidth,
      _element.clientHeight,
    );
  }
}
