import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/selective_repeat_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/reliable_transmission_animation.dart';

@Component(
    selector: "selective-repeat-animation",
    templateUrl: "selective_repeat_animation.html",
    styleUrls: const ["selective_repeat_animation.css"],
    directives: const [ReliableTransmissionAnimation]
)
class SelectiveRepeatAnimation with AnimationUI {

  I18nService _i18n;
  ReliableTransmissionProtocol protocol;

  SelectiveRepeatAnimation(this._i18n) {
    protocol = new SelectiveRepeatProtocol(_i18n);
  }

}