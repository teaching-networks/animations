import 'package:angular/angular.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/go_back_n_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/reliable_transmission_animation.dart';

@Component(
  selector: "go-back-n-animation",
  templateUrl: "go_back_n_animation.html",
  styleUrls: ["go_back_n_animation.css"],
  directives: [ReliableTransmissionAnimation, MaterialToggleComponent],
  pipes: [I18nPipe]
)
class GoBackNAnimation with AnimationUI {

  I18nService _i18n;
  GoBackNProtocol protocol;

  GoBackNAnimation(this._i18n) {
    protocol = new GoBackNProtocol(_i18n);
  }

}