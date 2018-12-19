import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http_delay_animation.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http_delay_animation.template.dart' as httpDelay;
import 'package:hm_animations/src/ui/animations/tcp/flow_control/tcp_flow_control_animation.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/tcp_flow_control_animation.template.dart' as tcpFlowControl;
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
import 'package:hm_animations/src/ui/animations/dns/dns_animation.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_animation.template.dart' as dns;
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/tcp_congestion_control_animation.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/tcp_congestion_control_animation.template.dart' as tcpCongestionControl;
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/csma_cd_animation.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/csma_cd_animation.template.dart' as CSMACD;

/// List of all animation is stored here.
class Animations {
  /// Counter for the animation ids.
  static int ID_COUNTER = 1;

  /// List of animations in this application.
  /// Add a new animation to this list in order to make it available to the application.
  static List<AnimationDescriptor> ANIMATIONS = <AnimationDescriptor>[
    new AnimationDescriptor<TransmissionAnimation>(
      ID_COUNTER++,
      transmission.TransmissionAnimationNgFactory,
      "packetTransmission",
      "img/animation/preview/packet-transmission-preview.png",
      "transmission",
    ),
    new AnimationDescriptor<StopAndWaitAnimation>(
      ID_COUNTER++,
      stopAndWait.StopAndWaitAnimationNgFactory,
      "reliable-transmission-animation.protocol.stop-and-wait",
      "img/animation/preview/stop-and-wait-preview.png",
      "stop-and-wait",
    ),
    new AnimationDescriptor<GoBackNAnimation>(
      ID_COUNTER++,
      goBackN.GoBackNAnimationNgFactory,
      "reliable-transmission-animation.protocol.go-back-n",
      "img/animation/preview/go-back-n-preview.png",
      "go-back-n",
    ),
    new AnimationDescriptor<SelectiveRepeatAnimation>(
      ID_COUNTER++,
      selectiveRepeat.SelectiveRepeatAnimationNgFactory,
      "reliable-transmission-animation.protocol.selective-repeat",
      "img/animation/preview/selective-repeat-preview.png",
      "selective-repeat",
    ),
    new AnimationDescriptor<QueueSimulationAnimation>(
      ID_COUNTER++,
      queueSimulation.QueueSimulationAnimationNgFactory,
      "queue-simulation-animation",
      "img/animation/preview/queue-simulation-preview.png",
      "queue-simulation",
    ),
    new AnimationDescriptor<HttpDelayAnimation>(
      ID_COUNTER++,
      httpDelay.HttpDelayAnimationNgFactory,
      "http-delay-animation",
      "img/animation/preview/http-delay-preview.png",
      "http-delay",
    ),
    new AnimationDescriptor<DNSAnimation>(
      ID_COUNTER++,
      dns.DNSAnimationNgFactory,
      "dns-animation",
      "img/animation/preview/dns-animation-preview.png",
      "dns",
    ),
    new AnimationDescriptor<TCPFlowControlAnimation>(
      ID_COUNTER++,
      tcpFlowControl.TCPFlowControlAnimationNgFactory,
      "tcp-flow-control-animation",
      "img/animation/preview/tcp-flow-control-preview.png",
      "tcp-flow-control",
    ),
    new AnimationDescriptor<TCPCongestionControlAnimation>(
      ID_COUNTER++,
      tcpCongestionControl.TCPCongestionControlAnimationNgFactory,
      "tcp-congestion-control-animation",
      "img/animation/preview/tcp_congestion_control_preview.png",
      "tcp-congestion-control",
    ),
    new AnimationDescriptor<CSMACDAnimation>(
      ID_COUNTER++,
      CSMACD.CSMACDAnimationNgFactory,
      "csma-cd-animation",
      "",
      "csma-cd",
    ),
  ];
}
