import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_connection.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_state.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/color.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

/// Node of the dijkstra animation.
class DijkstraNode extends CanvasDrawable {
  /// Alphabet to generate node names from.
  static const String _alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

  /// Default weight of a connection between nodes.
  static const int _defaultWeight = 50;

  /// Id of the node.
  final int id;

  /// Size of the node.
  final double size;

  /// Position of the node on the canvas.
  /// The coordinates are given in range [0.0, 1.0].
  Point<double> _coordinates;

  /// Connections to other nodes.
  List<DijkstraNodeConnection> _connectedTo;

  /// Connected from other nodes.
  List<DijkstraNodeConnection> _connectedFrom;

  /// State of the node during the algorithm.
  final DijkstraNodeState _state = DijkstraNodeState();

  /// Whether the node is selected.
  bool isSelected = false;

  /// Whether the node is currently hovered.
  bool isHovered = false;

  /// Whether the node is the start node.
  bool isStartNode = false;

  /// Generated node name for this node.
  String _tmpNodeName;

  /// Create node.
  DijkstraNode({
    @required this.id,
    @required this.size,
    @required Point<double> coordinates,
  }) : _coordinates = coordinates;

  @override
  void render(CanvasRenderingContext2D context, Rectangle<double> rect, [num timestamp = -1]) {
    context.save();
    context.translate(rect.left, rect.top);

    double x = _coordinates.x * rect.width;
    double y = _coordinates.y * rect.height;

    // Draw white background
    context.save();
    setFillColor(context, Colors.WHITE);
    context.beginPath();
    context.arc(x, y, size / 2, 0, 2 * pi);
    context.fill();
    context.restore();

    Color color = _nodeColor;

    setFillColor(context, color);
    setStrokeColor(context, color);

    // Draw round border
    context.lineWidth = window.devicePixelRatio * 2;
    context.beginPath();
    context.arc(x, y, size / 2, 0, 2 * pi);
    context.stroke();

    // Draw node name and distance if any.
    context.textAlign = "center";
    context.textBaseline = "middle";
    context.font = "${defaultFontSize}px sans-serif";
    if (state.distance != null) {
      context.font = "${getMatchingFontSize(context, state.distance.toString())}px sans-serif";

      context.save();
      setFillColor(context, Colors.BLACK);
      context.fillText(state.distance.toString(), x, y);

      double labelFontSize = getMatchingFontSize(context, nodeName);
      context.font = "${labelFontSize}px sans-serif";
      double nameWidth = context.measureText(nodeName).width;
      setFillColor(context, Colors.WHITE);
      context.fillRect(x - nameWidth / 2, y - size / 2 - labelFontSize / 2, nameWidth, labelFontSize);

      setFillColor(context, Colors.SLATE_GREY);
      context.fillText(nodeName, x, y - size / 2);
      context.restore();
    } else {
      context.font = "${getMatchingFontSize(context, nodeName)}px sans-serif";
      setFillColor(context, Colors.BLACK);
      context.fillText(nodeName, x, y);
    }

    context.restore();
  }

  /// Get the matching font size for the node.
  double getMatchingFontSize(CanvasRenderingContext2D context, String text) {
    final double textWidth = context.measureText(text).width;
    final double maxSize = size - context.lineWidth * 2;

    if (textWidth > maxSize) {
      return defaultFontSize * (maxSize / textWidth);
    }

    return defaultFontSize;
  }

  /// Get the most appropriate node color.
  Color get _nodeColor {
    Color color;
    if (isSelected) {
      color = Colors.CORAL;
    } else if (state.visited) {
      color = Colors.LIME;
    } else if (isStartNode) {
      color = Colors.ORANGE;
    } else {
      color = Colors.BLACK;
    }

    if (isHovered) {
      color = Color.brighten(color, 0.5);
    }

    return color;
  }

  /// Get the points coordinates.
  Point<double> get coordinates => _coordinates;

  /// Set new coordinates for the node.
  void set coordinates(Point<double> newCoords) => _coordinates = newCoords;

  /// Get all nodes this node is connected to.
  List<DijkstraNodeConnection> get connectedTo => _connectedTo;

  /// Get all nodes this node is connected from.
  List<DijkstraNodeConnection> get connectedFrom => _connectedFrom;

  /// Connect this node to the passed [node].
  void connectTo(DijkstraNode node, {int weight = _defaultWeight}) {
    if (_connectedTo == null) {
      _connectedTo = List<DijkstraNodeConnection>();
    }
    _connectedTo.add(DijkstraNodeConnection(
      to: node,
      weight: weight,
    ));

    if (node._connectedFrom == null) {
      node._connectedFrom = List<DijkstraNodeConnection>();
    }
    node._connectedFrom.add(DijkstraNodeConnection(
      to: this,
      weight: weight,
    ));
  }

  /// Disconnect the passed [node] from this node.
  void disconnect(DijkstraNode node) {
    if (_connectedTo != null) {
      _connectedTo.removeWhere((connection) => connection.to == node);
    }

    if (node._connectedFrom != null) {
      node._connectedFrom.removeWhere((connection) => connection.to == this);
    }
  }

  /// Disconnects this node from all other nodes.
  void disconnectAll() {
    if (_connectedTo != null) {
      for (DijkstraNodeConnection to in _connectedTo) {
        disconnect(to.to);
      }
    }

    if (_connectedFrom != null) {
      for (DijkstraNodeConnection from in _connectedFrom.sublist(0)) {
        from.to.disconnect(this);
      }
    }
  }

  /// Get the state during the algorithm.
  DijkstraNodeState get state => _state;

  @override
  bool operator ==(Object other) => identical(this, other) || other is DijkstraNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Get a node name for this node.
  String get nodeName {
    if (_tmpNodeName != null) {
      return _tmpNodeName;
    }

    List<int> alphabetIndices = List<int>();
    int num = id;
    int length = _alphabet.length;
    bool first = true;

    if (num == 0) {
      alphabetIndices.add(num);
    } else {
      while (num > 0) {
        int rest = num % length;
        num ~/= length;

        alphabetIndices.add(rest);

        if (first) {
          first = false;
          length += 1;
        }
      }
    }

    String name = "";
    List<int> reversed = alphabetIndices.reversed.toList(growable: false);
    for (int i = 0; i < reversed.length; i++) {
      if (i == reversed.length - 1) {
        name += _alphabet[reversed[i]];
      } else {
        name += _alphabet[max(reversed[i] - 1, 0)];
      }
    }

    _tmpNodeName = name;

    return name;
  }
}
