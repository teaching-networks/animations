import 'package:angular/angular.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/selective_repeat_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/reliable_transmission_animation.dart';

@Component(
    selector: "selective-repeat-animation",
    templateUrl: "selective_repeat_animation.html",
    styleUrls: const ["selective_repeat_animation.css"],
    directives: const [ReliableTransmissionAnimation]
)
class SelectiveRepeatAnimation {

  I18nService _i18n;
  ReliableTransmissionProtocol protocol;
  Message description;

  SelectiveRepeatAnimation(this._i18n) {
    protocol = new SelectiveRepeatProtocol(_i18n);
    description = _i18n.get("reliable-transmission-animation.protocol.selective-repeat.description");
  }

}