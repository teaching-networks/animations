/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular/core.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable_context.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/extension/mouse_listener.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/input/focus/focus_manager.dart';
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

  /// Drawable context that can be shared between multiple dependent drawables.
  MutableDrawableContext _mutableDrawableContext = MutableDrawableContext();

  /// The elements tab index used to make the element focusable.
  @HostBinding('tabindex')
  int tabIndex = 0;

  /// Manager managing focus inside the canvas.
  FocusManager _focusManager = FocusManager();

  /// Create viewer.
  DrawableViewer(
    this._cd,
  ) {
    _mutableDrawableContext.focusManager = _focusManager;
  }

  @override
  void ngOnDestroy() {
    _drawable.cleanup();
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

    _notifyDrawableContextChange();
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
    } else {
      window.requestAnimationFrame(_renderLoop);
    }
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

      _mutableDrawableContext.rootSize = size;
      _notifyDrawableContextChange();
    }
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    _onMouseDown(event, _drawable);
  }

  void _onMouseDown(CanvasMouseEvent event, Drawable parent) {
    if (parent is MouseListener) {
      (parent as MouseListener).onMouseDown(event);
    }

    if (parent.hasDependentDrawables) {
      for (Drawable drawable in parent.dependentDrawables) {
        _onMouseDown(event, drawable);
      }
    }

    event.event.preventDefault();
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
    _onMouseMove(event, _drawable);
  }

  void _onMouseMove(CanvasMouseEvent event, Drawable parent) {
    if (parent is MouseListener) {
      (parent as MouseListener).onMouseMove(event);
    }

    if (parent.hasDependentDrawables) {
      for (Drawable drawable in parent.dependentDrawables) {
        _onMouseMove(event, drawable);
      }
    }
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    _onMouseUp(event, _drawable);
  }

  void _onMouseUp(CanvasMouseEvent event, Drawable parent) {
    if (parent is MouseListener) {
      (parent as MouseListener).onMouseUp(event);
    }

    if (parent.hasDependentDrawables) {
      for (Drawable drawable in parent.dependentDrawables) {
        _onMouseUp(event, drawable);
      }
    }
  }

  /// Notify drawable of a drawable context change (root canvas size, ...).
  void _notifyDrawableContextChange() {
    if (_drawable != null) {
      _drawable.setDrawableContext(_mutableDrawableContext.getImmutableInstance());
    }
  }

  /// What should happen when the drawable viewer element is focused.
  @HostListener("focus")
  void onFocus(FocusEvent event) {
    _focusManager.onCanvasFocused();
  }

  /// What should happen when the drawable viewer loses focus.
  @HostListener("blur")
  void onBlur(FocusEvent event) {
    _focusManager.onCanvasBlurred();
  }

  /// On key down on the focused host element.
  @HostListener("keydown")
  void onKeyDown(KeyboardEvent event) {
    if (event.keyCode == 9) {
      // Tab key down
      event.preventDefault();

      if (event.shiftKey) {
        _focusManager.focusPrev();
      } else {
        _focusManager.focusNext();
      }
    }
  }
}
