import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/auto_dismiss/auto_dismiss.dart';
import 'package:angular_components/focus/focus.dart';
import 'package:angular_components/laminate/components/modal/modal.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_dialog/material_dialog.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_icon/material_icon_toggle.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/arrow/dijkstra_arrow.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/mouse/dijkstra_node_mouse_listener.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_connection.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/misc/undo_redo/impl/simple_undo_redo_manager.dart';
import 'package:hm_animations/src/ui/misc/undo_redo/undo_redo_step.dart';
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
    AutoDismissDirective,
    MaterialDialogComponent,
    ModalComponent,
    materialInputDirectives,
    formDirectives,
    AutoFocusDirective,
    MaterialIconToggleDirective
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

  /// Name of the keypress event.
  static const String _keyPressEventName = "keypress";

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

  /// Window key press listener.
  Function _windowKeyPressListener;

  /// Boolean used to only fire a key down event once.
  bool _keyEventFired = false;

  /// List of nodes to display.
  final List<DijkstraNode> _nodes = List<DijkstraNode>();

  /// Mouse listener to handle mouse events on the canvas.
  DijkstraNodeMouseListener mouseListener;

  /// Manager for undoing / redoing steps.
  SimpleUndoRedoManager _undoRedoManager = SimpleUndoRedoManager();

  /// Bounding boxes of the weights.
  List<DijkstraArrow> _weightBoundingBoxes = List<DijkstraArrow>();

  /// Whether to show the input dialog for new weights.
  bool _showInputDialog = false;

  StreamSubscription<DijkstraNodeConnection> _showInputDialogStreamSubscription;

  /// Currently editing node connection.
  DijkstraNodeConnection _currentlyEditingConnection;

  /// The start node for the algorithm.
  DijkstraNode _startNode;

  /// Create animation.
  DijkstraAlgorithmAnimation() {
    mouseListener = DijkstraNodeMouseListener(
      nodes: _nodes,
      nodeSize: _nodeSize,
      undoRedoManager: _undoRedoManager,
      weightBounds: _weightBoundingBoxes,
    );
  }

  /// Get the default height of the canvas.
  int get canvasHeight => 500;

  bool get showInputDialog => _showInputDialog;

  set showInputDialog(bool value) {
    _showInputDialog = value;
  }

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

    _windowKeyPressListener = (event) {
      _onWindowKeyPress(event);
    };
    window.addEventListener(_keyPressEventName, _windowKeyPressListener);

    _showInputDialogStreamSubscription = mouseListener.showInputDialogStream.listen((connection) {
      _showInputDialog = true;
      _currentlyEditingConnection = connection;
    });
  }

  @override
  void ngOnDestroy() {
    mouseListener.onDestroy();

    window.removeEventListener(_keyDownEventName, _windowKeyDownListener);
    window.removeEventListener(_keyUpEventName, _windowKeyUpListener);
    window.removeEventListener(_keyPressEventName, _windowKeyPressListener);

    _showInputDialogStreamSubscription.cancel();

    super.ngOnDestroy();
  }

  @override
  void onCanvasResize(Size newSize) {
    super.onCanvasResize(newSize);

    mouseListener.canvasSize = newSize;
  }

  @override
  void render(num timestamp) {
    _weightBoundingBoxes.clear();
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
    double headSize = _nodeSize / 2 * window.devicePixelRatio;
    double offset = _nodeSize;
    setFillColor(context, Colors.SLATE_GREY);
    setStrokeColor(context, Colors.SLATE_GREY);
    context.lineWidth = 2 * window.devicePixelRatio;

    for (DijkstraNode node in _nodes.sublist(0)) {
      if (node.connectedTo != null) {
        List<DijkstraNodeConnection> connectedTo = node.connectedTo.sublist(0);
        List<DijkstraNodeConnection> connectedFrom = node.connectedFrom?.sublist(0);

        for (DijkstraNodeConnection to in connectedTo) {
          bool isBidirectional = connectedFrom != null ? connectedFrom.where((connection) => connection.to == to.to).isNotEmpty : false;

          _drawArrow(node.coordinates, to.to.coordinates, to, headSize, offset, isBidirectional);
        }
      }
    }
  }

  /// Draw the passed [arrow] which is currently created.
  void _drawCurrentlyCreatingArrow(Tuple2<Point<double>, Point<double>> arrow) {
    setFillColor(context, Colors.CORAL);
    setStrokeColor(context, Colors.CORAL);

    context.lineWidth = 2 * window.devicePixelRatio;

    _drawArrow(arrow.item1, arrow.item2, null, _nodeSize / 2 * window.devicePixelRatio);
  }

  void _drawArrow(Point<double> from, Point<double> to, DijkstraNodeConnection connection, double headSize,
      [double offset = 0.0, bool isBidirectional = false]) {
    Point<double> start = _coordinatesToPosition(from);
    Point<double> end = _coordinatesToPosition(to);

    vector.Vector3 direction = vector.Vector3(end.x - start.x, end.y - start.y, 0.0);
    direction.length -= offset;

    // Draw line
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.beginPath();

    context.moveTo(start.x, start.y);
    if (isBidirectional) {
      vector.Vector2 lineVector = vector.Vector2(direction.x, direction.y);
      vector.Vector2 perpendicular = lineVector.scaleOrthogonalInto(1.0, vector.Vector2.all(0.0));
      perpendicular.length = 10 * window.devicePixelRatio;

      double midX = (direction.x) / 2;
      double midY = (direction.y) / 2;

      perpendicular.add(vector.Vector2(midX, midY));

      double controlPointX = start.x + perpendicular.x;
      double controlPointY = start.y + perpendicular.y;

      context.bezierCurveTo(
        controlPointX,
        controlPointY,
        controlPointX,
        controlPointY,
        start.x + direction.x,
        start.y + direction.y,
      );
      context.stroke();

      if (connection != null) {
        _drawWeight(connection, controlPointX, controlPointY);
      }
    } else {
      context.lineTo(start.x + direction.x, start.y + direction.y);
      context.stroke();

      if (connection != null) {
        _drawWeight(connection, start.x + direction.x / 2, start.y + direction.y / 2);
      }
    }

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

  /// Draw weight text.
  void _drawWeight(DijkstraNodeConnection connection, double xOffset, double yOffset) {
    String text = connection.weight.toString();

    double textHeight = defaultFontSize * 1.1;
    double textWidth = context.measureText(text).width * 1.2;

    Rectangle<double> bounds = Rectangle<double>(xOffset - textWidth / 2, yOffset - textHeight / 2, textWidth, textHeight);

    context.save();
    setFillColor(context, Colors.WHITE);
    context.beginPath();
    context.arc(xOffset, yOffset, textWidth / 2, 0, 2 * pi);
    context.fill();
    context.restore();

    context.fillText(text, xOffset, yOffset);

    _weightBoundingBoxes.add(DijkstraArrow(
      connection: connection,
      weightBounds: bounds,
    ));
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

    if (_startNode != null) {
      _drawStartNode(_startNode, canvasRect);
    }

    // Draw normal nodes.
    setFillColor(context, Colors.DARK_GRAY);
    setStrokeColor(context, Colors.DARK_GRAY);
    for (DijkstraNode node in _nodes.sublist(0)) {
      if (node != selectedNode && node != hoverNode && node != _startNode) {
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

  /// Draw a node as start node.
  void _drawStartNode(DijkstraNode node, Rectangle<double> canvasRect) {
    setFillColor(context, Colors.GREY_GREEN);
    setStrokeColor(context, Colors.GREY_GREEN);

    node.render(context, canvasRect);
  }

  /// What to do on window key down.
  void _onWindowKeyDown(KeyboardEvent event) {
    if (!_keyEventFired) {
      _keyEventFired = true;

      if (event.keyCode == _removeKeyCode && mouseListener.selectedNode != null) {
        _removeNodeAndAddUndoRedoStep(mouseListener.selectedNode);
      } else if (event.keyCode == _createModeKeyCode) {
        mouseListener.createMode = true;
      }
    }
  }

  /// Remove the passed [node] and add an undo/redo step.
  void _removeNodeAndAddUndoRedoStep(DijkstraNode node) {
    Point<double> removedNodeCoordinates = node.coordinates;
    int removedNodeId = node.id;
    List<DijkstraNodeConnection> connectedTo = node.connectedTo?.sublist(0);
    List<DijkstraNodeConnection> connectedFrom = node.connectedFrom?.sublist(0);

    _removeNode(node);

    _undoRedoManager.addStep(UndoRedoStep(
      undoFunction: () {
        DijkstraNode node = DijkstraNode(
          id: removedNodeId,
          size: _nodeSize * window.devicePixelRatio,
          coordinates: removedNodeCoordinates,
        );

        // Restore connections.
        if (connectedTo != null) {
          for (DijkstraNodeConnection to in connectedTo) {
            node.connectTo(to.to);
          }
        }
        if (connectedFrom != null) {
          for (DijkstraNodeConnection from in connectedFrom) {
            from.to.connectTo(node);
          }
        }

        _nodes.add(node);
      },
      redoFunction: () {
        _removeNode(_getNodeById(removedNodeId));
      },
    ));
  }

  /// What to do on window key up.
  void _onWindowKeyUp(KeyboardEvent event) {
    _keyEventFired = false;

    if (event.keyCode == _createModeKeyCode) {
      mouseListener.createMode = false;
    }
  }

  /// What to do on window key press.
  void _onWindowKeyPress(KeyboardEvent event) {
    if (event.ctrlKey) {
      if (event.keyCode == 26) {
        // Ctrl + z
        undo();
      } else if (event.keyCode == 25) {
        // Ctrl + y
        redo();
      }
    }

    if (showInputDialog) {
      if (event.keyCode == 13) {
        // Enter
        showInputDialog = false;
      }
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

    _nodes.remove(node);

    if (node == mouseListener.selectedNode) {
      mouseListener.deselectNode();
    }
  }

  /// Undo a step.
  void undo() {
    _undoRedoManager.undo();
  }

  /// Redo a step.
  void redo() {
    _undoRedoManager.redo();
  }

  /// Whether undo is currently possible.
  bool canUndo() => _undoRedoManager.canUndo();

  /// Whether redo is currently possible.
  bool canRedo() => _undoRedoManager.canRedo();

  /// Whether a node is currently selected.
  bool isNodeSelected() => mouseListener.selectedNode != null;

  /// Get a node by its id.
  DijkstraNode _getNodeById(int id) => _nodes.firstWhere((node) => node.id == id);

  /// Remove the currently selected node.
  void removeSelectedNode() {
    if (isNodeSelected()) {
      _removeNodeAndAddUndoRedoStep(mouseListener.selectedNode);
    }
  }

  /// Clear all connections from or to the selected node.
  void clearNodeConnections() {
    if (isNodeSelected()) {
      DijkstraNode node = mouseListener.selectedNode;

      int nodeId = node.id;
      List<DijkstraNodeConnection> connectedTo = node.connectedTo?.sublist(0);
      List<DijkstraNodeConnection> connectedFrom = node.connectedFrom?.sublist(0);

      node.disconnectAll();

      _undoRedoManager.addStep(UndoRedoStep(
        undoFunction: () {
          DijkstraNode toModify = _getNodeById(nodeId);

          if (connectedTo != null) {
            for (final to in connectedTo) {
              toModify.connectTo(to.to);
            }
          }

          if (connectedFrom != null) {
            for (final from in connectedFrom) {
              from.to.connectTo(toModify);
            }
          }
        },
        redoFunction: () {
          DijkstraNode toModify = _getNodeById(nodeId);
          toModify.disconnectAll();
        },
      ));
    }
  }

  /// Clear the current node selection.
  void clearSelection() {
    if (isNodeSelected()) {
      mouseListener.deselectNode();
    }
  }

  String get inputDialogContent => _currentlyEditingConnection != null ? _currentlyEditingConnection.weight.toString() : "";

  void setInputDialogContent(String content) {
    int value = int.tryParse(content) ?? 0;

    if (_currentlyEditingConnection != null) {
      _currentlyEditingConnection.weight = value;
    }
  }

  /// Switch between normal and create mode.
  void switchMode() {
    mouseListener.createMode = !mouseListener.isCreateMode;
  }

  /// Get the styles for the mode button.
  Map<String, String> getModeButtonStyle() => {
        "background-color": mouseListener.isCreateMode ? Colors.LIME.toCSSColorString() : Colors.WHITE.toCSSColorString(),
      };

  /// Select the currently selected node as start node.
  void selectNodeAsStart() {
    if (mouseListener.selectedNode != null) {
      _startNode = mouseListener.selectedNode;
    }
  }

  /// Start the animation.
  void start() {
    print("TEst");
  }
}
