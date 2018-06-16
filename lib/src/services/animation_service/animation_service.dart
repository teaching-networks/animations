import 'dart:async';
import 'package:angular/angular.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/animations/transmission/transmission_animation.dart';
import 'package:netzwerke_animationen/src/ui/animations/transmission/transmission_animation.template.dart' as transmission;
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/impl/stop_and_wait/stop_and_wait_animation.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/impl/stop_and_wait/stop_and_wait_animation.template.dart' as stopAndWait;
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/impl/go_back_n/go_back_n_animation.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/impl/go_back_n/go_back_n_animation.template.dart' as goBackN;
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/impl/selective_repeat/selective_repeat_animation.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/impl/selective_repeat/selective_repeat_animation.template.dart' as selectiveRepeat;

/**
 * Service holding all animations.
 */
@Injectable()
class AnimationService {
  Future<Map<String, AnimationDescriptor>> getAnimationDescriptors() async => {
        "transmission": new AnimationDescriptor<TransmissionAnimation>(
            transmission.TransmissionAnimationNgFactory,
            "packet-transmission.name",
            "img/packet-transmission-preview.svg",
            "transmission"
        ),
        "stop-and-wait": new AnimationDescriptor<StopAndWaitAnimation>(
            stopAndWait.StopAndWaitAnimationNgFactory,
            "reliable-transmission-animation.protocol.stop-and-wait",
            "img/reliable-transmission-preview.svg",
            "stop-and-wait"
        ),
        "go-back-n": new AnimationDescriptor<GoBackNAnimation>(
            goBackN.GoBackNAnimationNgFactory,
            "reliable-transmission-animation.protocol.go-back-n",
            "img/reliable-transmission-preview.svg",
            "go-back-n"
        ),
        "selective-repeat": new AnimationDescriptor<SelectiveRepeatAnimation>(
            selectiveRepeat.SelectiveRepeatAnimationNgFactory,
            "reliable-transmission-animation.protocol.selective-repeat",
            "img/reliable-transmission-preview.svg",
            "selective-repeat"
        )
      };
}
