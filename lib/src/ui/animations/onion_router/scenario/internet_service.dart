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
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';

/// Scenario  where the server to contact is routed in the "normal" internet.
class InternetService extends CanvasDrawable with Repaintable implements Scenario {
  /// Count of router rows to draw.
  static const int _routerRows = 3;

  /// Count of router columns to draw.
  static const int _routerColumns = 3;

  /// Duration of the packet transmission (from one point to another).
  static const Duration _packetTransmissionDuration = Duration(seconds: 3);

  /// Colors for the encryption layers of the packet.
  static const List<Color> _encryptionLayerColors = [
    Color.hex(0xFFFF3366),
    Color.hex(0xFF6699FF),
    Color.hex(0xFFFFCC33),
  ];

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

  /// Route through the routers in the onion router network to the server.
  List<int> _route = List<int>();

  EncryptedPacket _packet = EncryptedPacket();
  int _packetPosition = 0;
  num _packetTransitionTS;
  bool _startPacketTransition = false;
  bool _packetTransitionForward = true;
  double _packetTransitionProgress;

  /// The currently cached canvas.
  CanvasElement _cachedCanvas = CanvasElement();

  /// Context of the currently cached canvas.
  CanvasRenderingContext2D _cachedCanvasContext;

  /// Bounds of the currently cached canvas.
  Rectangle<double> _cachedCanvasRect;

  /// Create scenario.
  InternetService() {
    _loadImages();

    _cachedCanvasContext = _cachedCanvas.getContext("2d");
    reroute();
  }

  void test() {
    if (_route.isEmpty) {
      return;
    }

    _packet.reset();
    _packetPosition = 0;

    for (final color in _encryptionLayerColors) {
      _packet.encrypt(
        color: color,
        withAnimation: false,
      );
    }

    _startPacketTransition = true;
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
  bool get needsRepaint => super.needsRepaint || _packet.needsRepaint;

  @override
  void preRender([num timestamp = -1]) {
    super.preRender(timestamp);

    _checkTimestamp(timestamp);
    _updateAnimations(timestamp);

    _packet.preRender(timestamp);
  }

  /// Check the current timestamp for events.
  void _checkTimestamp(num timestamp) {
    if (_startPacketTransition) {
      _startPacketTransition = false;
      _packetTransitionTS = timestamp;
      _packetTransitionForward = true;

      invalidate();
    }
  }

  /// Update running animations (if any).
  void _updateAnimations(num timestamp) {
    if (_packetTransitionRunning) {
      // Update transition progress.
      _packetTransitionProgress = Curves.easeInOutCubic(_getProgress(timestamp, _packetTransitionTS, _packetTransmissionDuration));

      if (_packetTransitionProgress > 1.0) {
        if (_packetTransitionForward) {
          if (_packetPosition + 1 < _route.length + 1) {
            _packetPosition++;

            // Start transition all over again!
            _packetTransitionTS = timestamp;
            _packetTransitionProgress = 0;
            _packet.decrypt();
          } else {
            _packetTransitionForward = false; // Reverse transition direction
            _packetTransitionTS = timestamp;
            _packetTransitionProgress = 0;
          }
        } else {
          if (_packetPosition > 0) {
            _packetPosition--;

            // Restart transition progress
            _packetTransitionTS = timestamp;
            _packetTransitionProgress = 0;
            _packet.encrypt(color: _encryptionLayerColors[_encryptionLayerColors.length - 1 - _packetPosition]);
          } else {
            _packetTransitionTS = null; // End transition
          }
        }
      }

      if (!_packetTransitionForward) {
        _packetTransitionProgress = 1 - _packetTransitionProgress; // Reverse transition
      }

      invalidate();
    }
  }

  /// Get progress of an animation using its start timestamp and the duration.
  double _getProgress(num curTS, num startTS, Duration duration) => (curTS - startTS) / duration.inMilliseconds;

  /// Whether the packet transition is currently running.
  bool get _packetTransitionRunning => _packetTransitionTS != null;

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

    if (_hasCoordinates && _route.isNotEmpty) {
      List<Point<double>> routeCoordinates = List<Point<double>>();
      routeCoordinates.add(_hostCoordinates);
      for (int i in _route) {
        routeCoordinates.add(_routerCoordinates[i]);
      }
      routeCoordinates.add(_serviceCoordinates);

      if (_route.isNotEmpty) {
        _drawRoute(context, routeCoordinates);
      }

      if (_packetTransitionProgress != null) {
        _drawPacket(context, _packet, _packetTransitionProgress, routeCoordinates, _packetPosition, timestamp);
      }
    }
  }

  /// Draw the passed encrypted packet in the correct [positionInRoute] with the passed transition [progress].
  void _drawPacket(CanvasRenderingContext2D context, EncryptedPacket packet, double progress, List<Point<double>> route, int positionInRoute, num timestamp) {
    Point<double> startPt = route[positionInRoute];
    Point<double> endPt = route[positionInRoute + 1];

    Point<double> curPt = startPt + (endPt - startPt) * progress;

    double size = 100 * window.devicePixelRatio;

    _packet.render(context, Rectangle<double>(curPt.x - size / 2, curPt.y - size / 2, size, size), timestamp);
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
    _route.clear();

    for (int i = 0; i < _routerColumns; i++) {
      int row = _rng.nextInt(_routerRows);

      _route.add(row * _routerColumns + i);
    }

    invalidate();
  }

  @override
  String toString() {
    return name;
  }
}
