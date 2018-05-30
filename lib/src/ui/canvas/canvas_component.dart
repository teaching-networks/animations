import 'dart:async';
import 'dart:html';
import "package:angular/angular.dart";
import 'package:netzwerke_animationen/src/util/size.dart';

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
@Component(selector: "canvas-comp", templateUrl: "canvas_component.html", styleUrls: const ["canvas_component.css"], directives: const [coreDirectives])
class CanvasComponent implements OnInit {
  @ViewChild("canvasWrapper")
  HtmlElement canvasWrapper;

  @ViewChild("canvas")
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

  /*
  Width and height of the canvas.
   */
  int _width = 0;
  int _height = 100;

  /*
  Whether the x and y axis are resized automatically when the window size changes.
  This is deactivated by setting a value manually.
   */
  bool _resizeX = true;
  bool _resizeY = true;

  @override
  ngOnInit() {
    CanvasElement canvasElement = canvas as CanvasElement;

    // Get canvas rendering context used to draw on the canvas.
    CanvasRenderingContext2D context = canvasElement.getContext("2d");

    canvasElement.onClick.listen((event) {
      _clickController.add(_mouseEventToPoint(event));
    });

    _initCanvasSize();

    // Send event that the user is able to start drawing.
    _readyController.add(context);
    _readyController.close();
  }

  @Input()
  void set height(int height) {
    _height = height;
    _resizeY = false;
  }

  int get height {
    return _height;
  }

  /**
   * Get height with HiDPI support.
   */
  int get heightHidpi {
    return (_height * window.devicePixelRatio).round();
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
    return (_width * window.devicePixelRatio).round();
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

    if (resized) {
      _sizeChangedController.add(_getSize());
    }

    window.requestAnimationFrame((timestamp) {
      _resizeCanvas();
    });
  }

  /**
   * Set styles for HiDPI Support.
   * On HiDPI Screens the real canvas size is lower than what would be needed.
   * To fix this, the css width and height is set to the current width and height
   * while the real size is multiplied by the factor stored at window.deviceAspectRatio.
   */
  Map<String, String> setStyles() {
    return {"width": "${width}px", "height": "${height}px"};
  }

  /**
   * Get point from mouse event.
   */
  Point<double> _mouseEventToPoint(MouseEvent event) {
    var rect = canvas.getBoundingClientRect();

    Point<double> point = new Point<double>(event.client.x - rect.left, event.client.y - rect.top) * window.devicePixelRatio;

    return point;
  }
}
