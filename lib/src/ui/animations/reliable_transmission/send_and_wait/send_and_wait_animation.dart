import 'dart:html';
import 'dart:math';
import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_pipe.dart';
import 'package:netzwerke_animationen/src/services/i18n_service/i18n_service.dart';
import 'package:netzwerke_animationen/src/ui/animations/animation_descriptor.dart';
import 'package:netzwerke_animationen/src/ui/animations/reliable_transmission/transmission_window.dart';
import 'package:netzwerke_animationen/src/ui/canvas/animation/canvas_animation.dart';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_component.dart';

@Component(
  selector: "send-and-wait-animation",
  templateUrl: "send_and_wait_animation.html",
  styleUrls: const ["send_and_wait_animation.css"],
  directives: const [CORE_DIRECTIVES, materialDirectives, CanvasComponent],
  pipes: const [I18nPipe]
)
class SendAndWaitAnimation extends CanvasAnimation implements OnInit {

  /**
   * Descriptor for the animation.
   */
  static const AnimationDescriptor DESCRIPTOR = const AnimationDescriptor(SendAndWaitAnimation, "send-and-wait-animation.name", "img/image-preview.svg", "send-and-wait");

  I18nService _i18n;

  SendAndWaitAnimation(this._i18n);

  TransmissionWindow senderWindow = new TransmissionWindow();
  TransmissionWindow receiverWindow = new TransmissionWindow();

  @override
  ngOnInit() {

  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    context.textBaseline = "center";
    context.textAlign = "center";

    context.fillText("Yet to be implemented.", size.width / 2, size.height / 2);

    senderWindow.render(context, toRect(0.0, 0.0, size), timestamp);
    receiverWindow.render(context, toRect(0.0, 200.0, size), timestamp);
  }

}