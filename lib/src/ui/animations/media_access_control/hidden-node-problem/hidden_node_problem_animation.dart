import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/ui/animations/media_access_control/hidden-node-problem/node/wireless_node.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:vector_math/vector_math.dart' as v;

/// Animation showing the hidden node problem (RTS/CTS).
@Component(
  selector: "hidden-node-problem-animation",
  styleUrls: [
    "hidden_node_problem_animation.css",
  ],
  templateUrl: "hidden_node_problem_animation.html",
  directives: [
    coreDirectives,
    CanvasComponent,
    MaterialButtonComponent,
    MaterialIconComponent,
  ],
  pipes: [
    I18nPipe,
  ],
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class HiddenNodeProblemAnimation extends CanvasAnimation implements OnInit, OnDestroy {
  /// Color of the range circle around nodes.
  static const Color _rangeCircleColor = Color.rgba(100, 100, 100, 0.4);

  /// Service to get translations from.
  final I18nService _i18n;

  /// Change detector to update angular component with.
  final ChangeDetectorRef changeDetector;

  WirelessNode _accessPoint = WirelessNode(
    nodeName: "X",
    scale: 300000000,
    nodeCircleColor: Colors.PINK_RED,
    rangeCircleColor: Colors.LIME,
  );

  List<WirelessNode> _clients = <WirelessNode>[
    WirelessNode(
      nodeName: "A",
      scale: 300000000,
      nodeCircleColor: Colors.BLUE_GRAY,
      rangeCircleColor: _rangeCircleColor,
    ),
    WirelessNode(
      nodeName: "B",
      scale: 300000000,
      nodeCircleColor: Colors.GREY_GREEN,
      rangeCircleColor: _rangeCircleColor,
    ),
    WirelessNode(
      nodeName: "C",
      scale: 300000000,
      nodeCircleColor: Colors.BORDEAUX,
      rangeCircleColor: _rangeCircleColor,
    ),
  ];

  /// The radius of nodes in the last render cycle.
  double _lastRenderRadius;

  /// The currently hovered node.
  WirelessNode _hoveredNode;

  /// Boolean used to debounce the mouse move events.
  bool _canConsumeMoreMouseMoveEvents = true;

  /// Style to apply on the canvas.
  Map<String, String> _style = {
    "cursor": "default",
  };

  LanguageChangedListener _languageChangedListener;

  /// Create animation.
  HiddenNodeProblemAnimation(this._i18n, this.changeDetector);

  @override
  void ngOnInit() {
    _languageChangedListener = (_) {
      changeDetector.markForCheck(); // Update labels.
    };
    this._i18n.addLanguageChangedListener(_languageChangedListener);
  }

  @override
  ngOnDestroy() {
    this._i18n.removeLanguageChangedListener(_languageChangedListener);

    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    double radius = min(size.width, size.height) * 0.25;
    _accessPoint.render(context, Rectangle<double>(size.width / 2, size.height / 2, radius, radius), timestamp);

    v.Vector3 vector = v.Vector3(0.0, 1.0, 0.0);
    double radiusOffset = 2 * pi / _clients.length;
    v.Quaternion quaternion = v.Quaternion.axisAngle(v.Vector3(0.0, 0.0, 1.0), radiusOffset);

    double distance = radius * 0.8;
    for (WirelessNode node in _clients) {
      node.render(context, Rectangle<double>(size.width / 2 - vector.x * distance, size.height / 2 - vector.y * distance, radius, radius), timestamp);

      quaternion.rotate(vector);
    }

    _lastRenderRadius = radius;
  }

  /// Get the height of the canvas.
  int get canvasHeight => 500;

  /// How to react to a mouse up event.
  void onMouseUp(Point<double> pos) {
    WirelessNode node = _checkHoveredNode(pos);
    if (node != null) {
      node.emitSignal(Duration(seconds: 3), Color.opacity(Colors.AMBER, 0.6));
    }
  }

  /// How to react to a mouse move event.
  void onMouseMove(Point<double> pos) {
    if (_canConsumeMoreMouseMoveEvents) {
      _canConsumeMoreMouseMoveEvents = false;

      window.animationFrame.then((timestamp) {
        WirelessNode node = _checkHoveredNode(pos);

        if (node != null) {
          setCursorType("pointer");
        } else {
          setCursorType("default");
        }

        _canConsumeMoreMouseMoveEvents = true;
      });
    }
  }

  /// Check whether there is a node hovered.
  WirelessNode _checkHoveredNode(Point<double> pos) {
    if (_lastRenderRadius == null) {
      return null;
    }

    if (_hoveredNode != null) {
      _hoveredNode.hovered = false;
      _hoveredNode = null;
    }

    double threshold = _lastRenderRadius / WirelessNode.rangeToHoverCircleRatio;
    for (WirelessNode node in _clients) {
      if (node.distanceFromCenter(pos) < threshold) {
        node.hovered = true;
        _hoveredNode = node;
        return node;
      }
    }

    return null;
  }

  /// Get the cursor css style.
  Map<String, String> get style => _style;

  /// Set the cursor type to show.
  void setCursorType(String cursorType) {
    _style["cursor"] = cursorType;
    changeDetector.markForCheck();
  }

  void test() {
    setCursorType("pointer");
  }
}
