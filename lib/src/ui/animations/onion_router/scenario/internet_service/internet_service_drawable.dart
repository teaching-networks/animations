/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/src/core/linker/component_factory.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/internet_service/controls/internet_service_controls_component.template.dart'
    as internetServiceControls;
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario_drawable_mixin.dart';
import 'package:hm_animations/src/ui/animations/shared/encrypted_packet/encrypted_packet.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/layout_mode.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/vertical_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim_helper.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/control/button/timed_button/timed_button.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/shapes/bubble/bubble_container.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';
import 'package:hm_animations/src/util/str/message.dart';

/// Drawable illustrating the onion network, where a service is routed within
/// the internet, but accessible from within the onion network, via
/// multi layers of onion routers (relays).
class InternetServiceDrawable extends Drawable with ScenarioDrawable implements Scenario {
  /// Duration of the packet transmission (from one point to another).
  static const Duration _packetTransitionAnimationDuration = Duration(seconds: 3);

  /// Duration of the relay node growth animation.
  static const Duration _relayNodeGrowthAnimationDuration = Duration(seconds: 1);

  /// Duration of the TCP connection establishment animation.
  static const Duration _tcpConnectionAnimationDuration = Duration(seconds: 2);

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

  final I18nService _i18n;

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

  EncryptedPacket _packet;
  int _packetPosition = 0;

  BubbleContainer _infoBubble;
  Completer _infoBubbleCompleter;
  TimedButton _infoBubbleTimedButton;
  double _infoBubblePosIndex;
  bool _showBubbles = false;
  int _currentInfoBubbleID = 0;
  bool _autoSkipBubbles = true;

  List<Point<double>> _relativeRelayNodeCoordinates;

  /// Whether TCP connections are established between the relay nodes.
  bool _tcpConnectionsEstablished = false;

  /// Whether the keys have been exchanged.
  bool _keysExchanged = false;

  /// Position (Route index) in the key exchange animation.
  int _keyExchangeAnimationPosition = 1;

  /// Current index of the tcp connection animation.
  int _tcpConnectionAnimIndex = 0;

  AnimHelper _packetTransitionAnimation;
  AnimHelper _relayNodeGrowthAnimation;
  AnimHelper _tcpConnectionAnimation;
  AnimHelper _keyExchangeAnimation;

  IdMessage<String> _name;
  IdMessage<String>_circuitConnectingMsg;
  IdMessage<String>_circuitEncryptingMsg;
  IdMessage<String>_sendingDataMsg;
  IdMessage<String>_circuitEncryptionMechanismMsg;
  IdMessage<String>_decryptionMsg;
  IdMessage<String>_exitORMsg;
  IdMessage<String>_atServiceMsg;
  IdMessage<String>_decryptionAtSenderMsg;
  IdMessage<String>_continueMsg;

  Future<void> _tcpConnectionFuture;
  Future<void> _keyExchangeBubbleFuture;

  /// Create the internet service drawable.
  InternetServiceDrawable(this._name, this._i18n) {
    _packet = EncryptedPacket(parent: this);

    _circuitConnectingMsg = _i18n.get("onion-router.internet-service.circuit-connecting");
    _circuitEncryptingMsg = _i18n.get("onion-router.internet-service.circuit-encrypting");
    _sendingDataMsg = _i18n.get("onion-router.internet-service.sending-data");
    _circuitEncryptionMechanismMsg = _i18n.get("onion-router.internet-service.onion-router-mechanism");
    _decryptionMsg = _i18n.get("onion-router.internet-service.decryption");
    _exitORMsg = _i18n.get("onion-router.internet-service.exit-or");
    _atServiceMsg = _i18n.get("onion-router.internet-service.at-service");
    _decryptionAtSenderMsg = _i18n.get("onion-router.internet-service.decryption-at-sender");
    _continueMsg = _i18n.get("onion-router.continue");

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
  String get name => _name?.toString() ?? "";

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
      onEnd: (timestamp) async {
        if (_tcpConnectionAnimIndex < this._route.length) {
          _tcpConnectionAnimIndex++;
          _tcpConnectionAnimation.start();
        } else {
          _tcpConnectionAnimIndex = 0;
          _tcpConnectionsEstablished = true;

          if (_tcpConnectionFuture != null) {
            await _tcpConnectionFuture;
          }

          _startKeyExchangeAnimation();
        }
      },
      onReset: () {
        _tcpConnectionsEstablished = false;
      },
    );

    _keyExchangeAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      onEnd: (timestamp) async {
        if (_keyExchangeAnimationPosition + 1 < _route.length + 1) {
          _keyExchangeAnimationPosition++;
          _keyExchangeAnimation.start(
            timestamp: timestamp,
            duration: Duration(milliseconds: _keyExchangeAnimationDuration.inMilliseconds * _keyExchangeAnimationPosition),
          );
        } else {
          _keysExchanged = true;

          if (_keyExchangeBubbleFuture != null) {
            await _keyExchangeBubbleFuture;
          }

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
      _tcpConnectionFuture = _showBubble(
        _circuitConnectingMsg.toString(),
        0.5,
      );
    }

    invalidate();
  }

  /// Start the key exchange animation.
  void _startKeyExchangeAnimation() {
    _keyExchangeAnimation.start(duration: _keyExchangeAnimationDuration);

    if (_showBubbles) {
      _keyExchangeBubbleFuture = _showBubble(
        _circuitEncryptingMsg.toString(),
        0.5,
      );
    }

    invalidate();
  }

  /// Start the packet transition animation.
  void _startPacketTransitionAnimation() async {
    if (_showBubbles) {
      try {
        await _showBubble(
          _sendingDataMsg.toString(),
          0,
        );
      } catch (e) {
        return;
      }
    }

    try {
      await Future.wait([
        _animatePacketInitialization(),
        if (_showBubbles)
          _showBubble(
            _circuitEncryptionMechanismMsg.toString(),
            0,
          ),
      ]);
    } catch (e) {
      return;
    }

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
        _infoBubble.render(
          ctx,
          lastPassTimestamp,
          x: coords.x,
          y: coords.y,
        );
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

      if (_tcpConnectionAnimation.running && _tcpConnectionAnimIndex == i) {
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
        return this._tcpConnectionAnimIndex > index ? Colors.SPACE_BLUE : Colors.LIGHTER_GRAY;
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

    drawNodes(
      this,
      rectangle,
      nodeCoordinates,
      _routerImage,
      _routerImageInfo,
      bounds: _relayNodeBounds,
      coordinates: _relayNodeCoordinates,
      highlightAnimation: _relayNodeGrowthAnimation,
      indicesToHighlight: _route,
      oldIndicesToHighlight: _oldRoute,
    );
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

    Set<int> usedIndices = Set<int>();

    for (int i = 0; i < routeLength; i++) {
      _route[i] = _rng.nextInt(_relativeRelayNodeCoordinates.length);

      if (usedIndices.contains(_route[i])) {
        i--; // Index already in new route -> regenerate
      } else {
        usedIndices.add(_route[i]);
      }
    }

    invalidate();
  }

  @override
  bool needsRepaint() =>
      _packetTransitionAnimation.running || _tcpConnectionAnimation.running || _relayNodeGrowthAnimation.running || _keyExchangeAnimation.running;

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
  }

  /// Update running animations (if any).
  void _updateAnimations(num timestamp) {
    _packetTransitionAnimation.update(timestamp);
    _relayNodeGrowthAnimation.update(timestamp);
    _tcpConnectionAnimation.update(timestamp);
    _keyExchangeAnimation.update(timestamp);
  }

  /// What to do on the packet transition animation end in forward direction.
  void _onPacketTransitionAnimationEndForward(num timestamp) async {
    if (_packetPosition < _route.length) {
      _packetTransitionAnimation.reset();
      _packetPosition++;
      _packet.decrypt();

      invalidate();

      if (_showBubbles && _packetPosition == 1) {
        try {
          await _showBubble(
            _decryptionMsg.toString(),
            _packetPosition.toDouble(),
          );
        } catch (e) {
          return;
        }

        _packetTransitionAnimation.start();
      } else if (_showBubbles && _packetPosition == _route.length) {
        try {
          await _showBubble(
            _exitORMsg.toString(),
            _packetPosition.toDouble(),
          );
        } catch (e) {
          return;
        }

        _packetTransitionAnimation.start();
      } else {
        _packetTransitionAnimation.start(timestamp: timestamp); // Start transition all over again!
      }
    } else {
      _packetTransitionAnimation.reverse(); // Reverse transition direction

      if (_showBubbles) {
        try {
          await _showBubble(
            _atServiceMsg.toString(),
            (_route.length + 1).toDouble(),
          );
        } catch (e) {
          return;
        }

        _packetTransitionAnimation.start();
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
          _decryptionAtSenderMsg.toString(),
          0,
        );
      }

      await _animatePacketDecryption();

      _packet.reset();
      _packetPosition = 0;
    }

    invalidate();
  }

  /// Pause the packet transition animation and show a help bubble at the current [posIndex] position.
  Future<void> _showBubble(String text, double posIndex) {
    int id = ++_currentInfoBubbleID;

    Duration toWait = _bubbleDurationPerCharacter * text.length;

    _infoBubbleCompleter = Completer();
    Action end = () {
      if (_currentInfoBubbleID == id) {
        _infoBubble = null;
        _infoBubbleTimedButton = null;
        invalidate();
      }

      if (!_infoBubbleCompleter.isCompleted) {
        _infoBubbleCompleter.complete();
      }
    };

    _infoBubbleTimedButton = TimedButton(
      text: _continueMsg.toString(),
      duration: toWait,
      action: end,
    );

    _infoBubblePosIndex = posIndex;
    _infoBubble = BubbleContainer(
      parent: this,
      drawable: VerticalLayout(
        layoutMode: LayoutMode.FIT,
        alignment: HorizontalAlignment.RIGHT,
        children: [
          TextDrawable(
            text: text,
            color: Colors.WHITE,
            wrapAtLength: 30,
          ),
          _infoBubbleTimedButton,
        ],
      ),
    )..color = Color.opacity(Colors.BLACK, 0.6);

    if (autoSkipBubbles) {
      _infoBubbleTimedButton.start();
    }

    invalidate();

    return _infoBubbleCompleter.future;
  }

  /// Hide the bubble (if it is currently shown).
  void _hideBubble() {
    _currentInfoBubbleID = -1;
    _infoBubble = null;
    _infoBubbleTimedButton = null;

    if (_infoBubbleCompleter != null && !_infoBubbleCompleter.isCompleted) {
      _infoBubbleCompleter.completeError(Exception("Bubble has been cancelled"));
    }
  }

  @override
  String toString() => name;

  @override
  ComponentFactory<ControlsComponent> get controlComponentFactory => internetServiceControls.InternetServiceControlsComponentNgFactory;

  /// The minimum route length.
  int get minRouteLength => _minRouteLength;

  /// The maximum route length.
  int get maxRouteLength => _maxRouteLength;

  bool get autoSkipBubbles => _autoSkipBubbles;

  set autoSkipBubbles(bool value) {
    _autoSkipBubbles = value;

    if (_infoBubbleTimedButton != null) {
      if (value) {
        _infoBubbleTimedButton.start();
      } else {
        _infoBubbleTimedButton.reset();
      }
    }
  }
}
