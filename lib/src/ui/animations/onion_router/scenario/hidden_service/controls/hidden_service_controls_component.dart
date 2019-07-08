import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/hidden_service/hidden_service_drawable.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';

@Component(
  selector: "hidden-service-controls",
  templateUrl: "hidden_service_controls_component.html",
  styleUrls: ["hidden_service_controls_component.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    MaterialButtonComponent,
    MaterialSliderComponent,
    MaterialIconComponent,
    MaterialToggleComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class HiddenServiceControlsComponent implements ControlsComponent {
  HiddenServiceDrawable _scenario;

  bool showHelpBubbles = true;

  @override
  void set scenario(Scenario scenario) {
    if (!(scenario is HiddenServiceDrawable)) {
      throw Exception("Hidden service controls component needs the Hidden Service Scenario");
    }

    _scenario = scenario;
  }

  bool get hasScenario => _scenario != null;

  void start() {
    _scenario.start(showHelpBubbles);
  }

  void test() {
    _scenario.test();
  }

  bool get autoSkipBubbles => _scenario.autoSkipBubbles;

  set autoSkipBubbles(bool value) {
    _scenario.autoSkipBubbles = value;
  }
}
