import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_connection.dart';
import 'package:hm_animations/src/ui/animations/dijkstra_algorithm/node/dijkstra_node_state.dart';
import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:hm_animations/src/ui/canvas/util/colors.dart';
import 'package:meta/meta.dart';

/// Node of the dijkstra animation.
class DijkstraNode extends CanvasDrawable {
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

    if (state.distance != null) {
      context.save();
      setFillColor(context, Colors.WHITE);
      context.beginPath();
      context.arc(x, y, size / 2, 0, 2 * pi);
      context.fill();
      context.restore();

      context.textAlign = "center";
      context.textBaseline = "middle";

      context.font = "${defaultFontSize}px sans-serif";

      final labelWidth = context.measureText(state.distance.toString()).width;
      if (labelWidth > size) {
        // Decrease font size accordingly
        context.font = "${defaultFontSize * (size / labelWidth)}px sans-serif";
      }

      context.fillText(state.distance.toString(), x, y);
    } else {
      context.beginPath();
      context.arc(x, y, size / 4, 0, 2 * pi);
      context.fill();
    }

    context.lineWidth = window.devicePixelRatio * 2;
    context.beginPath();
    context.arc(x, y, size / 2, 0, 2 * pi);
    context.stroke();

    context.restore();
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
  void connectTo(DijkstraNode node) {
    if (_connectedTo == null) {
      _connectedTo = List<DijkstraNodeConnection>();
    }
    _connectedTo.add(DijkstraNodeConnection(
      to: node,
      weight: _defaultWeight,
    ));

    if (node._connectedFrom == null) {
      node._connectedFrom = List<DijkstraNodeConnection>();
    }
    node._connectedFrom.add(DijkstraNodeConnection(
      to: this,
      weight: _defaultWeight,
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
}
