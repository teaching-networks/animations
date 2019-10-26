/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/base/connector/animation_component_connector.dart';
import 'package:hm_animations/src/ui/animations/buffering/buffering_animation.template.dart' as template;
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/viewer/drawable_viewer.dart';

import '../animations.dart';
import 'drawable/buffering_animation_drawable.dart';

/// Animation visualizing buffering.
@Component(
  selector: "buffering-animation-component",
  templateUrl: "buffering_animation.html",
  styleUrls: ["buffering_animation.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    DrawableViewer,
  ],
  pipes: [
    I18nPipe,
  ],
)
class BufferingAnimation extends AnimationComponentConnector {
  /// Descriptor of the animation.
  static final AnimationDescriptor<BufferingAnimation> descriptor = AnimationDescriptor<BufferingAnimation>(
    id: Animations.ID_COUNTER++,
    baseTranslationKey: "buffering",
    componentFactory: template.BufferingAnimationNgFactory,
    path: "buffering",
    previewImagePath: "img/animation/preview/buffering-preview.png",
    version: 2,
  );

  /// The translation service.
  final I18nService _i18n;

  /// Root drawable of the animation.
  final BufferingAnimationDrawable _drawable;

  /// Create animation.
  BufferingAnimation(this._i18n) : _drawable = BufferingAnimationDrawable();

  @override
  AnimationDescriptor get animationDescriptor => descriptor;

  @override
  String get credits => _i18n.get("${animationDescriptor.baseTranslationKey}.credits").toString();

  @override
  Drawable get drawable => _drawable;
}
