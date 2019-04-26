import 'dart:async';
import 'dart:html';
import 'dart:math';

import 'package:angular/angular.dart';
import 'package:angular_components/auto_dismiss/auto_dismiss.dart';
import 'package:angular_components/focus/focus.dart';
import 'package:angular_components/laminate/components/modal/modal.dart';
import 'package:angular_components/material_button/material_button.dart';
import 'package:angular_components/material_checkbox/material_checkbox.dart';
import 'package:angular_components/material_dialog/material_dialog.dart';
import 'package:angular_components/material_icon/material_icon.dart';
import 'package:angular_components/material_icon/material_icon_toggle.dart';
import 'package:angular_components/material_input/material_input.dart';
import 'package:angular_components/material_slider/material_slider.dart';
import 'package:angular_components/material_tooltip/material_tooltip.dart';
import 'package:angular_forms/angular_forms.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_pipe.dart';
import 'package:hm_animations/src/services/i18n_service/i18n_service.dart';
import 'package:hm_animations/src/services/storage_service/storage_service.dart';
import 'package:hm_animations/src/ui/animations/animation_ui.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/arrow/dijkstra_arrow.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/dijkstra/dijkstra.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/mouse/dijkstra_node_mouse_listener.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_connection.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/serialize/model_serializer.dart';
import 'package:hm_animations/src/ui/canvas/animation/canvas_animation.dart';
import 'package:hm_animations/src/ui/canvas/canvas_component.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:hm_animations/src/ui/canvas/util/text_util.dart';
import 'package:hm_animations/src/ui/misc/description/description.component.dart';
import 'package:hm_animations/src/ui/misc/directives/auto_select_directive.dart';
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
    MaterialIconToggleDirective,
    MaterialSliderComponent,
    MaterialCheckboxComponent,
    MaterialTooltipDirective,
    AutoSelectDirective,
    DescriptionComponent,
  ],
  pipes: [
    I18nPipe,
  ],
)
class DijkstraAlgorithmAnimation extends CanvasAnimation with AnimationUI implements OnInit, OnDestroy {
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
  static const double _nodeSize = 30.0;

  /// Key under which a Dijkstra model can be stored.
  static const String _storedModelKey = "dijkstra_algorithm.stored_model";

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

  /// Whether to show the connection deletion security question.
  bool _showDeleteConnectionSecurityQuestion = false;

  /// Whether to show the help dialog.
  bool _showHelpDialog = false;

  StreamSubscription<DijkstraNodeConnection> _showInputDialogStreamSubscription;

  /// Currently editing node connection.
  DijkstraNodeConnection _currentlyEditingConnection;

  /// The start node for the algorithm.
  DijkstraNode _startNode;

  /// Dijkstra algorithm implementation.
  Dijkstra _dijkstra = Dijkstra();

  /// Controller issuing the next steps in the animation.
  StreamController<void> _nextStepController = StreamController<void>.broadcast(sync: true);

  /// Listener listening for the next step.
  StreamSubscription _nextStepSubscription;

  /// Duration until the next step in the animation will be called.
  Duration _nextStepDuration = Duration(seconds: 4);

  /// Text field where the user can set a new weight for a connection between nodes.
  @ViewChild("newWeightTextField", read: HtmlElement)
  HtmlElement newWeightTextField;

  /// Service to retrieve translations from.
  final I18nService _i18n;

  /// Store and retrieve things.
  final StorageService _storage;

  Message modeTooltip;
  Message undoTooltip;
  Message redoTooltip;
  Message selectNodeAsStartTooltip;
  Message removeNodeTooltip;
  Message disconnectNodeTooltip;
  Message clearSelectionTooltip;
  Message startOrPauseTooltip;
  Message nextStepTooltip;
  Message resetAlgorithmTooltip;
  Message timeToNextStepTooltip;
  Message saveModelTooltip;
  Message restoreModelTooltip;
  Message clearModelTooltip;
  Message helpLabel;

  /// Create animation.
  DijkstraAlgorithmAnimation(this._i18n, this._storage) {
    mouseListener = DijkstraNodeMouseListener(
      nodes: _nodes,
      nodeSize: _nodeSize,
      undoRedoManager: _undoRedoManager,
      weightBounds: _weightBoundingBoxes,
    );
  }

  /// Initialize all translations needed by the animation.
  void _initTranslations() {
    modeTooltip = _i18n.get("dijkstra-algorithm-animation.mode.tooltip");
    undoTooltip = _i18n.get("dijkstra-algorithm-animation.undo.tooltip");
    redoTooltip = _i18n.get("dijkstra-algorithm-animation.redo.tooltip");
    selectNodeAsStartTooltip = _i18n.get("dijkstra-algorithm-animation.select-node-as-start.tooltip");
    removeNodeTooltip = _i18n.get("dijkstra-algorithm-animation.remove-node.tooltip");
    disconnectNodeTooltip = _i18n.get("dijkstra-algorithm-animation.disconnect-node.tooltip");
    clearSelectionTooltip = _i18n.get("dijkstra-algorithm-animation.clear-selection.tooltip");
    startOrPauseTooltip = _i18n.get("dijkstra-algorithm-animation.start-or-pause.tooltip");
    nextStepTooltip = _i18n.get("dijkstra-algorithm-animation.next-step.tooltip");
    resetAlgorithmTooltip = _i18n.get("dijkstra-algorithm-animation.reset-algorithm.tooltip");
    timeToNextStepTooltip = _i18n.get("dijkstra-algorithm-animation.time-to-next-step.tooltip");
    saveModelTooltip = _i18n.get("dijkstra-algorithm-animation.save-model.tooltip");
    restoreModelTooltip = _i18n.get("dijkstra-algorithm-animation.restore-model.tooltip");
    clearModelTooltip = _i18n.get("dijkstra-algorithm-animation.clear-model.tooltip");
    helpLabel = _i18n.get("dijkstra-algorithm-animation.help-label");
  }

  /// Get the default height of the canvas.
  int get canvasHeight => 600;

  bool get showInputDialog => _showInputDialog;

  void set showInputDialog(bool value) {
    _showInputDialog = value;

    if (value) {
      // Select all text in text field
      final inputField = newWeightTextField.querySelector("input");
      if (inputField != null && inputField is TextInputElement) {
        inputField.setSelectionRange(0, inputField.text.length);
      }
    } else {
      // Reset the dialog.
      showDeleteConnectionSecurityQuestion = false;
    }
  }

  /// Whether the help dialog is shown.
  bool get showHelpDialog => _showHelpDialog;

  /// Set whether to show the help dialog.
  void set showHelpDialog(bool value) {
    _showHelpDialog = value;
  }

  /// Whether the delete connection security question is shown.
  bool get showDeleteConnectionSecurityQuestion => _showDeleteConnectionSecurityQuestion;

  /// Set whether to show the delete connection security question.
  void set showDeleteConnectionSecurityQuestion(bool value) {
    _showDeleteConnectionSecurityQuestion = value;
  }

  /// The dijkstra start node name
  String get startNodeName => _startNode != null ? _startNode.nodeName : "...";

  /// Get the time it takes to reach the next step in the animation.
  int get timeToNextStep => _nextStepDuration.inSeconds;

  /// Set the time it takes to reach the next step in the animation.
  void set timeToNextStep(int newTime) {
    _nextStepDuration = Duration(seconds: newTime);
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
      showInputDialog = true;
      _currentlyEditingConnection = connection;
    });

    if (hasModelToRestore) {
      restoreModel();
    }

    _initTranslations();
  }

  @override
  void ngOnDestroy() {
    mouseListener.onDestroy();

    window.removeEventListener(_keyDownEventName, _windowKeyDownListener);
    window.removeEventListener(_keyUpEventName, _windowKeyUpListener);
    window.removeEventListener(_keyPressEventName, _windowKeyPressListener);

    _showInputDialogStreamSubscription.cancel();

    if (_nextStepSubscription != null) {
      _nextStepSubscription.cancel();
    }

    _nextStepController.close();

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

    if (_nodes.isNotEmpty) {
      _drawArrows();
      _drawNodes(canvasRect);
    } else {
      _drawHelp();
    }
  }

  /// Draw a helping message.
  void _drawHelp() {
    if (size.width < 100) {
      return;
    }

    context.textAlign = "center";
    context.textBaseline = "middle";

    context.setFillColorRgb(100, 100, 100);
    setFont(sizeFactor: 1.5, fontFamily: "Raleway, sans-serif");

    String help = helpLabel.toString();
    List<String> lines = TextUtil.wrapText(context, help, size.width);

    double offset = defaultFontSize * 1.5;
    double startOffset = size.height / 2 - (lines.length * offset) / 2;
    for (int i = 0; i < lines.length; i++) {
      context.fillText(lines[i], size.width / 2, startOffset + offset * i);
    }
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
    for (DijkstraNode node in _nodes.sublist(0)) {
      node.render(context, canvasRect);
    }
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

  /// In case the remove button has been clicked within the input dialog.
  void onInputDialogRemoveClicked() {
    if (!_showDeleteConnectionSecurityQuestion) {
      _showDeleteConnectionSecurityQuestion = true;
      return;
    }

    if (_currentlyEditingConnection != null) {
      _currentlyEditingConnection.from.disconnect(_currentlyEditingConnection.to);

      int fromId = _currentlyEditingConnection.from.id;
      int toId = _currentlyEditingConnection.to.id;
      int weight = _currentlyEditingConnection.weight;

      _undoRedoManager.addStep(UndoRedoStep(
        undoFunction: () {
          DijkstraNode from = _getNodeById(fromId);
          DijkstraNode to = _getNodeById(toId);

          from.connectTo(to, weight: weight);
        },
        redoFunction: () {
          DijkstraNode from = _getNodeById(fromId);
          DijkstraNode to = _getNodeById(toId);

          from.disconnect(to);
        },
      ));

      showInputDialog = false;
      _currentlyEditingConnection = null;
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
      if (_startNode != null) {
        _startNode.isStartNode = false;
      }

      _startNode = mouseListener.selectedNode;
      _startNode.isStartNode = true;
    }
  }

  /// Whether the animation is currently running.
  bool isAnimationRunning() => _nextStepSubscription != null;

  /// Start or pause the animation.
  void startOrPause() {
    if (isAnimationRunning()) {
      _nextStepSubscription.cancel();
      _nextStepSubscription = null;
    } else {
      if (_dijkstra.isFinished) {
        if (_startNode == null) {
          _startNode = _nodes.first;
          _startNode.isStartNode = true;
        }

        _dijkstra.initialize(_startNode, _nodes);
      }

      _nextStepSubscription = _nextStepController.stream.listen((_) {
        nextStep(cancelAnimation: false);

        if (!_dijkstra.isFinished) {
          _scheduleNextStep();
        } else {
          _nextStepSubscription.cancel();
          _nextStepSubscription = null;
        }
      });

      _scheduleNextStep();
    }
  }

  /// Schedule the next animation step.
  void _scheduleNextStep() {
    Future.delayed(_nextStepDuration).then((_) {
      if (!_nextStepController.isClosed) {
        _nextStepController.add(null);
      }
    });
  }

  /// Call the next step in the algorithm.
  void nextStep({
    bool cancelAnimation = true,
  }) {
    if (_nextStepSubscription != null && cancelAnimation) {
      _nextStepSubscription.cancel();
      _nextStepSubscription = null;
    }

    if (isFinished) {
      if (_startNode == null) {
        _startNode = _nodes.first;
        _startNode.isStartNode = true;
      }

      _dijkstra.initialize(_startNode, _nodes);
    }

    _dijkstra.nextStep();
  }

  /// Whether the algorithm finished.
  bool get isFinished => _dijkstra.isFinished;

  /// Save the current model for later use.
  void saveModel() {
    String serialized = DijkstraModelSerializer.serialize(_nodes);

    _storage.set(_storedModelKey, serialized);
  }

  /// Restore a previously stored model.
  void restoreModel() {
    if (!hasModelToRestore) {
      return;
    }

    String serialized = _storage.get(_storedModelKey);
    List<DijkstraNode> nodes = DijkstraModelSerializer.deserialize(serialized);

    clearModel();
    _nodes.addAll(nodes);

    List<DijkstraNode> startNodes = _nodes.where((node) => node.isStartNode).toList();
    if (startNodes != null && startNodes.isNotEmpty) {
      _startNode = startNodes.first;
    }
  }

  /// Clear the current model.
  void clearModel() {
    _nodes.clear();

    if (_startNode != null) {
      _startNode.isStartNode = false;
    }
    _startNode = null;

    _undoRedoManager.clear();
  }

  /// Whether there is a model that can be restored.
  bool get hasModelToRestore => _storage.contains(_storedModelKey);

  /// Reset the animation.
  void reset() {
    if (isAnimationRunning()) {
      startOrPause();
    }

    _dijkstra.reset();

    for (DijkstraNode node in _nodes) {
      node.state.reset();
    }
  }

  /// Get all nodes.
  List<DijkstraNode> get dijkstraNodes => _nodes;

  /// Serialize a node list.
  String serializeNodeList(List<DijkstraNode> nodes) => nodes.map((node) => node.nodeName).toString();
}
