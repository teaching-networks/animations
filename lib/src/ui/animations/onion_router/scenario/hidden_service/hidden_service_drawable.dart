import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/src/core/linker/component_factory.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/controls_component.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/hidden_service/controls/hidden_service_controls_component.template.dart'
    as hiddenServiceControls;
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario.dart';
import 'package:hm_animations/src/ui/animations/onion_router/scenario/scenario_drawable_mixin.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawable.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/horizontal_alignment.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/layout_mode.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/drawables/layout/vertical_layout.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/anim/anim_helper.dart';
import 'package:hm_animations/src/ui/canvas/animation/v2/util/canvas_context_util.dart';
import 'package:hm_animations/src/ui/canvas/control/button/timed_button/timed_button.dart';
import 'package:hm_animations/src/ui/canvas/image/alignment/image_alignment.dart';
import 'package:hm_animations/src/ui/canvas/shapes/bubble/bubble_container.dart';
import 'package:hm_animations/src/ui/canvas/text/text_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/curves.dart';
import 'package:hm_animations/src/ui/misc/image/images.dart';
import 'package:meta/meta.dart';

/// Scenario where the service is routed only within the onion network.
class HiddenServiceDrawable extends Drawable with ScenarioDrawable implements Scenario {
  /// Number of introduction points for the hidden service.
  static const int _introductionPointCount = 3;

  /// Minimum size of the scroll image (when shrank).
  static const double _scrollMinSize = 100;

  /// Size of the scroll image when grown.
  static const double _scrollGrownSize = 200;

  /// Duration how long a bubble should be showing per character.
  static const Duration _bubbleDurationPerCharacter = Duration(milliseconds: 50);

  static Random _rng = Random();

  Rectangle<double> _hostBounds;
  Point<double> _hostCoordinates;

  Rectangle<double> _serviceBounds;
  Point<double> _serviceCoordinates;

  Rectangle<double> _databaseBounds;
  Point<double> _databaseCoordinates;

  List<Point<double>> _relativeRelayNodeCoordinates;

  List<int> _oldRelayNodeIndicesToHighlight = [];

  List<Point<double>> _relayNodeCoordinates = List<Point<double>>();
  List<Rectangle<double>> _relayNodeBounds = List<Rectangle<double>>();

  Anim _relayNodeHighlightAnimation;
  Anim _serviceInitAnimation;
  Anim _hiddenServiceDescriptorRequestAnimation;
  Anim _cookieFromClientTransmissionAnimation;
  Anim _cookieToServiceTransmissionAnimation;
  Anim _cookieFromServiceTransmissionAnimation;
  int _introductionPointToUse;
  bool _fromClient = true;
  bool _rendezvousPointConnectionEstablished = false;

  bool _showHelpBubbles = false;

  BubbleContainer _infoBubble;
  Completer _infoBubbleCompleter;
  TimedButton _infoBubbleTimedButton;
  Point<double> _infoBubblePosition;
  int _currentInfoBubbleID = 0;
  bool _autoSkipBubbles = true;

  List<int> _highlightedRelayNodes = List<int>();
  List<int> _introductionPoints = List<int>();
  int _rendezvousPoint;

  Message _name;

  /// Create service.
  HiddenServiceDrawable(this._name) {
    _init();
  }

  @override
  int get id => 2;

  @override
  String get name => _name?.toString() ?? "";

  @override
  String toString() => name;

  Future<void> _init() async {
    _setupAnimations();

    await _loadImages();

    _relativeRelayNodeCoordinates = await generateRelayNodes();

    invalidate();
  }

  /// Reset the animation.
  void _resetAnimation() {
    _hideBubble();
    _rendezvousPointConnectionEstablished = false;
  }

  Future<void> start(bool showHelpBubbles) async {
    _resetAnimation();

    _showHelpBubbles = showHelpBubbles;

    if (_showHelpBubbles) {
      try {
        await _showBubble(
          text:
              "Der Dienstanbieter erzeugt ein Schlüsselpaar (Public / Private Key). Die Schlüssel identifizieren den Dienst. So ist der Hostname, unter dem der Service aufzufinden sein wird, der halbierte SHA-1 Hash des Public Keys (Base64 kodiert) mit Suffix \".onion\". Lediglich der Dienstanbieter hat den passenden Private Key.",
          position: _serviceCoordinates,
        );
      } catch (e) {
        return;
      }
    }

    _oldRelayNodeIndicesToHighlight.clear();
    for (int i in _highlightedRelayNodes) {
      _oldRelayNodeIndicesToHighlight.add(i);
    }

    _highlightedRelayNodes.clear();
    _introductionPoints.clear();
    _rendezvousPoint = null;
    Set<int> usedIndices = Set<int>();
    for (int i = 0; i < _introductionPointCount; i++) {
      int newIndex = _rng.nextInt(_relayNodeCoordinates.length);

      if (usedIndices.contains(newIndex)) {
        i--;
      } else {
        _introductionPoints.add(newIndex);
        _highlightedRelayNodes.add(newIndex);
        usedIndices.add(newIndex);
      }
    }

    _relayNodeHighlightAnimation.start();

    if (_showHelpBubbles) {
      try {
        await _showBubble(
          text:
              "Es werden zu mehreren zufällig ausgewählten Relay Knoten Circuits aufgebaut, mit der Anfrage, als Introduction Point (IP) für den Dienst zu fungieren.",
          position: _relayNodeCoordinates[_highlightedRelayNodes.first],
        );
      } catch (e) {
        return;
      }
    }

    if (_showHelpBubbles) {
      try {
        await _showBubble(
          text:
              "Der Service generiert einen \"Hidden Service Descriptor\", welcher aus Public Key, Introduction Points besteht & mit dem Private Key signiert ist. Dieser wird in einen dezentralen Verzeichnisdienst (Distributed Hash Table) des TOR-Netzwerks hochgeladen.",
          position: _serviceCoordinates,
        );
      } catch (e) {
        return;
      }
    }

    _serviceInitAnimation.start();
  }

  void _setupAnimations() {
    _relayNodeHighlightAnimation = AnimHelper(
        curve: Curves.easeInOutCubic,
        duration: Duration(seconds: 1),
        onEnd: (_) async {
          if (_rendezvousPoint != null && _introductionPoints.isNotEmpty) {
            // Start the cookie transmission from client to the rendezvous point
            try {
              await _showBubble(
                text:
                    "Damit sich der Hidden Service später beim Rendezvous Point authentifizieren kann, generiert der Client ein One-Time-Secret/Cookie, der dem Rendezvous Point mitgeteilt wird.",
                position: _relayNodeCoordinates[_rendezvousPoint],
              );
            } catch (e) {
              return;
            }

            _cookieFromClientTransmissionAnimation.start();
          }
        });

    _serviceInitAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(seconds: 6),
      onEnd: (_) async {
        try {
          await _showBubble(
            text:
                "Nun kann ein Client, welcher den Hidden Service nutzen will, den Hidden Service Descriptor von der Distributed Hash Table mit Hilfe der \".onion\" Adresse abfragen.",
            position: _hostCoordinates,
          );
        } catch (e) {
          return;
        }

        _hiddenServiceDescriptorRequestAnimation.start();
      },
    );

    _hiddenServiceDescriptorRequestAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(seconds: 6),
      onEnd: (_) async {
        try {
          await _showBubble(
            text: "Nun kennt der Client die Introduction Points & den Public Key des Hidden Service.",
            position: _hostCoordinates,
          );
        } catch (e) {
          return;
        }

        // Choose rendezvous point and highlight it
        do {
          _rendezvousPoint = _rng.nextInt(_relativeRelayNodeCoordinates.length);
        } while (_introductionPoints.contains(_rendezvousPoint));

        try {
          await _showBubble(
            text: "Der Client baut einen Circuit zu einem beliebigen Relay Node auf, mit der Bitte als Rendezvous Point (RP) zu agieren",
            position: _relayNodeCoordinates[_rendezvousPoint],
          );
        } catch (e) {
          return;
        }

        _oldRelayNodeIndicesToHighlight.clear();
        for (int i in _introductionPoints) {
          _oldRelayNodeIndicesToHighlight.add(i);
        }
        _highlightedRelayNodes.add(_rendezvousPoint);

        _relayNodeHighlightAnimation.start();
      },
    );

    _cookieFromClientTransmissionAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(seconds: 3),
      onEnd: (_) async {
        try {
          await _showBubble(
            text:
                "Schlussendlich muss der Client dem Service noch mitteilen, dass eine Verbindung über den Rendezvous Point gewünscht ist. Dazu wird eine „Introduce Message“ (IM) mit dem One-Time-Secret/Cookie & der Adresse des Rendezvous Point verschlüsselt (mit dem Public Key des Hidden Service) an einen der, im Hidden Service Descriptor aufgelisteten, Introduction Points gesendet.",
            position: _hostCoordinates,
          );
        } catch (e) {
          return;
        }

        // Choose introduction point to use
        _introductionPointToUse = _rng.nextInt(_introductionPoints.length);

        _cookieToServiceTransmissionAnimation.start();
        _fromClient = true;
      },
    );

    _cookieToServiceTransmissionAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(seconds: 3),
      onEnd: (_) async {
        if (_fromClient) {
          _fromClient = false;
          // Cookie is now at the introduction point. Start transmission to the service.
          _cookieToServiceTransmissionAnimation.start();
        } else {
          try {
            await _showBubble(
              text:
                  "Der Hidden Service hat das One-Time-Secret/Cookie erhalten, sowie die Information, welcher Rendezvous Point die Kommunikation zwischen Service & Client vermittelt. Zu letzterem wird nun ein Circuit aufgebaut & das One-Time-Secret/Cookie in einer „Rendezvous Message“ gesendet, um die Verbindung einzuleiten.",
              position: _serviceCoordinates,
            );
          } catch (e) {
            return;
          }

          _rendezvousPointConnectionEstablished = true;
          _cookieFromServiceTransmissionAnimation.start();
        }
      },
    );

    _cookieFromServiceTransmissionAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(seconds: 3),
      onEnd: (_) async {
        try {
          await _showBubble(
            text: "Der Rendezvous Point kann anhand des mitgeschickten One-Time-Secrets/Cookies den anfragenden Client & Service zuordnen und verbinden.",
            position: _relayNodeCoordinates[_rendezvousPoint],
          );
        } catch (e) {
          return;
        }

        // Hide introduction points. Animation ended.
        _oldRelayNodeIndicesToHighlight.clear();
        for (final i in _highlightedRelayNodes) {
          _oldRelayNodeIndicesToHighlight.add(i);
        }
        _introductionPoints.clear();
        _highlightedRelayNodes = [_rendezvousPoint];
        _relayNodeHighlightAnimation.start();
      },
    );
  }

  Future<void> _loadImages() async {
    await Images.hostIconImage.load();
    await Images.serverImage.load();
    await Images.routerIconImage.load();
    await Images.database.load();
    await Images.scroll.load();
    await Images.blueRouter.load();
    await Images.cookie.load();
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

    _drawCircuitConnections();

    if (_serviceInitAnimation.running) {
      _drawServiceInit();
    } else if (_hiddenServiceDescriptorRequestAnimation.running) {
      _drawHiddenServiceDescriptorRequest();
    } else if (_cookieFromClientTransmissionAnimation.running) {
      _drawCookieTransmission(_hostCoordinates + Point<double>(_hostBounds.width / 2, 0),
          _relayNodeCoordinates[_rendezvousPoint] - Point<double>(_relayNodeBounds[_rendezvousPoint].width / 2, 0), _cookieFromClientTransmissionAnimation);
    } else if (_cookieToServiceTransmissionAnimation.running) {
      if (_fromClient) {
        _drawCookieTransmission(_hostCoordinates + Point<double>(_hostBounds.width / 2, 0), _relayNodeCoordinates[_introductionPoints[_introductionPointToUse]],
            _cookieToServiceTransmissionAnimation);
      } else {
        _drawCookieTransmission(_relayNodeCoordinates[_introductionPoints[_introductionPointToUse]],
            _serviceCoordinates - Point<double>(_serviceBounds.width / 2, 0), _cookieToServiceTransmissionAnimation);
      }
    } else if (_cookieFromServiceTransmissionAnimation.running) {
      _drawCookieTransmission(_serviceCoordinates - Point<double>(_serviceBounds.width / 2, 0),
          _relayNodeCoordinates[_rendezvousPoint] + Point<double>(_relayNodeBounds[_rendezvousPoint].width / 2, 0), _cookieFromServiceTransmissionAnimation);
    }

    _drawInfoBubble();
  }

  void _drawCookieTransmission(Point<double> from, Point<double> to, Anim animation) {
    Point<double> pos = from + (to - from) * animation.progress;

    double size = window.devicePixelRatio * 60;

    drawImageOnCanvas(
      Images.cookie.image,
      width: size,
      height: size,
      aspectRatio: Images.cookie.aspectRatio,
      x: pos.x - size / 2,
      y: pos.y - size / 2,
    );
  }

  void _drawInfoBubble() {
    if (_infoBubble == null) {
      return;
    }

    _infoBubble.render(ctx, lastPassTimestamp, x: _infoBubblePosition.x, y: _infoBubblePosition.y);
  }

  void _drawCircuitConnections() {
    setStrokeColor(Color.opacity(Colors.GREY_GREEN, 0.6));
    ctx.lineWidth = window.devicePixelRatio * 2;

    for (final i in _introductionPoints) {
      _drawCircuitConnection(Point<double>(_serviceCoordinates.x - _serviceBounds.width / 2 - 10, _serviceCoordinates.y),
          Point<double>(_relayNodeCoordinates[i].x + _relayNodeBounds[i].width / 2, _relayNodeCoordinates[i].y));
    }

    if (this._cookieToServiceTransmissionAnimation.running && _introductionPointToUse != null) {
      Point<double> introPoint = _relayNodeCoordinates[_introductionPoints[_introductionPointToUse]];
      Rectangle<double> introPointBounds = _relayNodeBounds[_introductionPoints[_introductionPointToUse]];

      _drawCircuitConnection(Point<double>(_hostCoordinates.x + _hostBounds.width / 2 + 10, _hostCoordinates.y),
          Point<double>(introPoint.x - introPointBounds.width / 2, introPoint.y));
    }

    setStrokeColor(Color.opacity(Colors.SPACE_BLUE, 0.6));

    if (_rendezvousPoint != null) {
      _drawCircuitConnection(Point<double>(_hostCoordinates.x + _hostBounds.width / 2 + 10, _hostCoordinates.y),
          Point<double>(_relayNodeCoordinates[_rendezvousPoint].x - _relayNodeBounds[_rendezvousPoint].width / 2, _relayNodeCoordinates[_rendezvousPoint].y));
    }

    if (_rendezvousPointConnectionEstablished) {
      _drawCircuitConnection(Point<double>(_serviceCoordinates.x - _serviceBounds.width / 2 - 10, _serviceCoordinates.y),
          Point<double>(_relayNodeCoordinates[_rendezvousPoint].x + _relayNodeBounds[_rendezvousPoint].width / 2, _relayNodeCoordinates[_rendezvousPoint].y));
    }
  }

  void _drawCircuitConnection(Point<double> start, Point<double> end) {
    ctx.lineCap = "round";

    Point<double> mid1 = start + (end - start) * 0.3;
    Point<double> mid2 = start + (end - start) * 0.7;

    ctx.beginPath();
    ctx.moveTo(start.x, start.y);
    ctx.lineTo(mid1.x, mid1.y);
    ctx.stroke();

    ctx.beginPath();
    ctx.setLineDash([2, 8]);
    ctx.moveTo(mid1.x, mid1.y);
    ctx.lineTo(mid2.x, mid2.y);
    ctx.stroke();
    ctx.setLineDash([]);

    ctx.beginPath();
    ctx.moveTo(mid2.x, mid2.y);
    ctx.lineTo(end.x, end.y);
    ctx.stroke();
  }

  /// Draw the scenario nodes (relay nodes or onion routers).
  void _drawNodes(Rectangle<double> rect) {
    if (_relativeRelayNodeCoordinates == null || !Images.routerIconImage.loaded || !Images.blueRouter.loaded) {
      return;
    }

    Map<int, NodeHighlightOptions> highlightOptions = {};
    if (_rendezvousPoint != null) {
      highlightOptions[_rendezvousPoint] = NodeHighlightOptions(
        replacementImageInfo: Images.blueRouter,
      );
    }

    drawNodes(
      this,
      rect,
      _relativeRelayNodeCoordinates,
      Images.routerIconImage.image,
      Images.routerIconImage,
      indicesToHighlight: _highlightedRelayNodes,
      oldIndicesToHighlight: _oldRelayNodeIndicesToHighlight,
      highlightAnimation: _relayNodeHighlightAnimation,
      coordinates: _relayNodeCoordinates,
      bounds: _relayNodeBounds,
      highlightOptions: highlightOptions,
    );
  }

  /// Draw the host icon.
  void _drawHost(Rectangle<double> rect) {
    if (!Images.hostIconImage.loaded) {
      return;
    }

    Rectangle<double> bounds = drawImageOnCanvas(
      Images.hostIconImage.image,
      aspectRatio: Images.hostIconImage.aspectRatio,
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
    if (!Images.serverImage.loaded || !Images.database.loaded) {
      return;
    }

    Rectangle<double> bounds = drawImageOnCanvas(
      Images.serverImage.image,
      aspectRatio: Images.serverImage.aspectRatio,
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
      Images.database.image,
      aspectRatio: Images.database.aspectRatio,
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

  /// Draw a scroll transfer from the passed two points.
  void _drawScrollTransfer(
    Anim animation,
    Point<double> start,
    Point<double> end, {
    double minSize = _scrollMinSize,
    double grownSize = _scrollGrownSize,
  }) {
    if (!animation.running) {
      return;
    }

    Point<double> curPos = start + (end - start) * animation.progress;

    double growProgress = sin(animation.progress * pi);

    double opacity = growProgress;
    double curSize = minSize + grownSize * growProgress;

    double oldGlobalAlpha = ctx.globalAlpha;
    ctx.globalAlpha = opacity;

    drawImageOnCanvas(
      Images.scroll.image,
      aspectRatio: Images.scroll.aspectRatio,
      width: curSize,
      height: curSize,
      x: curPos.x - curSize / 2,
      y: curPos.y - curSize / 2,
      mode: ImageDrawMode.FILL,
    );

    ctx.globalAlpha = oldGlobalAlpha;
  }

  /// Draw the request of the hidden service descriptor from the distributed hash table.
  void _drawHiddenServiceDescriptorRequest() {
    _drawScrollTransfer(_hiddenServiceDescriptorRequestAnimation, _databaseCoordinates, _hostCoordinates);
  }

  /// Draw the current state of the service initialization animation.
  void _drawServiceInit() {
    _drawScrollTransfer(_serviceInitAnimation, _serviceCoordinates, _databaseCoordinates);
  }

  @override
  bool needsRepaint() =>
      _relayNodeHighlightAnimation.running ||
      _serviceInitAnimation.running ||
      _hiddenServiceDescriptorRequestAnimation.running ||
      _cookieFromClientTransmissionAnimation.running ||
      _cookieToServiceTransmissionAnimation.running ||
      _cookieFromServiceTransmissionAnimation.running;

  @override
  void update(num timestamp) {
    _relayNodeHighlightAnimation.update(timestamp);
    _serviceInitAnimation.update(timestamp);
    _hiddenServiceDescriptorRequestAnimation.update(timestamp);
    _cookieFromClientTransmissionAnimation.update(timestamp);
    _cookieToServiceTransmissionAnimation.update(timestamp);
    _cookieFromServiceTransmissionAnimation.update(timestamp);
  }

  @override
  ComponentFactory<ControlsComponent> get controlComponentFactory => hiddenServiceControls.HiddenServiceControlsComponentNgFactory;

  /// Show a help bubble at the passed [position] with the specified [text].
  Future<void> _showBubble({
    @required String text,
    @required Point<double> position,
  }) {
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
      text: "Weiter...",
      duration: toWait,
      action: end,
    );

    _infoBubblePosition = position;
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
