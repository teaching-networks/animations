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

  /// Window key pressed listener.
  Function _windowKeyPressListener;

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

  @override
  void ngOnInit() {
    mouseListener.onInit();

    _windowKeyPressListener = (event) {
      _onWindowKeyPressed(event);
    };

    window.addEventListener("keypress", _windowKeyPressListener);
  }

  @override
  void ngOnDestroy() {
    mouseListener.onDestroy();

    window.removeEventListener("keypress", _windowKeyPressListener);

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

    _drawNodes(canvasRect);
  }

  /// Draw all nodes.
  void _drawNodes(Rectangle<double> canvasRect) {
    DijkstraNode selectedNode = mouseListener.selectedNode;
    DijkstraNode hoverNode = mouseListener.hoverNode;

    if (selectedNode != null) {
      _drawSelectedNode(selectedNode, canvasRect);
    }

    if (hoverNode != null) {
      _drawHoveredNode(hoverNode, canvasRect);
    }

    // Draw normal nodes.
    setFillColor(context, Colors.DARK_GRAY);
    setStrokeColor(context, Colors.DARK_GRAY);
    for (DijkstraNode node in _nodes) {
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

  /// What to do on window key pressed.
  void _onWindowKeyPressed(KeyboardEvent event) {
    if (event.keyCode == _removeKeyCode && mouseListener.selectedNode != null) {
      _nodes.remove(mouseListener.selectedNode);
      mouseListener.deselectNode();
    }
  }

  /// Get the default height of the canvas.
  int get canvasHeight => 500;
}
