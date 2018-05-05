import 'dart:math';

import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_pipe.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/canvas/animation/canvas_animation.dart';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_component.dart';
import 'package:netzwerke_animationen/src/util/size.dart';

@Component(
  selector: "stop-and-wait-animation",
  templateUrl: "stop_and_wait_animation.html",
  styleUrls: const ["stop_and_wait_animation.css"],
  directives: const [coreDirectives, materialDirectives, CanvasComponent],
  pipes: const [I18nPipe]
)
class StopAndWaitAnimation extends CanvasAnimation implements OnInit, OnDestroy {

  I18nService _i18n;

  StopAndWaitAnimation(this._i18n);

  TransmissionWindow senderWindow = new TransmissionWindow();
  TransmissionWindow receiverWindow = new TransmissionWindow();

  String _senderLabel;
  String _receiverLabel;

  LanguageChangedListener _languageChangedListener;

  @override
  ngOnInit() {
    _initTranslations();

    _languageChangedListener = (newLocale) {
      _initTranslations(); // Refresh translations
    };

    _i18n.addLanguageChangedListener(_languageChangedListener);
  }

  @override
  ngOnDestroy() {
    // Deregister language changed listener
    _i18n.removeLanguageChangedListener(_languageChangedListener);
  }

  void _initTranslations() {
    _senderLabel = _i18n.get("stop-and-wait-animation.sender").toString() + ":";
    _receiverLabel = _i18n.get("stop-and-wait-animation.receiver").toString() + ":";
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    context.textBaseline = "middle";
    context.textAlign = "right";

    double maxLabelWidth = max(context.measureText(_senderLabel).width, context.measureText(_receiverLabel).width);

    Size windowSize = new Size(size.width - maxLabelWidth, size.height / 10);

    // Draw sender and receiver labels
    context.setFillColorRgb(0, 0, 0);
    context.fillText(_senderLabel, maxLabelWidth, windowSize.height / 2);
    context.fillText(_receiverLabel, maxLabelWidth, size.height - windowSize.height / 2);

    // Draw sender window
    senderWindow.render(context, toRect(maxLabelWidth, 0.0, windowSize), timestamp);

    // Draw receiver window
    receiverWindow.render(context, toRect(maxLabelWidth, size.height - windowSize.height, windowSize), timestamp);

    // Draw packets
  }

}