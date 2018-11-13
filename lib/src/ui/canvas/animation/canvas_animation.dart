import 'dart:html';
import 'dart:math';
import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/canvas/canvas_context_base.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';

/**
 * Abstract class for animations using the canvas component.
 *
 * So when using the canvas component in another component inherit this class
 * to easily use the canvas component.
 *
 * Bind in your component to make it work:
 * <canvas-comp (onResized)="onCanvasResize($event)" (onReady)="onCanvasReady($event)"></canvas-comp>
 */
abstract class CanvasAnimation extends CanvasContextBase implements OnDestroy {

  /**
   * Whether to show FPS for development.
   */
  static const bool SHOW_FPS = true;

  /**
   * Draw fps every FPS_MILLIS milliseconds.
   */
  static const int FPS_MILLIS = 200;

  /**
   * FPS font color.
   */
  static const Color FPS_FONT_COLOR = Colors.WHITE;

  /**
   * FPS background color.
   */
  static const Color FPS_BG_COLOR = const Color.rgba(255, 102, 102, 0.5);

  /**
   * When the Fps have been drawn last.
   */
  num _lastFpsDraw = -1;

  /**
   * Fps to render.
   */
  int _renderFps = 0;

  CanvasRenderingContext2D context;
  Size size;

  /// Display unit can be used to get a unit dependend on the actual size of the canvas (in pixel).
  /// It is always one percent of the median of width and height.
  double displayUnit = 0.0;

  num _lastTimestamp = -1;
  int fps = 0;

  /**
   * Set this to true when the rendering loop should be killed.
   */
  bool _killLoop = false;

  /**
   * Background rectangle of the fps counter.
   */
  RoundRectangle _fpsBackgroundRectangle = new RoundRectangle(color: FPS_BG_COLOR, radius: new Edges.all(0.2));

  /**
   * Executed when the canvas component is ready to be drawn at.
   * Starts the render loop.
   */
  void onCanvasReady(CanvasRenderingContext2D context) {
    this.context = context;

    window.requestAnimationFrame(_renderLoop);
  }

  int i = 0;

  /**
   * Simple rendering loop which renders and starts over again.
   */
  void _renderLoop(num timestamp) {
    _initContextForIteration(context);

    render(timestamp);

    if (SHOW_FPS && _lastTimestamp != -1) {
      timestamp = window.performance.now();
      double delta = (timestamp - _lastTimestamp) / 1000;
      fps = (1 / delta).round();

      // Only render fps every few millis to avoid confusion.
      if (_lastFpsDraw == -1 || timestamp >= (_lastFpsDraw + FPS_MILLIS)) {
        _lastFpsDraw = timestamp;
        _renderFps = fps;
      }

      renderFps(_renderFps);
    }

    _lastTimestamp = timestamp;

    if (!_killLoop) {
      window.requestAnimationFrame(_renderLoop);
    }
  }

  /**
   * Render Fps to canvas.
   */
  void renderFps(int fps) {
    context.save();

    context.textBaseline = "middle";
    context.textAlign = "center";

    String fpsLabel = "Fps: $fps";

    TextMetrics textMetrics = context.measureText(fpsLabel);

    double width = textMetrics.width * 1.5;
    double height = defaultFontSize * 1.3;

    context.translate(size.width - width, size.height - height);

    _fpsBackgroundRectangle.render(context, new Rectangle<double>(0.0, 0.0, width, height));

    context.setFillColorRgb(FPS_FONT_COLOR.red, FPS_FONT_COLOR.green, FPS_FONT_COLOR.blue);
    context.fillText("Fps: $fps", width / 2, height / 2);

    context.restore();
  }

  /**
   * Render your graphics on the canvas.
   */
  void render(num timestamp);

  /**
   * Callback called when the canvas component is resized.
   */
  void onCanvasResize(Size newSize) {
    size = newSize;

    _recalculateDisplayUnit(newSize);
  }

  /// Calculate display unit which is always one percent of the median of width and height of the canvas.
  void _recalculateDisplayUnit(Size newSize) {
    displayUnit = max((newSize.width + newSize.height).toDouble() / 2 / 100, 0.0);
  }

  /**
   * Visible getter so that the last timestamp cannot be altered
   * by extending classes.
   */
  num get lastTimestamp {
    return _lastTimestamp;
  }

  /**
   * Get rectangle.
   */
  Rectangle<double> toRect(double left, double top, Size size) {
    return new Rectangle(left, top, size.width, size.height);
  }

  /**
   * Initialize context for each iteration.
   * You can make adjustments here in case they can only be made before each render cyclus.
   */
  void _initContextForIteration(CanvasRenderingContext2D context) {
    context.font = "${defaultFontSize}px 'Roboto'";
  }

  /// Set the font for the canvas.
  /// Font size is set using [sizeFactor] where 1.0 is the [defaultFontSize].
  /// Font Family is set using [fontFamily] where "sans-serif" is the default font family.
  void setFont({
    double sizeFactor = 1.0,
    String fontFamily = "sans-serif"
  }) {
    context.font = "${defaultFontSize * sizeFactor}px $fontFamily";
  }

  /// Get the windows height.
  int get windowHeight => window.innerHeight;

  @override
  ngOnDestroy() {
    // Stop rendering loop.
    _killLoop = true;
  }
}
