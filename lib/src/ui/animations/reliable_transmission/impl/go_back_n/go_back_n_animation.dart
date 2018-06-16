import 'package:angular/angular.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/go_back_n_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/reliable_transmission_animation.dart';

@Component(
  selector: "go-back-n-animation",
  templateUrl: "go_back_n_animation.html",
  styleUrls: const ["go_back_n_animation.css"],
  directives: const [ReliableTransmissionAnimation]
)
class GoBackNAnimation {

  I18nService _i18n;
  ReliableTransmissionProtocol protocol;
  Message description;

  GoBackNAnimation(this._i18n) {
    protocol = new GoBackNProtocol(_i18n);
    description = _i18n.get("reliable-transmission-animation.protocol.go-back-n.description");
  }

}