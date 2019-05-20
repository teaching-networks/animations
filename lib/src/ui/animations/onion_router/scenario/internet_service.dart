import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/animations/shared/encrypted_packet/encrypted_packet.dart';
import 'package:hm_animations/src/ui/canvas/animation/repaintable.dart';
import 'package:hm_animations/src/ui/canvas/canvas_context_base.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';

/// Scenario  where the server to contact is routed in the "normal" internet.
class InternetService extends CanvasDrawable with Repaintable implements Scenario {
  /// Count of router rows to draw.
  static const int _routerRows = 3;

  /// Count of router columns to draw.
  static const int _routerColumns = 3;

  static Random _rng = Random();

  ImageInfo _hostImageInfo;
  CanvasImageSource _hostImage;

  ImageInfo _routerImageInfo;
  CanvasImageSource _routerImage;

  ImageInfo _serviceImageInfo;
  CanvasImageSource _serviceImage;

  Point<double> _hostCoordinates;
  Point<double> _serviceCoordinates;
  List<Point<double>> _routerCoordinates = List<Point<double>>();

  /// Route from the host and the routers in the onion router network to the server.
  List<Point<double>> _route = List<Point<double>>();

  EncryptedPacket _test = EncryptedPacket();

  /// The currently cached canvas.
  CanvasElement _cachedCanvas = CanvasElement();

  /// Context of the currently cached canvas.
  CanvasRenderingContext2D _cachedCanvasContext;

  /// Bounds of the currently cached canvas.
  Rectangle<double> _cachedCanvasRect;

  void testEncrypt() {
    _test.encrypt(color: Colors.CORAL);
  }

  void testDecrypt() {
    _test.decrypt();
  }

  /// Create scenario.
  InternetService() {
    _loadImages();

    _cachedCanvasContext = _cachedCanvas.getContext("2d");
  }

  void _loadImages() async {
    _hostImageInfo = Images.hostIconImage;
    _hostImage = await _hostImageInfo.load();

    _serviceImageInfo = Images.serverImage;
    _serviceImage = await _serviceImageInfo.load();

    _routerImageInfo = Images.routerIconImage;
    _routerImage = await _routerImageInfo.load();

    invalidate();
  }

  @override
  int get id => 1;

  @override
  String get name => "Dienst im Internet geroutet";

  @override
  bool get needsRepaint => super.needsRepaint || _test.needsRepaint;

  @override
  void preRender([num timestamp = -1]) {
    super.preRender(timestamp);

    _test.preRender(timestamp);
  }

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    if (needsRepaint || rect != _cachedCanvasRect) {
      _cachedCanvas.width = rect.width.toInt();
      _cachedCanvas.height = rect.height.toInt();

      _cachedCanvasContext.clearRect(0, 0, rect.width, rect.height);
      _cachedCanvasRect = rect;

      repaint(_cachedCanvasContext, rect.width, rect.height, timestamp);

      validate();
    }

    context.drawImageToRect(_cachedCanvas, rect);
  }

  /// Repaint scene on the passed canvas context.
  void repaint(CanvasRenderingContext2D context, double width, double height, num timestamp) {
    _test.render(context, Rectangle<double>(100, 100, 200, 200), timestamp);

    // Calculate table layout with 6 columns and one row.
    int columns = 6;
    double cellW = width / columns;
    double cellH = height;

    double xOffset = 0.0;
    // In the first cell, draw the host image.
    _drawHost(context, Rectangle<double>(0, 0, cellW, cellH));
    xOffset += cellW;

    // In the intermediate cells, draw the routers.
    _drawRouters(context, Rectangle<double>(xOffset, 0, cellW * (columns - 2), cellH));
    xOffset += cellW * (columns - 2);

    // In the last cell, draw the service image.
    _drawService(context, Rectangle<double>(xOffset, 0, cellW, cellH));

    if (_hasCoordinates) {
      if (_route.isNotEmpty) {
        _drawRoute(context, _route);
      }
    }
  }

  /// Draw route from the host to the service over several onion routers.
  void _drawRoute(CanvasRenderingContext2D context, List<Point<double>> route) {
    context.lineWidth = window.devicePixelRatio * 3;
    setStrokeColor(context, Colors.SPACE_BLUE);

    context.beginPath();

    context.moveTo(route.first.x, route.first.y);
    for (int i = 1; i < route.length; i++) {
      context.lineTo(route[i].x, route[i].y);
    }

    context.stroke();

    setFillColor(context, Color.brighten(Colors.SPACE_BLUE, 0.3));
    double radius = 8 * window.devicePixelRatio;
    for (final coords in route) {
      context.beginPath();
      context.ellipse(coords.x, coords.y, radius, radius, 2 * pi, 0, 2 * pi, false);
      context.fill();
    }
  }

  void _drawHost(CanvasRenderingContext2D context, Rectangle<double> rectangle) {
    if (_hostImage == null) {
      return;
    }

    Rectangle<double> bounds = drawImageOnCanvas(
      context,
      _hostImage,
      aspectRatio: _hostImageInfo.aspectRatio,
      width: rectangle.width,
      height: rectangle.height,
      x: rectangle.left,
      y: rectangle.top,
      mode: ImageDrawMode.FILL,
      alignment: ImageAlignment.MID,
    );
    _hostCoordinates = Point<double>(bounds.left + bounds.width / 2, bounds.top + bounds.height);
  }

  void _drawService(CanvasRenderingContext2D context, Rectangle<double> rectangle) {
    if (_serviceImage == null) {
      return;
    }

    Rectangle<double> bounds = drawImageOnCanvas(
      context,
      _serviceImage,
      aspectRatio: _serviceImageInfo.aspectRatio,
      width: rectangle.width * 0.75,
      height: rectangle.height,
      x: rectangle.left,
      y: rectangle.top,
      mode: ImageDrawMode.FILL,
      alignment: ImageAlignment.MID,
    );
    _serviceCoordinates = Point<double>(bounds.left + bounds.width / 2, bounds.top + bounds.height);
  }

  void _drawRouters(CanvasRenderingContext2D context, Rectangle<double> rectangle) {
    if (_routerImage == null) {
      return;
    }

    _routerCoordinates.clear();

    double iW = rectangle.width / _routerColumns;
    double iH = rectangle.height / _routerRows;
    double paddingFactor = 0.3;
    double xPad = iW * paddingFactor / 2;
    double yPad = iH * paddingFactor / 2;
    iW *= 1.0 - paddingFactor;
    iH *= 1.0 - paddingFactor;

    double yOffset = yPad + rectangle.top;
    for (int row = 0; row < _routerRows; row++) {
      double xOffset = xPad + rectangle.left;
      double rowJitter = cos(row * pi / 2);
      for (int column = 0; column < _routerColumns; column++) {
        Rectangle<double> bounds = drawImageOnCanvas(
          context,
          _routerImage,
          width: iW,
          height: iH,
          aspectRatio: _routerImageInfo.aspectRatio,
          x: xOffset + iW * column + 100 * rowJitter,
          y: yOffset + iH * row,
          mode: ImageDrawMode.FILL,
          alignment: ImageAlignment.MID,
        );

        _routerCoordinates.add(Point<double>(bounds.left + bounds.width / 2, bounds.top + bounds.height));

        xOffset += xPad * 2;
      }

      yOffset += yPad * 2;
    }
  }

  bool get _hasCoordinates => _hostCoordinates != null && _serviceCoordinates != null && _routerCoordinates.isNotEmpty;

  // Find a new route in the onion router network.
  void reroute() {
    if (!_hasCoordinates) {
      return;
    }

    _route.clear();

    _route.add(_hostCoordinates);

    for (int i = 0; i < _routerColumns; i++) {
      int row = _rng.nextInt(_routerRows);

      _route.add(_routerCoordinates[row * _routerColumns + i]);
    }

    _route.add(_serviceCoordinates);

    invalidate();
  }

  @override
  String toString() {
    return name;
  }
}
