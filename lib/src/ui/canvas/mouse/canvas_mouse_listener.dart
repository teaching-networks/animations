/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

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
