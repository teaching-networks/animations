import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/drawable_shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/bus_shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/peer/bus_medium_peer.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/util/size.dart';

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
  DrawableSharedMedium _sharedMedium;

  /// Create animation.
  CSMACDAnimation(this._i18n) {
    reset();
  }

  /// Reset the animation to default state.
  void reset() {
    final busSharedMedium = BusSharedMedium(length: 250, speed: 1234);

    for (int i = 0; i < _peerCount; i++) {
      busSharedMedium.registerPeer(BusPeer());
    }

    _sharedMedium = DrawableSharedMedium(medium: busSharedMedium);
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

    double mediumSizeFactor = 0.9;
    double yOffset = size.height * ((1 - mediumSizeFactor) / 2);

    _sharedMedium.render(context, toRect(yOffset, yOffset, Size(size.width - yOffset, size.height * mediumSizeFactor)), timestamp);
  }

  int get canvasHeight => 500;
}
