import 'dart:html';

import 'dart:math';

import 'package:netzwerke_animationen/src/ui/canvas/canvas_drawable.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/edges.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/size_type.dart';
import 'package:netzwerke_animationen/src/ui/canvas/util/colors.dart';
import 'package:netzwerke_animationen/src/ui/canvas/util/curves.dart';

class WindowSpaceDrawable extends CanvasDrawable {

  static const Duration MOVE_ANIMATION_DURATION = const Duration(milliseconds: 500);

  final RoundRectangle rectangle = new RoundRectangle(
      radiusSizeType: SizeType.PERCENT,
      radius: new Edges.all(0.2),
      color: Colors.CORAL,
      paintMode: PaintMode.STROKE,
      strokeWidth: 0.03
  );

  int _offset = 0;
  int _windowSize = 0;

  num _duration;
  num _startTimestamp;
  int _oldOffset;
  bool _animInProgress = false;

  WindowSpaceDrawable(this._windowSize);

  void draw(CanvasRenderingContext2D context, double slotWidth, double slotHeight, double slotMargin, num timestamp) {
    double padding = slotMargin;

    Point<double> current = new Point(_offset * slotWidth + slotMargin - padding, -padding);

    if (_animInProgress) {
      double progress = (timestamp - _startTimestamp) / _duration;

      // Transform progress.
      progress = min(1.0, Curves.easeInOutCubic(progress));

      if (progress == 1.0) {
        _animInProgress = false;
      }

      double xDiff = (_offset - _oldOffset).abs() * slotWidth * (1.0 - progress);

      current = new Point(current.x - xDiff, current.y);
    }

    double spaceWidth = _windowSize * slotWidth - 2 * slotMargin;

    render(context, new Rectangle.fromPoints(current, new Point(spaceWidth + padding * 2, slotHeight + padding * 2) + current));
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    rectangle.render(context, rect);
  }

  void setOffset(int newOffset) {
    if (newOffset != _offset) {
      if (!_animInProgress) {
        _oldOffset = _offset;
        _startTimestamp = window.performance.now();
        _duration = MOVE_ANIMATION_DURATION.inMilliseconds;
      } else {
        int diff = (_offset - newOffset).abs();
        _duration += MOVE_ANIMATION_DURATION.inMilliseconds + diff;
      }

      _offset = newOffset;

      _animInProgress = true;
    }
  }

}