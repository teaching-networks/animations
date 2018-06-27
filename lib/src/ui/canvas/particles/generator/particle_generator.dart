import 'dart:html';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';

abstract class ParticleGenerator extends CanvasDrawable {

  /// Start generating.
  void start();

  /// Draw the particles.
  void draw(CanvasRenderingContext2D context, num timestamp);

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    draw(context, timestamp);
  }

}