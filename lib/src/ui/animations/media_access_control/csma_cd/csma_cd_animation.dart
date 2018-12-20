import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/angular_components.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/connection_step.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/non_persistent_http_connection.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/connection_type/persistent_http_connection.dart';
import 'package:hm_animations/src/ui/animations/http_delay/http/http_connection_configuration.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/bus_shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/renderable_shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/bus_medium_peer.dart';
import 'package:hm_animations/src/ui/animations/shared/round_trip/client_server_round_trip.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/progress/mutable_progress.dart';
import 'package:hm_animations/src/ui/canvas/progress/progress.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

/// Animation showing the CSMA/CD media-access-control protocol.
@Component(
    selector: "csma-cd-animation",
    styleUrls: ["csma_cd_animation.css"],
    templateUrl: "csma_cd_animation.html",
    directives: [coreDirectives, CanvasComponent],
    pipes: [I18nPipe])
class CSMACDAnimation extends CanvasAnimation implements OnInit, OnDestroy {
  /// Peers to display in the animation.
  static const int _peerCount = 3;

  /// Service to retrieve translations with.
  I18nService _i18n;

  /// Shared medium used to simulate CSMA/CD.
  RenderableSharedMedium _sharedMedium;

  /// Create animation.
  CSMACDAnimation(this._i18n) {
    reset();
  }

  /// Reset the animation to default state.
  void reset() {
    _sharedMedium = RenderableSharedMedium(BusSharedMedium(length: 250, speed: 1234));

    for (int i = 0; i < _peerCount; i++) {
      _sharedMedium.registerPeer(BusPeer());
    }
  }

  @override
  void ngOnInit() {}

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    context.strokeRect(0, 0, size.width, size.height);
  }

  int get canvasHeight => 500;
}
