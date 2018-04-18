import 'dart:async';
import 'package:angular/angular.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/animations/transmission/transmission_animation.dart';

/**
 * Service holding all animations.
 */
@Injectable()
class AnimationService {

  Future<Map<String, AnimationDescriptor>> getAnimationDescriptors() async => {
    TransmissionAnimation.DESCRIPTOR.path: TransmissionAnimation.DESCRIPTOR,
  };

}