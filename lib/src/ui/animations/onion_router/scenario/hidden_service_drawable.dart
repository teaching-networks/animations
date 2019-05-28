import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';

/// Scenario where the service is routed only within the onion network.
class HiddenServiceDrawable extends Drawable implements Scenario {
  /// Create service.
  HiddenServiceDrawable();

  @override
  int get id => 2;

  @override
  String get name => "Versteckter Dienst";

  @override
  String toString() => name;

  @override
  void draw() {
    // TODO: implement draw
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // TODO: implement update
  }
}
