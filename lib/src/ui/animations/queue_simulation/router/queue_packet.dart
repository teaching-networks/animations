/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';

class QueuePacket extends CanvasDrawable {

  final Color color;

  QueuePacket(this.color);

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();

    {
      setFillColor(context, color);
      context.fillRect(rect.left, rect.top, rect.width, rect.height);
    }

    context.restore();
  }

}
