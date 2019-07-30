/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';

/// Base class of a scenarios controls component.
abstract class ControlsComponent<T extends Scenario> {
  /// Set the scenario to control.
  void set scenario(T scenario);
}
