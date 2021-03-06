/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:hm_animations/src/services/animation_service/animation_service.dart';
import 'package:hm_animations/src/services/animation_service/model/animation.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animation_property_keys.dart';
import 'package:hm_animations/src/ui/misc/editor/editor.component.dart';
import 'package:hm_animations/src/ui/view/management/content/management_component_content.dart';
import 'package:hm_animations/src/util/name_util.dart';
import 'package:hm_animations/src/util/network/network_util.dart';
import 'package:hm_animations/src/util/options/save_options.dart';

/// Component displaying animation info.
@Component(
  selector: "animation-management-content-component",
  templateUrl: "animation_management_content.component.html",
  styleUrls: ["animation_management_content.component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    materialInputDirectives,
    EditorComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class AnimationManagementContentComponent implements ManagementComponentContent<AnimationDescriptor<dynamic>>, OnInit, OnDestroy {
  /// Maximum characters a description is allowed to have.
  static const int _maxDescriptionLength = 10000;

  /// Maximum characters a show description is allowed to have.
  static const int _maxShortDescriptionLength = 255;

  /// Maximum characters a title is allowed to have.
  static const int _maxTitleLength = 100;

  /// Maximum characters a url is allowed to have.
  static const int _maxURLLength = 100;

  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Where to get translations from.
  final I18nService _i18n;

  /// Service managing animations.
  final AnimationService _animationService;

  /// Listener getting notifications whenever the language changes.
  LanguageLoadedListener _languageLoadedListener;

  /// The current animation descriptor to display.
  AnimationDescriptor<dynamic> _animationDescriptor;

  /// The underlying animation object (if any).
  Animation _animation;

  /// Properties to edit.
  Map<String, String> _properties;

  /// The description to show / edit.
  String description;

  /// The short description to show / edit.
  String shortDescription;

  /// The title to show / edit.
  String title;

  /// The url to show / edit.
  String url = "";

  /// Create component
  AnimationManagementContentComponent(
    this._cd,
    this._i18n,
    this._animationService,
  );

  @override
  void ngOnInit() {
    _languageLoadedListener = (_) {
      _cd.markForCheck();

      _load();
    };
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
  }

  /// Load contents.
  Future<void> _load() async {
    if (_animationDescriptor == null) {
      return;
    }

    // Load animation object (if any).
    _animation = await _animationService.getAnimation(_animationDescriptor.id);

    if (_animation != null) {
      url = _animation.url;
    } else {
      url = "";
    }

    final animProps = await _animationService.getProperties(
      locale: _i18n.getCurrentLocale(),
      animationId: _animationDescriptor.id,
    );

    if (animProps != null) {
      _properties = Map<String, String>();
      for (final animProp in animProps) {
        _properties[animProp.key] = animProp.value;
      }

      if (_properties[AnimationPropertyKeys.descriptionKey] == null) {
        // Load from translations instead
        description = _i18n.get("${_animationDescriptor.baseTranslationKey}.description").toString();
      } else {
        description = _properties[AnimationPropertyKeys.descriptionKey];
      }

      if (_properties[AnimationPropertyKeys.shortDescriptionKey] == null) {
        // Load from translations instead
        shortDescription = _i18n.get("${_animationDescriptor.baseTranslationKey}.short-description").toString();
      } else {
        shortDescription = _properties[AnimationPropertyKeys.shortDescriptionKey];
      }

      if (_properties[AnimationPropertyKeys.titleKey] == null) {
        // Load from translations instead
        title = _i18n.get("${_animationDescriptor.baseTranslationKey}.name").toString();
      } else {
        title = _properties[AnimationPropertyKeys.titleKey];
      }
    }

    _cd.markForCheck();
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
  }

  @override
  Future<bool> onDelete() async {
    throw Exception("Deletion not supported");
  }

  @override
  Future<AnimationDescriptor<dynamic>> onSave() async {
    bool success = true;

    // Save description
    if (description != null) {
      success =
          await _animationService.setProperty(_i18n.getCurrentLocale(), _animationDescriptor.id, AnimationPropertyKeys.descriptionKey, description) && success;
    }

    // Save short description
    if (shortDescription != null) {
      success =
          await _animationService.setProperty(_i18n.getCurrentLocale(), _animationDescriptor.id, AnimationPropertyKeys.shortDescriptionKey, shortDescription) &&
              success;
    }

    // Save title
    if (title != null) {
      success = await _animationService.setProperty(_i18n.getCurrentLocale(), _animationDescriptor.id, AnimationPropertyKeys.titleKey, title) && success;
    }

    // Save url
    if (url != null) {
      url = getCompliantURL();

      if (_animation != null) {
        _animation.url = url;

        success = await _animationService.updateAnimation(_animation) && success;
      } else {
        // Create animation instead.
        Animation animation = Animation(_animationDescriptor.id, url);
        _animation = await _animationService.createAnimation(animation);
        if (_animation == null) {
          success = false;
        }
      }
    }

    return success ? _animationDescriptor : null;
  }

  @override
  Future<void> setEntity(AnimationDescriptor<dynamic> entity) async {
    _animationDescriptor = entity;

    await _load();

    _cd.markForCheck();
  }

  String getCompliantURL() {
    String src = url != null && url.isNotEmpty ? url : _animationDescriptor.path;

    return src != null && src.isNotEmpty ? NameUtil.makeUrlCompliant(src) : _animationDescriptor.id.toString();
  }

  /// Get the URL format of the animation.
  String getExampleUrl() {
    return NetworkUtil.baseUri.toString() + "#/animation/" + getCompliantURL();
  }

  /// Get the current animation descriptor to show.
  AnimationDescriptor<dynamic> get animationDescriptor => _animationDescriptor;

  /// The maximum description character length.
  int get maxDescriptionLength => _maxDescriptionLength;

  /// The maximum short description character length.
  int get maxShortDescriptionLength => _maxShortDescriptionLength;

  /// The maximum title character length.
  int get maxTitleLength => _maxTitleLength;

  /// The maximum URL character length.
  int get maxURLLength => _maxURLLength;

  /// Reset all fields to default values.
  void resetToDefaults() {
    title = _i18n.get("${_animationDescriptor.baseTranslationKey}.name").toString();
    shortDescription = _i18n.get("${_animationDescriptor.baseTranslationKey}.short-description").toString();
    description = _i18n.get("${_animationDescriptor.baseTranslationKey}.description").toString();
    url = "";
  }

  @override
  Future<SaveOption> checkIfUnsaved() async {
    return SaveOption.LOSE;
  }
}
