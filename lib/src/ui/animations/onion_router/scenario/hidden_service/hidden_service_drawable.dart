import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/src/core/linker/component_factory.dart';
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
import 'package:hm_animations/src/ui/misc/image/image_info.dart';
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

  ImageInfo _hostImageInfo;
  CanvasImageSource _hostImage;

  ImageInfo _routerImageInfo;
  CanvasImageSource _routerImage;

  ImageInfo _serviceImageInfo;
  CanvasImageSource _serviceImage;

  ImageInfo _databaseImageInfo;
  CanvasImageSource _databaseImage;

  ImageInfo _scrollImageInfo;
  CanvasImageSource _scrollImage;

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

  bool _showHelpBubbles = false;

  BubbleContainer _infoBubble;
  Point<double> _infoBubblePosition;
  int _currentInfoBubbleID = 0;

  List<int> _introductionPoints = List<int>();

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

  Future<void> start(bool showHelpBubbles) async {
    _showHelpBubbles = showHelpBubbles;

    if (_showHelpBubbles) {
      await _showBubble(
        text:
            "Der Dienstanbieter erzeugt ein Schlüsselpaar (Public / Private Key). Die Schlüssel identifizieren den Dienst. So ist der Hostname, unter dem der Service aufzufinden sein wird, der halbierte SHA-1 Hash des Public Keys (Base64 kodiert) mit Suffix \".onion\". Lediglich der Dienstanbieter hat den passenden Private Key.",
        position: _serviceCoordinates,
      );
    }

    _oldRelayNodeIndicesToHighlight.clear();
    for (int i in _introductionPoints) {
      _oldRelayNodeIndicesToHighlight.add(i);
    }

    _introductionPoints.clear();
    Set<int> usedIndices = Set<int>();
    for (int i = 0; i < _introductionPointCount; i++) {
      int newIndex = _rng.nextInt(_relayNodeCoordinates.length);

      if (usedIndices.contains(newIndex)) {
        i--;
      } else {
        _introductionPoints.add(newIndex);
        usedIndices.add(newIndex);
      }
    }

    _relayNodeHighlightAnimation.start();

    if (_showHelpBubbles) {
      await _showBubble(
        text:
            "Es werden zu mehreren zufällig ausgewählten Relay Knoten Circuits aufgebaut, mit der Anfrage, als Introduction Point (IP) für den Dienst zu fungieren.",
        position: _relayNodeCoordinates[_introductionPoints.first],
      );
    }

    if (_showHelpBubbles) {
      await _showBubble(
        text:
            "Der Service generiert einen \"Hidden Service Descriptor\", welcher aus Public Key, Introduction Points besteht & mit dem Private Key signiert ist. Dieser wird in einen dezentralen Verzeichnisdienst (Distributed Hash Table) des TOR-Netzwerks hochgeladen.",
        position: _serviceCoordinates,
      );
    }

    _serviceInitAnimation.start();
  }

  void test() {
    // TODO Remove when no more needed
    _showBubble(text: "Hallo Welt!", position: Point<double>(100.5, 100.5));
  }

  void _setupAnimations() {
    _relayNodeHighlightAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(seconds: 1),
    );

    _serviceInitAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(seconds: 6),
      onEnd: (_) async {
        await _showBubble(
          text:
              "Nun kann ein Client, welcher den Hidden Service nutzen will, den Hidden Service Descriptor von der Distributed Hash Table mit Hilfe der \".onion\" Adresse abfragen.",
          position: _hostCoordinates,
        );

        _hiddenServiceDescriptorRequestAnimation.start();
      },
    );

    _hiddenServiceDescriptorRequestAnimation = AnimHelper(
      curve: Curves.easeInOutCubic,
      duration: Duration(seconds: 6),
      onEnd: (_) async {
        await _showBubble(
          text: "Nun kennt der Client die Introduction Points & den Public Key des Hidden Service.",
          position: _hostCoordinates,
        );

        // TODO Next animation step
      },
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

    _scrollImageInfo = Images.scroll;
    _scrollImage = await _scrollImageInfo.load();
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

    _drawInfoBubble();
  }

  void _drawInfoBubble() {
    if (_infoBubble == null) {
      return;
    }

    _infoBubble.render(ctx, lastPassTimestamp, x: _infoBubblePosition.x, y: _infoBubblePosition.y);
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
      indicesToHighlight: _introductionPoints,
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

    if (_serviceInitAnimation.running) {
      _drawServiceInit();
    } else if (_hiddenServiceDescriptorRequestAnimation.running) {
      _drawHiddenServiceDescriptorRequest();
    }
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
      _scrollImage,
      aspectRatio: _scrollImageInfo.aspectRatio,
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
  bool needsRepaint() => _relayNodeHighlightAnimation.running || _serviceInitAnimation.running || _hiddenServiceDescriptorRequestAnimation.running;

  @override
  void update(num timestamp) {
    _relayNodeHighlightAnimation.update(timestamp);
    _serviceInitAnimation.update(timestamp);
    _hiddenServiceDescriptorRequestAnimation.update(timestamp);
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

    final completer = Completer();
    Action end = () {
      if (_currentInfoBubbleID == id) {
        _infoBubble = null;
        invalidate();
      }

      if (!completer.isCompleted) {
        completer.complete();
      }
    };

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
          TimedButton(
            text: "Weiter...",
            duration: toWait,
            action: end,
          ),
        ],
      ),
    )..color = Color.opacity(Colors.BLACK, 0.6);

    invalidate();

    return completer.future;
  }
}
