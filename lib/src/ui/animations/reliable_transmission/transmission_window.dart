import 'dart:html';
import 'package:netzwerke_animationen/src/ui/canvas/canvas_drawable.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/edges.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/paint_mode.dart';
import 'package:netzwerke_animationen/src/ui/canvas/shapes/util/size_type.dart';
import 'package:netzwerke_animationen/src/ui/canvas/util/colors.dart';
import 'package:netzwerke_animationen/src/util/size.dart';

/**
 * Receive or Send window for reliable transmission.
 */
class TransmissionWindow extends CanvasDrawable {

  /**
   * Default length for the window array.
   */
  static const int DEFAULT_LENGTH = 20;

  /**
   * Default window size for the window.
   */
  static const int DEFAULT_WINDOW_SIZE = 1;

  /**
   * Actual length of the window array.
   */
  final int _length;

  /**
   * Actual size of the window.
   */
  final int _windowSize;

  /**
   * Place of a packet.
   */
  final RoundRectangle _packetPlaceRect = new RoundRectangle(radius: new Edges.all(0.2), radiusSizeType: SizeType.PERCENT, paintMode: PaintMode.FILL, color: Colors.LIGHTGREY);

  /**
   * Create new transmission window.
   */
  TransmissionWindow({
    int length = DEFAULT_LENGTH,
    int windowSize = DEFAULT_WINDOW_SIZE
  }) : _length = length,
        _windowSize = windowSize;

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, num timestamp) {
    double width = rect.width / _length;
    double height = rect.height;
    double padding = 5.0;

    context.setFillColorRgb(0, 0, 0);
    for (int i = 0; i < _length; i++) {
      Rectangle<double> r = new Rectangle(rect.left + i * width + padding, rect.top, width - padding * 2, height);

      _packetPlaceRect.render(context, r, timestamp);
    }
  }

}
