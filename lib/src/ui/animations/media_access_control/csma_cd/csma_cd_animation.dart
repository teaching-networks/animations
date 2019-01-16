import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_input/material_auto_suggest_input.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/drawable_shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/medium/bus_shared_medium.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/csma_cd/drawable/drawable_shared_medium_peer.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';

/// Animation showing the CSMA/CD media-access-control protocol.
@Component(
  selector: "csma-cd-animation",
  styleUrls: [
    "csma_cd_animation.css",
  ],
  templateUrl: "csma_cd_animation.html",
  directives: [
    coreDirectives,
    CanvasComponent,
    MaterialAutoSuggestInputComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class CSMACDAnimation extends CanvasAnimation implements OnInit, OnDestroy {
  /// Peers to display in the animation.
  static const int _peerCount = 3;

  /// Suggestions for medium lengths in meter.
  static const List<int> _mediumLengthSuggestions = [
    1,
    5,
    10,
    50,
    100,
    250,
    500,
    1000,
    2500,
    5000,
    10000,
  ];
  static int _defaultMediumLengthSuggestion = _mediumLengthSuggestions[8];

  /// Suggestions for the signal size in bits.
  static const List<int> _signalSizeSuggestions = [
    50,
    100,
    250,
    500,
    1000,
    2500,
    5000,
    10000,
  ];
  static int _defaultSignalSizeSuggestion = _signalSizeSuggestions[3];

  /// Suggestions for the bandwidth in mega bit per second.
  static const List<int> _bandwidthSuggestions = [
    1,
    2,
    5,
    10,
    20,
    50,
    100,
    1000,
  ];
  static int _defaultBandwidthSuggestion = _bandwidthSuggestions[3];

  /// Service to retrieve translations with.
  I18nService _i18n;

  /// Shared medium used to simulate CSMA/CD.
  DrawableSharedMedium _sharedMedium;

  String selectedMediumLength = _defaultMediumLengthSuggestion.toString();
  String selectedBandwidth = _defaultBandwidthSuggestion.toString();
  String selectedSignalSize = _defaultSignalSizeSuggestion.toString();

  /// Create animation.
  CSMACDAnimation(this._i18n);

  @override
  void ngOnInit() {
    reset();
  }

  @override
  ngOnDestroy() {
    super.ngOnDestroy();
  }

  /// Reset the animation to default state.
  void reset() {
    int mediumLength = int.tryParse(selectedMediumLength) ?? _defaultMediumLengthSuggestion;
    int signalSize = int.tryParse(selectedSignalSize) ?? _defaultSignalSizeSuggestion;
    int bandwidth = int.tryParse(selectedBandwidth) ?? _defaultBandwidthSuggestion;

    // Apply new values to selected values in case the parsing failed.
    selectedMediumLength = mediumLength.toString();
    selectedSignalSize = signalSize.toString();
    selectedBandwidth = bandwidth.toString();

    final busSharedMedium = BusSharedMedium(
      length: mediumLength.toDouble(),
      speed: 2.0 * pow(10, 8),
    );

    double offset = 1.0 / (_peerCount - 1);

    _sharedMedium = DrawableSharedMedium(
      medium: busSharedMedium,
      bandwidth: bandwidth * 1000 * 1000,
      signalSize: signalSize,
      labelMap: {
        "time": _i18n.get("csma-cd-animation.time"),
        "busy-channel": _i18n.get("csma-cd-animation.peer.state.busy-channel"),
        "transmitting": _i18n.get("csma-cd-animation.peer.state.transmitting"),
      },
    );

    for (int i = 0; i < _peerCount; i++) {
      busSharedMedium.registerPeer(DrawableSharedMediumPeer(
        id: i,
        position: i * offset,
        medium: _sharedMedium,
        labelMap: {
          "exponential-backoff": _i18n.get("csma-cd-animation.peer.state.exponential-backoff"),
          "collisions": _i18n.get("csma-cd-animation.peer.state.exponential-backoff.collisions"),
        },
      ));
    }
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    _sharedMedium.render(context, toRect(0, 0, size), timestamp);

    afterRender();
  }

  void afterRender() {
    _sharedMedium.afterRender();
  }

  /// What to do on mouse up on the canvas.
  void onMouseUp(Point<double> pos) {
    _sharedMedium.onMouseUp(pos);
  }

  /// What to do on mouse move on the canvas.
  void onMouseMove(Point<double> pos) {
    _sharedMedium.onMouseMove(pos);
  }

  int get canvasHeight => 650;

  List<int> get bandwidthSuggestions => _bandwidthSuggestions;

  List<int> get signalSizeSuggestions => _signalSizeSuggestions;

  List<int> get mediumLengthSuggestions => _mediumLengthSuggestions;
}
