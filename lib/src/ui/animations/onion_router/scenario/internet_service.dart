import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/onion_router/animation_controller.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';

/// Scenario  where the server to contact is routed in the "normal" internet.
class InternetService extends CanvasDrawable implements Scenario {
  final AnimationController _controller;

  /// Create scenario.
  InternetService(this._controller);

  @override
  int get id => 1;

  @override
  String get name => "Dienst im Internet geroutet";

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    // TODO: implement render
  }

  @override
  String toString() {
    return name;
  }
}
