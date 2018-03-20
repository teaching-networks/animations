import 'dart:async';
import 'dart:html';
import "package:angular/angular.dart";
import 'package:angular_components/angular_components.dart';
import 'package:netzwerke_animationen/src/util/size.dart';

/**
 * Canvas component a component enclosing a canvas which you can draw on.
 * It provides canvas resizing and access to its canvas.
 */
@Component(selector: "canvas-comp", templateUrl: "canvas_component.html", styleUrls: const ["canvas_component.css"], directives: const [materialDirectives])
class CanvasComponent implements OnInit {
  @ViewChild("canvasWrapper")
  ElementRef canvasWrapper;

  @ViewChild("canvas")
  ElementRef canvas;

  /**
   * Stream controller emitting events when the canvas is resized.
   */
  final _sizeChangedController = new StreamController<Size>.broadcast();

  /**
   * Stream controller emitting events when the canvas is ready to be drawn on.
   */
  final _readyController = new StreamController<CanvasRenderingContext2D>.broadcast();

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
    _initCanvasSize();

    // Get canvas rendering context used to draw on the canvas.
    CanvasRenderingContext2D context = (canvas.nativeElement as CanvasElement).getContext("2d");

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

  @Input()
  void set width(int width) {
    _width = width;
    _resizeX = false;
  }

  int get width {
    return _width;
  }

  /**
   * Get current size of the canvas.
   */
  Size _getSize() {
    return new Size(_width, _height);
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
   * Initialize the canvas size and append window resize listeners
   * to listen for resize events.
   */
  void _initCanvasSize() {
    if (_resizeX || _resizeY) {
      DivElement e = canvasWrapper.nativeElement as DivElement;

      if (_resizeX) {
        _width = e.clientWidth;
        _sizeChangedController.add(_getSize());
      }

      // Listen for resize events in case the window gets resized.
      window.onResize.listen((event) {
        int newWidth = e.clientWidth;
        int newHeight = e.clientHeight;

        bool resized = false;

        if (_resizeX && newWidth != _width) {
          _width = e.clientWidth;
          resized = true;
        }

        if (_resizeY && newHeight != _height) {
          _height = e.clientHeight;
          resized = true;
        }

        if (resized) {
          _sizeChangedController.add(_getSize());
        }
      });
    }
  }
}
