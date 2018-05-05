import 'dart:async';
import 'package:angular/angular.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/stop_and_wait/stop_and_wait_animation.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/stop_and_wait/stop_and_wait_animation.template.dart' as stopAndWait;
import 'package:netzwerke_animationen/src/ui/animations/transmission/transmission_animation.dart';
import 'package:netzwerke_animationen/src/ui/animations/transmission/transmission_animation.template.dart' as transmission;

/**
 * Service holding all animations.
 */
@Injectable()
class AnimationService {

  Future<Map<String, AnimationDescriptor>> getAnimationDescriptors() async => {
    "transmission": new AnimationDescriptor<TransmissionAnimation>(transmission.TransmissionAnimationNgFactory, "packet-transmission.name", "img/packet-transmission-preview.svg", "transmission"),
    "stop-and-wait": new AnimationDescriptor<StopAndWaitAnimation>(stopAndWait.StopAndWaitAnimationNgFactory, "stop-and-wait-animation.name", "img/stop-and-wait-preview.svg", "stop-and-wait")
  };

}