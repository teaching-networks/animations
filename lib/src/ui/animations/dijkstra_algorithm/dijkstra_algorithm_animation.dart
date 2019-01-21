import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';

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
  static const int _removeKeyCode = 120;

  /// Default node size.
  static const double _nodeSize = 20.0;

  /// Whether mouse is down.
  bool _isMouseDown = false;

  /// Point where mouse down event has been last received.
  Point<double> _mouseDownStart;

  /// Window mouse up listener.
  Function _windowMouseUpListener;

  /// Window key pressed listener.
  Function _windowKeyPressListener;

  /// List of nodes to display.
  List<DijkstraNode> _nodes = List<DijkstraNode>();

  /// Currently selected dijkstra node.
  DijkstraNode _selectedNode;

  @override
  void ngOnInit() {
    _windowMouseUpListener = (event) {
      _onWindowMouseUp(event);
    };
    _windowKeyPressListener = (event) {
      _onWindowKeyPressed(event);
    };

    window.addEventListener("mouseup", _windowMouseUpListener);
    window.addEventListener("keypress", _windowKeyPressListener);
  }

  @override
  void ngOnDestroy() {
    window.removeEventListener("mouseup", _windowMouseUpListener);
    window.removeEventListener("keypress", _windowKeyPressListener);

    super.ngOnDestroy();
  }

  @override
  void render(num timestamp) {
    context.clearRect(0, 0, size.width, size.height);

    Rectangle<double> canvasRect = toRect(0, 0, size);

    setFillColor(context, Colors.CORAL);
    setStrokeColor(context, Colors.CORAL);
    if (_selectedNode != null) {
      _selectedNode.render(context, canvasRect);
    }

    setFillColor(context, Colors.BLACK);
    setStrokeColor(context, Colors.BLACK);
    for (DijkstraNode node in _nodes) {
      if (node != _selectedNode) {
        node.render(context, canvasRect);
      }
    }
  }

  /// What to do on mouse up on the window.
  void _onWindowMouseUp(MouseEvent event) {
    _isMouseDown = false;
  }

  /// What to do on window key pressed.
  void _onWindowKeyPressed(KeyboardEvent event) {
    if (event.keyCode == _removeKeyCode && _selectedNode != null) {
      _nodes.remove(_selectedNode);
      _selectedNode = null;
    }
  }

  /// What to do on mouse up on the canvas.
  void onMouseUp(Point<double> pos) {
    _isMouseDown = false;

    DijkstraNode nodeAtPos = _getNodeAtPos(pos);

    if (nodeAtPos != null) {
      _selectNode(nodeAtPos);
    } else {
      _selectedNode = null;

      if (pos == _mouseDownStart) {
        _addNode(pos);
      }
    }
  }

  /// What to do on mouse down on the canvas.
  void onMouseDown(Point<double> pos) {
    _isMouseDown = true;
    _mouseDownStart = pos;
  }

  /// What to do on mouse move on the canvas.
  void onMouseMove(Point<double> pos) {}

  /// Get the default height of the canvas.
  int get canvasHeight => 500;

  /// Get a node at the passed pos or null if no node could be found.
  DijkstraNode _getNodeAtPos(Point<double> pos) {
    Point<double> coordinates = _positionToCoordinates(pos);

    double xOffset = _nodeSize * window.devicePixelRatio / size.width;
    double yOffset = _nodeSize * window.devicePixelRatio / size.height;

    Rectangle<double> bounds = Rectangle<double>(coordinates.x - xOffset / 2, coordinates.y - yOffset / 2, xOffset, yOffset);

    for (DijkstraNode node in _nodes) {
      if (bounds.containsPoint(node.coordinates)) {
        return node;
      }
    }

    return null;
  }

  /// Add node at the passed [pos].
  void _addNode(Point<double> pos) {
    Point<double> coordinates = _positionToCoordinates(pos);

    _nodes.add(DijkstraNode(size: _nodeSize * window.devicePixelRatio, coordinates: coordinates));
  }

  /// Select the passed node.
  void _selectNode(DijkstraNode node) {
    _selectedNode = node;
  }

  /// Convert position to coordinates point.
  Point<double> _positionToCoordinates(Point<double> position) {
    return Point<double>(position.x / size.width, position.y / size.width);
  }

  // Convert coordinates to position point.
  Point<double> _coordinatesToPosition(Point<double> coordinates) {
    return Point<double>(coordinates.x * size.width, coordinates.y * size.height);
  }
}
