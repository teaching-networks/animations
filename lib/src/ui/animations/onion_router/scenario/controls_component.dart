import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';

/// Base class of a scenarios controls component.
abstract class ControlsComponent<T extends Scenario> {
  /// Set the scenario to control.
  void set scenario(T scenario);
}
