/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';

class LocationDot extends CanvasDrawable {

  static final double MAX_BRIGHTNESS_FACTOR = 0.4;

  Duration duration;
  Color color;
  double growFactor;

  num _time;
  bool _grow = true;

  LocationDot({
    this.duration = const Duration(seconds: 1),
    this.color = Colors.RED,
    this.growFactor = 0.2
  });

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    double progress = Curves.easeInOutCubic(_getProgress(timestamp));

    Color c = Color.brighten(color, MAX_BRIGHTNESS_FACTOR * progress);
    double size = max(rect.width + (rect.width * growFactor * progress), 0.0);

    context.save();

    {
      context.translate(rect.left, rect.top);
      setFillColor(context, c);

      context.beginPath();
      context.arc(0, 0, size, 0, 2 * pi);
      context.fill();
    }

    context.restore();
  }

  double _getProgress(num timestamp) {
    if (_time == null) {
      _time = _getTime(timestamp);
    }

    double progress = 0.0;
    if (_grow) {
      progress = (timestamp - _time) / duration.inMilliseconds;
    } else {
      progress = (_time - timestamp) / duration.inMilliseconds;
    }

    if (progress <= 0.0 || progress >= 1.0) { // Switch animation direction
      _grow = !_grow;
      _time = _getTime(timestamp);
    }

    return progress;
  }

  /// Get start or end time of the animation based on the _grow flag.
  double _getTime(num timestamp) => _grow ? timestamp : timestamp + duration.inMilliseconds;

}
