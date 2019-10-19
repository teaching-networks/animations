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
import 'package:hm_animations/src/ui/animations/base/connector/animation_component_connector.dart';
import 'package:hm_animations/src/ui/animations/ip_fragmentation/ip_fragmentation_animation.template.dart' as template;
import 'package:hm_animations/src/ui/animations/ip_fragmentation/ip_fragmentation_drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/viewer/drawable_viewer.dart';

import '../animations.dart';

/// The IP fragmentation animation.
/// It shows how IP datagrams are split (fragmented) into fragmentes when its size
/// is higher than the maximum transmission unit (MTU) of the connection to transmit the datagram over.
@Component(
  selector: "ip-fragmentation-animation",
  templateUrl: "ip_fragmentation_animation.html",
  styleUrls: ["ip_fragmentation_animation.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    materialInputDirectives,
    DrawableViewer,
  ],
  pipes: [
    I18nPipe,
  ],
)
class IPFragmentationAnimation extends AnimationComponentConnector {
  /// Descriptor of the IP fragmentation animation.
  static final AnimationDescriptor<IPFragmentationAnimation> descriptor = AnimationDescriptor<IPFragmentationAnimation>(
    id: Animations.ID_COUNTER++,
    baseTranslationKey: "ip-frag",
    componentFactory: template.IPFragmentationAnimationNgFactory,
    path: "ip-frag",
    previewImagePath: "img/animation/preview/ip-fragmentation-preview.png",
    version: 2,
  );

  /// The translation service.
  final I18nService _i18n;

  /// Drawable of the IP fragmentation animation.
  final IPFragmentationDrawable _drawable;

  /// Create IP fragmentation animation.
  IPFragmentationAnimation(this._i18n) : _drawable = IPFragmentationDrawable(_i18n);

  @override
  AnimationDescriptor get animationDescriptor => IPFragmentationAnimation.descriptor;

  @override
  String get credits => _i18n.get("${animationDescriptor.baseTranslationKey}.credits").toString();

  @override
  Drawable get drawable => _drawable;
}
