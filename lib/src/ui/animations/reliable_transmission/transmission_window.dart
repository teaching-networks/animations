import 'dart:html';
import 'package:netzwerke_animationen/src/ui/canvas/animation/canvas_drawable.dart';
import 'package:netzwerke_animationen/src/util/size.dart';

class TransmissionWindow extends CanvasDrawable {

  static const int DEFAULT_LENGTH = 20;
  static const int DEFAULT_WINDOW_SIZE = 1;

  final int _length;
  final int _windowSize;

  TransmissionWindow({
    int length = DEFAULT_LENGTH,
    int windowSize = DEFAULT_WINDOW_SIZE
  }) : _length = length,
        _windowSize = windowSize;

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, num timestamp) {
    double width = rect.width / _length;
    double height = rect.height / 10;
    double padding = 5.0;

    context.setFillColorRgb(0, 0, 0);
    for (int i = 0; i < _length; i++) {
      context.fillRect(rect.left + i * width + padding, rect.top + padding, width - padding * 2, height);
    }
  }

}
