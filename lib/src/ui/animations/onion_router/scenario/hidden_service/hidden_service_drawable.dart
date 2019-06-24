import 'dart:html';
import 'dart:math';

import 'package:angular/src/core/linker/component_factory.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/hidden_service/controls/hidden_service_controls_component.template.dart'
    as hiddenServiceControls;
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';

/// Scenario where the service is routed only within the onion network.
class HiddenServiceDrawable extends Drawable implements Scenario {
  ImageInfo _hostImageInfo;
  CanvasImageSource _hostImage;

  ImageInfo _routerImageInfo;
  CanvasImageSource _routerImage;

  ImageInfo _serviceImageInfo;
  CanvasImageSource _serviceImage;

  Rectangle<double> _hostBounds;
  Point<double> _hostCoordinates;

  Rectangle<double> _serviceBounds;
  Point<double> _serviceCoordinates;

  /// Create service.
  HiddenServiceDrawable() {
    _init();
  }

  @override
  int get id => 2;

  @override
  String get name => "Versteckter Dienst";

  @override
  String toString() => name;

  Future<void> _init() async {
    await _loadImages();

    invalidate();
  }

  Future<void> _loadImages() async {
    _hostImageInfo = Images.hostIconImage;
    _hostImage = await _hostImageInfo.load();

    _serviceImageInfo = Images.serverImage;
    _serviceImage = await _serviceImageInfo.load();

    _routerImageInfo = Images.routerIconImage;
    _routerImage = await _routerImageInfo.load();
  }

  @override
  void draw() {
    /*
     * Drawing scenario in a row layout with one row and 6 columns.
     */
    int columns = 6;

    double yPad = size.height * 0.03;
    double xPad = size.width * 0.03;

    double cellW = (size.width - xPad * 2) / columns;
    double cellH = size.height - yPad * 2;
    double cellX = xPad;
    double cellY = yPad;

    double xOffset = cellX;
    _drawHost(Rectangle<double>(xOffset, cellY, cellW, cellH));

    xOffset += cellW;
    _drawNodes(Rectangle<double>(xOffset, cellY, cellW * (columns - 2), cellH));

    xOffset += cellW * (columns - 2);
    _drawService(Rectangle<double>(xOffset, cellY, cellW, cellH));
  }

  /// Draw the scenario nodes (relay nodes or onion routers).
  void _drawNodes(Rectangle<double> rect) {
    // TODO
  }

  /// Draw the host icon.
  void _drawHost(Rectangle<double> rect) {
    if (_hostImage == null) {
      return;
    }

    Rectangle<double> bounds = drawImageOnCanvas(
      _hostImage,
      aspectRatio: _hostImageInfo.aspectRatio,
      width: rect.width,
      height: rect.height,
      x: rect.left,
      y: rect.top,
      mode: ImageDrawMode.FILL,
      alignment: ImageAlignment.MID,
    );

    _hostCoordinates = Point<double>(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
    _hostBounds = bounds;
  }

  /// Draw the service icon.
  void _drawService(Rectangle<double> rect) {
    if (_serviceImage == null) {
      return;
    }

    Rectangle<double> bounds = drawImageOnCanvas(
      _serviceImage,
      aspectRatio: _serviceImageInfo.aspectRatio,
      width: rect.width * 0.75,
      height: rect.height,
      x: rect.left + rect.width * 0.125,
      y: rect.top,
      mode: ImageDrawMode.FILL,
      alignment: ImageAlignment.MID,
    );

    _serviceCoordinates = Point<double>(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
    _serviceBounds = bounds;
  }

  @override
  bool needsRepaint() => false;

  @override
  void update(num timestamp) {
    // TODO: implement update
  }

  @override
  ComponentFactory<ControlsComponent> get controlComponentFactory => hiddenServiceControls.HiddenServiceControlsComponentNgFactory;
}
