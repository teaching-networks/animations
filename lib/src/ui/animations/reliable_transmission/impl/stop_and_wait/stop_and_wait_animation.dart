/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/reliable_transmission_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/protocols/stop_and_wait_protocol.dart';
import 'package:hm_animations/src/ui/animations/reliable_transmission/reliable_transmission_animation.dart';

@Component(
    selector: "stop-and-wait-animation",
    templateUrl: "stop_and_wait_animation.html",
    styleUrls: const ["stop_and_wait_animation.css"],
    directives: const [ReliableTransmissionAnimation]
)
class StopAndWaitAnimation with AnimationUI {

  I18nService _i18n;
  ReliableTransmissionProtocol protocol;

  StopAndWaitAnimation(this._i18n) {
    protocol = new StopAndWaitProtocol(_i18n);
  }

}
