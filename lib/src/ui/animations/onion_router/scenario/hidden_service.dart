import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/canvas/animation/repaintable.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';

/// Scenario where the service is routed only within the onion network.
class HiddenService extends CanvasDrawable with Repaintable implements Scenario {
  @override
  int get id => 2;

  @override
  String get name => "Versteckter Dienst";

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (!needsRepaint) {
      return;
    }

    validate();
  }

  @override
  String toString() {
    return name;
  }
}
