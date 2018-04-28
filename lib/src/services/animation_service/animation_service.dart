import 'dart:async';
import 'package:angular/angular.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/send_and_wait/send_and_wait_animation.template.dart' as sendAndWait;
import 'package:netzwerke_animationen/src/ui/animations/transmission/transmission_animation.template.dart' as transmission;

/**
 * Service holding all animations.
 */
@Injectable()
class AnimationService {

  Future<Map<String, AnimationDescriptor>> getAnimationDescriptors() async => {
    "transmission": new AnimationDescriptor(transmission.TransmissionAnimationNgFactory, "packet-transmission.name", "img/packet-transmission-preview.svg", "transmission"),
    "send-and-wait": new AnimationDescriptor(sendAndWait.SendAndWaitAnimationNgFactory, "send-and-wait-animation.name", "img/image-preview.svg", "send-and-wait")
  };

}