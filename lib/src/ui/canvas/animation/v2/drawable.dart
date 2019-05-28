import 'dart:html';

import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/util/size.dart';

/// Next generation canvas animation class.
abstract class Drawable extends CanvasContextUtil {
  /// Id of the 2D canvas rendering context.
  static const _canvas2dRenderingContextId = "2d";

  /// Default width of the drawable.
  static const double _defaultWidth = 100;

  /// Default height of the drawable.
  static const double _defaultHeight = 150;

  /// Canvas where to cache rendered content until it needs to be refreshed.
  CanvasElement _cacheCanvas;

  /// Size of the cached canvas.
  Size _cacheCanvasSize;

  /// Context of the cached canvas.
  CanvasRenderingContext2D _cacheCanvasContext;

  /// Whether the drawable needs to repaint itself the next rendering cycle.
  bool _invalid = true;

  /// Timestamp of the last rendering loop pass.
  num _lastPassTimestamp;

  /// Create drawable.
  Drawable() {
    _init();
  }

  /// Initialize the canvas.
  void _init() {
    _cacheCanvas = CanvasElement();
    setSize();
    _cacheCanvasContext = _cacheCanvas.getContext(_canvas2dRenderingContextId);

    setUtilCanvasContext(_cacheCanvasContext);
  }

  /// Invalidate the drawable to repaint itself the next rendering cycle.
  void invalidate() {
    _invalid = true;
  }

  /// Validate the drawable.
  void _validate() {
    _invalid = false;
  }

  /// Whether the drawable needs to be repainted.
  bool get isInvalid => _invalid || needsRepaint();

  /// Get the drawables canvas rendering context.
  CanvasRenderingContext2D get ctx => _cacheCanvasContext;

  /// Render the drawable onto the passed canvas rendering [context].
  void render(
    CanvasRenderingContext2D context,
    num timestamp, {
    double x = 0,
    double y = 0,
  }) {
    _lastPassTimestamp = timestamp;
    update(timestamp);

    if (isInvalid) {
      // Repaint drawable
      _cacheCanvasContext.clearRect(0, 0, size.width, size.height);
      draw();

      _validate(); // Drawable has been redrawn and thus is valid again!
    }

    drawOnCanvas(context, _cacheCanvas, x, y);
  }

  /// Draw cached canvas on the passed [context].
  /// Override this method if you need to adjust the cache canvas image alignment
  /// (for example centering the image where [x] and [y] is in the center).
  void drawOnCanvas(CanvasRenderingContext2D context, CanvasImageSource src, double x, double y) {
    context.drawImage(_cacheCanvas, x, y);
  }

  /// Set the size of the drawable.
  void setSize({
    double width = _defaultWidth,
    double height = _defaultHeight,
  }) {
    if (_cacheCanvasSize == null || width != _cacheCanvasSize.width || height != _cacheCanvasSize.height) {
      _cacheCanvasSize = Size(width, height);

      _cacheCanvas.width = width.toInt();
      _cacheCanvas.height = height.toInt();

      invalidate();
    }
  }

  /// Get the drawables size.
  Size get size => _cacheCanvasSize;

  /// Get the timestamp of the last rendering loop pass.
  num get lastPassTimestamp => _lastPassTimestamp;

  /// Check if the drawable needs to be repainted.
  /// It will be repainted no matter what this method is stating in case you
  /// call [invalidate()].
  bool needsRepaint();

  /// Update the drawable state based on the passed [timestamp].
  /// NOTE: Also update child drawables in here!
  void update(num timestamp);

  /// Draw the things you need to draw!
  /// Use the provided canvas rendering context [ctx].
  /// You can check the drawable size by calling [getSize()].
  /// The current pass timestamp is available via [lastPassTimestamp].
  void draw();
}
