import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http_delay_animation.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http_delay_animation.template.dart' as httpDelay;
import 'package:hm_animations/src/ui/animations/transmission/transmission_animation.dart';
import 'package:hm_animations/src/ui/animations/transmission/transmission_animation.template.dart' as transmission;
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/stop_and_wait/stop_and_wait_animation.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/stop_and_wait/stop_and_wait_animation.template.dart' as stopAndWait;
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/go_back_n/go_back_n_animation.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/go_back_n/go_back_n_animation.template.dart' as goBackN;
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/selective_repeat/selective_repeat_animation.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/selective_repeat/selective_repeat_animation.template.dart' as selectiveRepeat;
import 'package:hm_animations/src/ui/animations/queue_simulation/queue_simulation_animation.dart';
import 'package:hm_animations/src/ui/animations/queue_simulation/queue_simulation_animation.template.dart' as queueSimulation;

class Animations {

  /// List of animations in this application.
  /// Add a new animation to this list in order to make it available to the application.
  static List<AnimationDescriptor> ANIMATIONS = <AnimationDescriptor>[
    new AnimationDescriptor<TransmissionAnimation>(
        transmission.TransmissionAnimationNgFactory,
        "packet-transmission.name",
        "img/animation/preview/packet-transmission-preview.png",
        "transmission"
    ),
    new AnimationDescriptor<StopAndWaitAnimation>(
        stopAndWait.StopAndWaitAnimationNgFactory,
        "reliable-transmission-animation.protocol.stop-and-wait",
        "img/animation/preview/stop-and-wait-preview.png",
        "stop-and-wait"
    ),
    new AnimationDescriptor<GoBackNAnimation>(
        goBackN.GoBackNAnimationNgFactory,
        "reliable-transmission-animation.protocol.go-back-n",
        "img/animation/preview/go-back-n-preview.png",
        "go-back-n"
    ),
    new AnimationDescriptor<SelectiveRepeatAnimation>(
        selectiveRepeat.SelectiveRepeatAnimationNgFactory,
        "reliable-transmission-animation.protocol.selective-repeat",
        "img/animation/preview/selective-repeat-preview.png",
        "selective-repeat"
    ),
    new AnimationDescriptor<QueueSimulationAnimation>(
        queueSimulation.QueueSimulationAnimationNgFactory,
        "queue-simulation-animation.name",
        "img/animation/preview/queue-simulation-preview.png",
        "queue-simulation"
    ),
    new AnimationDescriptor<HttpDelayAnimation>(
        httpDelay.HttpDelayAnimationNgFactory,
        "http-delay-animation.name",
        "img/animation/preview/image-preview.svg",
        "http-delay"
    )
  ];

}
