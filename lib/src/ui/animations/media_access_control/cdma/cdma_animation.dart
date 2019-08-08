/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/animations.dart';
import 'package:hm_animations/src/ui/animations/base/connector/animation_component_connector.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/cdma/cdma_animation.template.dart' as template;
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/viewer/drawable_viewer.dart';

import 'cdma_drawable.dart';

/// Animation visualizing CDMA (Code Division Multiple Access).
@Component(
  selector: "cdma-animation-component",
  templateUrl: "cdma_animation.html",
  styleUrls: ["cdma_animation.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    DrawableViewer,
    materialInputDirectives,
  ],
  pipes: [I18nPipe],
)
class CDMAAnimation extends AnimationComponentConnector {
  /// Descriptor of this animation.
  static final AnimationDescriptor<CDMAAnimation> descriptor = AnimationDescriptor<CDMAAnimation>(
    id: Animations.ID_COUNTER++,
    componentFactory: template.CDMAAnimationNgFactory,
    baseTranslationKey: "cdma",
    previewImagePath: "",
    // TODO Specify preview image
    path: "cdma",
    version: 2,
  );

  /// Service to get translations from.
  final I18nService _i18n;

  /// Drawable of the CDMA animation.
  final CDMADrawable _drawable = CDMADrawable();

  /// Create animation.
  CDMAAnimation(this._i18n);

  @override
  AnimationDescriptor get animationDescriptor => CDMAAnimation.descriptor;

  @override
  String get credits => _i18n.get("${animationDescriptor.baseTranslationKey}.credits").toString();

  @override
  Drawable get drawable => _drawable;
}
