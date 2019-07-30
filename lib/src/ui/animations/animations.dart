/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/animation_descriptor.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/dijkstra_algorithm_animation.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/dijkstra_algorithm_animation.template.dart' as dijkstra;
import 'package:hm_animations/src/ui/animations/dns/dns_animation.dart';
import 'package:hm_animations/src/ui/animations/dns/dns_animation.template.dart' as dns;
import 'package:hm_animations/src/ui/animations/http_delay/http_delay_animation.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http_delay_animation.template.dart' as httpDelay;
import 'package:hm_animations/src/ui/animations/media_access_control/csma_ca/csma_ca_animation.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_ca/csma_ca_animation.template.dart' as CSMACA;
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/csma_cd_animation.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/csma_cd_animation.template.dart' as CSMACD;
import 'package:hm_animations/src/ui/animations/onion_router/onion_router_animation_component.dart';
import 'package:hm_animations/src/ui/animations/queue_simulation/queue_simulation_animation.dart';
import 'package:hm_animations/src/ui/animations/queue_simulation/queue_simulation_animation.template.dart' as queueSimulation;
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/go_back_n/go_back_n_animation.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/go_back_n/go_back_n_animation.template.dart' as goBackN;
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/selective_repeat/selective_repeat_animation.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/selective_repeat/selective_repeat_animation.template.dart' as selectiveRepeat;
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/stop_and_wait/stop_and_wait_animation.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/impl/stop_and_wait/stop_and_wait_animation.template.dart' as stopAndWait;
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/tcp_congestion_control_animation.dart';
import 'package:hm_animations/src/ui/animations/tcp/congestion_control/tcp_congestion_control_animation.template.dart' as tcpCongestionControl;
import 'package:hm_animations/src/ui/animations/tcp/flow_control/tcp_flow_control_animation.dart';
import 'package:hm_animations/src/ui/animations/tcp/flow_control/tcp_flow_control_animation.template.dart' as tcpFlowControl;
import 'package:hm_animations/src/ui/animations/transmission/transmission_animation.dart';
import 'package:hm_animations/src/ui/animations/transmission/transmission_animation.template.dart' as transmission;

/// List of all animation is stored here.
class Animations {
  /// Counter for the animation ids.
  static int ID_COUNTER = 1;

  /// List of animations in this application.
  /// Add a new animation to this list in order to make it available to the application.
  static List<AnimationDescriptor> ANIMATIONS = <AnimationDescriptor>[
    AnimationDescriptor<TransmissionAnimation>(
      id: ID_COUNTER++,
      componentFactory: transmission.TransmissionAnimationNgFactory,
      baseTranslationKey: "packetTransmission",
      previewImagePath: "img/animation/preview/packet-transmission-preview.png",
      path: "transmission",
    ),
    AnimationDescriptor<StopAndWaitAnimation>(
      id: ID_COUNTER++,
      componentFactory: stopAndWait.StopAndWaitAnimationNgFactory,
      baseTranslationKey: "reliable-transmission-animation.protocol.stop-and-wait",
      previewImagePath: "img/animation/preview/stop-and-wait-preview.png",
      path: "stop-and-wait",
    ),
    AnimationDescriptor<GoBackNAnimation>(
      id: ID_COUNTER++,
      componentFactory: goBackN.GoBackNAnimationNgFactory,
      baseTranslationKey: "reliable-transmission-animation.protocol.go-back-n",
      previewImagePath: "img/animation/preview/go-back-n-preview.png",
      path: "go-back-n",
    ),
    AnimationDescriptor<SelectiveRepeatAnimation>(
      id: ID_COUNTER++,
      componentFactory: selectiveRepeat.SelectiveRepeatAnimationNgFactory,
      baseTranslationKey: "reliable-transmission-animation.protocol.selective-repeat",
      previewImagePath: "img/animation/preview/selective-repeat-preview.png",
      path: "selective-repeat",
    ),
    AnimationDescriptor<QueueSimulationAnimation>(
      id: ID_COUNTER++,
      componentFactory: queueSimulation.QueueSimulationAnimationNgFactory,
      baseTranslationKey: "queue-simulation-animation",
      previewImagePath: "img/animation/preview/queue-simulation-preview.png",
      path: "queue-simulation",
    ),
    AnimationDescriptor<HttpDelayAnimation>(
      id: ID_COUNTER++,
      componentFactory: httpDelay.HttpDelayAnimationNgFactory,
      baseTranslationKey: "http-delay-animation",
      previewImagePath: "img/animation/preview/http-delay-preview.png",
      path: "http-delay",
    ),
    AnimationDescriptor<DNSAnimation>(
      id: ID_COUNTER++,
      componentFactory: dns.DNSAnimationNgFactory,
      baseTranslationKey: "dns-animation",
      previewImagePath: "img/animation/preview/dns-animation-preview.png",
      path: "dns",
    ),
    AnimationDescriptor<TCPFlowControlAnimation>(
      id: ID_COUNTER++,
      componentFactory: tcpFlowControl.TCPFlowControlAnimationNgFactory,
      baseTranslationKey: "tcp-flow-control-animation",
      previewImagePath: "img/animation/preview/tcp-flow-control-preview.png",
      path: "tcp-flow-control",
    ),
    AnimationDescriptor<TCPCongestionControlAnimation>(
      id: ID_COUNTER++,
      componentFactory: tcpCongestionControl.TCPCongestionControlAnimationNgFactory,
      baseTranslationKey: "tcp-congestion-control-animation",
      previewImagePath: "img/animation/preview/tcp_congestion_control_preview.png",
      path: "tcp-congestion-control",
    ),
    AnimationDescriptor<CSMACDAnimation>(
      id: ID_COUNTER++,
      componentFactory: CSMACD.CSMACDAnimationNgFactory,
      baseTranslationKey: "csma-cd-animation",
      previewImagePath: "img/animation/preview/csma-cd-preview.png",
      path: "csma-cd",
    ),
    AnimationDescriptor<DijkstraAlgorithmAnimation>(
      id: ID_COUNTER++,
      componentFactory: dijkstra.DijkstraAlgorithmAnimationNgFactory,
      baseTranslationKey: "dijkstra-algorithm-animation",
      previewImagePath: "img/animation/preview/dijkstra-preview.png",
      path: "dijkstra",
    ),
    AnimationDescriptor<CSMACAAnimation>(
      id: ID_COUNTER++,
      componentFactory: CSMACA.CSMACAAnimationNgFactory,
      baseTranslationKey: "csma-ca-animation",
      previewImagePath: "img/animation/preview/csma-ca-preview.png",
      path: "hidden-node-problem",
    ),
    OnionRouterAnimationComponent.descriptor,
  ];
}
