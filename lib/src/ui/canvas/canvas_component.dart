/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';

import "package:angular/angular.dart";
import 'package:hm_animations/src/util/size.dart';

/**
 * Canvas component a component enclosing a canvas which you can draw on.
 *
 * It provides canvas resizing and access to its canvas.
 *
 * Additionally the canvas component is able to resize it self to fit HiDPI
 * Screens. More over on HiDPI Screens (Like smartphones commonly have) the canvas is resized by the browser
 * which leads to unsharp graphics. To fix this the canvas component utilizes the window.deviceAspectRatio property
 * to properly scale the canvas content while setting the width and height css properties to the unscaled width and height.
 */
@Component(
  selector: "canvas-comp",
  templateUrl: "canvas_component.html",
  styleUrls: ["canvas_component.css"],
  directives: [
    coreDirectives,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class CanvasComponent implements OnInit, OnDestroy, CanvasComponentControl {
  /// Change detector reference.
  final ChangeDetectorRef _cd;

  @ViewChild("canvasWrapper", read: HtmlElement)
  HtmlElement canvasWrapper;

  @ViewChild("canvas", read: HtmlElement)
  HtmlElement canvas;

  /**
   * Stream controller emitting events when the canvas is resized.
   */
  final _sizeChangedController = new StreamController<Size>.broadcast();

  /**
   * Stream controller emitting events when the canvas is ready to be drawn on.
   */
  final _readyController = new StreamController<CanvasRenderingContext2D>.broadcast();

  /**
   * Stream controller emitting mouse click events on the canvas.
   */
  final _clickController = new StreamController<Point<double>>.broadcast();

  /// Stream controller emitting mouse move events on the canvas.
  final _mouseDownController = new StreamController<CanvasMouseEvent>.broadcast();

  /// Stream controller emitting mouse up events on the canvas.
  final _mouseUpController = new StreamController<CanvasMouseEvent>.broadcast();

  /// Stream controller emitting mouse moved events on the canvas.
  final _mouseMoveController = new StreamController<CanvasMouseEvent>.broadcast();

  /*
  Width and height of the canvas.
   */
  int _width = 0;
  int _height = 100;

  /// Custom aspect ratio to calculate the canvas height from if set.
  double _aspectRatio = null;

  /*
  Whether the x and y axis are resized automatically when the window size changes.
  This is deactivated by setting a value manually.
   */
  bool _resizeX = true;
  bool _resizeY = true;

  StreamSubscription<MouseEvent> _clickSub;
  StreamSubscription<MouseEvent> _mouseDownSub;
  StreamSubscription<MouseEvent> _mouseUpSub;
  StreamSubscription<MouseEvent> _mouseMoveSub;

  StreamSubscription<Size> _sizeChangedSub;

  /// Cursor type to show.
  String _cursorType = "auto";

  /// Create the component.
  CanvasComponent(this._cd);

  @override
  ngOnInit() {
    CanvasElement canvasElement = canvas as CanvasElement;

    // Get canvas rendering context used to draw on the canvas.
    CanvasRenderingContext2D context = canvasElement.getContext("2d");

    _clickSub = canvasElement.onClick.listen((event) {
      _clickController.add(_mouseEventToPoint(event));
    });

    _mouseDownSub = canvasElement.onMouseDown.listen((event) {
      _mouseDownController.add(CanvasMouseEvent(_mouseEventToPoint(event), event, this));
    });

    _mouseUpSub = canvasElement.onMouseUp.listen((event) {
      _mouseUpController.add(CanvasMouseEvent(_mouseEventToPoint(event), event, this));
    });

    _mouseMoveSub = canvasElement.onMouseMove.listen((event) {
      _mouseMoveController.add(CanvasMouseEvent(_mouseEventToPoint(event), event, this));
    });

    _initCanvasSize();

    _sizeChangedSub = _sizeChangedController.stream.listen((_) {
      _cd.markForCheck();
    });

    // Send event that the user is able to start drawing.
    _readyController.add(context);
    _readyController.close();
  }

  @override
  void ngOnDestroy() {
    _sizeChangedSub.cancel();

    _clickSub.cancel();
    _mouseUpSub.cancel();
    _mouseMoveSub.cancel();
    _mouseDownSub.cancel();

    _sizeChangedController.close();
    _clickController.close();
    _mouseUpController.close();
    _mouseDownController.close();
    _mouseMoveController.close();
  }

  @Input()
  void set height(int height) {
    _height = height;
    _resizeY = false;
  }

  int get height {
    if (_aspectRatio != null) {
      _height = _width ~/ _aspectRatio;
    }

    return _height;
  }

  /**
   * Get height with HiDPI support.
   */
  int get heightHidpi {
    return (height * window.devicePixelRatio).round();
  }

  @Input()
  void set width(int width) {
    _width = width;
    _resizeX = false;
  }

  int get width {
    return _width;
  }

  /**
   * Get width with HiPDI support.
   */
  int get widthHidpi {
    return (width * window.devicePixelRatio).round();
  }

  @Input()
  void set aspectRatio(double aspectRatio) {
    _aspectRatio = aspectRatio;
    _resizeY = false;
  }

  /**
   * Get current internal size of the canvas.
   */
  Size _getSize() {
    return new Size(widthHidpi, heightHidpi);
  }

  /**
   * Register on events fired when the canvas is resized.
   */
  @Output()
  Stream get onResized => _sizeChangedController.stream;

  /**
   * Register on events fired when the canvas is ready to be drawn on.
   */
  @Output()
  Stream get onReady => _readyController.stream;

  /**
   * Register on mouse click events on the canvas.
   */
  @Output()
  Stream get onClick => _clickController.stream;

  /// Register on mouse down events on the canvas.
  @Output()
  Stream get onMouseDown => _mouseDownController.stream;

  /// Register on mouse up events on the canvas.
  @Output()
  Stream get onMouseUp => _mouseUpController.stream;

  /// Register on mouse down events on the canvas.
  @Output()
  Stream get onMouseMove => _mouseMoveController.stream;

  /**
   * Initialize the canvas size and append window resize listeners
   * to listen for resize events.
   */
  void _initCanvasSize() {
    if (_resizeX || _resizeY) {
      if (!_resizeY) {
        onResized.listen((size) {
          canvasWrapper.style.height = "${_height}px";
        });
      }

      DivElement e = canvasWrapper as DivElement;

      if (_resizeX) {
        _width = e.clientWidth;
        _sizeChangedController.add(_getSize());
      }

      // Resize canvas according to parent.
      window.requestAnimationFrame((timestamp) {
        _resizeCanvas();
      });
    } else {
      // Just send one initial size.
      _sizeChangedController.add(_getSize());
    }
  }

  /**
   * Resize canvas: Fit canvas size to parent element.
   */
  void _resizeCanvas() {
    DivElement e = canvasWrapper as DivElement;

    bool resized = false;

    if (_resizeX && _width != e.clientWidth) {
      _width = e.clientWidth;
      resized = true;
    }

    if (_resizeY && _height != e.clientHeight) {
      _height = e.clientHeight;
      resized = true;
    }

    if (!_sizeChangedController.isClosed) {
      if (resized) {
        _sizeChangedController.add(_getSize());
      }

      window.requestAnimationFrame((timestamp) {
        _resizeCanvas();
      });
    }
  }

  /**
   * Set styles for HiDPI Support.
   * On HiDPI Screens the real canvas size is lower than what would be needed.
   * To fix this, the css width and height is set to the current width and height
   * while the real size is multiplied by the factor stored at window.deviceAspectRatio.
   */
  Map<String, String> setStyles() {
    return {
      "width": "${width}px",
      "height": "${height}px",
      "cursor": _cursorType,
    };
  }

  /**
   * Get point from mouse event.
   */
  Point<double> _mouseEventToPoint(MouseEvent event) {
    var rect = canvas.getBoundingClientRect();

    Point<double> point = new Point<double>(event.client.x - rect.left, event.client.y - rect.top) * window.devicePixelRatio;

    return point;
  }

  @override
  resetCursorType() {
    setCursorType("auto");
  }

  @override
  setCursorType(String type) {
    _cursorType = type;

    _cd.markForCheck();
  }

  @override
  String getCursorType() {
    return _cursorType;
  }
}

/// Mouse event on a canvas.
class CanvasMouseEvent {
  /// Position on the canvas of the mouse.
  final Point<double> pos;

  /// The original mouse event.
  final MouseEvent event;

  /// Control object to control the canvas component externally.
  final CanvasComponentControl control;

  /// Create mouse event.
  CanvasMouseEvent(this.pos, this.event, this.control);
}

/// Control object to control the canvas component.
abstract class CanvasComponentControl {
  /// Set the cursor type to show.
  setCursorType(String type);

  /// Get the cursor type currently shown.
  String getCursorType();

  /// Reset the cursor type to show.
  resetCursorType();
}
