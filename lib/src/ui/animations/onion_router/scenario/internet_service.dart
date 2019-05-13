import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/onion_router/animation_controller.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/canvas/canvas_context_base.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
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

  /// Create scenario.
  InternetService(this._controller) {
    _loadImages();
  }

  void _loadImages() async {
    _hostImageInfo = Images.hostIconImage;
    _hostImage = await _hostImageInfo.load();

    _serviceImageInfo = Images.hostIconImage; // TODO Change to correct service image
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
    context.save();

    context.translate(rect.left, rect.top);

    // Calculate table layout with 5 columns and one row.
    int columns = 5;
    double cellW = rect.width / columns;
    double cellH = rect.height;

    // In the first cell, draw the host image.
    _drawHost(context, Rectangle<double>(0, 0, cellW, cellH));
    context.translate(cellW, 0);

    // In the intermediate cells, draw the routers.
    _drawRouters(context, Rectangle<double>(0, 0, cellW * (columns - 2), cellH));
    context.translate(cellW * (columns - 2), 0);

    // In the last cell, draw the service image.
    _drawService(context, Rectangle<double>(0, 0, cellW, cellH));

    context.restore();
  }

  void _drawHost(CanvasRenderingContext2D context, Rectangle<double> rectangle) {
    if (_hostImage == null) {
      return;
    }

    drawImageOnCanvas(
      context,
      _hostImage,
      aspectRatio: _hostImageInfo.aspectRatio,
      width: rectangle.width,
      height: rectangle.height,
      mode: ImageDrawMode.FILL,
      alignment: ImageAlignment.MID,
    );
  }

  void _drawService(CanvasRenderingContext2D context, Rectangle<double> rectangle) {
    if (_serviceImage == null) {
      return;
    }

    drawImageOnCanvas(
      context,
      _serviceImage,
      aspectRatio: _serviceImageInfo.aspectRatio,
      width: rectangle.width,
      height: rectangle.height,
    );
  }

  void _drawRouters(CanvasRenderingContext2D context, Rectangle<double> rectangle) {
    if (_routerImage == null) {
      return;
    }

    double iW = rectangle.width / _routerColumns;
    double iH = rectangle.height / _routerRows;

    for (int row = 0; row < _routerRows; row++) {
      for (int column = 0; column < _routerColumns; column++) {
        drawImageOnCanvas(
          context,
          _routerImage,
          aspectRatio: _routerImageInfo.aspectRatio,
          width: iW,
          height: iH,
          x: iW * column,
          y: iH * row,
        );
      }
    }
  }

  @override
  String toString() {
    return name;
  }
}
