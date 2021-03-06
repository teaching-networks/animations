/*
 * Copyright (c) Munich University of Applied Sciences - https://hm.edu/
 * Licensed under GNU General Public License 3 (See LICENSE.md in the repositories root)
 */

import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/arrow/dijkstra_arrow.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_connection.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/mouse/canvas_mouse_listener.dart';
import 'package:hm_animations/src/ui/misc/undo_redo/impl/simple_undo_redo_manager.dart';
import 'package:hm_animations/src/ui/misc/undo_redo/undo_redo_step.dart';
import 'package:hm_animations/src/util/size.dart';
import 'package:meta/meta.dart';
import 'package:tuple/tuple.dart';

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

  /// Current size of the canvas.
  Size _canvasSize;

  /// Whether the mode is the create mode which means you cannot move nodes by dragging but instead will add arrows.
  bool _isCreateMode = false;

  /// The arrow currently creating (if any, otherwise null).
  Tuple2<Point<double>, Point<double>> _arrow;

  /// List of nodes in the animation.
  final List<DijkstraNode> nodes;

  /// Size of a dijkstra node.
  final double nodeSize;

  /// Undo redo manager used to undo / redo steps.
  final SimpleUndoRedoManager undoRedoManager;

  /// Bounds of the weight labels.
  final List<DijkstraArrow> weightBounds;

  /// Coordinates of the currently dragged node on the drag start.
  Point<double> _dragStartCoordinates;

  /// Show input dialog.
  StreamController<DijkstraNodeConnection> _showInputDialogController = new StreamController<DijkstraNodeConnection>.broadcast();

  /// Create listener.
  DijkstraNodeMouseListener({
    @required this.nodes,
    @required this.nodeSize,
    @required this.undoRedoManager,
    @required this.weightBounds,
  });

  /// Set the current canvas size.
  void set canvasSize(Size size) => _canvasSize = size;

  /// Set whether listener should be in create mode.
  void set createMode(bool createMode) => _isCreateMode = createMode;

  /// Check whether is in create mode.
  bool get isCreateMode => _isCreateMode;

  /// Get the currently selected node or null if none is selected.
  DijkstraNode get selectedNode => _selectedNode;

  /// Get the currently dragged node or null if none is dragged.
  DijkstraNode get draggedNode => _draggedNode;

  /// Get the currently hovered node or null if none is hovered.
  DijkstraNode get hoverNode => _hoverNode;

  /// Set the currently hovered node.
  void set hoverNode(DijkstraNode node) {
    _hoverNode = node;
    _hoverNode.isHovered = true;
  }

  /// Get the currently creating arrow (or null if not creating an arrow at the moment).
  Tuple2<Point<double>, Point<double>> get arrow => _arrow;

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
    if (_selectedNode == _hoverNode) {
      if (_hoverNode != null) {
        _hoverNode.isHovered = false;
      }
      _hoverNode = null;
    }

    if (_selectedNode != null) {
      _selectedNode.isSelected = false;
    }
    _selectedNode = null;
  }

  /// Reset mouse listener state.
  void _resetMouseListener() {
    _isMouseDown = false;
    _isDragging = false;
    _draggedNode = null;
    _arrow = null;
  }

  /// What to do on mouse up on the window.
  void _onWindowMouseUp(MouseEvent event) {
    _resetMouseListener();
  }

  @override
  void onMouseUp(CanvasMouseEvent event) {
    DijkstraNode nodeAtPos = _getNodeAtPos(event.pos);

    if (_isDragging) {
      if (_draggedNode != null) {
        if (_isCreateMode) {
          if (nodeAtPos != null) {
            _addArrow(_draggedNode, nodeAtPos);

            int fromId = _draggedNode.id;
            int toId = nodeAtPos.id;

            undoRedoManager.addStep(UndoRedoStep(
              undoFunction: () {
                _removeArrow(_getNodeById(fromId), _getNodeById(toId));
              },
              redoFunction: () {
                _addArrow(_getNodeById(fromId), _getNodeById(toId));
              },
            ));
          }
        } else {
          int nodeId = _draggedNode.id;
          Point<double> finalCoordinates = _positionToCoordinates(event.pos);
          Point<double> startCoordinates = _dragStartCoordinates;

          // Save node move as undo / redo step.
          undoRedoManager.addStep(UndoRedoStep(
            undoFunction: () {
              DijkstraNode node = _getNodeById(nodeId);
              node.coordinates = startCoordinates;
            },
            redoFunction: () {
              DijkstraNode node = _getNodeById(nodeId);
              node.coordinates = finalCoordinates;
            },
          ));
        }
      }
    } else {
      if (nodeAtPos != null) {
        _selectNode(nodeAtPos);
      } else {
        if (_selectedNode != null) {
          _selectedNode.isSelected = false;
        }
        _selectedNode = null;

        if (event.pos == _mouseDownStart) {
          if (_isCreateMode) {
            DijkstraNode newNode = _addNode(event.pos);

            // Add undoable step.
            undoRedoManager.addStep(UndoRedoStep(
              undoFunction: () {
                DijkstraNode nodeToRemove = _getNodeById(newNode.id);
                _removeNode(nodeToRemove);
              },
              redoFunction: () {
                _addNode(event.pos, id: newNode.id);
              },
            ));
          } else {
            DijkstraArrow weightArrow = _getWeightArrowAtPos(event.pos);
            if (weightArrow != null) {
              _showInputDialogController.add(weightArrow.connection);
            }
          }
        }
      }
    }

    _resetMouseListener();
  }

  @override
  void onMouseDown(CanvasMouseEvent event) {
    _isMouseDown = true;
    _mouseDownStart = event.pos;
  }

  @override
  void onMouseMove(CanvasMouseEvent event) {
    if (_isMouseDown) {
      _onDrag(event.pos);
    } else {
      _onHover(event.pos);
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
          _dragStartCoordinates = nodeAtPos.coordinates;
        }
      }
    }

    if (_isDragging && _draggedNode != null) {
      if (!_isCreateMode) {
        _onDragNode(pos, _draggedNode);
      } else {
        _onDragArrow(pos, _draggedNode);
      }
    }
  }

  /// Drag a node to the passed [pos].
  void _onDragNode(Point<double> pos, DijkstraNode toDrag) {
    _draggedNode.coordinates = _positionToCoordinates(pos);
  }

  /// Drag an arrow from the passed node to the passed [pos].
  void _onDragArrow(Point<double> pos, DijkstraNode toDragFrom) {
    _arrow = Tuple2(toDragFrom.coordinates, _positionToCoordinates(pos));
  }

  /// What to do on mouse hover on the canvas.
  void _onHover(Point<double> pos) {
    DijkstraNode nodeAtPos = _getNodeAtPos(pos);

    if (nodeAtPos != null) {
      _hoverNode = nodeAtPos;
      _hoverNode.isHovered = true;
    } else {
      if (_hoverNode != null) {
        _hoverNode.isHovered = false;
        _hoverNode = null;
      }
    }
  }

  DijkstraArrow _getWeightArrowAtPos(Point<double> pos) {
    for (DijkstraArrow weight in weightBounds.sublist(0)) {
      if (weight.weightBounds.containsPoint(pos)) {
        return weight;
      }
    }

    return null;
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
    if (_selectedNode != null) {
      _selectedNode.isSelected = false;
    }

    _selectedNode = node;
    _selectedNode.isSelected = true;
  }

  /// Convert position to coordinates point.
  Point<double> _positionToCoordinates(Point<double> position) {
    return Point<double>(position.x / _canvasSize.width, position.y / _canvasSize.height);
  }

  /// Add node at the passed [pos].
  DijkstraNode _addNode(
    Point<double> pos, {
    int id,
  }) {
    Point<double> coordinates = _positionToCoordinates(pos);

    int nextId = nodes.isEmpty ? 0 : _unusedId;

    DijkstraNode node = DijkstraNode(
      id: id == null ? nextId : id,
      size: nodeSize * window.devicePixelRatio,
      coordinates: coordinates,
    );
    nodes.add(node);

    return node;
  }

  /// Get the next id not in use.
  int get _unusedId => nodes.map((node) => node.id).fold(0, (int currentMax, int nextValue) => nextValue > currentMax ? nextValue : currentMax) + 1;

  /// Get a node by its id.
  DijkstraNode _getNodeById(int id) => nodes.firstWhere((node) => node.id == id);

  /// Remove the passed [node].
  void _removeNode(DijkstraNode node) {
    if (node == null) {
      return;
    }

    /// Disconnect all nodes this node is connected to and connected from.
    node.disconnectAll();

    nodes.remove(node);

    if (node == _selectedNode) {
      deselectNode();
    }
  }

  /// Add arrow [from] [to] the passed nodes.
  void _addArrow(DijkstraNode from, DijkstraNode to) {
    from.connectTo(to);
  }

  /// Remove arrow [from] [to] the passed nodes.
  void _removeArrow(DijkstraNode from, DijkstraNode to) {
    from.disconnect(to);
  }

  Stream<DijkstraNodeConnection> get showInputDialogStream => _showInputDialogController.stream;
}
