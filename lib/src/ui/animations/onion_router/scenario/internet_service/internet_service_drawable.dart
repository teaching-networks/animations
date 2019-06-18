import 'dart:html';
import 'dart:math';

import 'package:angular/src/core/linker/component_factory.dart';
import 'package:angular_components/laminate/enums/alignment.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/internet_service/controls/internet_service_controls_component.template.dart'
    as internetServiceControls;
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario_drawable_mixin.dart';
import 'package:hm_animations/src/ui/animations/shared/encrypted_packet/encrypted_packet.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim_helper.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/shapes/bubble/bubble.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';

/// Drawable illustrating the onion network, where a service is routed within
/// the internet, but accessible from within the onion network, via
/// multi layers of onion routers (relays).
class InternetServiceDrawable extends Drawable with ScenarioDrawable implements Scenario {
  /// Duration of the packet transmission (from one point to another).
  static const Duration _packetTransitionAnimationDuration = Duration(seconds: 3);

  /// Duration of the relay node growth animation.
  static const Duration _relayNodeGrowthAnimationDuration = Duration(seconds: 1);

  /// Duration of the TCP connection establishment animation.
  static const Duration _tcpConnectionAnimationDuration = Duration(seconds: 6);

  /// Duration of the key exchange animation.
  static const Duration _keyExchangeAnimationDuration = Duration(seconds: 2);

  /// Duration how long a bubble should be showing per character.
  static const Duration _bubbleDurationPerCharacter = Duration(milliseconds: 50);

  /// Colors for the encryption layers of the packet.
  static const List<Color> _encryptionLayerColors = [
    Color.hex(0xFFD91F37),
    Color.hex(0xFFF79621),
    Color.hex(0xFFF2EC36),
    Color.hex(0xFF80C143),
    Color.hex(0xFF0AC0F2),
    Color.hex(0xFF1177BF),
    Color.hex(0xFF653291),
  ];

  /// The maximum route length.
  static const int _maxRouteLength = 7;

  /// The minimum route length.
  static const int _minRouteLength = 1;

  /// Default length of the route through the relay nodes.
  static const int _defaultRouteLength = 3;

  static Random _rng = Random();

  ImageInfo _hostImageInfo;
  CanvasImageSource _hostImage;

  ImageInfo _routerImageInfo;
  CanvasImageSource _routerImage;

  ImageInfo _serviceImageInfo;
  CanvasImageSource _serviceImage;

  ImageInfo _keyImageInfo;
  CanvasImageSource _keyImage;

  Point<double> _hostCoordinates;
  Rectangle<double> _hostBounds;
  Point<double> _serviceCoordinates;
  Rectangle<double> _serviceBounds;

  List<Point<double>> _relayNodeCoordinates = List<Point<double>>();
  List<Rectangle<double>> _relayNodeBounds = List<Rectangle<double>>();

  /// Route through the routers in the onion router network to the server.
  List<int> _route = List<int>();
  List<int> _oldRoute = List<int>();

  EncryptedPacket _packet = EncryptedPacket();
  int _packetPosition = 0;

  Bubble _infoBubble;
  double _infoBubblePosIndex;
  bool _showBubbles = false;
  int _currentInfoBubbleID = 0;

  List<Point<double>> _relativeRelayNodeCoordinates;

  /// Whether TCP connections are established between the relay nodes.
  bool _tcpConnectionsEstablished = false;

  /// Whether the keys have been exchanged.
  bool _keysExchanged = false;

  /// Position (Route index) in the key exchange animation.
  int _keyExchangeAnimationPosition = 1;

  AnimHelper _packetTransitionAnimation;
  AnimHelper _relayNodeGrowthAnimation;
  AnimHelper _tcpConnectionAnimation;
  AnimHelper _keyExchangeAnimation;

  /// Create the internet service drawable.
  InternetServiceDrawable() {
    _init();
  }

  /// Initialize the drawable.
  Future<void> _init() async {
    _setupAnimations();

    // Initially load images
    await _loadImages();

    // Prepare relay nodes and route through them
    _relativeRelayNodeCoordinates = await generateRelayNodes();
    reroute();

    invalidate();
  }

  @override
  int get id => 1;

  @override
  String get name => "Dienst im Internet geroutet";

  /// Setup the animations needed by the scenario.
  void _setupAnimations() {
    _packetTransitionAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: _packetTransitionAnimationDuration,
      onEnd: (timestamp) {
        if (_packetTransitionAnimation.reversed) {
          _onPacketTransitionAnimationEndReverse(timestamp);
        } else {
          _onPacketTransitionAnimationEndForward(timestamp);
        }
      },
    );

    _relayNodeGrowthAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: _relayNodeGrowthAnimationDuration,
    );

    _tcpConnectionAnimation = AnimHelper(
      curve: Curves.easeOutCubic,
      duration: _tcpConnectionAnimationDuration,
      onEnd: (timestamp) {
        _tcpConnectionsEstablished = true;
        _startKeyExchangeAnimation();
      },
      onReset: () {
        _tcpConnectionsEstablished = false;
      },
    );

    _keyExchangeAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      onEnd: (timestamp) {
        if (_keyExchangeAnimationPosition + 1 < _route.length + 1) {
          _keyExchangeAnimationPosition++;
          _keyExchangeAnimation.start(
            timestamp: timestamp,
            duration: Duration(milliseconds: _keyExchangeAnimationDuration.inMilliseconds * _keyExchangeAnimationPosition),
          );
        } else {
          _keysExchanged = true;
          _startPacketTransitionAnimation();
        }
      },
      onReset: () {
        if (_keysExchanged) {
          _keyExchangeAnimationPosition = 1;
        }
        _keysExchanged = false;
      },
    );
  }

  /// Start the scenario.
  void start(bool withBubbles) {
    if (_route.isEmpty) {
      return;
    }

    _resetAnimation();

    _showBubbles = withBubbles;

    _tcpConnectionAnimation.start();

    if (_showBubbles) {
      _showBubble(
        "Zwischen Host, Dienst & Relay Knoten (Onion Router (OR)) werden TCP/TLS Verbindungen aufgebaut. Hier nur vereinfacht dargestellt.",
        0.5,
        Alignment.Start,
      );
    }

    invalidate();
  }

  /// Start the key exchange animation.
  void _startKeyExchangeAnimation() {
    _keyExchangeAnimation.start(duration: _keyExchangeAnimationDuration);

    if (_showBubbles) {
      _showBubble(
        "Zwischen dem Host und jedem Relay Knoten (OR) werden Schritt für Schritt symmetrische Schlüssel ausgetauscht.",
        0.5,
        Alignment.Start,
      );
    }

    invalidate();
  }

  /// Start the packet transition animation.
  void _startPacketTransitionAnimation() async {
    if (_showBubbles) {
      await _showBubble(
        "Daten werden als sogenannte \"Cells\" gesendet, welche 512 Byte Einheiten darstellen und aus Header & Payload bestehen.",
        0,
        Alignment.Start,
      );
    }

    await Future.wait([
      _animatePacketInitialization(),
      if (_showBubbles)
        _showBubble(
          "Für jeden Onion Router auf dem Weg zum Dienst wird das zu sendende Paket verschlüsselt. Folge: Nur der erste Onion Router kenn die Quell-IP und nur der letzte kennt die Ziel-IP.",
          0,
          Alignment.Start,
        ),
    ]);

    _packetTransitionAnimation.start();
    invalidate();
  }

  Future<void> _animatePacketInitialization() async {
    for (int i = 0; i < _route.length; i++) {
      await _packet.encrypt(
        color: _encryptionLayerColors[i],
        withAnimation: true,
      );
    }
  }

  Future<void> _animatePacketDecryption() async {
    for (int i = 0; i < _route.length; i++) {
      await _packet.decrypt(withAnimation: true);
    }
  }

  Future<void> _loadImages() async {
    _hostImageInfo = Images.hostIconImage;
    _hostImage = await _hostImageInfo.load();

    _serviceImageInfo = Images.serverImage;
    _serviceImage = await _serviceImageInfo.load();

    _routerImageInfo = Images.routerIconImage;
    _routerImage = await _routerImageInfo.load();

    _keyImageInfo = Images.key;
    _keyImage = await _keyImageInfo.load();
  }

  @override
  void draw() {
    // Calculate table layout with 6 columns and one row.
    int columns = 6;
    double cellW = size.width / columns;
    double cellH = size.height;

    double paddingY = 50.0 * window.devicePixelRatio;

    double xOffset = 0.0;
    // In the first cell, draw the host image.
    _drawHost(Rectangle<double>(0, 0, cellW, cellH));
    xOffset += cellW;

    // In the intermediate cells, draw the routers.
    _drawRelayNodes(Rectangle<double>(xOffset, paddingY, cellW * (columns - 2), cellH - paddingY * 2), _relativeRelayNodeCoordinates);
    xOffset += cellW * (columns - 2);

    // In the last cell, draw the service image.
    _drawService(Rectangle<double>(xOffset, 0, cellW, cellH));

    if (_hasCoordinates && _route.isNotEmpty) {
      List<Point<double>> routeCoordinates = List<Point<double>>();
      routeCoordinates.add(_hostCoordinates + Point<double>(0, _hostBounds.height / 2));
      for (int i in _route) {
        routeCoordinates.add(_relayNodeCoordinates[i] + Point<double>(0, _relayNodeBounds[i].height / 2));
      }
      routeCoordinates.add(_serviceCoordinates + Point<double>(0, _serviceBounds.height / 2));

      if (_route.isNotEmpty) {
        _drawRoute(routeCoordinates);
      }

      if (_packet != null) {
        _drawPacket(_packet, _packetTransitionAnimation.progress, routeCoordinates, _packetPosition, lastPassTimestamp);
      }

      if (_infoBubble != null) {
        Point<double> coords = _getCoordinatesForFloatingIndex(_infoBubblePosIndex);
        _infoBubble.render(ctx, Rectangle<double>(coords.x, coords.y, 0, 0), lastPassTimestamp);
      }
    }
  }

  /// Get coordinates for the passed floating point [index].
  /// The method will calculate the coordinates based on the coordinates before and after
  /// the passed integer indices and interpolate them.
  Point<double> _getCoordinatesForFloatingIndex(double index, {bool addOffset = true}) {
    Point<double> before = _getCoordinatesForIndex(index.floor(), addOffset: addOffset);
    Point<double> after = _getCoordinatesForIndex(index.ceil(), addOffset: addOffset);

    return before + (after - before) * (index - index.floor());
  }

  /// Get coordinates for the passed route [index].
  Point<double> _getCoordinatesForIndex(int index, {bool addOffset = true}) {
    if (index == 0) {
      return addOffset ? _hostCoordinates + Point<double>(0, _hostBounds.height / 2) : _hostCoordinates;
    } else if (index - 1 < _route.length) {
      return addOffset
          ? _relayNodeCoordinates[_route[index - 1]] + Point<double>(0, _relayNodeBounds[_route[index - 1]].height / 2)
          : _relayNodeCoordinates[_route[index - 1]];
    } else {
      return addOffset ? _serviceCoordinates + Point<double>(0, _serviceBounds.height / 2) : _serviceCoordinates;
    }
  }

  /// Draw the passed encrypted packet in the correct [positionInRoute] with the passed transition [progress].
  void _drawPacket(EncryptedPacket packet, double progress, List<Point<double>> route, int positionInRoute, num timestamp) {
    Point<double> startPt = route[positionInRoute];
    Point<double> endPt = route[positionInRoute + 1];

    Point<double> curPt = startPt + (endPt - startPt) * progress;

    double size = 100 * window.devicePixelRatio;

    _packet.packetSize = size;
    _packet.maxEncryptionLayers = _route.length;
    _packet.render(
      ctx,
      timestamp,
      x: curPt.x,
      y: curPt.y,
    );
  }

  /// Draw route from the host to the service over several onion routers.
  void _drawRoute(List<Point<double>> route) {
    ctx.lineWidth = window.devicePixelRatio * 3;

    for (int i = 0; i < route.length - 1; i++) {
      setStrokeColor(getRoutePartColor(i));

      ctx.beginPath();
      ctx.moveTo(route[i].x, route[i].y);
      ctx.lineTo(route[i + 1].x, route[i + 1].y);
      ctx.stroke();

      if (_tcpConnectionAnimation.running) {
        // Stroke the TCP connection handshake progress (Just for visualization).
        setStrokeColor(Colors.SPACE_BLUE);

        Point<double> cP = route[i] + (route[i + 1] - route[i]) * _tcpConnectionAnimation.progress;

        ctx.beginPath();
        ctx.moveTo(route[i].x, route[i].y);
        ctx.lineTo(cP.x, cP.y);
        ctx.stroke();
      }
    }

    // Draw dots for each "milestone" in the route.
    setFillColor(Color.brighten(Colors.SPACE_BLUE, 0.3));
    double radius = 8 * window.devicePixelRatio;
    for (final coords in route) {
      ctx.beginPath();
      ctx.ellipse(coords.x, coords.y, radius, radius, 2 * pi, 0, 2 * pi, false);
      ctx.fill();
    }

    if (_keyExchangeAnimation.running) {
      double index = _keyExchangeAnimationPosition * _keyExchangeAnimation.progress;

      Point<double> cP1 = _getCoordinatesForFloatingIndex(index);
      Point<double> cP2 = _getCoordinatesForFloatingIndex(_keyExchangeAnimationPosition - index);

      double keySize = window.devicePixelRatio * 50.0;

      drawImageOnCanvas(
        _keyImage,
        aspectRatio: _keyImageInfo.aspectRatio,
        width: keySize,
        height: keySize,
        x: cP1.x - keySize / 2,
        y: cP1.y - keySize / 2,
        mode: ImageDrawMode.FILL,
        alignment: ImageAlignment.MID,
      );

      drawImageOnCanvas(
        _keyImage,
        aspectRatio: _keyImageInfo.aspectRatio,
        width: keySize,
        height: keySize,
        x: cP2.x - keySize / 2,
        y: cP2.y - keySize / 2,
        mode: ImageDrawMode.FILL,
        alignment: ImageAlignment.MID,
      );
    }
  }

  /// Get the color of the passed route part [index].
  Color getRoutePartColor(int index) {
    if (!_tcpConnectionsEstablished || !_keysExchanged) {
      if (!_tcpConnectionsEstablished) {
        return Colors.LIGHTER_GRAY;
      } else if (!_keysExchanged) {
        if (index + 1 >= _keyExchangeAnimationPosition) {
          return Colors.SPACE_BLUE;
        } else {
          return _encryptionLayerColors[_route.length - 1 - index];
        }
      } else {
        return Colors.LIGHTER_GRAY;
      }
    } else if (_route.length > index) {
      return _encryptionLayerColors[_route.length - 1 - index];
    } else {
      return Colors.SPACE_BLUE;
    }
  }

  void _drawHost(Rectangle<double> rectangle) {
    if (_hostImage == null) {
      return;
    }

    Rectangle<double> bounds = drawImageOnCanvas(
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
    _hostBounds = bounds;
  }

  void _drawService(Rectangle<double> rectangle) {
    if (_serviceImage == null) {
      return;
    }

    Rectangle<double> bounds = drawImageOnCanvas(
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
    _serviceBounds = bounds;
  }

  void _drawRelayNodes(Rectangle<double> rectangle, List<Point<double>> nodeCoordinates) {
    if (nodeCoordinates == null || _routerImage == null) {
      return;
    }

    double iW = rectangle.width * 0.1;
    double iH = rectangle.height * 0.1;
    double xPad = rectangle.width * 0.1;
    double yPad = rectangle.height * 0.1;
    double x = rectangle.left + xPad;
    double y = rectangle.top + yPad;
    double w = rectangle.width - xPad * 2;
    double h = rectangle.height - yPad * 2;

    // Layout relay nodes first -> Calculate current coordinates on the canvas
    _relayNodeCoordinates.clear();
    _relayNodeBounds.clear();
    for (int i = 0; i < nodeCoordinates.length; i++) {
      Point<double> point = nodeCoordinates[i];

      Rectangle<double> b = layoutImage(
        width: iW,
        height: iH,
        aspectRatio: _routerImageInfo.aspectRatio,
        x: x + point.x * w - iW / 2,
        y: y + point.y * h - iH / 2,
        mode: ImageDrawMode.FILL,
        alignment: ImageAlignment.MID,
      );

      _relayNodeBounds.add(b);
      _relayNodeCoordinates.add(Point<double>(b.left + b.width / 2, b.top + b.height / 2));
    }

    final routeIndicesLookup = _route != null ? _route.toSet() : null;
    final oldRouteIndicesLookup = _oldRoute != null && _oldRoute.isNotEmpty ? _oldRoute.toSet() : null;

    // Draw background relay nodes
    ctx.save();
    ctx.globalAlpha = 0.5;

    for (int i = 0; i < nodeCoordinates.length; i++) {
      if ((routeIndicesLookup != null && routeIndicesLookup.contains(i)) ||
          (_relayNodeGrowthAnimation.running && oldRouteIndicesLookup != null && oldRouteIndicesLookup.contains(i))) {
        continue;
      }

      ctx.drawImageToRect(
        _routerImage,
        _relayNodeBounds[i],
      );
    }

    ctx.restore();

    if (_route != null) {
      if (_relayNodeGrowthAnimation.running) {
        if (_oldRoute != null && _oldRoute.isNotEmpty) {
          double reverseProgress = 1.0 - _relayNodeGrowthAnimation.progress;
          // Draw old chosen nodes of the route
          double shrinkWidth = iW + iW * reverseProgress;
          double shrinkHeight = iW + iH * reverseProgress;

          ctx.save();
          ctx.globalAlpha = 0.5 + 0.5 * reverseProgress;

          for (int i in _oldRoute) {
            Point<double> point = nodeCoordinates[i];

            final newBounds = layoutImage(
              width: shrinkWidth,
              height: shrinkHeight,
              aspectRatio: _routerImageInfo.aspectRatio,
              x: x + point.x * w - shrinkWidth / 2,
              y: y + point.y * h - shrinkHeight / 2,
              mode: ImageDrawMode.FILL,
              alignment: ImageAlignment.MID,
            );

            _relayNodeBounds[i] = newBounds;

            ctx.drawImageToRect(
              _routerImage,
              newBounds,
            );
          }

          ctx.restore();
        }

        // Draw new route nodes
        double growWidth = iW + iW * _relayNodeGrowthAnimation.progress;
        double growHeight = iH + iH * _relayNodeGrowthAnimation.progress;

        ctx.save();
        ctx.globalAlpha = 0.5 + 0.5 * _relayNodeGrowthAnimation.progress;

        for (int i in _route) {
          Point<double> point = nodeCoordinates[i];

          final newBounds = layoutImage(
            width: growWidth,
            height: growHeight,
            aspectRatio: _routerImageInfo.aspectRatio,
            x: x + point.x * w - growWidth / 2,
            y: y + point.y * h - growHeight / 2,
            mode: ImageDrawMode.FILL,
            alignment: ImageAlignment.MID,
          );

          _relayNodeBounds[i] = newBounds;

          ctx.drawImageToRect(
            _routerImage,
            newBounds,
          );
        }

        ctx.restore();
      } else {
        // Draw chosen nodes of the route
        for (int i in _route) {
          Point<double> point = nodeCoordinates[i];

          final newBounds = layoutImage(
            width: iW * 2,
            height: iH * 2,
            aspectRatio: _routerImageInfo.aspectRatio,
            x: x + point.x * w - iW,
            y: y + point.y * h - iH,
            mode: ImageDrawMode.FILL,
            alignment: ImageAlignment.MID,
          );

          _relayNodeBounds[i] = newBounds;

          ctx.drawImageToRect(
            _routerImage,
            newBounds,
          );
        }
      }
    }
  }

  bool get _hasCoordinates => _hostCoordinates != null && _serviceCoordinates != null && _relayNodeCoordinates.isNotEmpty;

  // Find a new route in the onion router network.
  void reroute({
    bool withAnimation = true,
    int routeLength = _defaultRouteLength,
  }) {
    if (routeLength < _minRouteLength || routeLength > _maxRouteLength) {
      throw Exception("Route length $routeLength is illegal. Must be in range [$_minRouteLength; $_maxRouteLength].");
    }

    _resetAnimation();

    // Cache old route
    _oldRoute.clear();
    for (int i in _route) {
      _oldRoute.add(i);
    }

    if (withAnimation) {
      _relayNodeGrowthAnimation.start();
    }

    if (_route.length != routeLength) _route.length = routeLength;

    Set<int> oldUsedIndices = _oldRoute != null ? _oldRoute.toSet() : Set<int>();
    Set<int> usedIndices = Set<int>();

    for (int i = 0; i < routeLength; i++) {
      _route[i] = _rng.nextInt(_relativeRelayNodeCoordinates.length);

      // Check that index hasn't been used yet and is not used in the old route (if any).
      if (usedIndices.contains(_route[i]) || oldUsedIndices.contains(_route[i])) {
        i--; // Regenerate index in next iteration
      } else {
        usedIndices.add(_route[i]);
      }
    }

    invalidate();
  }

  @override
  bool needsRepaint() => _packet.isInvalid;

  /// Reset the animation.
  void _resetAnimation() {
    _hideBubble();

    _packet.reset();
    _packetPosition = 0;

    _packetTransitionAnimation.reset(resetReverse: true);
    _relayNodeGrowthAnimation.reset();
    _tcpConnectionAnimation.reset();
    _keyExchangeAnimation.reset();

    invalidate();
  }

  @override
  void update(num timestamp) {
    _updateAnimations(timestamp);

    _packet.update(timestamp);
  }

  /// Update running animations (if any).
  void _updateAnimations(num timestamp) {
    bool updated = false;

    updated = _packetTransitionAnimation.update(timestamp) || updated;
    updated = _relayNodeGrowthAnimation.update(timestamp) || updated;
    updated = _tcpConnectionAnimation.update(timestamp) || updated;
    updated = _keyExchangeAnimation.update(timestamp) || updated;

    if (updated) {
      invalidate();
    }
  }

  /// What to do on the packet transition animation end in forward direction.
  void _onPacketTransitionAnimationEndForward(num timestamp) async {
    if (_packetPosition < _route.length) {
      _packetTransitionAnimation.reset();
      _packetPosition++;
      _packet.decrypt();

      invalidate();

      if (_showBubbles && _packetPosition == 1) {
        Duration waitDuration = await _showBubble(
          "Für jeden OR auf dem Weg vom Start zum Ziel wird nun das Paket einmal entschlüsselt.",
          _packetPosition.toDouble(),
          Alignment.Center,
        );

        _packetTransitionAnimation.start(timestamp: timestamp + waitDuration.inMilliseconds);
      } else if (_showBubbles && _packetPosition == _route.length) {
        Duration waitDuration = await _showBubble(
          "Auf den unverschlüsselten Daten wird am Host ein Digest-Wert berechnet. Nun sind die Daten unverschlüsselt und der berechnete Digest-Wert passt zum Digest-Wert in der Cell. So erkennt der Relay-Knoten, dass er der Ausstiegsknoten ist.",
          _packetPosition.toDouble(),
          Alignment.Center,
        );

        _packetTransitionAnimation.start(timestamp: timestamp + waitDuration.inMilliseconds);
      } else {
        _packetTransitionAnimation.start(timestamp: timestamp); // Start transition all over again!
      }
    } else {
      _packetTransitionAnimation.reverse(); // Reverse transition direction

      if (_showBubbles) {
        Duration waitDuration = await _showBubble(
          "Der Dienst erhält die unverschlüsselten Daten. Man kann TLS verwenden, um den Datenverkehr vom letzten OR zum Dienst zu verschlüsseln.",
          (_route.length + 1).toDouble(),
          Alignment.End,
        );

        _packetTransitionAnimation.start(timestamp: timestamp + waitDuration.inMilliseconds);
      } else {
        _packetTransitionAnimation.start(timestamp: timestamp);
      }
    }

    invalidate();
  }

  /// What to do when the packet transition animation ends in reverse direction.
  void _onPacketTransitionAnimationEndReverse(num timestamp) async {
    if (_packetPosition > 0) {
      _packetTransitionAnimation.reset();
      _packetPosition--;

      // Restart transition progress
      _packetTransitionAnimation.start(timestamp: timestamp);

      _packet.encrypt(color: _encryptionLayerColors[_route.length - 1 - _packetPosition]);
    } else {
      if (_showBubbles) {
        _showBubble(
          "Die Daten sind wieder verschlüsselt beim Absender angekommen. Nun können diese mit den symmetrischen Schlüsseln ${_route.length} mal entschlüsselt werden, um wieder die Originaldaten zu erhalten.",
          0,
          Alignment.Start,
        );
      }

      await _animatePacketDecryption();

      _packet.reset();
      _packetPosition = 0;
    }

    invalidate();
  }

  /// Pause the packet transition animation and show a help bubble at the current [posIndex] position.
  Future<Duration> _showBubble(String text, double posIndex, Alignment alignment) {
    int id = ++_currentInfoBubbleID;

    _infoBubble = Bubble(
      text,
      30,
      alignment: alignment,
      opacity: 0.7,
      color: Colors.BLACK,
    );
    _infoBubblePosIndex = posIndex;

    Duration toWait = _bubbleDurationPerCharacter * _infoBubble.text.length;

    invalidate();

    return Future.delayed(toWait).then((_) {
      if (_currentInfoBubbleID == id) {
        _infoBubble = null;
        invalidate();
      }

      return toWait;
    });
  }

  /// Hide the bubble (if it is currently shown).
  void _hideBubble() {
    _currentInfoBubbleID = -1;
    _infoBubble = null;
  }

  @override
  String toString() => name;

  @override
  ComponentFactory<ControlsComponent> get controlComponentFactory => internetServiceControls.InternetServiceControlsComponentNgFactory;

  /// The minimum route length.
  int get minRouteLength => _minRouteLength;

  /// The maximum route length.
  int get maxRouteLength => _maxRouteLength;
}
