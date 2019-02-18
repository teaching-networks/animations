import 'dart:math';

/// Mouse listener handling events on a canvas.
abstract class CanvasMouseListener {
  /// What to do on a mouse down event.
  void onMouseDown(Point<double> pos);

  /// What to do on a mouse up event.
  void onMouseUp(Point<double> pos);

  /// What to do on a mouse move event.
  void onMouseMove(Point<double> pos);
}
