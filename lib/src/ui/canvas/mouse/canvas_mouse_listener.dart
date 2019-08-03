/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'package:hm_animations/src/ui/canvas/canvas_component.dart';

/// Mouse listener handling events on a canvas.
abstract class CanvasMouseListener {
  /// What to do on a mouse down event.
  void onMouseDown(CanvasMouseEvent event);

  /// What to do on a mouse up event.
  void onMouseUp(CanvasMouseEvent event);

  /// What to do on a mouse move event.
  void onMouseMove(CanvasMouseEvent event);
}
