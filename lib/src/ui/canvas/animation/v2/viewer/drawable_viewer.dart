import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/mouse/canvas_mouse_listener.dart';
import 'package:hm_animations/src/util/size.dart';

/// Viewer for drawables (objects of class Drawable).
@Component(
  selector: "drawable-viewer",
  templateUrl: "drawable_viewer.html",
  styleUrls: ["drawable_viewer.css"],
  changeDetection: ChangeDetectionStrategy.OnPush,
  directives: [
    coreDirectives,
    CanvasComponent,
  ],
)
class DrawableViewer extends CanvasContextUtil implements CanvasMouseListener, OnDestroy {
  /// Default height of the drawable viewer.
  static const int _defaultHeight = 500;

  /// Change detector reference.
  final ChangeDetectorRef _cd;

  /// Drawable to display.
  Drawable _drawable;

  /// Height of the viewer.
  int _height = _defaultHeight;

  /// Current context to draw on the canvas.
  CanvasRenderingContext2D _ctx;

  /// Current size of the canvas to draw on.
  Size _size;

  /// Whether to kill the rendering loop.
  bool _killRenderingLoop = false;

  /// Controller emitting event when the rendering loop is killed.
  StreamController<void> _loopKilledController;

  /// Create viewer.
  DrawableViewer(
    this._cd,
  );

  @override
  void ngOnDestroy() {
    _killRenderLoop();
  }

  @Input()
  set drawable(Drawable value) {
    _drawable = value;

    if (_size != null) {
      _drawable.setSize(
        width: _size.width,
        height: _size.height,
      );
    }

    _drawable.invalidate();
  }

  @Input()
  set height(int value) {
    _height = value;

    _cd.markForCheck();
  }

  int get height => _height;

  /// Start the rendering loop.
  void _startRenderLoop() {
    window.requestAnimationFrame(_renderLoop);
  }

  /// Kill the current rendering loop.
  /// The returned future is resolved when the rendering loop has been killed.
  Future<void> _killRenderLoop() {
    _killRenderingLoop = true;

    _loopKilledController = StreamController<void>(sync: true);
    return _loopKilledController.stream.first.then((_) async {
      await _loopKilledController.close();
      _loopKilledController = null;
    });
  }

  /// Rendering loop of the drawable viewer.
  void _renderLoop(num timestamp) {
    _initRenderIterationContext(_ctx);

    if (_drawable != null) {
      _drawable.render(_ctx, timestamp);
    }

    if (_killRenderingLoop) {
      _killRenderingLoop = false;
      _loopKilledController.add(null);
    }

    window.requestAnimationFrame(_renderLoop);
  }

  /// Initialize the context for a rendering iteration.
  void _initRenderIterationContext(CanvasRenderingContext2D ctx) {
    ctx.font = "${defaultFontSize}px 'Roboto'";

    ctx.clearRect(0, 0, _size.width, _size.height);
  }

  void onCanvasReady(CanvasRenderingContext2D context) {
    _ctx = context;

    _startRenderLoop();
  }

  void onCanvasResize(Size size) {
    _size = size;

    if (_drawable != null) {
      _drawable.setSize(
        width: _size.width,
        height: _size.height,
      );
    }
  }

  @override
  void onMouseDown(Point<double> pos) {
    if (_drawable is MouseListener) {
      (_drawable as MouseListener).onMouseDown(pos);
    }
  }

  @override
  void onMouseMove(Point<double> pos) {
    if (_drawable is MouseListener) {
      (_drawable as MouseListener).onMouseMove(pos);
    }
  }

  @override
  void onMouseUp(Point<double> pos) {
    if (_drawable is MouseListener) {
      (_drawable as MouseListener).onMouseUp(pos);
    }
  }
}
