import 'package:angular/angular.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';

@Component(
  selector: "hidden-service-controls",
  templateUrl: "hidden_service_controls_component.html",
  styleUrls: ["hidden_service_controls_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
  ],
  pipes: [
    I18nPipe,
  ],
)
class HiddenServiceControlsComponent implements ControlsComponent {
  @override
  void set scenario(Scenario scenario) {
    // TODO: implement scenario
  }
}
