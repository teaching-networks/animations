import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/mouse/dijkstra_node_mouse_listener.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:tuple/tuple.dart';
import 'package:vector_math/vector_math.dart' as vector;

/// Animation visualizing the functioning of the dijkstra algorithm to find the shortest path.
@Component(
  selector: "dijkstra-algorithm-animation",
  styleUrls: ["dijkstra_algorithm_animation.css"],
  templateUrl: "dijkstra_algorithm_animation.html",
  directives: [
    coreDirectives,
    MaterialButtonComponent,
    MaterialIconComponent,
    CanvasComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class DijkstraAlgorithmAnimation extends CanvasAnimation implements OnInit, OnDestroy {
  /// Key code of the key which will remove a selected node.
  static const int _removeKeyCode = 46;

  /// Key code of the key which will enter the create mode (dragging of nodes will draw arrows instead of moving nodes).
  static const int _createModeKeyCode = 17;

  /// Name of the keydown event.
  static const String _keyDownEventName = "keydown";

  /// Name of the keyup event.
  static const String _keyUpEventName = "keyup";

  /// Default node size.
  static const double _nodeSize = 20.0;

  /// Quaternion used to rotate an arrow head vector to the left.
  static vector.Quaternion _rotateLeft = vector.Quaternion.axisAngle(vector.Vector3(0.0, 0.0, 1.0), pi / 4 * 3);

  /// Quaternion used to rotate an arrow head vector to the right.
  static vector.Quaternion _rotateRight = vector.Quaternion.axisAngle(vector.Vector3(0.0, 0.0, 1.0), -pi / 4 * 3);

  /// Window key down listener.
  Function _windowKeyDownListener;

  /// Window key up listener.
  Function _windowKeyUpListener;

  /// Boolean used to only fire a key down event once.
  bool _keyEventFired = false;

  /// List of nodes to display.
  final List<DijkstraNode> _nodes = List<DijkstraNode>();

  /// Mouse listener to handle mouse events on the canvas.
  DijkstraNodeMouseListener mouseListener;

  /// Create animation.
  DijkstraAlgorithmAnimation() {
    mouseListener = DijkstraNodeMouseListener(
      nodes: _nodes,
      nodeSize: _nodeSize,
    );
  }

  /// Get the default height of the canvas.
  int get canvasHeight => 500;

  @override
  void ngOnInit() {
    mouseListener.onInit();

    _windowKeyDownListener = (event) {
      _onWindowKeyDown(event);
    };
    window.addEventListener(_keyDownEventName, _windowKeyDownListener);

    _windowKeyUpListener = (event) {
      _onWindowKeyUp(event);
    };
    window.addEventListener(_keyUpEventName, _windowKeyUpListener);
  }

  @override
  void ngOnDestroy() {
    mouseListener.onDestroy();

    window.removeEventListener(_keyDownEventName, _windowKeyDownListener);
    window.removeEventListener(_keyUpEventName, _windowKeyUpListener);

    super.ngOnDestroy();
  }

  @override
  void onCanvasResize(Size newSize) {
    super.onCanvasResize(newSize);

    mouseListener.canvasSize = newSize;
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    Rectangle<double> canvasRect = toRect(0, 0, size);

    _drawArrows();
    _drawNodes(canvasRect);
  }

  /// Draw all arrows.
  void _drawArrows() {
    if (mouseListener.arrow != null) {
      _drawCurrentlyCreatingArrow(mouseListener.arrow);
    }

    // Draw all normal arrows.
    double headSize = _nodeSize / 3 * window.devicePixelRatio;
    double offset = _nodeSize;
    setFillColor(context, Colors.SLATE_GREY);
    setStrokeColor(context, Colors.SLATE_GREY);
    context.lineWidth = 2 * window.devicePixelRatio;
    for (DijkstraNode node in _nodes.sublist(0)) {
      if (node.connectedTo != null) {
        for (DijkstraNode to in node.connectedTo.sublist(0)) {
          _drawArrow(node.coordinates, to.coordinates, headSize, offset);
        }
      }
    }
  }

  /// Draw the passed [arrow] which is currently created.
  void _drawCurrentlyCreatingArrow(Tuple2<Point<double>, Point<double>> arrow) {
    setFillColor(context, Colors.CORAL);
    setStrokeColor(context, Colors.CORAL);

    context.lineWidth = 2 * window.devicePixelRatio;

    _drawArrow(arrow.item1, arrow.item2, _nodeSize / 3 * window.devicePixelRatio);
  }

  void _drawArrow(Point<double> from, Point<double> to, double headSize, [double offset = 0.0]) {
    Point<double> start = _coordinatesToPosition(from);
    Point<double> end = _coordinatesToPosition(to);

    vector.Vector3 direction = vector.Vector3(end.x - start.x, end.y - start.y, 0.0);
    direction.length -= offset;

    // Draw line
    context.beginPath();

    context.moveTo(start.x, start.y);
    context.lineTo(start.x + direction.x, start.y + direction.y);

    context.stroke();

    // Draw head
    vector.Vector3 leftHead = _rotateLeft.rotated(direction);
    leftHead.length = headSize;

    vector.Vector3 rightHead = _rotateRight.rotated(direction);
    rightHead.length = headSize;

    context.beginPath();

    context.moveTo(start.x + direction.x, start.y + direction.y);
    context.lineTo(start.x + direction.x + leftHead.x, start.y + direction.y + leftHead.y);
    context.lineTo(start.x + direction.x + rightHead.x, start.y + direction.y + rightHead.y);

    context.fill();
  }

  /// Draw all nodes.
  void _drawNodes(Rectangle<double> canvasRect) {
    DijkstraNode selectedNode = mouseListener.selectedNode;
    DijkstraNode hoverNode = mouseListener.hoverNode;

    if (selectedNode != null) {
      _drawSelectedNode(selectedNode, canvasRect);
    }

    if (hoverNode != null && hoverNode != selectedNode) {
      _drawHoveredNode(hoverNode, canvasRect);
    }

    // Draw normal nodes.
    setFillColor(context, Colors.DARK_GRAY);
    setStrokeColor(context, Colors.DARK_GRAY);
    for (DijkstraNode node in _nodes.sublist(0)) {
      if (node != selectedNode && node != hoverNode) {
        node.render(context, canvasRect);
      }
    }
  }

  /// Draw a node as selected.
  void _drawSelectedNode(DijkstraNode node, Rectangle<double> canvasRect) {
    setFillColor(context, Colors.CORAL);
    setStrokeColor(context, Colors.CORAL);

    node.render(context, canvasRect);
  }

  /// Draw a node as hovered.
  void _drawHoveredNode(DijkstraNode node, Rectangle<double> canvasRect) {
    setFillColor(context, Colors.GREY);
    setStrokeColor(context, Colors.GREY);

    node.render(context, canvasRect);
  }

  /// What to do on window key down.
  void _onWindowKeyDown(KeyboardEvent event) {
    if (!_keyEventFired) {
      _keyEventFired = true;

      if (event.keyCode == _removeKeyCode && mouseListener.selectedNode != null) {
        _removeNode(mouseListener.selectedNode);
      } else if (event.keyCode == _createModeKeyCode) {
        mouseListener.createMode = true;
      }
    }
  }

  /// What to do on window key up.
  void _onWindowKeyUp(KeyboardEvent event) {
    _keyEventFired = false;

    if (event.keyCode == _createModeKeyCode) {
      mouseListener.createMode = false;
    }
  }

  // Convert coordinates to position point.
  Point<double> _coordinatesToPosition(Point<double> coordinates) {
    return Point<double>(coordinates.x * size.width, coordinates.y * size.height);
  }

  /// Remove the passed [node].
  void _removeNode(DijkstraNode node) {
    /// Disconnect all nodes this node is connected to and connected from.
    node.disconnectAll();

    _nodes.remove(mouseListener.selectedNode);
    mouseListener.deselectNode();
  }
}
