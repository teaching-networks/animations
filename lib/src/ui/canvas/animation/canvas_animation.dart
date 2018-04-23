import 'dart:html';
import 'package:netzwerke_animationen/src/util/size.dart';

/**
 * Abstract class for animations using the canvas component.
 *
 * So when using the canvas component in another component inherit this class
 * to easily use the canvas component.
 *
 * Bind in your component to make it work:
 * <canvas-comp (onResized)="onCanvasResize($event)" (onReady)="onCanvasReady($event)"></canvas-comp>
 */
abstract class CanvasAnimation {

  /**
   * Whether to show FPS for development.
   */
  static const bool SHOW_FPS = true;

  /**
   * Draw fps every FPS_MILLIS milliseconds.
   */
  static const int FPS_MILLIS = 200;

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

  num _lastTimestamp = -1;
  int fps = 0;

  /**
   * Executed when the canvas component is ready to be drawn at.
   * Starts the render loop.
   */
  void onCanvasReady(CanvasRenderingContext2D context) {
    this.context = context;

    window.requestAnimationFrame(_renderLoop);
  }

  /**
   * Simple rendering loop which renders and starts over again.
   */
  void _renderLoop(num timestamp) {
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

    window.requestAnimationFrame(_renderLoop);
  }

  /**
   * Render Fps to canvas.
   */
  void renderFps(int fps) {
    context.textBaseline = "bottom";
    context.font = "2.0em 'Roboto'";
    context.textAlign = "end";
    context.setFillColorRgb(255, 102, 102);
    context.fillText("Fps: $fps", size.width, size.height);
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

}