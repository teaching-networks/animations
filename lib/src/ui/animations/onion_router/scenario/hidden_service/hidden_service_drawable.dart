import 'dart:html';
import 'dart:math';

import 'package:angular/src/core/linker/component_factory.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/hidden_service/controls/hidden_service_controls_component.template.dart'
    as hiddenServiceControls;
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario_drawable_mixin.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim_helper.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';

/// Scenario where the service is routed only within the onion network.
class HiddenServiceDrawable extends Drawable with ScenarioDrawable implements Scenario {
  ImageInfo _hostImageInfo;
  CanvasImageSource _hostImage;

  ImageInfo _routerImageInfo;
  CanvasImageSource _routerImage;

  ImageInfo _serviceImageInfo;
  CanvasImageSource _serviceImage;

  ImageInfo _databaseImageInfo;
  CanvasImageSource _databaseImage;

  Rectangle<double> _hostBounds;
  Point<double> _hostCoordinates;

  Rectangle<double> _serviceBounds;
  Point<double> _serviceCoordinates;

  Rectangle<double> _databaseBounds;
  Point<double> _databaseCoordinates;

  List<Point<double>> _relativeRelayNodeCoordinates;

  List<int> _relayNodeIndicesToHighlight = [];
  List<int> _oldRelayNodeIndicesToHighlight = [];

  List<Point<double>> _relayNodeCoordinates = List<Point<double>>();
  List<Rectangle<double>> _relayNodeBounds = List<Rectangle<double>>();

  Anim _relayNodeHighlightAnimation;

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
    _setupAnimations();

    await _loadImages();

    _relativeRelayNodeCoordinates = await generateRelayNodes();

    invalidate();
  }

  void test() {
    _oldRelayNodeIndicesToHighlight = _relayNodeIndicesToHighlight.sublist(0);
    _relayNodeIndicesToHighlight.add(_relayNodeIndicesToHighlight.length + 1);

    _relayNodeHighlightAnimation.start();
  }

  void _setupAnimations() {
    _relayNodeHighlightAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(seconds: 1),
    );
  }

  Future<void> _loadImages() async {
    _hostImageInfo = Images.hostIconImage;
    _hostImage = await _hostImageInfo.load();

    _serviceImageInfo = Images.serverImage;
    _serviceImage = await _serviceImageInfo.load();

    _routerImageInfo = Images.routerIconImage;
    _routerImage = await _routerImageInfo.load();

    _databaseImageInfo = Images.database;
    _databaseImage = await _databaseImageInfo.load();
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
    _drawServiceAndDatabase(Rectangle<double>(xOffset, cellY, cellW, cellH));
  }

  /// Draw the scenario nodes (relay nodes or onion routers).
  void _drawNodes(Rectangle<double> rect) {
    if (_relativeRelayNodeCoordinates == null || _routerImage == null) {
      return;
    }

    drawNodes(
      this,
      rect,
      _relativeRelayNodeCoordinates,
      _routerImage,
      _routerImageInfo,
      indicesToHighlight: _relayNodeIndicesToHighlight,
      oldIndicesToHighlight: _oldRelayNodeIndicesToHighlight,
      highlightAnimation: _relayNodeHighlightAnimation,
      coordinates: _relayNodeCoordinates,
      bounds: _relayNodeBounds,
    );
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
  void _drawServiceAndDatabase(Rectangle<double> rect) {
    if (_serviceImage == null || _databaseImage == null) {
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

    bounds = drawImageOnCanvas(
      _databaseImage,
      aspectRatio: _databaseImageInfo.aspectRatio,
      width: rect.width * 0.5,
      height: rect.height,
      x: rect.left + rect.width * 0.25,
      y: rect.top,
      mode: ImageDrawMode.FILL,
      alignment: ImageAlignment.START,
    );

    _databaseCoordinates = Point<double>(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2);
    _databaseBounds = bounds;
  }

  @override
  bool needsRepaint() => _relayNodeHighlightAnimation.running;

  @override
  void update(num timestamp) {
    _relayNodeHighlightAnimation.update(timestamp);
  }

  @override
  ComponentFactory<ControlsComponent> get controlComponentFactory => hiddenServiceControls.HiddenServiceControlsComponentNgFactory;
}
