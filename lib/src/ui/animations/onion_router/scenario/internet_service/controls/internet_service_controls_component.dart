/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:angular_components/material_toggle/material_toggle.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/internet_service/internet_service_drawable.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/util/str/message.dart';

@Component(
  selector: "internet-service-controls",
  templateUrl: "internet_service_controls_component.html",
  styleUrls: ["internet_service_controls_component.css"],
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
class InternetServiceControlsComponent implements ControlsComponent, OnInit, OnDestroy {
  final ChangeDetectorRef _cd;
  final I18nService _i18n;

  /// The scenario to control.
  InternetServiceDrawable _scenario;

  int currentRouteLength = 3;

  bool showHelpBubbles = true;

  IdMessage<String> _showHelpMsg;
  IdMessage<String> _skipAuto;

  LanguageLoadedListener _languageLoadedListener;

  InternetServiceControlsComponent(this._cd, this._i18n);

  @override
  void ngOnInit() {
    _showHelpMsg = _i18n.get("onion-router.show-help");
    _skipAuto = _i18n.get("onion-router.auto-advance");

    _languageLoadedListener = (_) => _cd.markForCheck();
    _i18n.addLanguageLoadedListener(_languageLoadedListener);
  }

  @override
  void ngOnDestroy() {
    _i18n.removeLanguageLoadedListener(_languageLoadedListener);
  }

  @override
  void set scenario(Scenario scenario) {
    if (!(scenario is InternetServiceDrawable)) {
      throw Exception("Internet Service controls component needs the Internet Service Scenario");
    }

    _scenario = scenario;
  }

  bool get hasScenario => _scenario != null;

  /// Start the scenario animation.
  void start() {
    _scenario.start(showHelpBubbles);
  }

  // Find a new route in the onion router network.
  void reroute() {
    _scenario.reroute(
      routeLength: currentRouteLength,
      withAnimation: true,
    );
  }

  int get minRouteLength => _scenario.minRouteLength;

  int get maxRouteLength => _scenario.maxRouteLength;

  void changeRouteLength(int newRouteLength) {
    currentRouteLength = newRouteLength;
    _scenario.reroute(routeLength: newRouteLength);
  }

  bool get autoSkipBubbles => _scenario.autoSkipBubbles;

  set autoSkipBubbles(bool value) {
    _scenario.autoSkipBubbles = value;
  }

  String get showHelpMsg => _showHelpMsg.toString();
  String get skipAuto => _skipAuto.toString();
}
