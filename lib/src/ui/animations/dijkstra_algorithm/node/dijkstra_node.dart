import 'dart:html';

import 'dart:math';

import 'package:hm_animations/src/ui/canvas/canvas_drawable.dart';
import 'package:meta/meta.dart';

/// Node of the dijkstra animation.
class DijkstraNode extends CanvasDrawable {
  /// Id of the node.
  final int id;

  /// Size of the node.
  final double size;

  /// Position of the node on the canvas.
  /// The coordinates are given in range [0.0, 1.0].
  Point<double> _coordinates;

  /// Connection to other nodes.
  List<DijkstraNode> _connectedTo;

  /// Connected from other nodes.
  List<DijkstraNode> _connectedFrom;

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

    context.lineWidth = window.devicePixelRatio * 2;
    context.beginPath();
    context.arc(x, y, size / 2, 0, 2 * pi);
    context.stroke();

    context.beginPath();
    context.arc(x, y, size / 4, 0, 2 * pi);
    context.fill();

    context.restore();
  }

  /// Get the points coordinates.
  Point<double> get coordinates => _coordinates;

  /// Set new coordinates for the node.
  void set coordinates(Point<double> newCoords) => _coordinates = newCoords;

  /// Get all nodes this node is connected to.
  List<DijkstraNode> get connectedTo => _connectedTo;

  /// Get all nodes this node is connected from.
  List<DijkstraNode> get connectedFrom => _connectedFrom;

  /// Connect this node to the passed [node].
  void connectTo(DijkstraNode node) {
    if (_connectedTo == null) {
      _connectedTo = List<DijkstraNode>();
    }
    _connectedTo.add(node);

    if (node._connectedFrom == null) {
      node._connectedFrom = List<DijkstraNode>();
    }
    node._connectedFrom.add(this);
  }

  /// Disconnect the passed [node] from this node.
  void disconnect(DijkstraNode node) {
    if (_connectedTo != null) {
      _connectedTo.remove(node);
    }

    if (node._connectedFrom != null) {
      node._connectedFrom.remove(this);
    }
  }

  /// Disconnects this node from all other nodes.
  void disconnectAll() {
    if (_connectedTo != null) {
      for (DijkstraNode to in _connectedTo) {
        disconnect(to);
      }
    }

    if (_connectedFrom != null) {
      for (DijkstraNode from in _connectedFrom.sublist(0)) {
        from.disconnect(this);
      }
    }
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is DijkstraNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}