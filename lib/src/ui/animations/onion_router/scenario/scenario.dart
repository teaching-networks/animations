/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';

abstract class Scenario {
  /// ID of the scenario.
  int get id;

  /// Name of the scenario.
  String get name;

  /// Get the Angular component factory for the scenario controls.
  ComponentFactory<ControlsComponent> get controlComponentFactory;
}
