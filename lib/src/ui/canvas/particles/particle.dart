import 'dart:html';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';

abstract class Particle extends CanvasDrawable {
  /// Whether the particle is currently visible or
  /// already dead.
  bool _alive = false;

  /// Initialize the particle start.
  /// Could also be used as a reset of the particle.
  void init() {
    _alive = true;
  }

  /// Draw the current particle state.
  void draw(CanvasRenderingContext2D context, num timestamp);

  /// What to do when the particle is dead.
  void onDead();

  /// Kill the particle.
  /// This might be done because the particle cannot be seen by the user anymore.
  void kill() {
    _alive = false;
    onDead();
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (_alive) {
      this.draw(context, timestamp);
    }
  }
}
