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

  CanvasRenderingContext2D context;
  Size size;

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

    window.requestAnimationFrame(_renderLoop);
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

}