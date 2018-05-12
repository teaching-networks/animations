import 'dart:async';
import 'package:angular/angular.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/reliable_transmission_animation.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/reliable_transmission_animation.template.dart' as reliableTransmission;
import 'package:netzwerke_animationen/src/ui/animations/transmission/transmission_animation.dart';
import 'package:netzwerke_animationen/src/ui/animations/transmission/transmission_animation.template.dart' as transmission;

/**
 * Service holding all animations.
 */
@Injectable()
class AnimationService {

  Future<Map<String, AnimationDescriptor>> getAnimationDescriptors() async => {
    "transmission": new AnimationDescriptor<TransmissionAnimation>(transmission.TransmissionAnimationNgFactory, "packet-transmission.name", "img/packet-transmission-preview.svg", "transmission"),
    "reliable-transmission": new AnimationDescriptor<ReliableTransmissionAnimation>(reliableTransmission.ReliableTransmissionAnimationNgFactory, "reliable-transmission-animation.name", "img/reliable-transmission-preview.svg", "reliable-transmission")
  };

}