import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/onion_router/animation_controller.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/canvas/canvas_context_base.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';

/// Scenario  where the server to contact is routed in the "normal" internet.
class InternetService extends CanvasDrawable implements Scenario {
  /// Count of router rows to draw.
  static const int _routerRows = 3;

  /// Count of router columns to draw.
  static const int _routerColumns = 3;

  final AnimationController _controller;

  ImageInfo _hostImageInfo;
  CanvasImageSource _hostImage;

  ImageInfo _routerImageInfo;
  CanvasImageSource _routerImage;

  ImageInfo _serviceImageInfo;
  CanvasImageSource _serviceImage;

  Point<double> _hostCoordinates;
  Point<double> _serviceCoordinates;
  List<Point<double>> _routerCoordinates = List<Point<double>>();

  /// Create scenario.
  InternetService(this._controller) {
    _loadImages();
  }

  void _loadImages() async {
    _hostImageInfo = Images.hostIconImage;
    _hostImage = await _hostImageInfo.load();

    _serviceImageInfo = Images.serverImage;
    _serviceImage = await _serviceImageInfo.load();

    _routerImageInfo = Images.routerIconImage;
    _routerImage = await _routerImageInfo.load();

    _controller.invalidate();
  }

  @override
  int get id => 1;

  @override
  String get name => "Dienst im Internet geroutet";

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    BuildInfo buildInfo = _controller.getBuildInfo();

    context.save();
    context.translate(rect.left, rect.top);

    context.fillText(timestamp.toString(), 100, 100);

    if (buildInfo.rebuild) {
      // Calculate table layout with 6 columns and one row.
      int columns = 6;
      double cellW = rect.width / columns;
      double cellH = rect.height;

      double xOffset = 0.0;
      // In the first cell, draw the host image.
      _drawHost(context, Rectangle<double>(0, 0, cellW, cellH));
      xOffset += cellW;

      // In the intermediate cells, draw the routers.
      _drawRouters(context, Rectangle<double>(xOffset, 0, cellW * (columns - 2), cellH));
      xOffset += cellW * (columns - 2);

      // In the last cell, draw the service image.
      _drawService(context, Rectangle<double>(xOffset, 0, cellW, cellH));
    }

    if (_hasCoordinates) {
      context.lineWidth = window.devicePixelRatio * 3;
      setStrokeColor(context, Colors.CORAL);

      context.beginPath();
      context.moveTo(_hostCoordinates.x, _hostCoordinates.y);
      context.lineTo(_routerCoordinates[2].x, _routerCoordinates[2].y);
      context.lineTo(_routerCoordinates[6].x, _routerCoordinates[6].y);
      context.lineTo(_serviceCoordinates.x, _serviceCoordinates.y);
      context.stroke();

      if (buildInfo.rebuild) {
        setFillColor(context, Colors.CORAL);

        context.beginPath();
        context.ellipse(_hostCoordinates.x, _hostCoordinates.y, 12, 12, 2 * pi, 0, 2 * pi, false);
        context.fill();

        context.beginPath();
        context.ellipse(_serviceCoordinates.x, _serviceCoordinates.y, 12, 12, 2 * pi, 0, 2 * pi, false);
        context.fill();

        for (final p in _routerCoordinates) {
          context.beginPath();
          context.ellipse(p.x, p.y, 12, 12, 2 * pi, 0, 2 * pi, false);
          context.fill();
        }
      }
    }

    context.restore();
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
    _hostCoordinates = Point<double>(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
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
    _serviceCoordinates = Point<double>(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
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

        _routerCoordinates.add(Point<double>(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2));

        xOffset += xPad * 2;
      }

      yOffset += yPad * 2;
    }
  }

  bool get _hasCoordinates => _hostCoordinates != null && _serviceCoordinates != null && _routerCoordinates.isNotEmpty;

  @override
  String toString() {
    return name;
  }
}
