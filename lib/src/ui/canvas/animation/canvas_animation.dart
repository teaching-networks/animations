/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:hm_animations/src/ui/canvas/canvas_context_base.dart';
import 'package:hm_animations/src/ui/canvas/shapes/round_rectangle.dart';
import 'package:hm_animations/src/ui/canvas/shapes/util/edges.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/debug.dart';
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
  /// Draw fps every FPS_MILLIS milliseconds.
  static const int _fpsMillis = 200;

  /**
   * FPS font color.
   */
  static const Color _fpsFontColor = Colors.WHITE;

  /**
   * FPS background color.
   */
  static const Color FPS_BG_COLOR = const Color.rgba(255, 102, 102, 0.5);

  /**
   * Fps to render.
   */
  int _renderFps = 0;

  CanvasRenderingContext2D context;
  Size size;

  /// Display unit can be used to get a unit dependend on the actual size of the canvas (in pixel).
  /// It is always one percent of the median of width and height.
  double displayUnit = 0.0;

  /// Counter counts rendered frames of the last [_fpsMillis] milliseconds.
  int _frameCounter = 0;

  /// Start timestamp of counting rendered frames.
  num _frameCounterStartTS;

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

    preRender(timestamp);
    render(timestamp);

    bool showFps = Debug.isDebugMode;
    if (showFps) {
      _frameCounter++;

      if (_needToRenderFPS(timestamp)) {
        _renderFps = _frameCounter * 1000 ~/ _fpsMillis;

        _frameCounterStartTS = timestamp;
        _frameCounter = 0;
      }

      renderFps(_renderFps);
    }

    if (!_killLoop) {
      window.requestAnimationFrame(_renderLoop);
    }
  }

  /// Check whether the FPS need to be rendered.
  bool _needToRenderFPS(num curTS) => _frameCounterStartTS == null || curTS - _frameCounterStartTS >= _fpsMillis;

  /**
   * Render Fps to canvas.
   */
  void renderFps(int fps) {
    context.save();

    context.textBaseline = "middle";
    context.textAlign = "center";

    String fpsLabel = "$fps";

    TextMetrics textMetrics = context.measureText(fpsLabel);

    double width = textMetrics.width * 1.5;
    double height = defaultFontSize * 1.3;

    context.translate(size.width - width, size.height - height);

    _fpsBackgroundRectangle.render(context, new Rectangle<double>(0.0, 0.0, width, height));

    setFillColor(context, _fpsFontColor);
    context.fillText(fpsLabel, width / 2, height / 2);

    context.restore();
  }

  /// Called before rendering.
  void preRender(num timestamp) {
    // Do nothing.
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
  void setFont({double sizeFactor = 1.0, String fontFamily = "sans-serif"}) {
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
