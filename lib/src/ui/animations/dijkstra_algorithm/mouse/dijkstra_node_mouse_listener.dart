import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';
import 'package:hm_animations/src/ui/canvas/mouse/canvas_mouse_listener.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';

/// Mouse listener handling mouse events on the dijkstra animation canvas.
class DijkstraNodeMouseListener implements CanvasMouseListener {
  /// Whether mouse is down.
  bool _isMouseDown = false;

  /// Point where mouse down event has been last received.
  Point<double> _mouseDownStart;

  /// Currently selected dijkstra node.
  DijkstraNode _selectedNode;

  /// Whether dragging is in progress.
  bool _isDragging = false;

  /// Currently dragged dijkstra node.
  DijkstraNode _draggedNode;

  /// Currently hovering over this dijkstra node.
  DijkstraNode _hoverNode;

  /// Window mouse up listener.
  Function _windowMouseUpListener;

  /// List of nodes in the animation.
  final List<DijkstraNode> nodes;

  /// Size of a dijkstra node.
  final double nodeSize;

  /// Current size of the canvas.
  Size _canvasSize;

  /// Create listener.
  DijkstraNodeMouseListener({
    @required this.nodes,
    @required this.nodeSize,
  });

  /// Set the current canvas size.
  void set canvasSize(Size size) => _canvasSize = size;

  /// Get the currently selected node or null if none is selected.
  DijkstraNode get selectedNode => _selectedNode;

  /// Get the currently dragged node or null if none is dragged.
  DijkstraNode get draggedNode => _draggedNode;

  /// Get the currently hovered node or null if none is hovered.
  DijkstraNode get hoverNode => _hoverNode;

  /// Initialize the listener.
  void onInit() {
    _windowMouseUpListener = (event) {
      _onWindowMouseUp(event);
    };

    window.addEventListener("mouseup", _windowMouseUpListener);
  }

  /// Destroy listener.
  void onDestroy() {
    window.removeEventListener("mouseup", _windowMouseUpListener);
  }

  /// Deselect the currently selected node.
  void deselectNode() {
    _selectedNode = null;
  }

  /// Reset mouse listener state.
  void _resetMouseListener() {
    _isMouseDown = false;
    _isDragging = false;
    _draggedNode = null;
  }

  /// What to do on mouse up on the window.
  void _onWindowMouseUp(MouseEvent event) {
    _resetMouseListener();
  }

  @override
  void onMouseUp(Point<double> pos) {
    if (!_isDragging) {
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

    _resetMouseListener();
  }

  @override
  void onMouseDown(Point<double> pos) {
    _isMouseDown = true;
    _mouseDownStart = pos;
  }

  @override
  void onMouseMove(Point<double> pos) {
    if (_isMouseDown) {
      _onDrag(pos);
    } else {
      _onHover(pos);
    }
  }

  /// What to do on mouse drag on the canvas.
  void _onDrag(Point<double> pos) {
    if (!_isDragging) {
      _isDragging = true;

      if (_draggedNode == null) {
        DijkstraNode nodeAtPos = _getNodeAtPos(pos);

        if (nodeAtPos != null) {
          _draggedNode = nodeAtPos;
        }
      }
    } else {
      if (_draggedNode != null) {
        _draggedNode.coordinates = _positionToCoordinates(pos);
      }
    }
  }

  /// What to do on mouse hover on the canvas.
  void _onHover(Point<double> pos) {
    DijkstraNode nodeAtPos = _getNodeAtPos(pos);

    if (nodeAtPos != null) {
      _hoverNode = nodeAtPos;
    } else if (_hoverNode != null) {
      _hoverNode = null;
    }
  }

  /// Get a node at the passed pos or null if no node could be found.
  DijkstraNode _getNodeAtPos(Point<double> pos) {
    Point<double> coordinates = _positionToCoordinates(pos);

    double xOffset = nodeSize * window.devicePixelRatio / _canvasSize.width;
    double yOffset = nodeSize * window.devicePixelRatio / _canvasSize.height;

    Rectangle<double> bounds = Rectangle<double>(coordinates.x - xOffset / 2, coordinates.y - yOffset / 2, xOffset, yOffset);

    for (DijkstraNode node in nodes) {
      if (bounds.containsPoint(node.coordinates)) {
        return node;
      }
    }

    return null;
  }

  /// Select the passed node.
  void _selectNode(DijkstraNode node) {
    _selectedNode = node;
  }

  /// Convert position to coordinates point.
  Point<double> _positionToCoordinates(Point<double> position) {
    return Point<double>(position.x / _canvasSize.width, position.y / _canvasSize.width);
  }

  // Convert coordinates to position point.
  Point<double> _coordinatesToPosition(Point<double> coordinates) {
    return Point<double>(coordinates.x * _canvasSize.width, coordinates.y * _canvasSize.height);
  }

  /// Add node at the passed [pos].
  void _addNode(Point<double> pos) {
    Point<double> coordinates = _positionToCoordinates(pos);

    nodes.add(DijkstraNode(size: nodeSize * window.devicePixelRatio, coordinates: coordinates));
  }
}
